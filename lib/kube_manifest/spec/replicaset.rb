class KubeManifest::Spec
  class ReplicaSet < self
    describe apiVersion: 'apps/v1' do
      _metadata ObjectMeta
      _spec ReplicaSetSpec
    end
  end

  class ReplicaSetSpec < self
    describe do
      _minReadySeconds Integer
      _replicas Integer
      _selector LabelSelector
      _template PodTemplateSpec
    end
  end
end
