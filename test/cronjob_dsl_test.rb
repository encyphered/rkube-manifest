require 'base'

class CronJobDslTest < TestBase
  def test_one
    definition = KubeManifest.CronJob do
      certbot = KubeManifest.Container do
        name 'certbot'
        image 'alpine:3.9'
        ports protocol: 'TCP', containerPort: 80
        tty true
        env name: 'SECERT_PATCH_TEMPLATE', value: to_json({kind: "Secret", apiVersion: "v1", metadata: {"name"=>"NAME", "namespace"=>"NAMESPACE"}, data: {"tls.crt"=>"TLSCERT", "tls.key"=>"TLSKEY"}, "type"=>"kubernetes.io/tls"}, pretty: true)
        env name: 'KUBE_NAMESPACE', value: 'production'
        env name: 'SECRET_NAME', value: 'https-darkcrystaltactics-dot-com-v3'
        env name: 'DOMAIN', value: 'darkcrystaltactics.com'
        lifecycle(
            postStart: {
                exec: {
                    command: ['sh', '-c', 'apk add --no-cache bash curl jq python certbot']
                }
            }
        )
      end

      spec do
        jobTemplate.spec.template.spec do
          containers certbot
        end
        schedule '0 0 * * *'
        successfulJobsHistoryLimit 3
      end

      metadata name: 'letsencrypt-darkcrystaltactics-dot-com', namespace: 'production'
    end

    manifest = definition.as_hash

    assert_equal '0 0 * * *', manifest.dig(:spec, :schedule)

    container = manifest.dig(:spec, :jobTemplate, :spec, :template, :spec, :containers, 0)
    assert_not_nil container
    assert_equal 'certbot', container[:name]
    assert_equal 'alpine:3.9', container[:image]
    assert_equal true, container[:tty]
  end
end
