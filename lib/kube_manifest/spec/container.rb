class KubeManifest::Spec
  class Container < self
    describe do
      _args String, Array
      _command String, Array
      _env EnvVar, Array
      _envFrom EnvFromSource, Array
      _image String
      _imagePullPolicy String
      _lifecycle LifeCycle
      _livenessProbe Probe
      _name String
      _ports ContainerPort, Array
      _readinessProbe Probe
      _resources ResourceRequirements
      _securityContext SecurityContext
      _startupProbe Probe
      _stdin true | false
      _stdinOnce true | false
      _terminationMessagePath String
      _terminationMessagePolicy String
      _tty true | false
      _volumeDevices VolumeDevice, Array
      _volumeMounts VolumeMount, Array
      _workingDir String
    end
  end

  class EnvVar < self
    describe do
      _name String
      _value String
      _valueFrom EnvVarSource
    end
  end

  class EnvVarSource < self
    describe do
      _configMapKeyRef ConfigMapKeySelector
      _fieldRef ObjectFieldSelector
      _resourceFieldRef ResourceFieldSelector
      _secretKeyRef SecretKeySelector
    end
  end

  class EnvFromSource < self
    describe do
      _prefix String
      _configMapRef ConfigMapEnvSource
      _secretRef SecretEnvSource
    end
  end

  class LifeCycle < self
    describe do
      _postStart Handler
      _preStop Handler
    end
  end

  class Probe < self
    describe do
      _exec ExecAction
      _httpGet HTTPGetAction
      _tcpSocket TCPSocketAction
      _failureThreshold Integer
      _initialDelaySeconds Integer
      _periodSeconds Integer
      _successThreshold Integer
      _timeoutSeconds Integer
    end
  end

  class ContainerPort < self
    describe do
      _name String
      _protocol String
      _containerPort Integer
      _hostIP String
      _hostPort Integer
    end
  end

  class ResourceRequirements < self
    describe do
      _limits Hash
      _requests Hash
    end
  end

  class SecurityContext < self
    describe do
      _allowPrivilegeEscalation true | false
      _capabilities Capabilities
      _privileged true | false
      _readOnlyRootFilesystem true | false
      _runAsGroup Integer
      _runAsNonRoot true | false
      _runAsUser true | false
      _seLinuxOptions SELinuxOptions
      _windowsOptions WindowsSecurityContextOptions
    end
  end

  class VolumeDevice < self
    describe do
      _devicePath String
      _name String
    end
  end

  class VolumeMount < self
    describe do
      _name String
      _mountPath String
      _readOnly true | false
      _subPath String
    end
  end

  class ConfigMapEnvSource < self
    describe do
      _name String
      _optional true | false
    end
  end

  class SecretEnvSource < self
    describe do
      _name String
      _optional true | false
    end
  end

  class ConfigMapKeySelector < self
    describe do
      _key String
      _name String
      _optional true | false
    end
  end

  class ObjectFieldSelector < self
    describe do
      _apiVersion String
      _fieldPath String
    end
  end

  class ResourceFieldSelector < self
    describe do
      _containerName String
      _divisor String
      _resource String
    end
  end

  class SecretKeySelector < self
    describe do
      _key String
      _name String
      _optional true | false
    end
  end

  class Handler < self
    describe do
      _exec ExecAction
      _httpGet HTTPGetAction
      _tcpSocket TCPSocketAction
    end
  end

  class ExecAction < self
    describe do
      _command Array
    end
  end

  class HTTPGetAction < self
    describe do
      _host String
      _path String
      _port Integer
      _httpHeaders Array
      _scheme String
    end
  end

  class TCPSocketAction < self
    describe do
      _host String
      _port Integer
    end
  end

  class Capabilities < self
    describe do
      _add String, Array
      _drop String, Array
    end
  end

  class SELinuxOptions < self
    describe do
      _level String
      _role String
      _type String
      _user String
    end
  end

  class WindowsSecurityContextOptions < self
    describe do
      _gmsaCredentialSpec String
      _gmsaCredentialSpecName String
      _runAsUserName String
    end
  end
end
