class PonctualScripts::FixDematboxServices < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end

  private

  def execute
    dematboxes = Dematbox.where("DATE_FORMAT(updated_at, '%Y') = 2020")

    dematboxes.each do |demat|
      @user = demat.user

      logger_infos("--User: #{@user.code} | Demat_id: #{demat.id} | Updated_at: #{demat.updated_at} | Services : #{demat.services.count}--")

      all_groups   = DematboxService.groups.order(name: :asc).to_a
      all_services = DematboxService.services.order(name: :asc).to_a

      current_group  = all_groups.shift
      previous_group = all_groups.shift

      if current_group && previous_group
        journal_names.each do |journal_name|
          current_demat_service   = demat.services.where(name: journal_name, is_for_current_period: true).first
          previous_demat_service  = demat.services.where(name: journal_name, is_for_current_period: false).first

          next unless current_demat_service && previous_demat_service

          current_service  = all_services.shift
          previous_service = all_services.shift

          if current_service && previous_service
            current_demat_service.pid = current_service.pid
            current_demat_service.group_pid = current_group.pid
            current_demat_service.save

            previous_demat_service.pid = previous_service.pid
            previous_demat_service.group_pid = previous_group.pid
            previous_demat_service.save
          end
        end
      end
    end
  end


  def journal_names
    @user.account_book_types.order(name: :asc).map(&:name)
  end

end