# -*- encoding : UTF-8 -*-
class DataVerificator::IbizaboxFolderStateProcessing
  def execute
    ibizabox_folders = IbizaboxFolder.where("updated_at < ? AND state = ?", 6.hours.ago, 'processing')

    counter = 0

    messages = []

    ibizabox_folders.each do |ibizabox_folder|
      counter += 1
      messages << "ibizabox_folder_id: #{ibizabox_folder.id}, user_code: #{ibizabox_folder.user.code}"

      ibizabox_folder.update(state: 'ready')
    end

    {
      title: "IbizaboxFolderStateProcessing - #{counter} IbizaboxFolder(s) with state processing and updated is before 6 hours ago",
      type: "table",
      message: messages.join('; ')
    }
  end
end