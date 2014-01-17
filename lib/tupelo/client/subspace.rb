class Tupelo::Client
  module Api
    def define_subspace metatuple
      defaults = {__tupelo__: "subspace", addr: nil}
      write_wait defaults.merge!(metatuple)
    end

    # call this just once at start of first client (it's optional to
    # preserve behavior of non-subspace-aware code)
    def use_subspaces!
      return if subspace(TUPELO_SUBSPACE_TAG)
      define_subspace(
        tag:          TUPELO_SUBSPACE_TAG,
        template:     {
          __tupelo__: {value: "subspace"},
          tag:        nil,
          addr:       nil,
          template:   nil
        }
      )
    end

    def subspace tag
      tag = tag.to_s
      worker.subspaces.find {|sp| sp.tag == tag} or begin
        if subscribed_tags.include? tag
          read __tupelo__: "subspace", tag: tag, addr: nil, template: nil
          worker.subspaces.find {|sp| sp.tag == tag}
        end
      end
      ## this impl will not be safe with dynamic subspaces
    end
  end
end