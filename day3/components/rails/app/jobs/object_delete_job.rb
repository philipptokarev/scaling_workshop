class ObjectDeleteJob < ApplicationJob
  def perform
    return unless LeaderElector.new.leader?

    ids = HeavyFileObject.where(state: :processed).ids
    # sending ids to delete
    sleep(rand(1..3))
    HeavyFileObject.where(id: ids).update_all(state: :deleted)
  end
end
