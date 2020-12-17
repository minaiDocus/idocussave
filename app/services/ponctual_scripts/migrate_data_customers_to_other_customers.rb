class PonctualScripts::MigrateDataCustomersToOtherCustomers < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end

  def self.rollback
    new().rollback
  end

  private

  def execute
    user_id_before = get_user_id 'ACC%ADAPTO'
    user_id_after  = get_user_id 'ACC%0455'

    models.each do |mod|
      if mod.to_s == 'Pack'
        datas = mod.unscoped.where(owner_id: user_id_before)
      else
        datas = mod.unscoped.where(user_id: user_id_before)
      end

      tab_ids = datas.collect(&:id)
      logger_infos "[MigrateDataCustomersToOtherCustomers] - DataModel: #{mod.to_s} - data_count: #{datas.size}"
      datas.each do |data|
        if mod.to_s == 'Pack'
          data.update(owner_id: user_id_after)
        else
          data.update(user_id: user_id_after) if data.user_id.present?
        end
      end

      file_path = File.join(ponctual_dir, "#{mod}.csv")
      File.write(file_path, tab_ids.join(','))
    end
  end

  def backup
    user_id_before = get_user_id 'ACC%0455'
    user_id_after  = get_user_id 'ACC%ADAPTO'

    models.each do |mod|
      file_path = File.join(ponctual_dir, "#{mod}.csv")

      tab_ids = File.read(file_path).split(',')

      datas = mod.unscoped.where(id: tab_ids)

      datas.each do |data|
        if mod.to_s == 'Pack'
          data.update(owner_id: user_id_after)
        else
          data.update(user_id: user_id_after)  if data.user_id.present?
        end
      end
    end
  end

  def get_user_id(code)
    User.find_by_code(code).try(:id).to_i
  end

  def models
    #AccountNumberRule, BankAccount
    [McfDocument, Notification, Operation, Pack::Piece, Pack::Report::Expense, Pack::Report::Preseizure, Pack::Report, Pack, PeriodDocument, PreAssignmentDelivery, PreAssignmentExport, RemoteFile, RetrievedData, TempDocument, TempPack]
  end

  def ponctual_dir
    dir = "#{Rails.root}/spec/support/files/ponctual_scripts/move_customers"
    FileUtils.makedirs(dir)
    FileUtils.chmod(0777, dir)
    dir
  end
end

