class AddHeavyFileObject < ActiveRecord::Migration[7.2]
  def change
    create_table :heavy_file_objects do |t|
      t.string :uuid
      t.integer :state, default: 0
      t.timestamps
    end
  end
end
