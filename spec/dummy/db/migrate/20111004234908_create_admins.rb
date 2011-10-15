class CreateAdmins < ActiveRecord::Migration
  def change
    create_table :admins do |t|
      t.string  :name
      t.string  :email
      t.string  :password_digest
      t.boolean :admin, :default => false
      t.string  :kind, :default => 'semi-cool'
      t.timestamps
    end
  end
end