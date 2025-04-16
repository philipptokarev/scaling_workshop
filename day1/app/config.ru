require 'json'
require 'logger'
require 'get_process_mem'

require 'active_support/all'
require 'awesome_print'

# LogHelper
class LogHelper < ::Logger
  def initialize(*args, **kwargs)
    $stdout.sync
    $stderr.sync
    super($stdout, *args, **kwargs)
  end

  def exception(message, e)
    error "#{message}: #{e.inspect}"
    error "Backtrace: #{e.backtrace}"
  end
end

$logger = ActiveSupport::TaggedLogging.new(LogHelper.new($stdout)).tagged("PID:#{Process.pid}")

SUCCESS_RESPONSE = [
  'HTTP/1.1 200 OK',
  'Connection: Keep-Alive',
  'Content-Type: application/json',
  '',
  ''
].join("\r\n").freeze

  # puma -t 1:1 -p 3000
  # PASSENGER_MAX_REQUEST_QUEUE_SIZE=1
  # passenger start --max-pool-size 1
  # thin start --threaded --threadpool-size 2
class Application
  def initialize(*args); end

  def call(env)
    request = Rack::Request.new(env)
    url = URI.parse(request.url)

    action, *args = url.path.gsub('//', '/').split('/').select(&:present?)
    if action.nil? || action.empty? || action == 'favicon.ico'
      # logger.info 'Empty action. Skip'
      [200, {}, ['{}']]
    else
      logger.info "Processing #{action.inspect} with #{args.inspect}..."
      send(action, request, *args)
    end
  rescue StandardError => e
    logger.exception('Server error:', e)
    [500, {}, [render_string("Error: #{e.inspect}")]]
  end

  def mem(request, *args)
    bytes = GetProcessMem.new.bytes
    puts "MEM:#{bytes / 1024 / 1024}"
    [200, {}, [render_string("current memory for #{bytes / 1024 / 1024}")]]
  end

  def sync_sleep(_request, seconds, *_args)
    sleep(seconds.to_f)
    [200, {}, [render_string("sleeping for #{seconds.to_f}")]]
  end

  # асинхронная обработка запроса - веб сервер отдаём сетевой сокет во владение самому приложению и забывает про него
  # это НЕкорректная реализация - так делать нельзя
  def async(request, *_args)
    case (srv = server(request))
    when :thin
      # в Thin так вебсервер информируется об асинхронной обработке
      throw :async
    when :puma
      # в Puma вебсервер "забывает" про сокет когда получает такой ответ от вашего приложения
      [-1, {}, []]
    when :passenger
      # в Passenger вебсервер "забывает" про сокет когда получает такой ответ от вашего приложения
      [-1, {}, []]
    else
      raise "Invalid server for asyn processing: #{srv.inspect}"
    end
  end

  def async_sleep(request, seconds, *_args)
    case server(request)
    when :thin
      Thread.new(request.env['async.callback']) do |cb|
        sleep(seconds.to_f)
        cb.call([200, {}, render_string("Thin thread sleep: #{seconds.to_f}")])
      end
      # в Thin так вебсервер информируется об асинхронной обработке
      throw :async
    when :puma
      Thread.new(request.env['puma.socket']) do |socket|
        sleep(seconds.to_f)
        socket.write(SUCCESS_RESPONSE)
        socket.write(render_string("Puma thread sleep: #{seconds.to_f}"))
        socket.write("\n\n")
        socket.close
      end
      # в Puma вебсервер "забывает" про сокет когда получает такой ответ от вашего приложения
      [-1, {}, []]
    when :passenger
      Thread.new(request.env['rack.hijack'].call) do |socket|
        sleep(seconds.to_f)
        socket.write(SUCCESS_RESPONSE)
        socket.write(render_string("Passenger thread sleep: #{seconds.to_f}"))
        socket.write("\n\n")
        socket.close
      end
      # в Passenger вебсервер "забывает" про сокет когда получает такой ответ от вашего приложения
      [-1, {}, []]
    else
      sleep(seconds.to_f)
      [200, {}, [render_string('No async sleep')]]
    end
  end

  def cpu_bound(_request, fib_number, *_args)
    [200, {}, [render_string(calc_fibonacci(fib_number))]]
  end

  def cpu_bound_async(request, fib_number, *_args)
    case server(request)
    when :thin
      Thread.new(request.env['async.callback']) do |cb|
        cb.call([200, {}, [render_string(calc_fibonacci(fib_number))]])
      end
      # в Thin так вебсервер информируется об асинхронной обработке
      throw :async
    when :puma
      Thread.new(request.env['puma.socket']) do |socket|
        socket.write(SUCCESS_RESPONSE)
        socket.write(render_string(calc_fibonacci(fib_number)))
        socket.write("\n\n")
        socket.close
      end
      # в Puma вебсервер "забывает" про сокет когда получает такой ответ от вашего приложения
      [-1, {}, []]
    when :passenger
      Thread.new(request.env['rack.hijack'].call) do |socket|
        socket.write(SUCCESS_RESPONSE)
        socket.write(render_string(calc_fibonacci(fib_number)))
        socket.write("\n\n")
        socket.close
      end
      # в Passenger вебсервер "забывает" про сокет когда получает такой ответ от вашего приложения
      [-1, {}, []]
    else
      [200, {}, [render_string(calc_fibonacci(fib_number))]]
    end
  end

  def io_bound(_request, *_args)
    File.read('test.png')

    [200, {}, [render_string('done')]]
  end

  def io_bound_async(request, *_args)
    case server(request)
    when :thin
      Thread.new(request.env['async.callback']) do |cb|
        File.read('test.png')

        cb.call([200, {}, [render_string('done')]])
      end
      # в Thin так вебсервер информируется об асинхронной обработке
      throw :async
    when :puma
      Thread.new(request.env['puma.socket']) do |socket|
        File.read('test.png')

        socket.write(SUCCESS_RESPONSE)
        socket.write(render_string('done'))
        socket.write("\n\n")
        socket.close
      end
      # в Puma вебсервер "забывает" про сокет когда получает такой ответ от вашего приложения
      [-1, {}, []]
    when :passenger
      Thread.new(request.env['rack.hijack'].call) do |socket|
        File.read('test.png')

        socket.write(SUCCESS_RESPONSE)
        socket.write(render_string('done'))
        socket.write("\n\n")
        socket.close
      end
      # в Passenger вебсервер "забывает" про сокет когда получает такой ответ от вашего приложения
      [-1, {}, []]
    else
      [200, {}, [render_string('done')]]
    end
  end

  private

  def calc_fibonacci(int = 0)
    int = int.to_i
    return int if int <= 1

    calc_fibonacci(int - 1) + calc_fibonacci(int - 2)
  end

  def render_string(msg)
    "#{ENV['HOSTNAME']}[#{Process.pid}] #{Time.now}:#{msg}"
  end

  def logger
    $logger
  end

  def server(request)
    if request.env['SERVER_SOFTWARE']&.downcase&.[]('thin')
      :thin
    elsif request.env['SERVER_SOFTWARE']['puma']
      :puma
    elsif request.env['SERVER_SOFTWARE']['Passenger']
      :passenger
    else
      :other
    end
  end
end

run Application.new
