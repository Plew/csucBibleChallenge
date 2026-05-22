class AddCountryCodeToGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :groups, :country_code, :string, limit: 2
  end
end
