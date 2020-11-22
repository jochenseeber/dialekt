# frozen_string_literal: true

module Dialekt
  module Model
    # BaseAccessor base class
    class BasicProperty
      # Property configuration
      class Shape
        attr_reader :name, :type, :factory, :transformer

        def initialize(name:, type:, factory: nil, transformer: nil)
          @name = name.to_sym
          @type = type
          @factory = factory&.call_adapter
          @transformer = transformer&.call_adapter
        end
      end

      attr_reader :name
      attr_writer :type

      def initialize(name:, type: nil, factory: nil, transformer: nil)
        raise ArgumentError, "Name must not be nil" if name.nil?

        @name = name
        @type = type

        @variable = :"@#{name}"
        @factory = factory&.call_adapter
        @transformer = transformer&.call_adapter
      end

      def setup(owner:); end

      def access_value(shape:, target:, value: EMPTY)
        if value.equal?(EMPTY)
          get_value(shape: shape, target: target)
        else
          set_value(shape: shape, target: target, value: value)
        end
      end

      def get_value(shape:, target:)
        if target.instance_variable_defined?(@variable)
          target.instance_variable_get(@variable)
        else
          value = shape.factory&.call(object: target)
          target.instance_variable_set(@variable, value)
        end
      end

      def set_value(shape:, target:, value:)
        if shape.transformer
          begin
            value = shape.transformer.call(object: target, value: value)
          rescue StandardError
            raise TypeError, "Cannot transform value '#{value}' for property #{@name}"
          end
        end

        type_checker = target.class.dialekt_type_checker

        begin
          type_checker.check!(type: shape.type, value: value)
        rescue StandardError
          raise TypeError, <<~MSG
            Value '#{value}' (#{value.class}) for property #{@name} must conform to #{type_checker.format(type: shape.type)}
          MSG
        end

        target.instance_variable_set(@variable, value)
      end

      def type(type = EMPTY)
        type == EMPTY ? @type : (@type = type)
      end

      def factory(factory = EMPTY, &block)
        if factory == EMPTY
          if block
            self.factory = block
          else
            @factory
          end
        else
          raise ArgumentError, "Please provide either a factory proc or a block, not both" if block

          self.factory = factory
        end
      end

      def factory=(factory)
        @factory = factory&.call_adapter
      end

      def transformer(transformer = EMPTY, &block)
        if transformer == EMPTY
          if block
            self.transformer = block
          else
            @transformer
          end
        else
          raise ArgumentError, "Please provide either a transformer proc or a block, not both" if block

          self.transformer = transformer
        end
      end

      def transformer=(transformer)
        @transformer = transformer&.call_adapter
      end
    end
  end
end
