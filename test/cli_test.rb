require 'base'

class CliTest < TestBase
  def test_cli_mixin
    filename = File.join(__dir__, 'definitions/pod_user_defined_function.rb')
    mixin = File.join(__dir__, 'definitions/functions.rb')

    manifests = KubeManifest::CLI.run([filename], {}, mixin: mixin).map{|m|m.as_hash}
    assert_equal 'alpine:latest', manifests.dig(0, :spec, :containers, 0, :image)
  end

  def test_cli_variables
    filename = File.join(__dir__, 'definitions/variables.rb')
    manifests = KubeManifest::CLI.run([filename], {}).map{|m|m.as_hash}
    assert_equal 'tmp', manifests.dig(0, :spec, :volumes, 0, :name)
    assert_equal 'log', manifests.dig(0, :spec, :volumes, 1, :name)
  end
end
