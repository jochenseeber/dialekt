# frozen_string_literal: true

require "dialekt/test_base"

module Dialekt
  class BasicTypeCheckerTest < Calificador::Test
    operation :check! do
      must "succeed if type is valid" do
        def subject.valid?(type:, value:)
          true
        end

        assert { check!(type: String, value: "Hello") } == true
      end

      must "fail if type is valid" do
        def subject.valid?(type:, value:)
          false
        end

        assert { check!(type: String, value: "Hello") }.raises?(TypeError)
      end
    end

    operation :format do
      must "format types for display" do
        result = format(type: [String, Symbol])
  
        assert { result }.is_a?(String)
        assert { result } == "[String, Symbol]"
      end
    end

    operation :valid? do
      must "raise error" do
        assert { valid?(type: String, value: "Hello") }.raises?(NotImplementedError)
      end
    end

    operation :union_type do
      must "raise error" do
        assert { union_type(types: [String, Symbol]) }.raises?(NotImplementedError)
      end
    end
  end
end
