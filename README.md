## Cotcube::Helpers

Just a collection of helpers not fitting into other repositories of the Cotcube suite. Also usable aside of Cotcube. Where appropriate, these are provided as core\_extensions, otherwise within the model Cotcube::Helpers

#### Extending Array

##### compact\_or\_nil

Returns the array compacted--or just nil, when the result is empty?

##### split\_by(attr)

This is a rather old implementation. Most probably something I developed before I met Array#group\_by.

##### pairwise(&block) / triplewise(&block)

Yields block on each consecutive pair of the array, hence returning array.size-1 results.

##### triplewise(&block)
 
Yields block on each consecutive triple of the array, hence returning array.size-2 results.

#### Extending Enumerator

##### shy\_peek

Peeks into the successor without raising if there is none available--returning nil instead.

#### Extending Hash

##### keys\_to\_sym

Transforms the keys of a Hash (recursivly for subsequent Arrays and Hashes) into symbols.

#### Extending Range

##### to\_time\_intervals(timezone: Time.find\_zone('America/Chicago'), step:, ranges: nil)

Uses the range of *date alikes* delivered to create an Array of time periods of length :step
(which is a ActiveSupport::Duration, e.g. 5.minutes or 1.hour). 

When the step is sub-day, the periods are cleared for DST-changes.

When ranges are nil, only periods are returned that are within the full trading hours. This is
accomplished by the fact, that Sunday is wday==0. If you want to use ranges, just send a an array
of ranges, providing seconds starting at Sunday morning midnight. Here is the default as example:

```
    ranges ||= [
       61200..143999,   # Sun 5pm .. Mon 4pm
      147600..230399,   # Mon 5pm .. Tue 4pm
      234000..316799,   # ...
      320400..403199,
      406800..489599
    ]
```

#### Extending String

##### is\_valid\_json?

#### Subpattern

##### sub(minimum: 1) { [:hyper, :mega] }

sub (should be 'subpattern', but too long) is for use in case / when statements
it returns a lambda, that checks the case'd expression for matching subpattern
based on the the giving minimum. E.g. 'a', 'ab' .. 'abcd' will match sub(1){'abcd'}
but only 'abc' and 'abcd' will match sub(3){'abcd'}

The recommended use within evaluating user input, where abbreviation of incoming commands
is desirable (h for hoover and hyper, what will translate to sub(2){'hoover'} and sub(2){hyper})

To extend functionality even more, it is possible to send a group of patterns to, like
sub(2){[:hyper,:mega]}, what will respond truthy to "hy" and "meg" but not to "m" or "hypo"

*paired with keystroke() it allows an easy build of an inputhandler*

#### SimpleOutput

This is a very simple class, that mocks a more complex output handler. It provides puts, print,
puts! and print!. The actual OutputHandler is another project that needs to be rewritten. Once
that is done, SimpleOutput will be replaced. The new OutputHandler is a tool to handle information
flow like logs, to pause and continue output.

#### Input

##### keystroke(quit: false)

A version of STDIN.gets, that does not wait for pressing 'enter' but instantly returns the content
of the keystroke. 

*paired with subpattern it allows an easy build of an inputhandler*

#### Parallelize

##### parallelize(ary, processes: 1, threads: 1, progress: "", &block)

Based on https://github.com/grosser/parallel, it is a quite convenient way to parallelize tasks. 


