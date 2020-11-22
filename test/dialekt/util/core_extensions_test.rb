# frozen_string_literal: true

require "dialekt/test_base"

module Dialekt
  module Util
    class CoreExtensionsTest < Calificador::Test
      examines Module

      class CustomTypeChecker < RubyTypeChecker
        include Singleton
      end

      class AlternateTypeChecker < RubyTypeChecker
        include Singleton
      end

      class CustomInflector
        include Singleton
      end

      class AlternateInflector
        include Singleton
      end

      def define_test_module(name:, parent: nil)
        instance = Module.new

        instance.singleton_class.define_method(:name) do
          @__dialekt_name
        end

        instance.singleton_class.define_method(:dialekt_enclosing_module) do
          @__dialekt_enclosing_module
        end

        instance.instance_variable_set(:@__dialekt_name, [parent&.name, name].compact.join("::"))
        instance.instance_variable_set(:@__dialekt_enclosing_module, parent)

        instance
      end

      factory Module do
        trait :outer do
          init_with { define_test_module(name: "Outer") }
        end

        trait :inner do
          init_with { define_test_module(name: "Inner", parent: module_outer) }
        end
      end

      factory Class do
        init_with { define_test_class(name: "TestClass") }
      end

      module Outer
        module Inner
        end
      end

      operation :dialekt_enclosing_module do
        must "return enclosing module", -> { Outer::Inner } do
          assert { subject.dialekt_enclosing_module } == Outer
        end

        must "return nil if no enclosing module", -> { Kernel } do
          assert { subject.dialekt_enclosing_module }.nil?
        end
      end

      examine Module do
        operation :base_name do
          must "return base name for nested modules", :inner do
            assert { base_name } == "Inner"
          end

          must "return name for top level modules", -> { Kernel } do
            assert { base_name } == "Kernel"
          end
        end

        operation :dialekt_type_checker do
          must "return defined type checker", :outer do
            subject.module_eval do
              dialekt_type_checker CustomTypeChecker.instance
            end

            assert { subject.dialekt_type_checker }.is_a?(CustomTypeChecker)
          end

          must "return default type checker when enclosing module defines it", :outer do
            assert { subject.dialekt_type_checker }.is_a?(RubyTypeChecker)
          end

          must "return inherited type checker when defined in enclosing module", :inner do
            subject.dialekt_enclosing_module.module_eval do
              dialekt_type_checker CustomTypeChecker.instance
            end

            assert { subject.dialekt_type_checker }.is_a?(CustomTypeChecker)
          end

          must "raise error if type checker already defined", :outer do
            subject.dialekt_type_checker(CustomTypeChecker.instance)
            assert { subject.dialekt_type_checker(AlternateTypeChecker.instance) }.raises?(ArgumentError)
          end
        end

        operation :dialekt_inflector do
          must "return defined inflector", :outer do
            subject.module_eval do
              dialekt_inflector CustomInflector.instance
            end

            assert { subject.dialekt_inflector }.is_a?(CustomInflector)
          end

          must "return default inflector when enclosing module defines it", :outer do
            assert { subject.dialekt_inflector }.is_a?(Dry::Inflector)
          end

          must "return inherited inflector when defined in enclosing module", :inner do
            subject.dialekt_enclosing_module.module_eval do
              dialekt_inflector CustomInflector.instance
            end

            assert { subject.dialekt_inflector }.is_a?(CustomInflector)
          end

          must "raise error if inflector already defined", :outer do
            subject.dialekt_inflector(CustomInflector.instance)
            assert { subject.dialekt_inflector(AlternateInflector.instance) }.raises?(ArgumentError)
          end
        end
      end

      factory Proc do
        init_with { ->(value:) { value } }
      end

      examine Proc do
        operation :call_signature do
          must "must return a call signature" do
            assert { subject.call_signature.options.keys } == [:value]
          end
        end

        operation :call_adapter do
          must "must wrap proc in call adapter" do
            assert { subject.call_adapter }.is_a?(CallAdapter)
          end
        end
      end
    end
  end
end
