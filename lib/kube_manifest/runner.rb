class KubeManifest::Runner
  def initialize(code)
    @code = code
  end

  def ctx
    instance_eval(@code)
  end

  def method_missing(name, *args, **kwargs, &block)
    klass_name = name.to_s
                 .sub(/^[a-z\d]*/) { |match| match.capitalize }
                 .gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub("/", "::")
    klass = ::KubeManifest::Spec.const_get(klass_name)
    ::KubeManifest::Context.new(klass, **kwargs, &block)
  end
end