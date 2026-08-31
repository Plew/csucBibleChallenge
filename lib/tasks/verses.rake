namespace :verses do
  desc "Import missing Bible texts (ESV OT, NASB OT, ASV OT, KJV)"
  task import_missing: :environment do
    ImportMissingVersesJob.perform_now
  end
end
