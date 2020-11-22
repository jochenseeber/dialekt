# frozen_string_literal: true

require "docile"

module Dialekt
  module Model
    # Base class for primitive DSL properties
    class ScalarProperty < BasicProperty
      def initialize(name:, type: nil, factory: nil, transformer: nil)
        super(name: name, type: type, factory: factory, transformer: transformer)

        @shapes = {}
      end

      def setup(owner:)
        super

        raise ArgumentError, "Missing type for property #{name} of #{owner}" if @shapes.empty? && @type.nil?

        unless @shapes.key?(name)
          @shapes[name] = BasicProperty::Shape.new(
            name: name,
            type: @type || owner.class.type_checker.union_type(types: @shapes.values.map(&:type)),
            factory: @factory,
            transformer: @transformer
          )
        end

        property = self

        @shapes.each_value do |shape|
          owner.define_method(shape.name) do |value = EMPTY, &block|
            property.access_value(shape: shape, target: self, value: value, &block)
          end

          owner.define_method(:"#{shape.name}=") do |value|
            property.set_value(shape: shape, target: self, value: value)
          end
        end
      end

      def shape(name = nil, **options)
        name = name&.to_sym || self.name

        raise ArgumentError, "Property #{self.name} already has a shape called #{name}" if @shapes.key?(name)

        options[:type] ||= @type
        options[:factory] ||= @factory
        options[:transformer] ||= @transformer

        raise ArgumentError, "Missing shape for value #{name} of property #{self.name}" if options[:type].nil?

        config = BasicProperty::Shape.new(name: name, **options)
        @shapes[name] = config
      end

      def shapes
        @shapes.dup.freeze
      end

      def shapes=(shapes)
        shapes = shapes.values if shapes.is_a?(Hash)

        raise ArgumentError, "Shapes must be an Enumerable" unless shapes.is_a?(Enumerable)

        @shapes = shapes.map { |shape| [shape.name, shape] }.to_h
      end
    end
  end
end
