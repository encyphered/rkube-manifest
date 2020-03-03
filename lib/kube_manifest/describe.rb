require 'singleton'

class KubeManifest::Describe
  SPEC_VAR = '@@spec'

  def initialize(klass)
    @klass = klass
  end

  def method_missing(name, *args, &block)
    field_name = name.to_s.gsub(/^_/, '').to_sym
    field_type = args[0]
    is_spec = field_type.is_a?(Class) && field_type.ancestors.include?(::KubeManifest::Spec)
    is_array = args[1] == Array
    if is_spec && !field_type.class_variable_defined?(::KubeManifest::Describe::SPEC_VAR)
      field_type.class_variable_set(::KubeManifest::Describe::SPEC_VAR, {})
    end

    unless @klass.instance_methods.include? field_name
      method = if is_spec && is_array
                 ::KubeManifest::SpecUtils.children_node(field_name, field_type)
               elsif is_spec && !is_array
                 ::KubeManifest::SpecUtils.child_node(field_name, field_type)
               elsif !is_spec && is_array
                 ::KubeManifest::SpecUtils.children_value(field_name)
               else
                 ::KubeManifest::SpecUtils.child_value(field_name)
               end
      @klass.define_method(field_name, method)
      @klass.alias_method name, field_name
    end

    @klass.class_variable_get(::KubeManifest::Describe::SPEC_VAR)[field_name] = field_type
  end

  def self.new_value(obj, klass, *args, **kwargs, &block)
    if args.first.is_a? ::KubeManifest::Context
      returning = args.first.evaluate(overriding: obj._ctx)
      returning.instance_eval(&block) if block
      return returning
    elsif args.first.is_a? Array
      args = args.first
      returning = args.map do |arg|
        if arg.is_a? ::KubeManifest::Context
          arg.evaluate(overriding: obj._ctx)
        else
          arg
        end
      end
      return returning
    end

    returning = klass.new(ctx: obj._ctx, values: obj._values)
    returning.instance_eval(&block) if block
    kwargs.each_pair do |key, value|
      field_type = klass.class_variable_get(::KubeManifest::Describe::SPEC_VAR)[key]
      is_spec = field_type.is_a?(Class) && field_type.ancestors.include?(::KubeManifest::Spec)
      if is_spec
        if value.is_a? Hash
          child = ::KubeManifest::Describe.new_value(obj, field_type, *args, **value, &nil)
          returning.instance_variable_set("@#{key}", child)
        elsif value.is_a? Array
          child = value.map { |e| e.class == ::KubeManifest::Context ? e.evaluate(overriding: obj._ctx) : e }
          returning.instance_variable_set("@#{key}", child)
        end
      else
        returning.instance_variable_set("@#{key}", value)
      end
    end
    returning
  end
end

class KubeManifest::Describer
  include Singleton

  attr_accessor :describers

  def initialize
    @describers = []
  end

  def self.append(klass, defaults, block)
    self.instance.describers.append([klass, defaults, block])
  end

  def self.describe!
    self.instance.describers.each do |pair|
      klass, defaults, block = pair

      ::KubeManifest.define_singleton_method klass.name.split('::').last do |**args, &blk|
        ::KubeManifest::Context.new(klass, args, &blk)
      end

      unless defaults.empty?
        klass.define_method(:initialize) do |**kwargs|
          super(**kwargs)
          defaults.each_pair do |key, value|
            instance_variable_set("@#{key}", value)
          end
        end
      end

      describer = ::KubeManifest::Describe.new(klass)
      defaults.each_pair do |key, value|
        describer.send(key.to_sym, value)
      end
      describer.instance_eval(&block) if block
    end
    self.instance.describers.clear
  end
end

module KubeManifest::DescribeHelper
  def self.extended(base)
    base.class_eval do
      def self.describe(**defaults, &blk)
        self.class_variable_set(::KubeManifest::Describe::SPEC_VAR, {})
        if defaults.include?(:apiVersion) && !defaults.include?(:kind)
          defaults[:kind] = self.name.split('::').last
        end
        KubeManifest::Describer.append(self, defaults, blk)
      end
    end
  end
end
