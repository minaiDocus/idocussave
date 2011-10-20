namespace :order do
	desc "Get documents for orders"
	task :get_documents => :environment do
    puts "Get documents started..."
    Order.get_documents
    puts "Get documents endded..."
  end
end