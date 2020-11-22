# frozen_string_literal: true

module Dialekt
  module Util
    # Call adapter for Proc that filters out excess named parameters
    class CallAdapter
      def initialize(callable:)
        @callable = callable
        @signature = callable.call_signature

        if @signature.required_parameter_count.positive?
          raise ArgumentError, "Callable '#{callable}' must not have any required positional parameters"
        end
      end

      def method_missing(method, *arguments, &block)
        if method == :call
          options = arguments.last&.keys || []
          define_call_method(options: options)
          send(method, *arguments, &block)
        else
          super
        end
      end

      ruby2_keywords :method_missing

      def respond_to_missing?(method, include_all = true)
        method == :call ? true : super
      end

      def define_call_method(options:)
        accepted_options = options.intersection(@signature.options.keys)

        if accepted_options.size == options.size
          define_singleton_method(:call, @callable)
        elsif accepted_options.empty?
          define_singleton_method(:call) do |**_call_options|
            @callable.call
          end
        else
          define_singleton_method(:call) do |**call_options|
            @callable.call(**call_options.slice(*accepted_options))
          end
        end
      end

      def call_adapter
        self
      end

      def source_info
        "#{File.basename(@callable.source_location.first)}:#{@callable.source_location.last}"
      end
    end
  end
end
