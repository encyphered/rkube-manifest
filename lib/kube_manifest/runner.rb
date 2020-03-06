class KubeManifest::Runner
  @@MODULE_CACHE = {}

  def initialize(code, values: {}, cwd: [])
    @code, @values, @cwd = code, values, cwd
  end

  def ctx
    result = instance_eval(@code)
    if result.is_a? Array
      return result.map do |c|
        c.cwd = @cwd
        c.values = @values
        c
      end
    end

    result.cwd = @cwd
    result.values = @values
    result
  end

  def method_missing(name, *args, **kwargs, &block)
    klass_name = name.to_s
                 .sub(/^[a-z\d]*/) { |match| match.capitalize }
                 .gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub("/", "::")
    klass = ::KubeManifest::Spec.const_get(klass_name)
    ::KubeManifest::Context.new(klass, **kwargs, &block)
  end

  def self.load_mixin!(mixin)
    if mixin.is_a? Module
      return KubeManifest::Spec.include(mixin)
    end

    return unless mixin.is_a?(String)

    filename = if Pathname.new(mixin).absolute?
                 mixin
               else
                 Pathname.new(File.join(Dir.pwd, mixin)).expand_path.to_s
               end
    return unless File.exists? filename

    mod = @@MODULE_CACHE[filename] || Module.new do
      eval(File.open(filename).read)
    end

    @@MODULE_CACHE[filename] = mod

    KubeManifest::Spec.include(mod)
  end

  def self.unload_mixin!(mixin)
    filename = if Pathname.new(mixin).absolute?
                 mixin
               else
                 Pathname.new(File.join(Dir.pwd, mixin)).expand_path.to_s
               end

    return unless @@MODULE_CACHE.include? filename
    @@MODULE_CACHE[filename].instance_methods.each do |m|
      KubeManifest::Spec.undef_method(m)
    end
  end
end