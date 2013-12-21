require 'faker'
require 'securerandom'

module Deathstare
  # Represents a cached session belonging to an upstream end point.
  # Provides tools to generate and register sessions upstream.
  class UpstreamSession < ActiveRecord::Base
    belongs_to :end_point
    validates_presence_of :end_point_id
    serialize :info, OpenStruct

    # WARNING this is not an indexed query unless chained through EndPoint,
    # e.g.: `EndPoint.first.upstream_sessions.state('created')`
    scope :state, ->(state) { where(session_state: state) }

    # XXX for backward compatability, may be removed
    scope :not_logged_in, -> { where(session_state:nil) }

    # Generate an UpstreamSession given an end point. Does not attempt to save.
    #
    # @param end_point [EndPoint]
    # @return [UpstreamSession]
    def self.generate end_point
      session = new end_point_id: end_point.id
      session.generate
      session
    end

    # Override to generate needed data for a new session.
    def generate
      # noop
    end

    # Override to specify params to be merged into every session request.
    def session_params
      {}
    end

    cattr_accessor :session_states, :warm_up_steps
    # Declare a session warm-up state. You can specify multiple states,
    # and they will be executed in order. The callback must return a {RequestPromise}.
    def self.session_state state, cb=nil, &block
      cb ||= block
      state = state.to_s.freeze
      self.session_states ||= []
      self.session_states << state
      self.warm_up_steps ||= {}
      self.warm_up_steps[state] = cb
    end

    # Warm up a session, given a client handle. Can only be called on saved instances.
    # This steps through each session state as needed until the session is warmed up.
    #
    # @param client [Client]
    # @return [RequestPromise] fires on completion of login or failure
   def register_and_login client
      self.class.session_states.map {|s|[s, self.class.warm_up_steps[s]]}.inject(nil) do |p, step|
        if attained_state?(step && step.first)
          RequestPromise::Success.new(nil)
        elsif p 
          p.then { change_state client, *step }
        else
          change_state client, *step 
        end
      end
    end

    private

    def change_state client, state, cb
      # XXX produce a friendier error when the result is not a promise
      instance_exec(client, &cb).then { update(session_state:state) }
    end

    def attained_state? state
      return false unless state && session_state
      self.class.session_states.index(session_state.to_s) >=
        self.class.session_states.index(state.to_s)
    end
  end
end
