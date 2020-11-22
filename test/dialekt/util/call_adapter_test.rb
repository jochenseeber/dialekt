# frozen_string_literal: true

require "dialekt/test_base"

module Dialekt
  module Util
    class CallAdapterTest < Calificador::Test
      factory CallAdapter do
        transient do
          callable { -> {} }
        end
      end

      type do
        operation :new do
          must "raise error if callable has required arguments" do
            assert { call(callable: ->(_required) {}) }.raises?(ArgumentError)
          end
        end
      end

      operation :call_adapter do
        must "return itself when converted to call adapter" do
          assert { call_adapter.equal?(subject) } == true
        end
      end

      must "dynamically define call method" do
        refute { subject.methods }.include?(:call)
        subject.call
        assert { subject.methods }.include?(:call)
      end

      must "raise error when other missing methods are called" do
        refute { subject.methods }.include?(:missing)
        assert { subject.mussing }.raises?(NoMethodError)
      end

      must "answer to call method" do
        assert { subject.respond_to?(:call) } == true
      end

      must "not answer to missing methods" do
        assert { subject.respond_to?(:missing) } == false
      end

      operation :call do
        without "keywords", props { callable { -> { "Test" } } } do
          must "ignore all keywords" do
            assert { call(one: 1, two: 2) } == "Test"
          end
        end

        with "more keywords", props { callable { ->(one:) { "Test:#{one}" } } } do
          must "ignore additional keywords" do
            assert { call(one: 1, two: 2) } == "Test:1"
          end
        end

        with "less keywords", props { callable { ->(one:, two:) { "Test:#{one}:#{two}" } } } do
          must "ignore additional keywords" do
            assert { call(one: 1) }.raises?(ArgumentError)
          end
        end
      end
    end
  end
end
