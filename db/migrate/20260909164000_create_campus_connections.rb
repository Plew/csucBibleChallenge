class CreateCampusConnections < ActiveRecord::Migration[7.2]
  def change
    create_table :campus_connections, if_not_exists: true do |t|
      t.references :user, null: false, foreign_key: true  # Officer who authorized it
      t.string :campus_name, null: false                  # e.g. "Christian Students at UC"
      t.string :hub_url, null: false                      # e.g. "https://uc-campushub.org"
      t.string :sso_secret, null: false                   # Secure generated secret
      t.references :challenge, foreign_key: true          # Selected reading challenge
      t.timestamps
    end
    add_index :campus_connections, :hub_url, unique: true, if_not_exists: true
  end
end
