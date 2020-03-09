class KubeManifest::Spec
  class PersistentVolumeClaim < self
    describe apiVersion: 'v1' do
      _metadata ObjectMeta
      _spec PersistentVolumeClaimSpec
    end
  end

  class PersistentVolumeClaimSpec < self
    describe do
      _accessModes String, Array
      _dataSource TypedLocalObjectReference
      _resources ResourceRequirements
      _selector LabelSelector
      _storageClassName String
      _volumeMode String
      _volumeName String
    end
  end

  class TypedLocalObjectReference < self
    describe do
      _apiGroup String
      _kind String
      _name String
    end
  end

  class Volume < self
    describe do
      _name String
      _emptyDir Hash
      _configMap ConfigMapVolumeSource
      _hostPath HostPathVolumeSource
      _secret SecretVolumeSource
      _persistentVolumeClaim PersistentVolumeClaimVolumeSource
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

  class PersistentVolumeClaimVolumeSource < self
    describe do
      _claimName String
      _readOnly true | false
    end
  end
end
