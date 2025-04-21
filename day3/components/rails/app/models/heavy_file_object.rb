class HeavyFileObject < ApplicationRecord
  STATES = {
    initial: 0,
    processing: 1,
    processed: 2,
    deleted: 3
  }.freeze

  enum state: STATES
end
