# rubocop:disable Naming/FileName
# rubocop:enable Naming/FileName
# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/time'
require 'active_support/core_ext/numeric'
require 'parallel'

require_relative 'cotcube-helpers/array_ext'
require_relative 'cotcube-helpers/enum_ext'
require_relative 'cotcube-helpers/hash_ext'
require_relative 'cotcube-helpers/range_ext'
require_relative 'cotcube-helpers/string_ext'
require_relative 'cotcube-helpers/subpattern'
require_relative 'cotcube-helpers/parallelize'
require_relative 'cotcube-helpers/simple_output'
require_relative 'cotcube-helpers/input'
require_relative 'cotcube-helpers/reduce'

module Cotcube
  module Helpers
    module_function :sub,
                    :parallelize,
                    :reduce,
                    :keystroke

    # please not that module_functions of source provided in private files must be published there
  end
end
