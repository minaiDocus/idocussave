# -*- encoding : UTF-8 -*-
class FiduceoCategory
  def self.all(type=nil)
    Rails.cache.fetch(['fiduceo', 'categories', 'all', type], :expires_in => 7.days, :compress => true) do
      Fiduceo.categories(type)
    end
  end
end
