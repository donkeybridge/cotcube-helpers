## 0.2.2.2 (November 28, 2021)
  - dataclient fixing = for false ==
  - solving merge conflicts
  - Bump version to 0.2.2.

## 0.2.2.1 (November 28, 2021)
  - Bump version to 0.2.2.1

## 0.2.2 (November 13, 2021)
  - some further improvements to DataClient
  - some fixes related to ib_contracts
  - some fixes related to DataClient

## 0.2.1.1 (November 10, 2021)
  - Bump version to 0.2.1.

## 0.2.1 (November 10, 2021)
  - added new class 'dataclient' for communication with dataproxy
  - added .translate_ib_contract

## 0.2.0 (November 07, 2021)
  - added module Candlestick_Recognition
  - added instance_inspect method to 'scan' objects for contents of instance variables
  - symbols: made selection of symbols more versatile by key
  - added headers (:ib_symbol, :internal, :exchange, :currency) to symbol headers as well as symbol examples
  - added scripts/symbols to list (and filter) symbols from command line (put to PATH!)

## 0.1.10 (October 28, 2021)
  - added script cron_ruby_wrapper.sh (linkable as /usr/local/bin/cruw.sh)
  - added numeric ext .with_delimiter to support printing like 123_456_789.00121
  - added micros to module
  - added Helpers.micros to symbols.rb
  - subpattern: excaping regex pattern to avoid ESC errors
  - minor change

## 0.1.9.2 (July 24, 2021)
  - added missing module_functions
  - init: minor fix
  - datetime_ext: added warning comment / TODO, as switch from to daylight time will produce erroneous results
  - constants: minor fix (typo)
  - array_ext: added param to provide a default return value if result is an empty array

## 0.1.9.1 (May 07, 2021)
  - moved 'get_id_set' to Cotcube::Helpers
  - minor fix to suppress some warning during build

## 0.1.9 (May 07, 2021)
  - added constants, init and symbols to helpers

## 0.1.8 (April 18, 2021)
  - datetime_ext: Date.cw provides a range of (Date..Date) representing the according calendar week

## 0.1.7.4 (March 13, 2021)
  - hotfix on 0.1.7.3

## 0.1.7.3 (March 13, 2021)
  - array_ext: pairwise and triplewise now support saving result in latter members []=

## 0.1.7.2 (February 01, 2021)
  - adding #deep_freeze to Enumerable
  - range_ext: added #mod to modify an (actually) immutable range
  - simple_series_stats: minor fix

## 0.1.7.1 (January 17, 2021)
  - bugfix

## 0.1.7 (January 17, 2021)
  - added new method 'simple_series_stats'

## 0.1.6 (January 15, 2021)
  - removing :ranges from Range#select_within
  - Added Array#select_right_by

## 0.1.5.4 (January 02, 2021)


## 1.5.1.3 (January 02, 2021)
  - hotfixing the hotfix (hello CI tools, c ya coming)

## 1.5.1.2 (January 02, 2021)
  - hotfix problem in Range.to_time_intervals

## 0.1.5.1 (January 02, 2021)
  - Hotfixing parallelize

## 0.1.5 (January 02, 2021)
  - applied new datetime helper to Range#to_time_intervals
  - added new DateTime extension, containing 'to_seconds_since_sunday_morning'
  - added #select_within to array_ext

## 0.1.4 (December 27, 2020)
  - applied cops
  - added README for reduce; minor changes

## 0.1.3 (December 22, 2020)
  - added .reduce(bars: , to: ,*args, &block) to reduce a series of bars to a higher timeframe (though only 1hour and 1day are supported yet)

## 0.1.2 (December 21, 2020)
  - minor changes
  - minor fix to parallelize and application of positional arguments
  - added license and README

## 0.1.1 (December 21, 2020)


