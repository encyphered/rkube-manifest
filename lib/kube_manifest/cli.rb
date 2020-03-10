require 'optparse'
require 'pathname'
require 'yaml'
require 'pp'

module KubeManifest::CLI
end

module KubeManifest::CLI::Utils
  def symbolize_keys(hash)
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

  def transform_to_hash(kvs)
    result = {}
    (kvs || []).each do |v|
      pair = v.split('=')
      keys = pair.first.split('.')

      if keys.length == 1
        result[keys.first] = pair[1..-1].join('=')
      else
        child_keys = pair[0].split('.')
        converted = {}
        (child_keys.size - 1).downto(1) do |index|
          key = child_keys[index]
          if index == child_keys.size - 1
            converted = {key => pair[1..-1].join('=')}
          else
            converted = {key => converted}
          end
        end

        result[keys.first] = converted
      end
    end
    result
  end

  def merge_hash_recursive(lh, rh)
    result = lh.inject({}) { |init, (k, v)| init[k] = v; init; }
    rh.each_pair do |key, value|
      merged = if value.is_a?(Hash) && lh[key].is_a?(Hash) && rh[key].is_a?(Hash)
                 merge_hash_recursive(lh[key], rh[key])
               else
                 value
               end
      result[key] = merged
    end
    result
  end

  def expand_dir(filename)
    return nil unless filename
    return nil unless File.exist? filename

    if File.directory? filename
      return Pathname.new(filename).expand_path.to_s
    elsif File.file? filename
      return Pathname.new(File.dirname(filename)).expand_path.to_s
    end

    nil
  end
end

class KubeManifest::CLI::Exec
  include KubeManifest::CLI::Utils

  attr_accessor :options, :values, :cwd, :filenames

  def initialize(options: {}, values: {}, filenames: [])
    @options = options
    @values = values
    @filenames = filenames
    @cwd = nil
  end

  def parse_options!
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: rkube-manifest template [options] filename"

      opts.on('--set KEY=VALUE', String, 'Set values') do |v|
        @options[:values] ||= []
        @options[:values] << v
      end

      opts.on('-f VALUE_FILE', '--values VALUE_FILE', String, 'Read values from a YAML file and override') do |v|
        @options[:values_file] = v
      end

      opts.on('-v', '--[no-]verbose', 'Run verbosely. The log would be be write into stderr') do |v|
        @options[:verbose] = v
      end

      opts.on('-m METHODS_FILE', '--methods METHODS_FILE', String, 'Import methods from a given file') do |v|
        @options[:method_file] = v
      end

      opts.on("-h", "--help", "Prints this help") do
        puts opts
        exit
      end
    end

    parser.parse!

    command = ARGV.shift
    if command != 'template'
      STDERR.write "Error: unknown command: #{command}\n"
      STDERR.write parser.banner
      STDERR.write "\n"
      exit 1
    end
    @filenames = ARGV || []
    if @filenames.empty?
      STDERR.write "Error: File or directory not given\n"
      STDERR.write parser.banner
      STDERR.write "\n"
      exit 1
    end
  end

  def run
    self.load_values!
    mixin = if @options[:method_file] && File.exist?(@options[:method_file])
              @options[:method_file]
            else
              nil
            end

    if @options[:verbose]
      STDERR.write "# Processing manifests within #{@cwd} with values:\n"
      STDERR.write "#{@values.pretty_inspect.gsub(/^/, '#  ')}"
      STDERR.flush
    end
    self.class.run(@filenames, @values, cwd: @cwd, mixin: mixin, verbose: @options[:verbose])
  end

  def run!
    manifests = run
    STDOUT.write manifests.map{|m|m.as_yaml}.join("\n")
  rescue
    STDERR.write "Error: #{$!.message}\n"
    exit 2
  end

  def self.run(filenames, values, mixin: nil, cwd: nil, verbose: false)
    KubeManifest::Runner.load_mixin!(mixin)

    collected = filenames.inject([]) do |result, filename|
      if filename == '-'
        result << filename
      else
        filename = if Pathname.new(filename).absolute?
                     filename
                   else
                     Pathname.new(File.join(Dir.pwd, filename)).expand_path.to_s
                   end
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
        ctx = KubeManifest::Runner.new(STDIN.read, values: values).ctx
        result << ctx
      else
        file = File.open(filename)
        STDERR.write "# Processing #{filename}\n" if verbose
        ctx = KubeManifest::Runner.new(file.read, values: values, cwd: [cwd, File.dirname(filename)]).ctx
        if ctx.is_a? Array
          ctx.each do |m|
            result << m
          end
        elsif ctx
          result << ctx
        end
      end

      result
    end
  end

  protected

  def load_values!
    if @filenames.size == 1
      @cwd = expand_dir(@filenames.first)
    end

    @cwd ||= Dir.pwd

    values = {}

    %w(values.yml values.yaml).each do |f|
      filename = File.join(@cwd, f)
      if File.exists? filename
        begin
          values = YAML.load(File.open(filename).read)
          STDERR.write "# Reading values from #{filename}\n" if @options[:verbose]
        rescue
          values = {}
        end
      end
    end

    if @options[:values_file]
      file = File.open(@options[:values_file])
      @cwd = expand_dir(file) || Dir.pwd
      begin
        yaml_values = YAML.load(file.read)
        STDERR.write "# Reading values from #{Pathname.new(file).expand_path.to_s}\n" if @options[:verbose]
      rescue
        yaml_values = {}
      end
      values = merge_hash_recursive(values, yaml_values)
    end

    opt_values = transform_to_hash(@options[:values])
    values = merge_hash_recursive(values, opt_values)
    @values = symbolize_keys(values)
  end
end
