# frozen_string_literal: true

require "dialekt/test_base"

module Dialekt
  module Util
    class CallSignatureTest < Calificador::Test
      factory CallSignature::Parameter do
        init_with { CallSignature::Parameter.new(name: :a, optional: false) }
      end

      examine CallSignature::Parameter do
        operation :== do
          must "compare correctly" do
            assert { call(CallSignature::Parameter.new(name: :a, optional: false)) } == true
            assert { call(CallSignature::Parameter.new(name: :a, optional: true)) } == false
            assert { call(CallSignature::Parameter.new(name: :b, optional: false)) } == false
          end
        end

        operation :"!=" do
          must "compare correctly" do
            assert { call(CallSignature::Parameter.new(name: :a, optional: false)) } == false
            assert { call(CallSignature::Parameter.new(name: :a, optional: true)) } == true
            assert { call(CallSignature::Parameter.new(name: :b, optional: false)) } == true
          end
        end
      end

      factory CallSignature do
        transient do
          signature { [] }
        end

        initialize_with { CallSignature.create(signature: signature) }
      end

      type do
        operation :create do
          must "parse arguments" do
            call(signature: [%i[req a], %i[opt b]])

            assert { result.parameters } == [
              CallSignature::Parameter.new(name: :a, optional: false),
              CallSignature::Parameter.new(name: :b, optional: true),
            ]
          end

          must "parse extra arguments" do
            call(signature: [%i[req a], %i[rest b]])

            assert { result.parameters } == [
              CallSignature::Parameter.new(name: :a, optional: false),
            ]
  
            assert { result.extra_parameters } == CallSignature::Parameter.new(name: :b, optional: true)
          end

          must "parse keywords" do
            call(signature: [%i[keyreq a], %i[key b]])

            assert { result.options } == {
              a: CallSignature::Parameter.new(name: :a, optional: false),
              b: CallSignature::Parameter.new(name: :b, optional: true),
            }
          end
  
          must "parse extra options" do
            call(signature: [%i[keyreq a], %i[keyrest b]])

            assert { result.options } == {
              a: CallSignature::Parameter.new(name: :a, optional: false),
            }
  
            assert { result.extra_options } == CallSignature::Parameter.new(name: :b, optional: true)
          end

          must "provide number of required arguments" do
            call(signature: [%i[req a], %i[opt b], %i[opt c]])

            assert { result.required_parameter_count } == 1
          end
  
          must "provide number of optional parameters" do
            call(signature: [%i[req a], %i[opt b], %i[opt c]])

            assert { result.optional_parameter_count } == 2
          end
  
          must "reject unknown parameter types" do
            assert { subject.create(signature: [%i[req a], %i[unknown b]]) }.raises?(ArgumentError)
          end
        end
      end
    end
  end
end
