# Supplementing the Librato Ruby client, as it doesn't implement all
# then endpoints we need
class LibratoApp

  # @return [Hash] suite_name => instrument_id, a hash with all available instruments by canonical name.
  #   Note that not all instruments may be "ready" -- an instrument cannot be created unless all the metrics are valid
  #   For new or first time test runs this may not be the case.
  def self.create_or_update_instruments(*suite_names)
    suite_names.flatten!
    suite_names = Deathstar::Suite.suites.map(&:to_s) if suite_names.blank?
    suites = suite_names.reduce({}) { |h, s| h[s] = Deathstar::Suite.const_get(s).new.test_names.map { |name| name.gsub(/\W+/, '_').downcase }; h }
    # set up instrument for each suite

    resp = LibratoApiV1.get(url: "/instruments")
    raise "Missing instruments -- need pagination" if resp['query'] && resp['query']['total'].to_i == 100

    live_instruments = {}
    suites.each do |suite_name, metric_names|

      if (instrument = resp['instruments'].find { |i| i['name']==suite_name }).present?
        # Instrument exists, update if needed
        if metric_names.sort != instrument['streams'].map { |s| s['metric'].sub(/\.\w+$/,'') }.sort
          # We got more metrics than Librato's intrument. Update the metrics
          resp2 = LibratoApiV1.put(url: "/instruments/#{instrument['id']}", body: prepare_instrument_metrics(metric_names))
          raise "Error updating the metrics on instrument #{instrument['id']}, Suite: #{suite_name}" unless success?(resp2)
        end
        live_instruments[suite_name] = instrument['id'] if success?(resp)
      else
        # Create instrument
        body = prepare_instrument_metrics(metric_names)
        body[:name] = suite_name
        resp = LibratoApiV1.post(url: '/instruments', body: body, with_headers: true)
        if success?(resp)
          live_instruments[suite_name] = resp[:headers]['Location'].split('/').last.to_i
        end
      end
    end
    live_instruments
  end

  def self.success?(resp)
    !resp.has_key? :error
  end

  def self.prepare_instrument_metrics(metric_names)
    streams = metric_names.map do |metric|
      {
        'metric' => "#{metric}.response_time",
        'source' => '%'     # use Librato's "dynamic" sources
      }
    end
    {streams: streams}
  end


end
