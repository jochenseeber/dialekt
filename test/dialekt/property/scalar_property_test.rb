# frozen_string_literal: true

require "dialekt/test_base"

module Dialekt
  module Model
    class ScalarPropertyTest < Calificador::Test
      class TestContainer
        def initialize
          @test = "something"
        end
      end

      factory TestContainer, :container do
        init_with { Class.new(TestContainer) }
      end

      factory ScalarProperty do
        transient do
          name { :test }
          type { Set[Symbol, String] }
          type_checker { RubyTypeChecker.instance }
          factory { nil }
          transformer { nil }
        end

        shapes { [shape_string] }
      end

      factory BasicProperty::Shape do
        transient do
          factory { nil }
          transformer { nil }
        end

        trait :string do
          transient do
            name { :test_string }
            type { String }
          end
        end

        trait :symbol do
          transient do
            name { :test_symbol }
            type { Symbol }
          end
        end
      end

      operation :shape do
        must "add scalar shape" do
          shape(:shape_symbol, type: Symbol)
          assert { subject.shapes }.key?(:shape_symbol)
        end

        must "inherit default name from property if not set" do
          shape(type: Symbol)
          assert { subject.shapes.fetch(:test).name } == :test
        end

        must "inherit type from property if not set" do
          shape(:test)
          assert { subject.shapes.fetch(:test).type } == Set[Symbol, String]
        end

        must "inherit factory from property if not set", props { factory { -> { :Test } } } do
          shape(type: Symbol)
          refute { subject.shapes.fetch(:test).factory }.nil?
        end

        must "inherit transformer from property if not set", props { transformer { ->(value:) { value&.to_sym } } } do
          shape(type: Symbol)
          refute { subject.shapes.fetch(:test).transformer }.nil?
        end

        must "raise error when type cannot be inherited", props { type { nil } } do
          assert { shape(:test_symbol) }.raises?(ArgumentError)
        end

        must "raise error when shape already exists" do
          assert { shape(:test_string, type: Symbol) }.raises?(ArgumentError)
        end
      end

      operation :shapes= do
        must "set shapes from Array" do
          subject.shapes = [shape_symbol]
          assert { subject.shapes }.key?(:test_symbol)
        end

        must "set shapes from Hash" do
          subject.shapes = { test_symbol: shape_symbol }
          assert { subject.shapes }.key?(:test_symbol)
        end

        must "raise error if argument is neither Array nor Hash" do
          assert { subject.shapes = shape_string }.raises?(ArgumentError)
        end
      end

      operation :setup, args { owner { container } } do
        must "setup with provided shapes" do
          subject.shape(:test, type: Integer)
          setup(owner: _)
          assert { container }.public_method_defined?(:test)
          assert { container }.public_method_defined?(:test=)
          assert { container }.public_method_defined?(:test_string)
          assert { container }.public_method_defined?(:test_string=)
        end

        must "setup with default shape if none defined", props { shapes { [] } } do
          setup(owner: _)
          assert { container }.public_method_defined?(:test)
          assert { container }.public_method_defined?(:test=)
        end

        must "raise error if property has neither type nor shapes", props { type { nil }; shapes { [] } } do
          assert { setup(owner: _) }.raises?(ArgumentError)
        end

        must "provide setter for container" do
          setup(owner: _)
          object = container.new
          object.test = "nothing"
          assert { object.instance_variable_get(:@test) } == "nothing"        
        end

        must "provide accessor for container" do
          setup(owner: _)
          object = container.new
          object.test "nothing"
          assert { object.instance_variable_get(:@test) } == "nothing"        
        end
      end
    end
  end
end

# context "ScalarProperty" do
#   context "with single shape" do
#     subject do
#       owner_class = Class.new do
#         scalar :value, type: String
#       end

#       owner_class.new
#     end

#     should "store value" do
#       subject.value "Hello"
#       subject.value.assert == "Hello"
#     end

#     should "reject wrong type" do
#       TypeError.assert.raised? do
#         subject.value :Hello
#       end
#     end
#   end

#   context "with alternative values" do
#     subject do
#       owner_class = Class.new do
#         scalar :value do
#           value :string_value, type: String
#           value :symbol_value, type: Symbol
#         end
#       end

#       owner_class.new
#     end

#     should "store alternatives" do
#       subject.string_value "Hello"
#       subject.string_value.assert == "Hello"
#       subject.value.assert == "Hello"

#       subject.symbol_value :World
#       subject.symbol_value.assert == :World
#       subject.value.assert == :World
#     end
#   end

#   context "with factory" do
#     subject do
#       owner_class = Class.new do
#         scalar :value, type: String, factory: -> { "something" }
#       end

#       owner_class.new
#     end

#     should "return created value" do
#       subject.value.assert == "something"
#     end
#   end

#   context "with failing factory" do
#     subject do
#       owner_class = Class.new do
#         scalar :value, type: String, factory: -> { raise StandardError, "Bark" }
#       end

#       owner_class.new
#     end

#     should "report error" do
#       StandardError.assert.raised? do
#         subject.value
#       end
#     end
#   end

#   context "with transformer" do
#     subject do
#       owner_class = Class.new do
#         scalar :value, type: String, transformer: ->(value:) { value&.to_s }
#       end

#       owner_class.new
#     end

#     should "store transformed value" do
#       subject.value :Hello
#       subject.value.assert == "Hello"
#     end
#   end

#   should "reject missing type" do
#     ArgumentError.assert.raised? do
#       Class.new do
#         scalar :value
#       end
#     end
#   end

#   should "reject missing value type" do
#     ArgumentError.assert.raised? do
#       Class.new do
#         scalar :value do
#           value :string_value
#         end
#       end
#     end
#   end
# end
