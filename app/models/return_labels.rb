# -*- encoding : UTF-8 -*-
class ReturnLabels
  FILE_NAME = 'return_labels.pdf'.freeze
  FILE_PATH = Order::FileSendingKitGenerator::TEMPDIR_PATH + "#{FILE_NAME}"


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
    documents = PeriodDocument.where(
      "scanned_at > ? AND scanned_at < ?", current_time.beginning_of_day, current_time.end_of_day
    )

    User.where(id: documents.pluck(:user_id))
  end


  def users_ids
    @ids ||= users.map(&:id)
  end


  def render_pdf
    clients_data = []
    @customers.each do |(id, data)|
      next unless id.to_i.in?(users_ids)

      user = User.find id

      next unless data[:is_checked].present? && data[:is_checked] == 'true'

      number = data[:number].to_i
      number = 0 if number > 99

      client_data = {}
      client_data[:number]   = number
      client_data[:customer] = user
      clients_data << client_data

      user.update_attribute(:return_label_generated_at, Time.now)
    end

    Order::KitGenerator.labels Order::FileSendingKitGenerator.to_return_labels(clients_data), FILE_NAME
  end


  def remove_pdf
    File.delete FILE_PATH if File.exist? FILE_PATH
  end
end
