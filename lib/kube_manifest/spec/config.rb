class KubeManifest::Spec
  class ConfigMap < self
    describe apiVersion: 'v1' do
      _metadata ObjectMeta
      _data Hash
      _binaryData Hash
    end
  end

  class Secret < self
    describe apiVersion: 'v1' do
      _type String
      _metadata ObjectMeta
      _data Hash
      _stringData Hash
    end
  end
end
