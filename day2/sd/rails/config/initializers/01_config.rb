$current_ip = ENV.fetch('CURRENT_IP', '192.168.0.111')

Diplomat.configure do |config|
  config.url = "http://#{$current_ip}:8500"
end

class LeaderElector
  SESSION_NAME = 'leader_session'.freeze
  KEY = 'think/rails-web/leader'.freeze
  TTL = '10s'.freeze

  def initialize; end

  def identifier
    $identifier ||= "#{ENV['HOSTNAME']}_#{Time.now.to_i}"
  end

  def leader_identifier
    Diplomat::Kv.put(KEY)
  rescue Diplomat::KeyNotFound => e
    nil
  end

  def leader?
    if (lid = leader_identifier)
      return lid == identifier
    end

    Diplomat::Kv.put(KEY, identifier, acquire: consul_session)
    leader_identifier == identifier
  end

  def consul_session
    Diplomat::Session.create({ Name: SESSION_NAME, TTL: TTL, Behavior: 'delete' })
  end
end

Rails.application.config.after_initialize do
  registry = Prometheus::Client.registry
  memory_gauge = registry.gauge(:rss_memory_bytes, docstring: 'RSS memory in bytes')
  memory_gauge_mb = registry.gauge(:rss_memory_mb, docstring: 'RSS memory in MB')

  total_database_count = registry.gauge(:total_records, docstring: 'total records in DB')

  cpu_time_gauge = registry.gauge(:cpu_time, docstring: 'CPU working time')

  elector = LeaderElector.new

  ActiveSupport::Notifications.subscribe('metrics.before_scrape') do
    bytes = GetProcessMem.new.bytes
    mb = bytes / 1024 / 1024
    memory_gauge.set(bytes)
    memory_gauge_mb.set(mb)

    if elector.leader?
      total_database_count.set(100)
    end
  end

  cpu_times = {}
  ActiveSupport::Notifications.subscribe 'start_processing.action_controller' do |*args|
    cpu_times[Thread.current.object_id] = Process.clock_gettime(
      Process::CLOCK_PROCESS_CPUTIME_ID,
      :millisecond
    )
  end

  ActiveSupport::Notifications.subscribe 'process_action.action_controller' do |*args|
    start_cpu_time = cpu_times.delete(Thread.current.object_id)
    if start_cpu_time
      end_cpu_time = Process.clock_gettime(Process::CLOCK_PROCESS_CPUTIME_ID, :millisecond)
      cpu_time_gauge.set((end_cpu_time - start_cpu_time) / 1000.0)
    end
  end
end
