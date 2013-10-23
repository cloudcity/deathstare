require "deathstar/engine"
require "deathstar/config"

module Deathstar
  # @return [Deathstar::Config]
  def self.config
    @config ||= Config.new
  end

  # Configure Deathstar. Works similarly to `Rails.configure`.
  # See {Deathstar::Config} for available options.
  #
  # @return [void]
  def self.configure &block
    instance_exec &block
  end
end
