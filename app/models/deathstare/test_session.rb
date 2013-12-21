module Deathstare

  # This is the primary entry point for configuring asynchronous test suite runs.
  #
  # Configure and create an instance, then launch tests asynchronously using {#enqueue}.
  class TestSession < ActiveRecord::Base
    include Sidekiq::Worker
    sidekiq_options :retry => false, :backtrace => true

    belongs_to :end_point
    belongs_to :user
    has_many :upstream_sessions, through: :end_point
    has_many :test_results, dependent: :delete_all
    has_many :test_errors, -> { where(error:true) }, class_name:TestResult

    # List of running tests. By design, this should only be one or zero in length.
    scope :running, -> { where('deathstare_test_sessions.ended_at is null') }

    before_validation :set_defaults, on: :create
    validate :no_tests_are_running, on: :create

    validates :devices, numericality: {only_integer: true, greater_than_or_equal_to: 1}
    validates :run_time, numericality: {only_integer: true, greater_than_or_equal_to: 0}
    validates_presence_of :base_url
    validate :has_sufficient_workers_and_suites, on: :create

    # @return [TestSession]
    def self.new_with_defaults # useful in the controller to serve the 'new' form w/ sensible defaults
      new.tap { |ts| ts.send :set_defaults }
    end

    # @!attribute [rw] test_names
    # @return [Array<String>]
    def test_names=(tn)
      @suite_names = nil
      tn = Array.wrap(tn)
      tn.reject!(&:blank?)
      write_attribute(:test_names, tn)
    end

    def start_session
      update_columns(started_at:DateTime.now)
    end

    def end_session
      update_columns(ended_at:DateTime.now).tap do |is_ended|
        # Attempt to scale workers down to zero.
        if user && HerokuApp.user_authorized_for_app?(user)
          HerokuApp.scale_sidekiq_workers(user, 0)
        end
      end
    end

    def cancel_session
      update_columns(cancelled_at:DateTime.now).tap do |is_cancelled|
        end_session if is_cancelled
      end
    end

    def started?
      started_at && started_at <= DateTime.now
    end

    def cancelled?
      cancelled_at && cancelled_at <= DateTime.now
    end

    def ended?
      ended_at && ended_at <= DateTime.now
    end

    def running?
      !ended?
    end

    # @!attribute [rw] suite_names
    # @return [Array<String>]
    def suite_names
      @suite_names ||= test_names.map {|tn| tn.split('#',2).first }.uniq
    end

    # @!attribute [rw] suite_names
    # @return [Array<String>]
    def suite_names=(sns)
      @suite_names = Array.wrap(sns)
      write_attribute(:test_names, suite_classes.
        map {|sc| sc.test_names.map {|tn| "#{sc.name}##{tn}" } }.flatten)
      @suite_names
    end

    # Get the requested test_names for the given suite.
    # @param suite_class [Deathstare::Suite] suite subclass
    # @return [Array<String>] test names for the given suite
    def suite_test_names suite_class
      s = /^#{suite_class.name}#/
      test_names.select {|tn| tn.match(s) }.map{|tn| tn.split('#',2).last }.uniq
    end

    # Enqueue the TestSession to generate devices and start the suite(s). This is the primary
    # entry point for the dashboard code and the rake tasks.
    #
    # @return [void]
    def enqueue
      self.class.perform_async(test_session_id: id)
    end

    # Register and login the required number of devices for this test session. If the
    # needed amount of devices is already cached this will be a noop. This method blocks
    # until registration and login are completed.
    #
    # @return [void]
    def initialize_devices
      count = workers * devices
      client = Client.new(base_url, max_concurrency: [count, 200].min) # Typheous gets flaky above 200
      if end_point.nil?
        update(end_point: EndPoint.find_or_create_by(base_url: base_url))
      end
      log "setup", "Checking for #{count} generated devices in the local database."
      end_point.generate_devices(count) {|progress| log "setup", "Devices: #{progress}" }
      log "setup", "Checking for #{count} logged in users."
      end_point.register_and_login_devices client,
        ->(r) { log "setup", "Logged in!";r },
        ->(r) { log_error "setup", "Device registration or login failed: #{r}" }
    end

    # Add an error log message, spits to stderr in development mode.
    #
    # @param test [String] test name or other string for grouping
    # @param message [String] logged message
    # @return [String]
    def log_error test, message
      $stderr.puts message if Rails.env.development?
      TestResult.new(suite_name: self.class.name, test_name: test, messages: message, error:true).tap do |tr|
        test_results << tr
      end
      message
    end

    # Print a debug message, spits to stdout in development mode.
    #
    # @param test [String] test name or other string for grouping
    # @param message [String] logged message
    # @return [String]
    def log test, message
      puts message if Rails.env.development?
      TestResult.new(suite_name: self.class.name, test_name: test, messages: message).tap do |tr|
        test_results << tr
      end
      message
    end

    # Safely return the suites as classes.
    # @return [Array<Class>]
    def suite_classes
      suite_names.map(&:safe_constantize).compact
    end

    # @!visibility private
    # This is not meant to be used by developers, but is an entry point for Sidekiq.
    # The worker initializes the needed devices before starting the test suites.
    def perform opts={}
      session = self.class.find(opts['test_session_id'])
      session.initialize_devices
      session.start_session

      # Spread suites out across workers, but don't start more suites than we have workers.
      offset = 0
      session.workers.times do |i|
        suite = session.suite_classes[i%session.suite_classes.count]
        suite.perform_async(test_session_id:session.id,
                            device_offset:offset,
                            test_names:session.suite_test_names(suite))
        offset += session.devices
      end
    end

    private

    def set_defaults
      self.devices = ENV['DEVICES'] || 50 if self.devices.blank?
      self.run_time = ENV['RUN_TIME'] || 0 if self.run_time.blank?
      self.workers = ENV['WORKERS'] || 1 if self.workers.blank?
      self.verbose = Rails.env.development? if self.verbose.nil?
    end

    def has_sufficient_workers_and_suites
      errors.add(:test_names, "must be specified") if test_names.blank?
      errors.add(:workers, "can not be less than the number of suites") if (workers||0) < suite_names.size
    end

    def no_tests_are_running
      errors.add(:base, "There is another test running!") if self.class.running.any?
    end
  end
end
