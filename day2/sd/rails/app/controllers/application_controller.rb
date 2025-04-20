require 'ostruct'

class ApplicationController < ActionController::Base
  def sync_sleep; end

  def info; end

  # 561.176 seconds seconds without cache
  # 52.553 seconds with cache
  def cpu_bound
    @number = params[:number]
    @fib = cache.fetch("think:rails:cpu_bound_#{@number}", expires_in: 60.seconds) do
      @fib = calc_fibonacci(@number)
    end
  end

  # 76.831 seconds without cache
  # 51.704 seconds with cache
  def io_bound
    size = cache.fetch('think:rails:io_bound', expires_in: 60.seconds) do
      file = File.open('test.png', 'rb')
      file.read
      size = file.size
    end
    render(json: { size: })
  end

  def cluster *_args
    all = Diplomat::Health.service('think/rails-web', passing: true).map do |meta|
      id = meta.dig(:Service, 'ID')
      ip = meta.dig(:Service, 'Address')
      port = meta.dig(:Service, 'Port')
      [id, ip, port]
    end

    @infos = all.shuffle.map do |(id, ip, port)|
      info = Net::HTTP.get(URI("http://#{ip}:#{port}/info"))
      [id, ip, port, info]
    end.sort
  end

  private

  def calc_fibonacci(int)
    int = int.to_i
    return int if int <= 1

    calc_fibonacci(int - 1) + calc_fibonacci(int - 2)
  end

  helper_method :identifier
  def identifier
    $identifier ||= "#{ENV['HOSTNAME']}_#{Time.now.to_i}"
  end

  helper_method :pid
  def pid
    Process.pid.to_s
  end

  helper_method :leader_identifier
  def leader_identifier
    cache.read('think:rails:leader')
  end

  helper_method :leader?
  def leader?
    if (lid = leader_identifier)
      return lid == identifier
    end

    cache.write('think:rails:leader', identifier, expires_in: 10.seconds)
    leader_identifier == identifier
  end


  def redis
    @redis ||= Redis.new(host: $current_ip)
  end

  def cache
    $cache ||= ActiveSupport::Cache::RedisCacheStore.new(redis: redis)
  end

  helper_method :seconds
  def seconds
    params.fetch(:seconds, 0).to_f
  end
end
