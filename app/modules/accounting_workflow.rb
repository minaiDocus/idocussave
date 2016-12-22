module AccountingWorkflow
  def self.dir
    Rails.root.join('files', Rails.env, 'prepa_compta')
  end


  def self.grouping_dir
    dir.join('grouping')
  end


  def self.pre_assignments_dir
    dir.join('pre_assignments')
  end
end
