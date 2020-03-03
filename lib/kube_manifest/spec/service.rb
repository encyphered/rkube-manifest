class KubeManifest::Spec
  class Service < self
    describe apiVersion: 'v1' do
      _metadata ObjectMeta
      _spec ServiceSpec
    end
  end

  class ServiceSpec < self
    describe do
      _clusterIP String
      _externalName String
      _externalTrafficPolicy String
      _healthCheckNodePort Integer
      _loadBalancerIP String
      _loadBalancerSourceRanges String, Array
      _ports ServicePort, Array
      _publishNotReadyAddresses true | false
      _selector Hash
      _sessionAffinity String
      _sessionAffinityConfig SessionAffinityConfig
      _type String
    end
  end

  class ServicePort < self
    describe do
      _name String
      _port Integer
      _targetPort Integer
      _nodePort Integer
      _protocol String
    end
  end

  class SessionAffinityConfig < self
    describe do
      _clientIP ClientIPConfig
    end
  end

  class ClientIPConfig < self
    describe do
      _timeoutSeconds Integer
    end
  end
end
