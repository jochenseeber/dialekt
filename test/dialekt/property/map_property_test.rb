# frozen_string_literal: true

require "dialekt/test_base"

module Dialekt
  module Model
    class MapPropertyTest < Calificador::Test
      class TestContainer
        def initialize
          @constants = { 1 => "Oans" }
        end
      end

      factory Class, :container_type do
        init_with { Class.new(TestContainer) }
      end

      factory TestContainer, :container do
        init_with { container_type.new }
      end

      factory MapProperty do
        transient do
          name { :constants }
          type_checker { RubyTypeChecker.instance }
          key_type { Integer }
          value_type { Set[Symbol, String, Integer] }
          key_transformer { nil }
          value_transformer { nil }
          value_factory { nil }
        end

        entries { [entry_string, entry_symbol] }
      end

      factory MapProperty::Entry, :entry do
        trait :string do
          transient do
            name { :string_constant}
            key_type { Integer }
            value_type { String }
            key_transformer { nil }
            value_transformer { nil }
            value_factory { nil }
          end
        end

        trait :symbol do
          transient do
            name { :symbol_constant }
            key_type { Integer }
            value_type { Symbol }
          end
        end

        trait :integer do
          transient do
            name { :integer_constant }
            key_type { Integer }
            value_type { Integer }
            key_transformer { ->(value:) { value&.to_i } }
            value_transformer { ->(value:) { value&.to_i } }
            value_factory { ->(key:) { key } }
          end
        end
      end

      examine MapProperty::Entry, :integer do
        operation :to_s do
          must "return a string representation" do
            assert { to_s } =~ %r{\Ainteger_constant \(Entry\) \{.*\}\z}
          end

          must "not include transformers and factories if unset" do
            properties(MapProperty::Entry, :integer) do
              key_transformer { nil }
              value_transformer { nil }
              value_factory { nil }
            end

            assert { to_s } =~ %r{\Ainteger_constant \(Entry\) \{.*\}\z}
            refute { to_s }.include?("key_transformer:")
            refute { to_s }.include?("value_transformer:")
            refute { to_s }.include?("value_factory:")
          end
        end
      end

      type do
        operation :new do
          must "assign default factory if omitted" do
            factory = new(name: :constants).factory
            assert { factory }.is_a?(Util::CallAdapter)
            assert { factory.call }.is_a?(Hash)
          end

          must "assign default transformer if omitted" do
            transformer = new(name: :constants).transformer
            assert { transformer }.is_a?(Util::CallAdapter)
            assert { transformer.call(value: [[:a, "a"]]) } == { a: "a" }
            assert { transformer.call(value: nil) }.nil?
          end
        end
      end

      operation :setup, args { owner { container_type } } do
        must "setup with provided entries" do
          setup(owner: _)
          assert { container_type }.public_method_defined?(:constants)
          assert { container_type }.public_method_defined?(:constants=)
          assert { container_type }.public_method_defined?(:string_constant)
          assert { container_type }.public_method_defined?(:symbol_constant)
        end

        must "setup with default entry accessors if no entries provided", props { entries { [] } } do
          setup(owner: _)
          assert { container_type }.public_method_defined?(:constants)
          assert { container_type }.public_method_defined?(:constants=)
          assert { container_type }.public_method_defined?(:constant)
        end

        must "raise error if neither entries nor key type provided", props { entries { [] }; key_type { nil } } do
          assert { setup(owner: _) }.raises?(StandardError)
        end

        must "raise error if neither entries nor value type provided", props { entries { [] }; value_type { nil } } do
          assert { setup(owner: _) }.raises?(StandardError)
        end

        must "provide accessor for map" do
          setup(owner: _)
          object = container_type.new
          object.constants({ 1 => "one" })
          assert { object.constants } == { 1 => "one" }
        end

        must "provide setter for map" do
          setup(owner: _)
          object = container_type.new
          object.constants = { 1 => "one" }
          assert { object.constants } == { 1 => "one" }
        end

        must "provide accessor for entries" do
          setup(owner: _)
          object = container_type.new
          object.string_constant 1, "one"
          assert { object.constants } == { 1 => "one" }
        end
      end

      operation :access_entry, args { entry { entry_string }; target { container } } do
        must "return value if no argument given" do
          assert { access_entry(entry: _, target: _, key: 1) } == "Oans"
        end

        must "set value if argument given" do
          access_entry(entry: _, target: _, key: 1, value: "one")
          assert { container.instance_variable_get(:@constants).fetch(1) } == "one"
        end

        must "configure value if block given" do
          result = nil

          access_entry(entry: _, target: _, key: 1) do
            result = to_s
          end

          assert { result } == "Oans"
        end
      end

      operation :get_entry, args { entry { entry_string }; target { container } } do
        must "return entry" do
          assert { get_entry(entry: _, target: _, key: 1) } == "Oans"
        end

        must "return entry using key transformer if present" do
          properties(MapProperty::Entry, :string) do
            key_transformer { ->(key:) { key&.to_i } }
          end

          assert { get_entry(entry: _, target: _, key: "1") } == "Oans"
        end

        must "raise error when key transformer fails" do
          properties(MapProperty::Entry, :string) do
            key_transformer { -> { raise ArgumentError } }
          end

          assert { get_entry(entry: _, target: _, key: "1") }.raises?(ArgumentError)
        end

        operation :set_entry, args { entry { entry_string }; target { container } } do
          must "store entry" do
            set_entry(entry: _, target: _, key: 2, value: "Zwoa")
            assert { container.instance_variable_get(:@constants).fetch(2) } == "Zwoa"
          end

          must "apply key transformer if present" do
            properties(MapProperty::Entry, :string) do
              key_transformer { ->(key:) { key&.to_i } }
            end
  
            set_entry(entry: _, target: _, key: "2", value: "Zwoa")
            assert { container.instance_variable_get(:@constants).fetch(2) } == "Zwoa"
          end

          must "raise error if key transformer fails" do
            properties(MapProperty::Entry, :string) do
              key_transformer { -> { raise ArgumentError } }
            end
  
            assert { set_entry(entry: _, target: _, key: "2", value: "Zwoa") }.raises?(ArgumentError)
          end

          must "raise error if wrong key type" do
            assert { set_entry(entry: _, target: _, key: "2", value: "Zwoa") }.raises?(TypeError)
          end

          must "apply value transformer if present" do
            properties(MapProperty::Entry, :string) do
              value_transformer { ->(value:) { value&.to_s } }
            end
  
            set_entry(entry: _, target: _, key: 2, value: :Zwoa)
            assert { container.instance_variable_get(:@constants).fetch(2) } == "Zwoa"
          end

          must "raise error if value transformer fails" do
            properties(MapProperty::Entry, :string) do
              value_transformer { -> { raise ArgumentError } }
            end
  
            assert { set_entry(entry: _, target: _, key: 2, value: :Zwoa) }.raises?(ArgumentError)
          end

          must "raise error if wrong value type" do
            assert { set_entry(entry: _, target: _, key: 2, value: :Zwoa) }.raises?(TypeError)
          end
        end

        must "return default value when value factory present" do
          properties(MapProperty::Entry, :string) do
            value_factory { -> { "one" } } 
          end

          assert { get_entry(entry: _, target: _, key: 2) } == "one"
        end

        must "raise error when value factory fails" do
          properties(MapProperty::Entry, :string) do
            value_factory { -> { raise ArgumentError } }
          end

          assert { get_entry(entry: _, target: _, key: 2) }.raises?(StandardError)
        end

        must "raise error when entry not found and no value factory given" do
          assert { get_entry(entry: _, target: _, key: 2) }.raises?(KeyError)
        end
      end

      operation :entry do
        must "add entry" do
          entry(:string_constant_to_string, key_type: String, value_type: String)
          assert { subject.entries }.key?(:string_constant_to_string)
        end

        must "raise error if entry already exists" do
          assert { entry(:string_constant) }.raises?(ArgumentError)
        end
      end

      operation :entries do
        must "return entries" do
          assert { entries.keys.to_set } == Set[:string_constant, :symbol_constant]
        end
      end

      operation :entries= do
        must "set entries from Array" do
          subject.entries = [entry_symbol]
          assert { subject.entries.keys.to_set } == Set[:symbol_constant]
        end

        must "set entries from Hash" do
          subject.entries = { symbol_constant: entry_symbol }
          assert { subject.entries.keys.to_set } == Set[:symbol_constant]
        end

        must "raise error if key does not match entry name in Hash" do
          assert { subject.entries = { bad_key: entry_symbol } }.raises?(ArgumentError)
        end

        must "raise error if argument is not enumerable" do
          assert { subject.entries = entry_symbol }.raises?(ArgumentError)
        end
      end

      operation :key_type do
        must "set key type when called with argument" do
          subject.key_type String
          assert { subject.key_type } == String
        end

        must "clear key type when called with nil" do
          subject.key_type nil
          assert { subject.key_type }.nil?
        end
      end

      operation :key_transformer do
        must "set key transformer when called with argument" do
          subject.key_transformer ->(value:) { value&.to_sym }
          assert { subject.key_transformer }.is_a?(Util::CallAdapter)
        end

        must "clear key transformer when called with nil" do
          subject.key_transformer nil
          assert { subject.key_transformer }.nil?
        end
      end

      operation :value_type do
        must "set value type when called with argument" do
          subject.value_type Symbol
          assert { subject.value_type } == Symbol
        end

        must "clear value type when called with nil" do
          subject.value_type nil
          assert { subject.value_type }.nil?
        end
      end

      operation :value_transformer do
        must "set value transformer when called with argument" do
          subject.value_transformer ->(value:) { value&.to_sym }
          assert { subject.value_transformer }.is_a?(Util::CallAdapter)
        end

        must "clear value transformer when called with nil" do
          subject.value_transformer nil
          assert { subject.value_transformer }.nil?
        end
      end

      operation :value_factory do
        must "set value factory when called with argument" do
          subject.value_factory -> { "Test" }
          assert { subject.value_factory }.is_a?(Util::CallAdapter)
        end

        must "clear value factory when called with nil" do
          subject.value_factory nil
          assert { subject.value_factory }.nil?
        end
      end

      operation :to_s do
        must "return a string representation" do
          assert { to_s } =~ %r{\Aconstants \(MapProperty\) \{.*\}\z}
        end

        must "not include factory and transformer if unset" do
          properties(MapProperty) do
            transformer { nil }
            factory { nil }
          end

          assert { to_s } =~ %r{\Aconstants \(MapProperty\) \{.*\}\z}
          refute { to_s }.include?("transformer:")
          refute { to_s }.include?("factory:")
        end
      end
    end
  end
end

# EMPTY = Object.new.freeze

# TestNumber = Struct.new(:name, :tested, keyword_init: true) do
#   def tested(value = EMPTY)
#     value == EMPTY ? @tested : (@tested = value)
#   end
# end

# class MapContainer
# end

# class MapPropertyTest < Calificador::Test
#   def one
#     TestNumber.new(name: "one")
#   end

#   def two
#     TestNumber.new(name: "two")
#   end

#   factory MapProperty::Entry do
#     transient do
#       name { :value }
#       key_type { Integer }
#       key_transformer { ->(key:) { key&.to_i } }
#       value_type { TestNumber }
#       value_factory { ->(key:) { TestNumber.new(name: key&.to_s) } }
#       value_transformer { ->(value:) { value.is_a?(TestNumber) ? value : TestNumber.new(name: value&.to_s) } }
#     end
#   end

#   factory MapProperty do
#     transient do
#       owner { Class.new }
#       name { :values }
#       key_type { Integer }
#       value_type { TestNumber }
#       type_checker { RubyTypeChecker.new }
#     end

#     entries do
#       [create(MapProperty::Entry)]
#     end
#   end

#   factory MapContainer do
#     transient do
#       property { create(MapProperty) }
#     end

#     init_with do
#       Class.new(MapContainer).new
#     end

#     after_create do |object|
#       property.setup(owner: object.class)
#     end
#   end

#   examine MapProperty::Entry do
#     must "symbolize name", name: "name" do
#       assert { subject.name } == :name
#     end

#     must "convert key transformer to call adapter", key_transformer: -> {} do
#       assert { subject.key_transformer }.is_a?(Util::CallAdapter)
#     end

#     must "convert value factory to call adapter", value_factory: -> {} do
#       assert { subject.value_factory }.is_a?(Util::CallAdapter)
#     end

#     must "convert value transformer to call adapter", value_transformer: -> {} do
#       assert { subject.value_transformer }.is_a?(Util::CallAdapter)
#     end
#   end

#   examine MapProperty do
#     must "have a configurable key type" do
#       subject.key_type Symbol
#       assert { subject.key_type } == Symbol
#     end

#     must "have a configurable value type" do
#       subject.value_type String
#       assert { subject.value_type } == String
#     end

#     must "have a default type" do
#       assert { subject.type } == Hash
#     end

#     must "have a default factory" do
#       assert { subject.factory.call(object: nil) } == {}
#     end

#     must "have a default transformer" do
#       assert { subject.transformer.call(object: nil, value: [[1, one]]) } == { 1 => one }
#     end

#     must "set key transformer" do
#       subject.key_transformer ->(key:) { key&.to_i }
#       assert { subject.key_transformer }.is_a?(Util::CallAdapter)
#     end

#     must "clear key transformer" do
#       subject.key_transformer nil
#       assert { subject.key_transformer }.nil?
#     end

#     must "set value factory" do
#       subject.value_factory ->(key:) { key&.to_s }
#       assert { subject.value_factory }.is_a?(Util::CallAdapter)
#     end

#     must "clear value factory" do
#       subject.value_factory nil
#       assert { subject.value_factory }.nil?
#     end

#     must "set value transformer" do
#       subject.value_transformer ->(value:) { value&.to_s }
#       assert { subject.value_transformer }.is_a?(Util::CallAdapter)
#     end

#     must "clear value transformer" do
#       subject.value_transformer nil
#       assert { subject.value_transformer }.nil?
#     end

#     must "get entry descriptors as frozen copy" do
#       assert { subject.entries }.size == 1
#       assert { subject.entries }.frozen?
#     end

#     must "set copy of entry descriptors" do
#       entries = []

#       subject.entries = entries
#       assert { subject.entries }.empty?

#       entries << "Test"

#       assert { subject.entries }.empty?
#     end

#     must "add entry descriptor" do
#       subject.entry :other
#     end

#     must "reject duplicate entry name" do
#       assert { subject }.raises?(ArgumentError).entry :value
#     end

#     must "set key type from entry descriptors", key_type: nil do
#       subject.setup(owner: Class.new)
#       assert { subject.key_type } == Integer
#     end

#     must "set value type from entry descriptors", value_type: nil do
#       subject.setup(owner: Class.new)
#       assert { subject.value_type } == TestNumber
#     end

#     without "entries", entries: [] do
#       must "use configured key type" do
#         subject.setup(owner: Class.new)
#         assert { subject.key_type } == Integer
#       end

#       must "use configured value type" do
#         subject.setup(owner: Class.new)
#         assert { subject.value_type } == TestNumber
#       end

#       must "reject missing key type", key_type: nil do
#         assert { subject }.raises?(StandardError).setup(owner: Class.new)
#       end

#       must "reject missing value type", value_type: nil do
#         assert { subject }.raises?(StandardError).setup(owner: Class.new)
#       end
#     end
#   end

#   examine MapContainer do
#     must "return value when accessor is called without value" do
#       assert { subject.values } == {}
#     end

#     must "set value when accessor is called with value" do
#       subject.values Hash[1 => one]
#       assert { subject.values } == Hash[1 => one]
#     end

#     with "nillable property", MapProperty => { type: [Hash, NilClass] } do
#       must "clear value when accessor is called with nil" do
#         subject.values nil
#         assert { subject.values }.nil?
#       end
#     end

#     must "set value" do
#       subject.values = Hash[1 => one]
#       assert { subject.values } == Hash[1 => one]
#     end

#     must "get entry when accessor is called without value" do
#       subject.values = Hash[1 => one]
#       assert { subject.value(1) } == one
#     end

#     must "set entry when accessor is called with value" do
#       subject.value 1, one
#       assert { subject.values } == Hash[1 => one]
#     end

#     must "create default value" do
#       subject.value 1
#       assert { subject.values } == Hash[1 => TestNumber.new(name: "1")]
#     end

#     must "configure created value" do
#       subject.value 1 do
#         tested true
#       end
#       assert { subject.value(1) }.tested
#     end

#     without "key transformer", MapProperty::Entry => { key_transformer: nil } do
#       must "get value without key transformer" do
#         subject.value 1
#       end

#       must "set value without key transformer" do
#         subject.value 1, one
#       end

#       must "reject illegal key types" do
#         assert { subject }.raises?(TypeError).value("1", one)
#       end
#     end

#     without "value transformer", MapProperty::Entry => { value_transformer: nil } do
#       must "get value without value transformer" do
#         subject.value 1
#       end

#       must "reject illegal value types" do
#         assert { subject }.raises?(TypeError).value(1, "one")
#       end
#     end

#     without "value factory", MapProperty::Entry => { value_factory: nil } do
#       must "get value" do
#         subject.values = Hash[1 => one]
#         assert { subject.value(1) } == one
#       end

#       must "raise error when getting absent value" do
#         assert { subject }.raises?(KeyError).value(1)
#       end
#     end

#     with "failing key transformer", MapProperty::Entry => { key_transformer: -> { raise "Meow" } } do
#       must "raise error when getting value" do
#         assert { subject }.raises?(ArgumentError).value(1)
#       end

#       must "raise error when setting value" do
#         assert { subject }.raises?(ArgumentError).value(1, one)
#       end
#     end

#     with "failing value transformer", MapProperty::Entry => { value_transformer: -> { raise "Bark" } } do
#       must "raise error when setting value" do
#         assert { subject }.raises?(ArgumentError).value(1, one)
#       end
#     end

#     without "value factory", MapProperty::Entry => { value_factory: -> { raise "Growl" } } do
#       must "not create value" do
#         assert { subject }.raises?(StandardError).value(1)
#       end
#     end
#   end
