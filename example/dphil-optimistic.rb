# Dining philosopher example. Like dphil.rb, but uses transactions and
# can work correctly without the "room tickets", which are really
# global locks. We optimistically let all philosophers dine at the same time.
# This version is several times faster than the locking version (try increasing
# N_PHIL).

require 'tupelo/app/dsl'
require 'tupelo/app/monitor'

N_PHIL = 5
N_ITER = 10
VERBOSE = ARGV.delete "-v"

Tupelo::DSL.application do
  start_monitor if VERBOSE

  N_PHIL.times do |i|
    child do
      log.progname << ": phil #{i}"
      write ["eat", i, 0] # amount eaten

      N_ITER.times do
        transaction do
          # lock the resource (in transaction, so optimistically):
          c0 = take ["chopstick", i]
          c1 = take_nowait ["chopstick", (i+1)%N_PHIL]
          fail! unless c1 # try again (unlikely, but possible)

          # use the resource:
          _,_,count = take ["eat", i, nil]
          write ["eat", i, count+1]

          # release the resource:
          write c0, c1
        end
      end
      
      log "ate #{read(["eat", i, nil])[2]}"
    end
  end
  
  local do
    N_PHIL.times do |i|
      write ["chopstick", i]
    end
  end
end