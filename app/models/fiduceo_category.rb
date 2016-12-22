# -*- encoding : UTF-8 -*-
### Fiduceo related - remained untouched (or nearly) : to be deprecated soon ###
class FiduceoCategory
  def self.all(type = nil)
    Rails.cache.fetch(['fiduceo', 'categories', 'all', type], expires_in: 7.days, compress: true) do
      categories = Fiduceo.categories(type)
      if Fiduceo.response.code == 200
        categories.each do |category|
          category.id = category.id.to_i
        end
      else
        []
      end
    end
  end


  def self.flush_cache
    Rails.cache.delete %w(fiduceo categories all debit)
    Rails.cache.delete %w(fiduceo categories all credit)
    Rails.cache.delete ['fiduceo', 'categories', 'all', nil]
  end


  def self.find(id)
    if id == 0
      obj = OpenStruct.new
      obj.name = 'Autres recettes'
      obj.id = 0
      obj
    elsif id == -1
      obj = OpenStruct.new
      obj.name = 'Autres dépenses'
      obj.id = -1
      obj
    else
      result = all.select { |e| e.id.to_i == id }.first
      if result
        result
      else
        obj = OpenStruct.new
        obj.name = 'Inconnue'
        obj.id = -2
        obj
      end
    end
  end
end
