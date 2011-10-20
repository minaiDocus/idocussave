namespace :reprocess_styles do
	desc "Reprocess styles"
	task :do => :environment do
    puts "Starting reprocess..."
    Document.do_reprocess_styles
    puts "Reprocess is finished."
  end
end