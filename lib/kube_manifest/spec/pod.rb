class KubeManifest::Spec
  class Pod < self
    describe apiVersion: 'v1' do
      _metadata ObjectMeta
      _spec PodSpec
    end
  end

  class PodSpec < self
    describe do
      _containers Container, Array
      _hostAliases HostAlias, Array
      _initContainers Container, Array
      _serviceAccountName String
      _volumes Volume, Array
      _restartPolicy String
    end
  end

  class HostAlias < self
    describe do
      _hostnames String, Array
      _ip String
    end
  end
end

