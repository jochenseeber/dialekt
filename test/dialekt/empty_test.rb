# frozen_string_literal: true

require "dialekt/test_base"

module Dialekt
  class EmptyTest < Calificador::Test
    operation :to_s do
      must "return string representation" do
        assert { to_s } == "<empty>"
      end
    end
  end
end
