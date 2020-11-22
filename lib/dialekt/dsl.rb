# frozen_string_literal: true

module Dialekt
  # DSL extensions
  module Dsl
    # DSL mixins for Class
    module ClassMixins
      def dsl_scalar(name, **options, &block)
        property = Model::ScalarProperty.new(name: name, **options)
        Docile.dsl_eval(property, &block) if block
        property.setup(owner: self)
        property
      end

      def dsl_map(name, **options, &block)
        property = Model::MapProperty.new(name: name, **options)
        Docile.dsl_eval(property, &block) if block
        property.setup(owner: self)
        property
      end

      def dsl_set(name, **options, &block)
        property = Model::SetProperty.new(name: name, **options)
        Docile.dsl_eval(property, &block) if block
        property.setup(owner: self)
        property
      end
    end

    Class.include(ClassMixins)
  end
end
