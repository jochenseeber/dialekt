# frozen_string_literal: true

require "singleton"

module Dialekt
  # Ruby type checker
  class RubyTypeChecker < BasicTypeChecker
    include Singleton
    
    def union_type(types:)
      union_type = Set.new(types.flatten.uniq)

      raise ArgumentError, "Types must not be empty" if union_type.empty?

      union_type.size == 1 ? union_type.first : union_type
    end

    def valid?(type:, value:)
      case type
      when Array, Set
        type.any? { |t| valid?(type: t, value: value) }
      when Class
        value.is_a?(type)
      else
        raise TypeError, "Illegal type '#{type}'"
      end
    end
  end
end
