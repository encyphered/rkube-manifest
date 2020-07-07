require 'base64'
require 'digest'
require 'digest/sha2'
require 'json'
require 'yaml'
require 'kube_manifest/describe'

module KubeManifest::SpecUtils
  def self.included(base)
    base.class_eval do
      protected

      def to_json(value, pretty: false)
        if pretty
          JSON.pretty_generate(value)
        else
          JSON.generate(value)
        end
      end

      def file(filename, rstrip: true)
        dir = []
        dir.concat(@_ctx.cwd || []) if @_ctx
        dir << '.'

        dir.each do |d|
          path = File.join(d, filename)
          next unless File.exists? path
          f = File.open(path).read
          if rstrip
            return f.rstrip
          end
          return f
        end

        nil
      end

      def b64encode(value)
        Base64.urlsafe_encode64(value || '')
      end

      def manifest(value)
        ctx = ::KubeManifest::Runner.new(file(value), values: self._values, cwd: self._ctx.cwd).ctx
        ctx.as_yaml
      end

      def sha256(value)
        Digest::SHA2.new(256).hexdigest(value || '')
      end

      def md5(value)
        Digest::MD5.hexdigest(value || '')
      end
    end
  end

  def self.child_node(field_name, field_type)
    lambda do |*args, **kwargs, &blk|
      value = ::KubeManifest::Describe.new_value(self, field_type, *args, **kwargs, &blk)
      self.instance_variable_set("@#{field_name}", value)
    end
  end

  def self.children_node(field_name, field_type)
    lambda do |*args, **kwargs, &blk|
      if instance_variable_get("@#{field_name}").nil?
        instance_variable_set("@#{field_name}", [])
      end
      value = ::KubeManifest::Describe.new_value(self, field_type, *args, **kwargs, &blk)
      if value.is_a? Array
        instance_variable_get("@#{field_name}").concat(value)
      else
        instance_variable_get("@#{field_name}") << value
      end
    end
  end

  def self.children_value(field_name)
    lambda do |value|
      if instance_variable_get("@#{field_name}").nil?
        instance_variable_set("@#{field_name}", [])
      end
      if value.is_a? Array
        instance_variable_get("@#{field_name}").concat(value)
      else
        instance_variable_get("@#{field_name}") << value
      end
    end
  end

  def self.child_value(field_name)
    lambda do |value|
      instance_variable_set("@#{field_name}", value)
    end
  end
end

class KubeManifest::Spec
  extend KubeManifest::DescribeHelper
  include KubeManifest::SpecUtils

  attr_accessor :_ctx
  attr_accessor :_values

  def initialize(ctx: nil, values: {})
    @_ctx = ctx
    @_values = values
  end

  def as_hash(stringify_keys=false)
    self.class.as_hash(self, stringify_keys)
  end

  def as_yaml
    self.as_hash(true).to_yaml(line_width: -1)
  end

  def empty?
    specs = self.class.class_variable_get(::KubeManifest::Describe::SPEC_VAR).keys
    (self.instance_variables.map{|s|s.to_s.sub(/^@/, '')} & specs.map{|s|s.to_s}).empty?
  end

  private

  def self.as_hash(obj, stringify_keys)
    result = {}
    if obj.kind_of? ::KubeManifest::Spec
      keys = obj.class.class_variable_get(::KubeManifest::Describe::SPEC_VAR).keys
    elsif obj.kind_of? Hash
      keys = obj.keys
    else
      return obj
    end
    keys.each do |key|
      value = if obj.kind_of? ::KubeManifest::Spec
                obj.instance_variable_get("@#{key}") || obj.send(key) rescue nil
              elsif obj.kind_of? Hash
                obj[key]
              end
      next unless value

      if value.is_a?(Array)
        value = value.reject { |v| v.respond_to?(:empty?) && v.empty? || v.nil? }
      end
      if value.respond_to?(:empty?) && value.empty?
        next unless key == :emptyDir && obj.is_a?(::KubeManifest::Spec::Volume) # Preserve emptyDir: {}
      end

      k = stringify_keys ? key.to_s : key

      if value.kind_of? Hash
        result[k] = as_hash(value, stringify_keys)
      elsif value.kind_of? ::KubeManifest::Spec
        result[k] = as_hash(value, stringify_keys)
      elsif value.is_a? Array
        result[k] = value.map{|v| as_hash(v, stringify_keys) }
      else
        result[k] = value
      end
    end

    result
  end
end
