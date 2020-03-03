class KubeManifest::Spec
  class Deployment < self
    describe apiVersion: 'apps/v1' do
      _metadata ObjectMeta
      _spec DeploymentSpec
    end
  end

  class DeploymentSpec < self
    describe do
      _minReadySeconds Integer
      _progressDeadlineSeconds Integer
      _replicas Integer
      _revisionHistoryLimit Integer
      _selector LabelSelector
      _strategy DeploymentStrategy
      _template PodTemplateSpec
    end
  end

  class PodTemplateSpec < self
    describe do
      _metadata ObjectMeta
      _spec PodSpec
    end
  end

  class DeploymentStrategy < self
    describe do
      _type String
      _rollingUpdate RollingUpdateDeployment
    end
  end

  class RollingUpdateDeployment < self
    describe do
      _maxSurge String
      _maxUnavailable String
    end
  end
end
