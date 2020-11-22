# frozen_string_literal: true

require "docile"
require "dry/inflector"

module Dialekt
  module Model
    # Base class for DSL set accessors
    class SetProperty < BasicProperty
      class Entry
        attr_reader :name, :value_type, :value_transformer

        def initialize(name:, value_type:, value_transformer: nil)
          @name = name.to_sym
          @value_type = value_type
          @value_transformer = value_transformer&.call_adapter
        end

        def to_s
          result = StringIO.new
          result << @name << " (" << self.class.base_name << ") {"
          result << "value_type: " << @value_type.to_s
          result << ", value_transformer: " << @value_transformer.source_info if @value_transformer
          result << "}"

          result.string
        end
      end

      def initialize(
        name:,
        value_type: nil,
        type: Set,
        factory: -> { Set.new },
        transformer: ->(value:) { value&.to_set }
      )
        super(
          name: name,
          type: type,
          factory: factory,
          transformer: transformer
        )

        @value_type = value_type
        @value_transformer = nil
        @entries = {}
      end

      def entries
        @entries.dup.freeze
      end

      def entries=(entries)
        case entries
        when Hash
          @entries = {}

          entries.each do |name, entry|
            if name != entry.name
              raise ArgumentError, "Entry key '#{name}' does not match entry name for '#{entry.name}'"
            end

            define_entry(entry)
          end
        when Enumerable
          @entries = {}
          entries.each { |entry| define_entry(entry) }
        else
          raise ArgumentError, "Entries must be an Enumerable or a Hash"
        end
      end

      def entry(name, value_type: nil, value_transformer: nil)
        entry = Entry.new(
          name: name.to_sym,
          value_type: value_type || @value_type,
          value_transformer: value_transformer || @value_transformer
        )

        define_entry(entry)
      end

      def setup(owner:)
        super

        property = self

        if @entries.empty?
          raise StandardError, "Please specify a value type for property '#{@name}'" if @value_type.nil?

          define_entry(Entry.new(name: owner.dialekt_inflector.singularize(@name), value_type: @value_type))
        end

        @value_type ||= owner.class.type_checker.union_type(types: @entries.values.map(&:value_type))

        owner.define_method(@name) do |value = EMPTY, &block|
          value = property.access_value(shape: property.set_shape, target: self, value: value, &block)
          value.dup.freeze
        end

        owner.define_method(:"#{@name}=") do |value|
          property.set_value(shape: property.set_shape, target: self, value: value)
        end

        @entries.each_value do |entry|
          owner.define_method(entry.name) do |value, &block|
            property.add_entry(entry: entry, target: self, value: value, &block)
          end
        end
      end

      def set_shape
        @set_shape ||= BasicProperty::Shape.new(
          name: @name,
          type: @type,
          factory: @factory,
          transformer: @transformer
        )
      end

      def add_entry(entry:, target:, value:, &block)
        set = get_value(shape: set_shape, target: target)

        if entry.value_transformer
          begin
            value = entry.value_transformer.call(object: target, value: value)
          rescue StandardError
            raise ArgumentError, "Cannot transform value '#{value}' for property '#{@name}' (#{entry.name})"
          end
        end

        unless target.class.dialekt_type_checker.valid?(type: entry.value_type, value: value)
          raise TypeError, "Illegal value type '#{value.class}' for property '#{@name}' (#{entry.name})"
        end

        set.add(value)

        Docile.dsl_eval(value, &block) if !value.nil? && block

        value
      end

      def value_type(type = EMPTY)
        type == EMPTY ? @value_type : (@value_type = type)
      end

      def value_transformer(transformer = EMPTY)
        transformer == EMPTY ? @value_transformer : (@value_transformer = transformer&.call_adapter)
      end

      def value_factory(factory = EMPTY)
        factory == EMPTY ? @value_factory : (@value_factory = factory&.call_adapter)
      end

      def to_s
        result = StringIO.new

        result << @name << " (" << self.class.base_name << ") {"
        result << "type: " << @type
        result << ", value_type: " << @value_type
        result << ", factory: " << @factory.source_info if @factory
        result << ", transformer: " << @transformer.source_info if @transformer
        result << ", entries: [" << @entries.values.map(&:name).join(", ") << "]"
        result << "}"

        result.string
      end

      protected

      def define_entry(entry)
        if entry.name == @name
          raise ArgumentError, "Entry '#{entry.name}' cannot have the same name as its set property"
        end

        raise ArgumentError, "Entry '#{entry.name}' already exists for property '#{@name}'" if @entries.key?(entry.name)

        @entries[entry.name] = entry
      end
    end
  end
end
