require 'base'

class DeploymentDslTest < TestBase
  attribute :definition, :manifest

  def setup
    @definition = KubeManifest.Deployment do
      apiVersion 'apps/v1beta'
      spec replicas: 2 do
        labels = {:app => 'webapp'}

        selector matchLabels: labels do
          matchExpressions key: 'environment', operator: 'In', values: ['edge']
        end

        template do
          metadata do
            labels labels.merge(:branch => 'master')
            annotations 'ad.datadoghq.com/app.logs' => to_json([service: 'webapp', source: 'unicorn']),
                        'ad.datadoghq.com/fluentd.logs' => to_json([service: 'webapp', source: 'rails']),
                        'ad.datadoghq.com/nginx.logs' => to_json([service: 'webapp', source: 'nginx']),
                        'nginx-manifest-checksum' => sha256(manifest('../example/deployment.rb'))
          end
          spec do
            containers name: 'nginx', image: "nginx:#{_values[:nginx_version]}" do
              ports name: 'http', containerPort: 80, protocol: 'TCP'
              env name: 'DOCUMENT_ROOT', value: '/var/www'
              env name: 'PROXY_BACKEND', value: '127.0.0.1'
              env name: 'PROXY_PORT', value: '8080'
              env name: 'SET_REAL_IP_FROM', value: '10.18.0.0/16 10.19.0.0/16'
              volumeMounts mountPath: '/var/www', name: 'public'
              volumeMounts mountPath: '/opt/webapps/tmp', name: 'tmp'
            end

            containers name: 'fluentd', image: "fluentd:#{_values[:fluentd_version]}" do
              volumeMounts mountPath: '/app', name: 'log'
            end

            volumes name: 'rails-config-public', configMap: {name: 'webapp-config-files'}
            volumes name: 'rails-config-secret', secret: {secretName: 'webapp-config-files'}
            volumes name: 'rails-config-actual', emptyDir: '{}'
            volumes name: 'log', emptyDir: {}

            initContainers name: 'config-processor', image: 'yq:2.4.0' do
              volumeMounts name: 'rails-config-public', mountPath: '/var/config/public'
              volumeMounts name: 'rails-config-secret', mountPath: '/var/config/secret'
              volumeMounts name: 'rails-config-actual', mountPath: '/var/config/actual'
              command [
                          'bash', '-c', <<~EOF
                            for f in $(cat <(ls /var/config/secret) <(ls /var/config/public) | sort | uniq); do
                              if [ -f /var/config/secret/$f ] && [ -f /var/config/public/$f ]; then
                                yq merge /var/config/public/$f /var/config/secret/$f > /var/config/actual/$f
                              elif [ -f /var/config/secret/$f ] && [ ! -f /var/config/public/$f ]; then
                                cp -L /var/config/secret/$f /var/config/actual/
                              elif [ ! -f /var/config/secret/$f ] && [ -f /var/config/public/$f ]; then
                                cp -L /var/config/public/$f /var/config/actual/
                              fi
                            done
                          EOF
                      ]
            end
          end
        end

        strategy type: 'RollingUpdate',
                 rollingUpdate: {
                     maxSurge: '25%',
                     maxUnavailable: '25%'
                 }
      end

      metadata do
        namespace 'edge'
        name 'webapp'
        labels 'branch' => 'master', 'primary-container' => 'app'
      end
    end

    @definition.cwd << __dir__
    @definition.values = {
        nginx_version: '1.17.0.0',
        fluentd_version: '1.4.2.2',
    }
    @manifest = @definition.as_hash
  end

  def test_basic
    assert_equal 'apps/v1beta', @manifest[:apiVersion]
    assert_equal 'Deployment', @manifest[:kind]
    assert_include @manifest, :spec
    assert_include @manifest, :metadata
  end

  def test_metadata
    metadata = @manifest[:metadata]
    assert_equal 'webapp', metadata[:name]
    assert_equal 'edge', metadata[:namespace]

    labels = {'branch' => 'master', 'primary-container' => 'app'}
    assert_equal labels, metadata[:labels]
  end

  def test_spec
    assert_equal 2, @manifest.dig(:spec, :replicas)

    strategy = @manifest.dig(:spec, :strategy)
    assert_equal 'RollingUpdate', strategy.dig(:type)
    assert_equal '25%', strategy.dig(:rollingUpdate, :maxSurge)
    assert_equal '25%', strategy.dig(:rollingUpdate, :maxUnavailable)

    selector = @manifest.dig(:spec, :selector)
    assert_equal({app: 'webapp'}, selector.dig(:matchLabels))
    assert_equal 'environment', selector.dig(:matchExpressions, 0, :key)
    assert_equal 'In', selector.dig(:matchExpressions, 0, :operator)
    assert_equal 'edge', selector.dig(:matchExpressions, 0, :values, 0)
  end

  def test_template
    assert_include @manifest.dig(:spec, :template), :metadata
    assert_include @manifest.dig(:spec, :template), :spec
  end

  def test_template_metadata
    metadata = @manifest.dig(:spec, :template, :metadata)

    labels = {:app => 'webapp', :branch => 'master'}
    assert_equal(labels, metadata[:labels])

    annotations = {
        'ad.datadoghq.com/app.logs' => '[{"service":"webapp","source":"unicorn"}]',
        'ad.datadoghq.com/fluentd.logs' => '[{"service":"webapp","source":"rails"}]',
        'ad.datadoghq.com/nginx.logs' => '[{"service":"webapp","source":"nginx"}]',
        'nginx-manifest-checksum' => '13f8f4ea7f8f50883e0d9b252cf8a1ac4ab4add096e4dc62b723a515a0e8bade',
    }
    assert_equal(annotations, metadata[:annotations])
  end

  def test_template_spec
    spec = @manifest.dig(:spec, :template, :spec)

    assert_include spec, :containers
    assert_include spec, :volumes
    assert_include spec, :initContainers
  end

  def test_template_spec_volumes
    volumes = @manifest.dig(:spec, :template, :spec, :volumes)
    assert_equal 4, volumes.length

    assert_equal 'rails-config-public', volumes.dig(0, :name)
    assert_equal 'webapp-config-files', volumes.dig(0, :configMap, :name)
    assert_equal 'rails-config-secret', volumes.dig(1, :name)
    assert_equal 'webapp-config-files', volumes.dig(1, :secret, :secretName)
    assert_equal 'rails-config-actual', volumes.dig(2, :name)
    assert_equal '{}', volumes.dig(2, :emptyDir)
    assert_equal ({}), volumes.dig(3, :emptyDir)
  end

  def test_container
    nginx_container = @manifest.dig(:spec, :template, :spec, :containers, 0)
    assert_equal 'nginx:1.17.0.0', nginx_container[:image]
  end
end
