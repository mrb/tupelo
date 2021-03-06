require 'tupelo/app'

Tupelo.application do
  local do
    write_wait [1]

    note = notifier

    transaction do
      x = take [1]
      write x
    end
    
    note.wait
    status, tick, cid, op = note.wait
    p op # should "read [1]", not "write [1]; take [1]"
    # this is just an optimization, not really a bug
  end
end
