require 'base'

class DeploymentDescribeSpecTest < TestBase
  def test_deployment
    specs = get_specs KubeManifest::Spec::Deployment
    assert_include specs, :apiVersion
    assert_include specs, :kind
    assert_include specs, :metadata
    assert_include specs, :spec

    obj = KubeManifest::Spec::Deployment.new
    assert_equal 'apps/v1', obj.instance_variable_get('@apiVersion')
    assert_equal 'Deployment', obj.instance_variable_get('@kind')
  end

  def test_deployment_spec
    specs = get_specs KubeManifest::Spec::DeploymentSpec
    assert_include specs, :selector
    assert_include specs, :replicas
    assert_include specs, :minReadySeconds
    assert_include specs, :strategy
    assert_include specs, :template
  end

  def test_deployment_strategy
    specs = get_specs KubeManifest::Spec::DeploymentStrategy
    assert_include specs, :type
    assert_include specs, :rollingUpdate
  end

  def test_rolling_update_deployment
    specs = get_specs KubeManifest::Spec::RollingUpdateDeployment
    assert_include specs, :maxSurge
    assert_include specs, :maxUnavailable
  end

  def test_label_selector
    specs = get_specs KubeManifest::Spec::LabelSelector
    assert_include specs, :matchLabels
  end

  def test_pod_template_spec
    specs = get_specs KubeManifest::Spec::PodTemplateSpec
    assert_include specs, :metadata
    assert_include specs, :spec
  end

  def test_pod_spec
    specs = get_specs KubeManifest::Spec::PodSpec
    assert_include specs, :containers
    assert_include specs, :volumes
    assert_include specs, :initContainers
  end

  def test_container
    specs = get_specs KubeManifest::Spec::Container
    assert_include specs, :name
    assert_include specs, :image
    assert_include specs, :imagePullPolicy
    assert_include specs, :livenessProbe
    assert_include specs, :readinessProbe
    assert_include specs, :lifecycle
    assert_include specs, :ports
    assert_include specs, :env
    assert_include specs, :tty
    assert_include specs, :volumeMounts
    assert_include specs, :command
  end

  def test_container_port
    specs = get_specs KubeManifest::Spec::ContainerPort
    assert_include specs, :name
    assert_include specs, :protocol
    assert_include specs, :containerPort
    assert_include specs, :hostIP
    assert_include specs, :hostPort
  end
end
