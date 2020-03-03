class KubeManifest::Spec
  class CronJob < self
    describe apiVersion: 'batch/v1beta1' do
      _metadata ObjectMeta
      _spec CronJobSpec
    end
  end

  class CronJobSpec < self
    describe do
      _concurrencyPolicy String
      _failedJobsHistoryLimit Integer
      _jobTemplate JobTemplateSpec
      _schedule String
      _startingDeadlineSeconds Integer
      _successfulJobsHistoryLimit Integer
      _suspend true | false
    end
  end

  class JobTemplateSpec < self
    describe do
      _metadata ObjectMeta
      _spec JobSpec
    end
  end
end
