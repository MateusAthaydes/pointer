namespace :db do
  desc "Clean profiles db for development purposes"
  task clean_db: :environment do
    raise "Not allowed to run on production" if Rails.env.production?

    puts "Executing purge..."
    Rake::Task['db:purge'].execute
    Rake::Task['db:mongoid:purge'].execute

    puts "Executing drop..."
    Rake::Task['db:drop'].execute
    Rake::Task['db:mongoid:drop'].execute

    puts "Done."
  end

end
