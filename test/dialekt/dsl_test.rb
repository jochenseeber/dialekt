# frozen_string_literal: true

require "dialekt/test_base"
require "singleton"

module Dialekt
  module Model
    class DslTest < Calificador::Test
      examines Class

      must "allow defining scalar property" do
        subject.class_eval do
          dsl_scalar :value, type: Numeric
        end

        assert { subject }.method_defined?(:value)
        assert { subject }.method_defined?(:value=)
      end

      must "allow defining scalar property with nested type" do
        subject.class_eval do
          dsl_scalar :value, type: Numeric do
            type Integer
          end
        end

        assert { subject }.method_defined?(:value)
        assert { subject }.method_defined?(:value=)
      end

      must "allow defining set property" do
        subject.class_eval do
          dsl_set :values, value_type: Numeric
        end

        assert { subject }.method_defined?(:values)
        assert { subject }.method_defined?(:values=)
      end

      must "allow defining set property with nested value types" do
        subject.class_eval do
          dsl_set :values do
            value_type Numeric
          end
        end

        assert { subject }.method_defined?(:values)
        assert { subject }.method_defined?(:values=)
      end

      must "allow defining map property" do
        subject.class_eval do
          dsl_map :values, key_type: Symbol, value_type: Numeric
        end

        assert { subject }.method_defined?(:values)
        assert { subject }.method_defined?(:values=)
      end

      must "allow defining map property with nested key and value type" do
        subject.class_eval do
          dsl_map :values do
            key_type Symbol
            value_type Numeric
          end
        end

        assert { subject }.method_defined?(:values)
        assert { subject }.method_defined?(:values=)
      end
    end
  end
end
