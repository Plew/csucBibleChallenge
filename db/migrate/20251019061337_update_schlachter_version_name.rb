class UpdateSchlachterVersionName < ActiveRecord::Migration[8.0]
  def up
    Verse.where(version: 'Schlachter 2000').update_all(version: 'SCHL2000')
  end

  def down
    Verse.where(version: 'SCHL2000').update_all(version: 'Schlachter 2000')
  end
end
