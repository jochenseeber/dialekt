# frozen_string_literal: true

module Dialekt
  module Util
    # Core Ruby extensions
    module CoreExtensions
      TYPE_CHECKER_CONST = :DIALEKT_TYPE_CHECKER
      INFLECTOR_CONST = :DIALEKT_INFLECTOR
  
      module ModuleMixins
        def dialekt_base_name
          @__dialekt_base_name ||= begin # rubocop:disable Naming/MemoizedInstanceVariableName
            name.gsub(%r{\A.+::}, "")
          end
        end

        def dialekt_enclosing_module
          if %r{\A(?<parent_name>[^:#]+(?:::[^:#]+)*)::[^:]+\z} =~ name && Kernel.const_defined?(parent_name)
            Kernel.const_get(parent_name)
          end
        end

        def dialekt_lookup_type_checker
          if const_defined?(TYPE_CHECKER_CONST, true)
            const_get(TYPE_CHECKER_CONST)
          else
            enclosing_module = self.dialekt_enclosing_module

            type_checker = if enclosing_module.nil?
              RubyTypeChecker.instance
            else
              enclosing_module.dialekt_type_checker
            end

            const_set(TYPE_CHECKER_CONST, type_checker)
          end
        end

        def dialekt_type_checker(checker = EMPTY)
          if checker == EMPTY
            dialekt_lookup_type_checker
          else
            if const_defined?(TYPE_CHECKER_CONST)
              raise ArgumentError, "#{self.class} #{self} already has a type checker defined"
            end

            const_set(TYPE_CHECKER_CONST, checker)
          end
        end

        def dialekt_lookup_inflector
          if const_defined?(INFLECTOR_CONST, true)
            const_get(INFLECTOR_CONST)
          else
            enclosing_module = self.dialekt_enclosing_module

            inflector = if enclosing_module.nil?
              Dry::Inflector.new
            else
              enclosing_module.dialekt_inflector
            end

            const_set(INFLECTOR_CONST, inflector)
          end
        end

        def dialekt_inflector(inflector = EMPTY)
          if inflector == EMPTY
            dialekt_lookup_inflector
          else
            if const_defined?(INFLECTOR_CONST)
              raise ArgumentError, "#{self.class} #{self} already has an inflector defined"
            end

            const_set(INFLECTOR_CONST, inflector)
          end
        end
      end

      Module.include(ModuleMixins)

      module CallableExtensions
        def call_signature
          CallSignature.create(signature: parameters)
        end
      end

      Proc.include(CallableExtensions)
      Method.include(CallableExtensions)
      UnboundMethod.include(CallableExtensions)

      module ProcExtensions
        def call_adapter
          CallAdapter.new(callable: self)
        end
      end

      Proc.include(ProcExtensions)
    end
  end
end
