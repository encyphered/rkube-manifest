require 'test/unit'
require 'kube_manifest'

class TestBase < Test::Unit::TestCase
  protected

  def get_specs(klass)
    klass.class_variable_get(::KubeManifest::Describe::SPEC_VAR)
  end
end
