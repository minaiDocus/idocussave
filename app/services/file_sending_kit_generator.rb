# -*- encoding : UTF-8 -*-
class FileSendingKitGenerator
  TEMPDIR_PATH = "#{Rails.root}/files/#{Rails.env}/kit/"

  class << self
    def generate(clients_data,file_sending_kit, one_workshop_labels_page_per_customer=false)
      BarCode::init

      clients = to_clients(clients_data)

      clients.each do |client|
        BarCode.generate_png(client.code, 20, 0)
      end

      KitGenerator.folder to_folders(clients_data), file_sending_kit
      KitGenerator.mail to_mails(clients), file_sending_kit
      KitGenerator.customer_labels to_labels(clients_data, true)
      KitGenerator.labels to_workshop_labels(clients_data, one_workshop_labels_page_per_customer)
    end

    def to_clients(clients_data)
      clients_data.map { |client_data| client_data[:user] }
    end

    def to_folders(clients_data)
      folders_data = []
      clients_data.each do |client_data|
        current_time = Time.now.beginning_of_month
        current_time += client_data[:start_month].month
        end_time = current_time + client_data[:offset_month].month
        while current_time < end_time
          client_data[:period_duration] = client_data[:user].scan_subscriptions.last.period_duration
          client_data[:user].account_book_types.asc(:name).each do |account_book_type|
            folders_data << to_folder(client_data, current_time, account_book_type)
          end
          current_time += client_data[:period_duration].month
        end
      end
      folders_data
    end

    def to_folder(client_data, period, account_book_type)
      part_number = 1
      user = client_data[:user]
      folder = {}
      folder[:code] = user.code
      folder[:company] = user.company.upcase
      if client_data[:period_duration] == 1
        folder[:period] = I18n.l(period, format: '%B %Y').upcase
      elsif client_data[:period_duration] == 3
        duration = period.month
        if duration < 4
          part_number = 1
        elsif duration < 7
          part_number = 2
        elsif duration < 10
          part_number = 3
        else
          part_number = 4
        end
        folder[:period] = "#{KitGenerator::TRIMESTRE[part_number]} #{period.year}"
      end
      folder[:account_book_type] = "#{account_book_type.name} #{account_book_type.description.upcase}"
      folder[:instructions] = account_book_type.instructions || ''
      if client_data[:period_duration] == 1
        folder[:file_code] = "#{user.code} #{account_book_type.name} #{period.year}#{"%0.2d" % period.month}"
      elsif client_data[:period_duration] == 3
        folder[:file_code] = "#{user.code} #{account_book_type.name} #{period.year}T#{part_number}"
      end
      folder[:left_logo] = client_data[:left_logo]
      folder[:right_logo] = client_data[:right_logo]
      folder
    end

    def to_mails(users)
      users.map { |user| to_mail(user) }
    end

    def to_mail(user)
      mail = {}
      mail[:prescriber_company] = user.organization.leader.company
      mail[:client_email] = user.email
      mail[:client_password] = 'v46hps32'
      mail[:client_code] = user.code
      mail[:client_address] = address(user)
      mail
    end

    def address(user)
      address = user.addresses.for_shipping.first
      [
        address.company,
        [address.last_name, address.first_name].join(' '),
        address.address_1,
        address.address_2,
        "#{address.zip} #{address.city}"
      ].
      reject { |e| e.nil? or e.empty? }
    end

    def to_labels(clients_data, kit_shipping=false)
      labels = []
      clients_data.each do |client_data|
        label = to_label(client_data, kit_shipping)
        2.times { labels << label }
      end
      labels
    end

    def to_label(client_data, kit_shipping=false)
      user = client_data[:user]
      if kit_shipping
        address = user.addresses.for_kit_shipping.first
      else
        address = user.addresses.for_shipping.first
      end
      journals_count = user.account_book_types.count
      journals_count = 5 if journals_count < 5
      period_duration = user.scan_subscriptions.last.period_duration
      periods_count = (client_data[:offset_month] + client_data[:start_month].abs) / period_duration
      info = "J%02dP%02d" % [journals_count, periods_count]
      [
        info,
        user.code,
        address.company,
        [address.last_name, address.first_name].join(' '),
        address.address_1,
        address.address_2,
        "#{address.zip} #{address.city}"
      ].
      reject { |e| e.nil? or e.empty? }
    end

    def to_workshop_labels(clients_data, one_workshop_labels_page_per_customer=false)
      data = []
      clients_data.each do |client_data|
        user = client_data[:user]
        if user.scanning_provider && user.scanning_provider.addresses.any?
          data += to_workshop_label(client_data, one_workshop_labels_page_per_customer)
        end
      end
      data
    end

    def to_workshop_label(client_data, one_workshop_labels_page_per_customer=false)
      data = []
      user = client_data[:user]
      address = user.scanning_provider.addresses.first
      stringified_address = stringify_address(address)
      if one_workshop_labels_page_per_customer
        14.times do
          data << [user.code] + stringified_address
        end
      else
        current_time = Time.now.beginning_of_month
        current_time += client_data[:start_month].month
        end_time = current_time + client_data[:offset_month].month
        period_duration = user.scan_subscriptions.last.period_duration
        while current_time < end_time
          data << [user.code] + stringified_address
          current_time += period_duration.month
        end
      end
      data
    end

    def stringify_address(address)
      [
        address.company,
        address.address_1,
        address.address_2,
        [address.zip, address.city].join(' ')
      ].
      reject { |e| e.nil? or e.empty? }
    end

    def to_return_labels(clients_data)
      data = []
      clients_data.each { |client_data| data += to_return_label(client_data) }
      data
    end

    def to_return_label(client_data)
      customer = client_data[:customer]
      address = customer.addresses.for_shipping.first
      BarCode.generate_png(customer.code, 20, 0)
      stringified_address = stringify_return_address(address)
      data = []
      client_data[:number].times do
        data << [customer.code] + stringified_address
      end
      data
    end

    def stringify_return_address(address)
      [
        address.company,
        address.name,
        address.address_1,
        address.address_2,
        [address.zip, address.city].join(' ')
      ].
      reject { |e| e.nil? || e.empty? }
    end
  end
end
