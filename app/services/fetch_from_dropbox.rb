# -*- encoding : UTF-8 -*-
class FetchFromDropbox
  class << self
    def execute
      DropboxBasic.all.each do |dropbox_basic|
        new(dropbox_basic).execute
        print '.'
      end
    end
  end

  def initialize(dropbox_basic)
    @dropbox_basic = dropbox_basic
    @user = @dropbox_basic.external_file_storage.user
    @customers = customers
    @path = path
  end

  def execute
    if @dropbox_basic.external_file_storage.is_used?(ExternalFileStorage::F_DROPBOX) && @dropbox_basic.is_configured?
      fetch_documents
      update_directories
    end
  end

  def customers
    if @user.is_prescriber && @user.organization
      @user.extend_organization_role
      @user.customers.entries
    else
      [@user]
    end
  end

  def path
    if @user.is_prescriber
      "exportation vers iDocus/#{@user.code} - #{@user.company.gsub(/[^0-9A-Za-z]/, '')}/" + @dropbox_basic.export_path
    else
      "exportation vers iDocus/" + @dropbox_basic.export_path
    end
  end

  def update_directories
    periods = ['période actuelle', 'période précédente']
    @customers.each do |customer|
      delete_unused_journal_folder customer
      original_path = @path
      customer_path = original_path.gsub(/:code/ , "#{customer.code} - #{customer.company.gsub(/[^0-9A-Za-z]/, '')}")
      periods.each do |period|
        period_path = customer_path.gsub(/:period/ , period)
        customer.account_book_types.each do |account_book_type|
          final_path = period_path.gsub(/:account_book/ , account_book_type.name)
          unless is_exists(final_path)
            @dropbox_basic.client.file_create_folder(final_path)
          end
        end
      end
    end
    delete_unused_customer_folder if @user.is_prescriber
  end

  def fetch_documents
    periods = ['période actuelle', 'période précédente']
    @customers.each do |customer|
      original_path = @path
      customer_path = original_path.gsub(/:code/ , "#{customer.code} - #{customer.company.gsub(/[^0-9A-Za-z]/, '')}")
      periods.each do |period|
        curent_path = customer_path.gsub(/:period/ , period)
        customer.account_book_types.each do |account_book_type|
          if is_exists(curent_path.gsub(/:account_book/ , account_book_type.name))
            files_metadata = @dropbox_basic.client.metadata(curent_path.gsub(/:account_book/ , account_book_type.name))
            files_metadata['contents'].each do |file_metadata|
              contents = @dropbox_basic.client.get_file(file_metadata['path'])
              if UploadedDocument.valid_extensions.include?(File.extname(file_metadata['path']))
                File.open("#{Rails.root}/tmp/#{File.basename(file_metadata['path'])}", 'wb') do |f|
                  f.puts contents
                  if period == 'période actuelle'
                    period_offset = 0
                  elsif period == 'période précédente'
                    period_offset = 1
                  end
                  uploaded_document = UploadedDocument.new(f, File.basename(file_metadata['path']), customer, account_book_type.name, period_offset)
                end
                File.delete("#{Rails.root}/tmp/#{File.basename(file_metadata['path'])}")
                @dropbox_basic.client.file_delete(file_metadata['path'])
              end
            end
          end
        end
      end
    end
  end

  def delete_unused_journal_folder(customer)
    customer_account_book_types = []
    customer.account_book_types.each do |account_book_type|
      customer_account_book_types << account_book_type.name
    end
    periods = ['période actuelle', 'période précédente']
    original_path = @path
    customer_path = original_path.gsub(/:code/ , "#{customer.code} - #{customer.company.gsub(/[^0-9A-Za-z]/, '')}")
    customer_path.gsub!(/:account_book.*/ , '')
    periods.each do |period|
      period_path = customer_path.gsub(/:period/ , period)
      if is_exists(period_path)
        files_metadata = @dropbox_basic.client.metadata(period_path)
        files_metadata['contents'].each do |folder|
          unless customer_account_book_types.include?(File.basename(folder['path']))
            @dropbox_basic.client.file_delete(folder['path'])
          end
        end
      end
    end
  end

  def delete_unused_customer_folder
    customers_code = []
    @customers.each do |customer|
      customers_code << "#{customer.code} - #{customer.company.gsub(/[^0-9A-Za-z]/, '')}"
    end
    original_path = @path
    if is_exists(original_path.gsub(/:code.*/ , ''))
      files_metadata = @dropbox_basic.client.metadata(@path.gsub(/:code.*/ , ''))
      files_metadata['contents'].each do |folder|
        unless customers_code.include?(File.basename(folder['path']))
          @dropbox_basic.client.file_delete(folder['path'])
        end
      end
    end
  end

  def is_exists(filepath)
    exists = false
    begin
      metadata = @dropbox_basic.client.metadata(filepath)
      exists = true if metadata && metadata['is_deleted'] != true
    rescue DropboxError
    end
    exists
  end
end
