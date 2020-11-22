# frozen_string_literal: true

require "pp"
require "stringio"

module Dialekt
  # Type checker
  class BasicTypeChecker
    def valid?(type:, value:)
      raise NotImplementedError
    end

    def union_type(types:)
      raise NotImplementedError
    end

    def check!(type:, value:)
      raise TypeError, "Object must be of type(s) #{type}" unless valid?(type: type, value: value)

      true
    end

    def format(type:)
      PP.singleline_pp(type, StringIO.new).string
    end
  end
end
