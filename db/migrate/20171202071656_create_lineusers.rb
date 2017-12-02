class CreateLineusers < ActiveRecord::Migration[5.0]
  def change
    create_table :lineusers do |t|
      t.string :userId
      t.boolean :following
      t.boolean :news
      t.string :subscribe
      t.timestamps
    end
  end
end
