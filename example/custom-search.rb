require 'tupelo/app'

class MyClient < Tupelo::Client
  # A custom search method. Note this is not the same as using a custom
  # data structure for the tuplespace, which can be much more efficient than
  # the default linear search.
  def read_all_diagonal val, &bl
    diag_matcher = proc {|t| t.all? {|v| v == val} }
      # Note that Proc#===(t) calls the proc on t. It's convenient, but not
      # essential to this example. We could also define a custom class with any
      # implementation of #===.

    read_all diag_matcher, &bl
  end
end

Tupelo.application do
  local MyClient do
    write [41, 42, 43]
    write [42, 42, 42]
    write [42, 42]
    write_wait [42] # make sure all writes up to this one have completed

    log read_all
    log read_all_diagonal 42
  end
end
