require 'librato/metrics/client'

module Librato
  module Metrics
    class TypheousClient < Client

      attr_accessor :hydra

      def initialize(hydra)
        @hydra = hydra
      end

      def persistence
        @persistence ||= :typheous_direct
      end

      def delete
        raise "OOPS, not implemented"
      end

      def fetch
        raise "OOPS, not implemented"
      end

      def update
        raise "OOPS, not implemented"
      end

      def list
        raise "OOPS, not implemented"
      end

      def faraday_adapter
        raise "OOPS, this shouldn't be called"
      end

      def faraday_adapter=(arg)
        raise "OOPS, this shouldn't be called"
      end

    end
  end
end
