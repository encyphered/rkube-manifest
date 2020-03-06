require 'base'

class RunnerTest < TestBase
  def test_runner
    f = File.open(File.join(__dir__, '../example/pods.rb')).read
    definition = KubeManifest::Runner.new(f).ctx
    manifest = definition.map(&:as_hash)
    assert_not_empty manifest

    assert_equal 'alpine-latest', manifest.first.dig(:metadata, :name)
    assert_equal 'alpine-3.9', manifest.last.dig(:metadata, :name)
  end

  def test_cli_variables
    filename = File.join(__dir__, '../example/variables.rb')

    runner = KubeManifest::Runner.new File.read filename
    manifest = runner.ctx.as_hash
    assert_equal 'tmp', manifest.dig(:spec, :volumes, 0, :name)
    assert_equal 'log', manifest.dig(:spec, :volumes, 1, :name)
  end

  def test_cli_mixin
    filename = File.join(__dir__, '../example/pod_user_defined_function.rb')
    mixin = File.join(__dir__, '../example/functions.rb')

    runner = KubeManifest::Runner.new File.read filename
    KubeManifest::Runner.load_mixin! mixin
    manifest = runner.ctx.as_hash

    assert_equal 'alpine:latest', manifest.dig(:spec, :containers, 0, :image)
    KubeManifest::Runner.unload_mixin! mixin
  end
end
