require 'base'

class ContainerDslTest < TestBase
  attribute :definition, :manifest

  def setup
    lifecycle = KubeManifest.LifeCycle do
      postStart exec: {command: ['bash', '-c', file('post-start-example.sh')]}
      preStop exec: {command: %w(bash -c sleep\ 5)}
    end

    @definition = KubeManifest.Container do
      _name 'app'
      image 'emeplatform.azurecr.io/sg-web-ams:latest'
      imagePullPolicy 'Always'
      ports name: 'http', containerPort: 8080, protocol: 'TCP'
      env name: 'RAILS_ENV', value: 'edge'
      envFrom configMapRef: {name: 'public-environments'}
      envFrom secretRef: {name: 'secret-environments'}

      livenessProbe _values[:probe].merge(periodSeconds: 13, initialDelaySeconds: 7)
      readinessProbe _values[:probe].merge(periodSeconds: 11, initialDelaySeconds: 5)
      lifecycle lifecycle do
        preStop exec: {command: %w(bash -c sleep\ 1)}
      end
      volumeMounts mountPath: '/var/config/public', name: 'rails-config-public'
      volumeMounts mountPath: '/var/config/secret', name: 'rails-config-secret'
      volumeMounts mountPath: '/var/config/actual', name: 'rails-config-actual'
      volumeMounts mountPath: '/var/lib/initializers', name: 'ruby-initializers'
      volumeMounts mountPath: '/var/www/', name: 'public'
      volumeMounts mountPath: '/opt/webapps/sg-web-ams/tmp', name: 'tmp'
      volumeMounts mountPath: '/opt/webapps/sg-web-ams/log', name: 'log'
      command ['/bin/sh', '-ce', 'true']
    end

    @definition.cwd << __dir__
    @definition.values = {
        probe: {
            timeoutSeconds: 1,
            successThreshold: 1,
            failureThreshold: 3,
            httpGet: {
                path: '/api/public/service/test',
                port: 'http',
                scheme: 'HTTP'
            }
        }
    }

    @manifest = @definition.as_hash
  end

  def test_container
    assert_equal 'app', @manifest[:name]
    assert_equal 'emeplatform.azurecr.io/sg-web-ams:latest', @manifest[:image]
    assert_equal 'Always', @manifest[:imagePullPolicy]

    assert_equal 8080, @manifest.dig(:ports, 0, :containerPort)
    assert_equal 'TCP', @manifest.dig(:ports, 0, :protocol)
    assert_equal 'http', @manifest.dig(:ports, 0, :name)

    assert_equal 'RAILS_ENV', @manifest.dig(:env, 0, :name)
    assert_equal 'edge', @manifest.dig(:env, 0, :value)

    assert_equal 'public-environments', @manifest.dig(:envFrom, 0, :configMapRef, :name)
    assert_equal 'secret-environments', @manifest.dig(:envFrom, 1, :secretRef, :name)

    probe = {
        timeoutSeconds: 1,
        successThreshold: 1,
        failureThreshold: 3,
        httpGet: {
            path: '/api/public/service/test',
            port: 'http',
            scheme: 'HTTP'
        }
    }
    assert_equal probe.merge(periodSeconds: 13, initialDelaySeconds: 7), @manifest[:livenessProbe]
    assert_equal probe.merge(periodSeconds: 11, initialDelaySeconds: 5), @manifest[:readinessProbe]

    assert_equal 'bash', @manifest.dig(:lifecycle, :postStart, :exec, :command, 0)
    assert_not_nil @manifest.dig(:lifecycle, :postStart, :exec, :command, 2)
    assert_equal 'bash', @manifest.dig(:lifecycle, :preStop, :exec, :command, 0)
    assert_equal 'sleep 1', @manifest.dig(:lifecycle, :preStop, :exec, :command, 2)

    assert_equal 7, @manifest[:volumeMounts].length
    assert_equal '/var/config/public', @manifest.dig(:volumeMounts, 0, :mountPath)
    assert_equal 'rails-config-public', @manifest.dig(:volumeMounts, 0, :name)

    assert_equal '/bin/sh', @manifest.dig(:command, 0)
    assert_equal '-ce', @manifest.dig(:command, 1)
    assert_equal 'true', @manifest.dig(:command, 2)
  end
end
