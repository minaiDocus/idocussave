# -*- encoding : UTF-8 -*-
class PrepaCompta
  class << self
    def dir
      Rails.root.join('files', Rails.env, 'prepa_compta')
    end

    def grouping_dir
      dir.join('grouping')
    end

    def pre_assignments_dir
      dir.join('pre_assignments')
    end
  end
end
