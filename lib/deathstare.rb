require "deathstare/engine"
require "deathstare/config"
require "deathstare/suite"

module Deathstare
  # @return [Deathstare::Config]
  def self.config
    @config ||= Config.new
  end

  # Configure Deathstare. Works similarly to `Rails.configure`.
  # See {Deathstare::Config} for available options.
  #
  # @return [void]
  def self.configure &block
    instance_exec &block
  end
end
