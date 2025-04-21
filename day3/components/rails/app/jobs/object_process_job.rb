class ObjectProcessJob < ApplicationJob
  def perform(uuid)
    object = HeavyFileObject.find_by(uuid:)
    object.processed! if object&.processing?
  end
end
