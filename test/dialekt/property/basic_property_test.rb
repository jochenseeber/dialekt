# frozen_string_literal: true

require "dialekt/test_base"

module Dialekt
  module Model
    class BasicPropertyTest < Calificador::Test
      class TestContainer
      end

      factory TestContainer, :container do
        init_with { Class.new(TestContainer) }
      end
  
      factory BasicProperty do
        transient do
          name { :test }
          type { [String, Symbol] }
          type_checker { RubyTypeChecker.instance }
          factory { nil }
          transformer { nil }
        end
      end

      factory BasicProperty::Shape, :test_string do
        transient do
          name { :test_int }
          type { String }
          factory { nil }
          transformer { nil }
        end
      end

      type do
        operation :new, args { name { :test } } do
          must "raise error if name is nil" do
            assert { new(name: nil) }.raises?(ArgumentError)
          end

          must "convert factory to call adapter" do
            assert { new(name: _, factory: -> { "test" }).factory }.is_a?(Util::CallAdapter)
          end

          must "convert transformer to call adapter" do
            assert do
              new(name: _, transformer: -> { value.to_s }).transformer
            end.is_a?(Util::CallAdapter)
          end
        end
      end

      operation :get_value do
        must "return nil for unset properties" do
          assert { get_value(shape: test_string, target: container) }.nil?
        end

        with "factory", props(BasicProperty::Shape) { factory { -> { String.new("default") } } } do
          must "return default value" do
            assert { get_value(shape: test_string, target: container) } == "default"
          end

          must "cache default value" do
            value = get_value(shape: test_string, target: container)
            assert { value } == "default"

            repeat = get_value(shape: test_string, target: container)
            assert { repeat.__id__ } == value.__id__
          end
        end
      end

      operation :set_value do
        must "set value" do
          set_value(shape: test_string, target: container, value: "test")
          assert { container.instance_variable_get(:"@#{basic_property.name}") } == "test"
        end

        must "raise error if value has incorrect type" do
          assert { set_value(shape: test_string, target: container, value: 1) }.raises?(TypeError)
        end

        with "transformer", props(BasicProperty::Shape) { transformer { ->(value:) { value.to_s } } } do
          must "transform value" do
            assert { set_value(shape: test_string, target: container, value: :test) } == "test"
          end
        end

        with "failing transformer", props(BasicProperty::Shape) { transformer { -> { raise StandardError } } } do
          must "catch error" do
            assert { set_value(shape: test_string, target: container, value: 1) }.raises?(TypeError)
          end
        end
      end

      operation :access_value do
        must "set value if argument provided" do
          access_value(shape: test_string, target: container, value: "test")
          assert { container.instance_variable_get(:"@#{basic_property.name}") } == "test"
        end

        must "get value if no argument provided" do
          container.instance_variable_set(:"@#{basic_property.name}", "test")
          assert { access_value(shape: test_string, target: container) } == "test"
        end
      end

      operation :type do
        must "get value when called without argument" do
          type = String
          assert { type } == String
        end

        must "set value when called with argument" do
          type(String)
          assert { type } == String
        end
      end

      operation :factory do
        must "set value when called with argument" do
          factory(-> { "Test" })
          assert { factory }.is_a?(Util::CallAdapter)
          assert { factory.call } == "Test"
        end

        must "set value when called with block" do
          factory(&-> { "Test" })
          assert { factory }.is_a?(Util::CallAdapter)
          assert { factory.call } == "Test"
        end

        must "clear value when called with nil" do
          factory(nil)
          assert { factory }.nil?
        end

        must "raise error when called with argument and block" do
          assert { factory(-> { "Test" }, &-> { "Test" }) }.raises?(ArgumentError)
        end
      end

      operation :transformer do
        must "set value when called with argument" do
          transformer(->(value:) { value&.to_s })
          assert { transformer }.is_a?(Util::CallAdapter)
          assert { transformer.call(value: :Test) } == "Test"
        end

        must "set value when called with block" do
          transformer(&->(value:) { value&.to_s })
          assert { transformer }.is_a?(Util::CallAdapter)
          assert { transformer.call(value: :Test) } == "Test"
        end

        must "clear value when called with nil" do
          transformer(nil)
          assert { transformer }.nil?
        end

        must "raise error when called with argument and block" do
          assert { transformer(->(value:) { value&.to_s }, &->(value:) { value&.to_s }) }.raises?(ArgumentError)
        end
      end
    end
  end
end
