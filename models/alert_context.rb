class AlertContext
  DEFAULT_MIN_INTERVAL_SECONDS = 5

  def initialize(platform: nil, log_file_path: nil, uri: nil)
    @platform = platform.new(uri: uri)
    @log_file_path = log_file_path
  end

  def notify(message: nil)
    if avoid_flood?
      puts "Alerta ignorado (Flood Protection)"
      return
    end

    @platform.notify(message:)

    @last_alert_time = Time.now
  end

  def avoid_flood?
    return false if @last_alert_time.nil?

    now = Time.now
    now - @last_alert_time < (@platform.class::MIN_INTERVAL_SECONDS || DEFAULT_MIN_INTERVAL_SECONDS)
  end
end
