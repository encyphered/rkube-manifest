module KubeManifest
  class Context
    attr_accessor :cwd, :values

    def initialize(klass, args, &blk)
      @klass, @args, @blk = klass, args, blk
      @cwd, @values = [], {}
    end

    def evaluate(overriding: nil)
      if overriding
        @cwd = overriding.cwd
        @values = overriding.values
      end

      @manifest = @klass.new(ctx: self, values: @values)
      @manifest.instance_eval(&@blk) if @blk
      @args.each_pair do |k, v|
        @manifest.send(k, v)
      end
      @manifest
    end

    def values=(values)
      @values = values
    end

    def as_hash
      self.evaluate.as_hash
    end

    def as_yaml
      self.evaluate.as_yaml
    end
  end
end
