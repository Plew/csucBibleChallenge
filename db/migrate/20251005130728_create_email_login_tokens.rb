class CreateEmailLoginTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :email_login_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.references :challenge, null: false, foreign_key: true
      t.references :reading, null: false, foreign_key: true
      t.string :token, null: false
      t.datetime :clicked_at
      t.datetime :sent_at

      t.timestamps
    end

    add_index :email_login_tokens, :token, unique: true
  end
end
