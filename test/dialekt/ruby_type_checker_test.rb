# frozen_string_literal: true

require "dialekt/test_base"

module Dialekt
  class RubyTypeCheckerTest < Calificador::Test
    operation :valid? do
      must "validate scalar types" do
        assert { valid?(type: String, value: "Hello") } == true
      end

      must "validate union types" do
        assert { valid?(type: [String, Symbol], value: "Hello") } == true
      end

      must "reject invalid types" do
        assert { valid?(type: "Something", value: "Hello") }.raises?(TypeError)
      end
    end

    operation :union_type do
      must "unique union types" do
        assert { union_type(types: [String, Symbol, String]) } == Set[String, Symbol]
      end

      must "flatten union types" do
        assert { union_type(types: [String, [Symbol, String]]) } == Set[String, Symbol]
      end

      must "unpack union with only one type" do
        assert { union_type(types: [String]) } == String
      end

      must "raise error if types is empty" do
        assert { union_type(types: []) }.raises?(ArgumentError)
      end
    end
  end
end
