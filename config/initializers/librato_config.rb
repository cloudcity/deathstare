require 'librato/librato_api_v1'

# Fix bug in module Librato::Metrics::Processor by monkey patching

module Librato
  module Metrics

    module Processor
      private

      def create_persister
        type = self.client.persistence.to_s.camelize
        Librato::Metrics::Persistence.const_get(type).new
      end

    end
  end
end
