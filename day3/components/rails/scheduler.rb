#!/usr/bin/env ruby

require 'rufus-scheduler'

Rails.logger.info 'Run scheduler'

class Scheduler
  def initialize
    @pidfile = ENV.fetch('PIDFILE', '/tmp/scheduler.pid')
  end

  def start(&block)
    Rufus::Scheduler.new(frequency: 5, max_work_threads: 2).tap do |s|
      @scheduler = s

      ActiveSupport::Notifications.instrument('local.start_metrics')

      File.write(@pidfile, Process.pid)

      block.call(s)

      s.join

      ActiveSupport::Notifications.instrument('local.stop_metrics')

      FileUtils.rm(@pidfile, force: true)
    end
  end

  def shutdown
    @shutdown = true
    return unless @scheduler

    @scheduler&.stop rescue nil
    sleep 2
    @scheduler&.kill rescue nil
    @scheduler = nil
  end
end

scheduler = Scheduler.new

Signal.trap('INT') do
  Thread.new { scheduler.shutdown }
end

Signal.trap('TERM') do
  Thread.new { scheduler.shutdown }
end

scheduler.start do |s|
  # s.cron '0 * * * *' do
  #   TestJob.perform_later('Regular minute')
  # end

  # s.every '10s' do
  #   TestJob.perform_later('Regular 10s')
  # end

  s.every '15s' do
    ObjectDeleteJob.perform_later
  end

  # s.every '10s' do
  #   TestSidekiqJob.perform_later('Regular 10s')
  # end

  # s.every '10s' do
  #   TestSchedulerJob.perform_later(Time.now, 1.week.since)
  # end
end

scheduler.shutdown
Rails.logger.warn 'Shutdown ok'
