class KubeManifest::Spec
  class Volume < self
    describe do
      _name String
      _emptyDir Hash
      _configMap ConfigMapVolumeSource
      _hostPath HostPathVolumeSource
      _secret SecretVolumeSource
    end
  end

  class ConfigMapVolumeSource < self
    describe do
      _name String
      _defaultMode Integer
      _items KeyToPath, Array
    end
  end

  class SecretVolumeSource < self
    describe do
      _secretName String
      _defaultMode Integer
      _items KeyToPath, Array
    end
  end

  class HostPathVolumeSource < self
    describe do
      _path String
      _type String
    end
  end

  class KeyToPath < self
    describe do
      _key String
      _mode Integer
      _path String
    end
  end
end
