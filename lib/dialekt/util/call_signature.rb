# frozen_string_literal: true

module Dialekt
  module Util
    # Call signature information for Proc objects
    class CallSignature
      # Parameter information
      class Parameter
        attr_reader :name

        def initialize(name:, optional:)
          @name = name.to_sym
          @optional = optional
        end

        def optional?
          @optional
        end

        def ==(other)
          @name == other.name && @optional == other.optional?
        end
      end

      class << self
        def create(signature:)
          parameters = []
          options = {}
          extra_parameters = nil
          extra_options = nil

          signature.each do |type, name|
            case type
            when :req, :opt
              parameters << Parameter.new(name: name, optional: type == :opt)
            when :rest
              extra_parameters = Parameter.new(name: name, optional: true)
            when :keyreq, :key
              options[name] = Parameter.new(name: name, optional: type == :key)
            when :keyrest
              extra_options = Parameter.new(name: name, optional: true)
            else
              raise ArgumentError, "Illegal type #{type} in signature #{PP.singleline_pp(signature, StringIO.new).string}"
            end
          end

          new(parameters: parameters, extra_parameters: extra_parameters, options: options, extra_options: extra_options)
        end
      end

      attr_reader :parameters, :options, :extra_parameters, :extra_options

      def initialize(parameters:, extra_parameters:, options:, extra_options:)
        @parameters = parameters.dup.freeze
        @extra_parameters = extra_parameters
        @options = options.dup.freeze
        @extra_options = extra_options
      end

      def required_parameter_count
        @required_parameter_count ||= @parameters.count { |p| !p.optional? }
      end

      def optional_parameter_count
        @optional_parameter_count ||= @parameters.count(&:optional?)
      end
    end
  end
end
