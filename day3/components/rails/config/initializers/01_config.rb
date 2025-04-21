require 'prometheus/client/data_stores/direct_file_store'

$current_ip = ENV.fetch('CURRENT_IP', '192.168.0.111')

Diplomat.configure do |config|
  config.url = "http://#{$current_ip}:8500"
end

class LeaderElector
  def initialize; end

  def identifier
    $identifier ||= "#{ENV['HOSTNAME']}_#{Time.now.to_i}"
  end

  def leader_identifier
    cache.read('think:metrics:leader')
  end

  def leader?
    if (lid = leader_identifier)
      return lid == identifier
    end

    cache.write('think:metrics:leader', identifier, expires_in: 10.seconds)
    leader_identifier == identifier
  end

  def redis
    @redis = Redis.new(host: $current_ip)
  end

  def cache
    $cache ||= ActiveSupport::Cache::RedisCacheStore.new(redis: redis)
  end
end

Rails.application.config.after_initialize do
  Prometheus::Client.config.data_store = Prometheus::Client::DataStores::DirectFileStore.new(dir: '/tmp/prometheus_metrics')
  registry = Prometheus::Client.registry
  memory_gauge = registry.gauge(:rss_memory_bytes, docstring: 'RSS memory in bytes')
  memory_gauge_mb = registry.gauge(:rss_memory_mb, docstring: 'RSS memory in MB')

  total_database_count = registry.gauge(:total_records, docstring: 'total records in DB')
  file_processing_count = registry.gauge(:file_processing_count, docstring: 'file processing count')
  file_processed_count = registry.gauge(:file_processed_count, docstring: 'file processed count')
  file_deleted_count = registry.gauge(:file_deleted_count, docstring: 'file deleted count')

  elector = LeaderElector.new

  ActiveSupport::Notifications.subscribe('metrics.before_scrape') do
    bytes = GetProcessMem.new.bytes
    mb = bytes / 1024 / 1024
    memory_gauge.set(bytes)
    memory_gauge_mb.set(mb)

    if elector.leader?
      total_database_count.set(100)
      file_processing_count.set(
        HeavyFileObject.where(state: :processing, created_at: 1.day.ago..Time.now
      ).count)
      file_processed_count.set(
        HeavyFileObject.where(state: :processed, created_at: 1.day.ago..Time.now
      ).count)
      file_deleted_count.set(
        HeavyFileObject.where(state: :deleted, created_at: 1.day.ago..Time.now
      ).count)
    end
  end
end
