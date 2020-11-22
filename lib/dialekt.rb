# frozen_string_literal: true

require "singleton"
require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.setup

# Main module
module Dialekt
  class Empty
    include Singleton

    def to_s
      "<empty>"
    end

    alias_method :inspect, :to_s
  end

  EMPTY = Empty.instance
end

require "dialekt/dsl"
require "dialekt/util/core_extensions"
