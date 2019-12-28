# -*- encoding: utf-8 -*-
class DatabaseCleanerService
	class << self
		def clear_all
			execute	
		end

		def execute

			## Destroy McfDocument records 'created_at < 2.years.ago'
			McfDocument.where('created_at < ?', 2.years.ago).destroy_all

			## Destroy all models records when created date are more than 2 years ago
			# models = model_collections
			# models.each do |model|
			# 	model.where('created_at < ?', 2.years.ago).destroy_all
			# end
		end

		### --------- TODO ------------- ###
		def model_collections
		    models = []
		    folder = File.join(Rails.root, "app", "models")
		    Dir[File.join(folder, "*")].each do |filename|
		      klass = File.basename(filename, '.rb').camelize.constantize
		      models << klass
		    end
		    return models
		end
		
	end	
end