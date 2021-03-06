# The local control flow in this example is more complex than in
# broker-locking.rb, but it has far fewer bottlenecks (try inserting some sleep
# 1 calls), and it is not possible for a token to be lost (leaving the lock in a
# locked state) if a process dies.
# However, this version is vulnerable to contention. Try this: N_PLAYERS=40
# and comment out the sleep line.

require 'tupelo/app'

N_PLAYERS = 10

Tupelo.application do
  N_PLAYERS.times do
    # sleep rand / 10 # reduce contention -- could also randomize inserts
    child do
      me = client_id
      write name: me
      
      begin
        t = transaction
        if t.take_nowait name: me
          you = t.take(name: nil)["name"]
          t.write(
            player1: me,
            player2: you)
          t.commit.wait
        else
          t.fail!
        end
      rescue Tupelo::Client::TransactionFailure => ex
        game = read_nowait(
          player1: nil,
          player2: me)
        retry unless game
        you = game["player1"]
      end

      log "now playing with #{you}"
    end
  end
end
