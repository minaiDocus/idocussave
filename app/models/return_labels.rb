# -*- encoding : UTF-8 -*-
class ReturnLabels
  FILE_NAME = 'return_labels.pdf'
  FILE_PATH = File.join([Rails.root, 'files', 'kit', FILE_NAME])

  attr_accessor :scanned_by, :customers, :time

  def initialize(attributes = {})
    attributes.each do |key, value|
      send("#{key}=", value)
    end
  end

  def current_time
    time || Time.now
  end

  def users
    documents = Scan::Document.any_of({ :created_at.gt => current_time.beginning_of_day, :created_at.lt => current_time.end_of_day },
                                      { :scanned_at.gt => current_time.beginning_of_day, :scanned_at.lt => current_time.end_of_day }).
                               where(scanned_by: /#{@scanned_by}/)
    codes = documents.map { |e| e.name.split[0] }.uniq
    User.any_in(code: codes)
  end

  def users_ids
    @ids ||= users.distinct(:_id).map(&:to_s)
  end

  def render_pdf
    clients_data = []
    @customers.each do |(id, data)|
      if id.in?(users_ids)
        user = User.find id
        if data[:is_checked].present? && data[:is_checked] == 'true'
          number = data[:number].to_i
          number = 0 if number > 99
          client_data = {}
          client_data[:customer] = user
          client_data[:number] = number
          clients_data << client_data
          user.update_attribute(:return_label_generated_at, Time.now)
        end
      end
    end
    KitGenerator::labels FileSendingKitGenerator::to_return_labels(clients_data), FILE_NAME
  end

  def remove_pdf
    File.delete FILE_PATH if File.exist? FILE_PATH
  end
end
