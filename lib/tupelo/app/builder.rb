module Tupelo
  # Not an essential part of the library, but used to build up groups of
  # processes for use in examples, tests, benchmarks, etc.
  class AppBuilder
    attr_reader :ez

    # Does this app own (as child processes) the seq, cseq, and arc servers?
    attr_reader :owns_servers

    # Arguments available to application after tupelo has parsed out switches
    # and args that it recognizes.
    attr_reader :argv

    def initialize ez, owns_servers: nil, argv: argv
      @ez = ez
      @owns_servers = owns_servers
      @argv = argv
    end

    def log
      ez.log
    end

    # Yields a client that runs in this process.
    def local client_class = Client, **opts, &block
      ez.local :seqd, :cseqd, :arcd do |seqd, cseqd, arcd|
        opts = {seq: seqd, cseq: cseqd, arc: arcd, log: log}.merge(opts)
        run_client client_class, **opts do |client|
          if block
            if block.arity == 0
              client.instance_eval &block
            else
              yield client
            end
          end
        end
      end
    end

    # Yields a client that runs in a subprocess.
    #
    # A passive client will be forced to stop after all active clients exit. Use
    # the passive flag for processes that wait for tuples and respond in some
    # way. Then you do not have to manually interrupt the whole application when
    # the active processes are done. See examples.
    def child client_class = Client, passive: false, **opts, &block
      ez.child :seqd, :cseqd, :arcd, passive: passive do |seqd, cseqd, arcd|
        opts = {seq: seqd, cseq: cseqd, arc: arcd, log: log}.merge(opts)
        run_client client_class, **opts do |client|
          if block
            if block.arity == 0
              client.instance_eval &block
            else
              yield client
            end
          end
        end
      end
    end

    def run_client client_class, opts
      log = opts[:log]
      log.progname = "client <starting in #{log.progname}>"
      client = client_class.new opts
      client.start do
        log.progname = "client #{client.client_id}"
      end
      yield client
    ensure
      client.stop if client # gracefully exit the tuplespace management thread
    end
  end
end
