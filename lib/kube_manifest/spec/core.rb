class KubeManifest::Spec
  class ObjectMeta < self
    describe do
      _name String
      _namespace String
      _labels Hash
      _annotations Hash
    end
  end

  class LabelSelector < self
    describe do
      _matchExpressions LabelSelectorRequirement, Array
      _matchLabels Hash
    end
  end

  class LabelSelectorRequirement < self
    describe do
      _key String
      _operator String
      _values String, Array
    end
  end
end
