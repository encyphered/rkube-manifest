class KubeManifest::Spec
  class Job < self
    describe apiVersion: 'batch/v1' do
      _metadata ObjectMeta
      _spec JobSpec
    end
  end

  class JobSpec < self
    describe do
      _activeDeadlineSeconds Integer
      _backoffLimit Integer
      _completions Integer
      _manualSelector true | false
      _parallelism Integer
      _selector LabelSelector
      _ttlSecondsAfterFinished Integer
      _template PodTemplateSpec
    end
  end
end
