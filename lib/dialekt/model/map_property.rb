# frozen_string_literal: true

require "docile"
require "stringio"

module Dialekt
  module Model
    # Base class for DSL map accessors
    class MapProperty < BasicProperty
      # Entry configuration
      class Entry
        attr_reader :name, :key_type, :key_transformer, :value_type, :value_factory, :value_transformer

        def initialize(name:, key_type:, value_type:, key_transformer: nil, value_factory: nil, value_transformer: nil)
          @name = name.to_sym
          @key_type = key_type
          @key_transformer = key_transformer&.call_adapter
          @value_type = value_type
          @value_factory = value_factory&.call_adapter
          @value_transformer = value_transformer&.call_adapter
        end

        def to_s
          result = StringIO.new
          result << @name << " (" << self.class.base_name << ") {"
          result << "key_type: " << @key_type.to_s
          result << ", key_transformer: " << @key_transformer.source_info if @key_transformer
          result << ", value_type: " << @value_type.to_s
          result << ", value_factory: " << @value_factory.source_info if @value_factory
          result << ", value_transformer: " << @value_transformer.source_info if @value_transformer
          result << "}"

          result.string
        end
      end

      def initialize(
        name:,
        key_type: nil,
        value_type: nil,
        type: Hash,
        factory: -> { {} },
        transformer: ->(value:) { value&.to_h }
      )
        super(
          name: name,
          type: type,
          factory: factory,
          transformer: transformer
        )

        @key_type = key_type
        @key_transformer = nil

        @value_type = value_type
        @value_transformer = nil
        @value_factory = nil

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

      def entry(name, key_type: nil, key_transformer: nil, value_type: nil, value_transformer: nil, value_factory: nil)
        entry = Entry.new(
          name: name.to_sym,
          key_type: key_type || @key_type,
          key_transformer: key_transformer || @key_transformer,
          value_type: value_type || @value_type,
          value_factory: value_factory || @value_factory,
          value_transformer: value_transformer || @value_transformer
        )

        define_entry(entry)
      end

      def setup(owner:)
        super

        property = self

        if @entries.empty?
          raise StandardError, "Please specify a key type or entries for property '#{@name}'" if @key_type.nil?
          raise StandardError, "Please specify a value type or entries for property '#{@name}'" if @value_type.nil?

          define_entry(Entry.new(name: owner.dialekt_inflector.singularize(@name), key_type: @key_type, value_type: @value_type))
        end

        type_checker = owner.class.dialekt_type_checker

        @key_type ||= type_checker.union_type(types: @entries.values.map(&:key_type))
        @value_type ||= type_checker.union_type(types: @entries.values.map(&:value_type))

        owner.define_method(@name) do |value = EMPTY, &block|
          value = property.access_value(shape: property.map_shape, target: self, value: value, &block)
          value.dup.freeze
        end

        owner.define_method(:"#{@name}=") do |value|
          property.set_value(shape: property.map_shape, target: self, value: value)
        end

        @entries.each_value do |entry|
          owner.define_method(entry.name) do |key, value = EMPTY, &block|
            property.access_entry(entry: entry, target: self, key: key, value: value, &block)
          end
        end
      end

      def map_shape
        @map_shape ||= BasicProperty::Shape.new(
          name: @name,
          type: @type,
          factory: @factory,
          transformer: @transformer
        )
      end

      def access_entry(entry:, target:, key:, value: EMPTY, &block)
        value = if value == EMPTY
          get_entry(entry: entry, target: target, key: key)
        else
          set_entry(entry: entry, target: target, key: key, value: value)
        end

        Docile.dsl_eval(value, &block) if !value.nil? && block
        value
      end

      def get_entry(entry:, target:, key:)
        map = get_value(shape: map_shape, target: target)

        if entry.key_transformer
          begin
            key = entry.key_transformer.call(object: target, key: key)
          rescue StandardError
            raise ArgumentError, "Cannot transform key '#{key}' for property '#{@name}' (#{entry.name})"
          end
        end

        if entry.value_factory
          map.fetch(key) do
            value = begin
              entry.value_factory.call(object: target, key: key)
            rescue StandardError
              raise StandardError, "Cannot create entry for '#{key}' for property '#{@name}' (#{entry.name})"
            end

            map[key] = value
          end
        else
          map.fetch(key) do
            raise KeyError, "No value for key '#{key}' for property '#{@name}' (#{entry.name})"
          end
        end
      end

      def set_entry(entry:, target:, key:, value:)
        map = get_value(shape: map_shape, target: target)
        type_checker = target.class.dialekt_type_checker

        if entry.key_transformer
          begin
            key = entry.key_transformer.call(object: target, key: key)
          rescue StandardError
            raise ArgumentError, "Cannot transform key '#{key}' for property '#{@name}' (#{entry.name})"
          end
        end

        unless type_checker.valid?(type: entry.key_type, value: key)
          raise TypeError, "Illegal key type '#{key.class}' for property '#{@name}' (#{entry.name})"
        end

        if entry.value_transformer
          begin
            value = entry.value_transformer.call(object: target, key: key, value: value)
          rescue StandardError
            raise ArgumentError, "Cannot transform value '#{value}' for property '#{@name}' (#{entry.name})"
          end
        end

        unless type_checker.valid?(type: entry.value_type, value: value)
          raise TypeError, "Illegal value type '#{value.class}' for property '#{@name}' (#{entry.name})"
        end

        map.store(key, value)
      end

      def key_type(type = EMPTY)
        type == EMPTY ? @key_type : (@key_type = type)
      end

      def key_transformer(transformer = EMPTY)
        transformer == EMPTY ? @key_transformer : (@key_transformer = transformer&.call_adapter)
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
        result << ", key_type: " << @key_type
        result << ", value_type: " << @value_type
        result << ", factory: " << @factory.source_info if @factory
        result << ", transformer: " << @transformer.source_info if @transformer
        result << ", entries: [" << @entries.values.map(&:name).join(", ") << "]"
        result << "}"

        result.string
      end

      protected

      def define_entry(entry)
        raise ArgumentError, "Entry '#{entry.name}' already exists for property '#{@name}'" if @entries.key?(entry.name)

        @entries[entry.name] = entry
      end
    end
  end
end
