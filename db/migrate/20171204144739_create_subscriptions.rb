class CreateSubscriptions < ActiveRecord::Migration[5.0]
  def change
    create_table :subscriptions do |t|
      t.string :lineuser_id
      t.string :currency_pair
      t.string :status, default: "ON"
      t.timestamps
    end
  end
end
