# rubocop:disable Naming/FileName
# rubocop:enable Naming/FileName
# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/time'
require 'active_support/core_ext/numeric'
require 'parallel'
require 'csv'

require_relative 'cotcube-helpers/array_ext'
require_relative 'cotcube-helpers/enum_ext'
require_relative 'cotcube-helpers/hash_ext'
require_relative 'cotcube-helpers/range_ext'
require_relative 'cotcube-helpers/string_ext'
require_relative 'cotcube-helpers/datetime_ext'
require_relative 'cotcube-helpers/numeric_ext'
require_relative 'cotcube-helpers/subpattern'
require_relative 'cotcube-helpers/parallelize'
require_relative 'cotcube-helpers/simple_output'
require_relative 'cotcube-helpers/simple_series_stats'
require_relative 'cotcube-helpers/constants'
require_relative 'cotcube-helpers/input'
require_relative 'cotcube-helpers/reduce'
require_relative 'cotcube-helpers/symbols'
require_relative 'cotcube-helpers/init'
require_relative 'cotcube-helpers/get_id_set'

module Cotcube
  module Helpers
    module_function :sub,
                    :parallelize,
                    :config_path,
                    :config_prefix,
                    :reduce,
                    :simple_series_stats,
                    :keystroke,
                    :symbols,
                    :micros,
                    :get_id_set,
                    :init

    # please not that module_functions of source provided in private files must be published there
  end
end
