require 'optparse'
require 'pathname'
require 'yaml'

class KubeManifest::CLI
  def initialize
    @options = {}
    @values = {}
  end

  def prepare
    self.parse_options!
    self.load_values!
    self
  end

  def run!
    self.class.run!(@filenames, @values)
  end

  def self.run!(filenames, values, mixin: nil)
    manifests = run(filenames, values, mixin: mixin)
    STDOUT.write manifests.map{|m|m.as_yaml}.join("\n")
  end

  def self.run(filenames, values, mixin: nil)
    load_mixin!(mixin)

    collected = filenames.inject([]) do |result, filename|
      if filename == '-'
        result << filename
      else
        filename = regularize(filename)
        if File.directory? filename
          result << Dir["#{filename}/*.rb"]
        elsif File.exists? filename
          result << filename
        end
      end

      result
    end.flatten.uniq

    collected.inject([]) do |result, filename|
      if filename == '-'
        manifest = self.ctx(STDIN.read)
        manifest.values = values
        result << manifest
      else
        file = File.open(filename)
        manifest = self.ctx(file.read)
        if manifest.is_a? Array
          manifest.each do |m|
            m.values = values
            m.cwd = File.dirname(filename)
            result << m
          end
        elsif manifest
          manifest.values = values
          manifest.cwd = File.dirname(filename)
          result << manifest
        end
      end

      result
    end
  end

  protected

  def parse_options!
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: rkube-manifest [options]"

      opts.on('--set KEY=VALUE', String, 'Set values') do |v|
        @options[:values] ||= []
        @options[:values] << v
      end

      opts.on('-f VALUE_FILE', '--values VALUE_FILE', String, 'Set values from a YAML file') do |v|
        @options[:values_file] = v
      end
    end

    parser.parse!

    @filenames = ARGV
  end

  def load_values!
    if @options[:values_file]
      values = YAML.load(File.open(@options[:values_file]).read)
    else
      values = nil
      %w(values.yml values.yaml).each do |f|
        filename = File.join(Dir.pwd, f)
        if File.exists? filename
          values = YAML.load(File.open(filename).read)
        end
      end
    end

    values ||= {}

    opt_values = (@options[:values] || []).inject({}) do |init, v|
      pair = v.split('=')
      keys = pair.first.split('.')

      if keys.length == 1
        init[keys.first] = pair[1..-1].join('=')
      else
        value = self.class.transform_to_hash pair[0], pair[1..-1]
        init[keys.first] = value
      end

      init
    end

    values.merge!(opt_values)
    @values = self.class.symbolize_keys(values)
  end

  def self.ctx(definition)
    KubeManifest::Runner.new(definition).ctx
  end

  def self.load_mixin!(mixin)
    if mixin.is_a? Module
      return KubeManifest::Spec.include(mixin)
    end

    return unless mixin.is_a?(String)

    mixin = regularize(mixin)
    return unless File.exists? mixin

    methods = File.open(mixin).read

    mod = Module.new do
      private

      eval(methods)
    end
    KubeManifest::Spec.include(mod)
  end

  def self.symbolize_keys(hash)
    result = {}
    hash.each_pair do |key, value|
      v = if value.is_a? Hash
            symbolize_keys(value)
          else
            value
          end
      result[key.to_sym] = v
    end
    result
  end

  def self.transform_to_hash(key, value)
    keys = key.split('.')
    result = {}
    (keys.size - 1).downto(1) do |index|
      key = keys[index]
      if index == keys.size - 1
        result = {key => value.join('=')}
      else
        result = {key => result}
      end
    end
    result
  end

  def self.regularize(filename)
    if Pathname.new(filename).absolute?
      filename
    else
      Pathname.new(File.join(Dir.pwd, filename)).expand_path.to_s
    end
  end
end
