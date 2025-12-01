class RemoveAuthFieldsFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :verification_code, :string
    remove_column :users, :verification_sent_at, :datetime
    remove_column :users, :email_verified_at, :datetime
    remove_column :users, :reset_token, :string
    remove_column :users, :reset_sent_at, :datetime
  end
end
