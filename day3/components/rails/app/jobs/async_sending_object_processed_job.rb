class AsyncSendingObjectProcessedJob < ApplicationJob
  def perform(uuid)
    $redis.then{ |r| r.publish('think_tasks', "ObjectProcessJob:#{uuid}") }
  end
end
