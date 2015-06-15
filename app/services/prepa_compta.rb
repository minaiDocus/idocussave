# -*- encoding : UTF-8 -*-
class PrepaCompta
  PATH = File.join([Rails.root, 'files', Rails.env, 'prepacompta'])

  class DocumentBundler
    class << self
      def prepare
        temp_packs = TempPack.bundle_needed.not_recently_updated
        if temp_packs.any?
          pack_names = []
          documents = []
          temp_packs.each do |temp_pack|
            current_documents = temp_pack.temp_documents.bundle_needed
            if current_documents.size > 0
              documents += current_documents
              pack_names << temp_pack.name
            end
          end
          if documents.size > 0
            path = current_folder_path
            prepare_folder(path)
            documents.each do |document|
              if document.uploaded?
                document.burst(File.join(path, 'upload'))
              elsif document.scanned_by_dematbox?
                document.burst(File.join(path, 'dematbox_scan'))
              elsif document.scanned?
                new_file_path = File.join(path, 'scan', document.file_name_with_position)
                FileUtils.cp document.content.path, new_file_path
              end
              document.bundling
            end
            create_info_file pack_names, path
          end
        end
      end

      def bundle
        not_processed_dirs.each do |dir|
          file_path = File.join(dir, 'regroupments', 'result.xml')
          if File.exist? file_path
            begin
              file = File.open(file_path)
              doc = Nokogiri::XML file
              doc.css('lot').each do |lot|
                pack_name = lot['name'].gsub('_', ' ') + ' all'
                temp_pack = TempPack.where(name: pack_name).first

                ['upload', 'dematbox_scan', 'scan'].each do |origin|
                  lot.css("piece[origin=#{origin}]").each do |piece|
                    create_piece temp_pack, piece, dir, origin
                  end
                end
              end
              mark_as_processed dir
            ensure
              file.close
            end
          end
        end
      end

      def create_piece(temp_pack, piece, dir, origin)
        Dir.mktmpdir do |tmpdir|
          file_path = File.join(tmpdir, temp_pack.basefilename)

          positions = []
          file_paths = piece.css('file_name').map do |file_name|
            part = file_name.content.sub(/\.pdf\z/i, '').split('_')
            if part.size.in?([4, 5]) && origin == 'scan'
              positions << part[-1].to_i
            elsif part.size.in?([5, 6])
              positions << part[-2].to_i
            end
            File.join(dir, 'regroupments', origin, file_name)
          end

          temp_documents = temp_pack.temp_documents.any_in(position: positions).by_position
          original_temp_document = temp_documents.first

          if file_paths.size > 1
            Pdftk.new.merge file_paths, file_path
          else
            FileUtils.cp file_paths.first, file_path
          end

          temp_document                     = TempDocument.new
          temp_document.temp_pack           = temp_pack
          temp_document.user                = temp_pack.user
          temp_document.organization        = temp_pack.organization
          temp_document.is_an_original      = false
          temp_document.is_a_cover          = original_temp_document.is_a_cover?
          temp_document.content             = open(file_path)
          temp_document.pages_number        = DocumentTools.pages_number(file_path)
          temp_document.position            = temp_pack.next_document_position
          temp_document.delivered_by        = original_temp_document.delivered_by
          temp_document.delivery_type       = original_temp_document.delivery_type
          temp_document.dematbox_box_id     = original_temp_document.dematbox_box_id     if original_temp_document.dematbox_box_id
          temp_document.dematbox_service_id = original_temp_document.dematbox_service_id if original_temp_document.dematbox_service_id
          temp_document.dematbox_text       = original_temp_document.dematbox_text       if original_temp_document.dematbox_text
          if temp_document.save
            temp_document.ready
            temp_documents.each(&:bundled)
          end
        end
      end

      def current_folder_path
        File.join([PrepaCompta::PATH, current_folder_name, 'regroupments'])
      end

      def current_folder_name
        name = Date.today.to_s
        last_name = Dir.glob("#{PrepaCompta::PATH}/*#{name}*").sort.last
        if last_name
          if (number=last_name.split('_')[1])
            "#{name}_#{number.to_i+1}"
          else
            "#{name}_2"
          end
        else
          name
        end
      end

      def prepare_folder(path)
        FileUtils.mkdir_p File.join(path, 'scan')
        FileUtils.mkdir_p File.join(path, 'upload')
        FileUtils.mkdir_p File.join(path, 'dematbox_scan')
        Dir.chdir path
      end

      def create_info_file(pack_names, path)
        File.open(File.join([path, 'info.csv']), 'w') do |f|
          pack_names.each do |pack_name|
            f.puts pack_name.sub(' all', '')
          end
        end
      end

      def not_processed_dirs
        Dir.glob(File.join(PrepaCompta::PATH, '*')).select do |e|
          File.basename(e).match /^\d{4}-\d{2}-\d{2}(_\d+)*$/
        end
      end

      def mark_as_processed(dir)
        new_dir = File.join(File.dirname(dir), "[processed]#{File.basename(dir)}")
        FileUtils.mv dir, new_dir
      end
    end
  end

  class PreAssignment
    class << self
      def prepare(pieces)
        pieces.each do |piece|
          Prepare.new(piece).execute unless piece.is_a_cover
        end
      end

      def prepare_mapping(users)
        PrepareMapping.new.execute(users)
      end

      def prepare_users_list(users)
        lines = [[:code, :name, :company, :address_first_name, :address_last_name, :address_company, :address_1, :address_2, :city, :zip, :state, :country].join(',')]
        users.each do |user|
          address = user.addresses.for_shipping.first
          line = [user.code, user.name, user.company]
          keys = [:first_name, :last_name, :company, :address_1, :address_2, :city, :zip, :state, :country]
          keys.each do |key|
            line << address.try(key).try(:gsub, ',', '')
          end
          lines << line.join(',')
        end
        File.open(Rails.root.join('data/compta/abbyy/liste_dossiers.csv'), 'w') do |f|
          f.write lines.join("\n")
        end
      end
    end

    class Prepare
      def initialize(piece)
        @piece = piece
        @dir = dir
      end

      def execute
        FileUtils.mkdir_p(@dir)
        FileUtils.cp(@piece.content.path, File.join(@dir, file_name))
        @piece.update(is_awaiting_pre_assignment: true)
      end

      def file_name
        data = [@piece.name]
        if journal.is_pre_assignment_processable?
          data << "DTI#{journal.default_account_number}"
          data << "ATI#{journal.account_number}"
          data << "DCP#{journal.default_charge_account}"
          data << "ACP#{journal.charge_account}"
          data << "TVA#{journal.vat_account}"
          data << "ANO#{journal.anomaly_account}"
          data << "TAX#{is_taxable ? 1 : 0}"
        end
        data.join('_').gsub(/\/+/, '').gsub(' ', '_') + '.pdf'
      end

      def dir
        list = [current_base_dir]
        list << 'dynamic' if @piece.temp_document.is_an_original
        list << compta_type
        File.join list
      end

      def compta_type
        journal = @piece.user.account_book_types.where(name: @piece.journal).first
        journal.compta_type
      end

      def current_base_dir
        File.join Compta::ROOT_DIR, 'input', Time.now.strftime('%Y%m%d')
      end

      def journal
        @journal ||= @piece.user.account_book_types.where(name: @piece.journal).first
      end

      def is_taxable
        @is_taxable ||= @piece.user.options.is_taxable
      end
    end

    class PrepareMapping
      def execute(users)
        grouped_users = users.group_by(&:organization)
        grouped_users.each do |organization, _users|
          if organization.try(:ibiza).try(:is_configured?)
            client = organization.ibiza.client
            _users.each do |user|
              error_file_path = Rails.root.join("data/compta/mapping/#{user.code}.error")
              xml_data = false
              xml_data = get_ibiza_accounting_plan(client, user.ibiza_id) if user.ibiza_id.present?
              if xml_data
                FileUtils.rm error_file_path if File.exist?(error_file_path)
                csv_data = ibiza_accounting_plan_to_csv(xml_data)
                write_accounting_plan(user.code, xml_data, csv_data)
              else
                FileUtils.touch error_file_path
              end
            end
          else
            _users.each do |user|
              xml_data = accounting_plan_to_xml(user.accounting_plan)
              csv_data = accounting_plan_to_csv(user.accounting_plan)
              write_accounting_plan(user.code, xml_data, csv_data)
            end
          end
        end
        true
      end

      def write_accounting_plan(code, xml_data, csv_data)
        File.open(Rails.root.join("data/compta/mapping/#{code}.xml"), 'w') do |f|
          f.write xml_data
        end

        File.open(Rails.root.join("data/compta/abbyy/mapping_csv/#{code}.csv"), 'w') do |f|
          f.write csv_data
        end
      end

      def accounting_plan_to_xml(accounting_plan)
        builder = Nokogiri::XML::Builder.new do
          data {
            accounting_plan.customers.each do |customer|
              wsAccounts {
                category 1
                associate customer.conterpart_account
                name customer.third_party_name
                number customer.third_party_account
                send(:'vat-account', accounting_plan.vat_accounts.find_by_code(customer.code).try(:account_number))
              }
            end
            accounting_plan.providers.each do |provider|
              wsAccounts {
                category 2
                associate provider.conterpart_account
                name provider.third_party_name
                number provider.third_party_account
                send(:'vat-account', accounting_plan.vat_accounts.find_by_code(provider.code).try(:account_number))
              }
            end
          }
        end
        builder.to_xml
      end

      def accounting_plan_to_csv(accounting_plan)
        data = [['category', 'name', 'number', 'associate'].join(',')]
        [[1, accounting_plan.customers], [2, accounting_plan.providers]].each do |category, accounts|
          accounts.each do |account|
            data << [
              category,
              account.third_party_name,
              account.third_party_account,
              account.conterpart_account,
            ].join(',')
          end
        end
        data.join("\n")
      end

      def get_ibiza_accounting_plan(client, ibiza_id)
        client.request.clear
        client.company(ibiza_id).accounts?
        if client.response.success?
          xml_data = client.response.body
          xml_data.force_encoding('UTF-8')
        else
          false
        end
      end

      def ibiza_accounting_plan_to_csv(xml_data)
        header = ['category', 'name', 'number', 'associate'].join(',')
        accounts = Nokogiri::XML(xml_data).css('wsAccounts').select do |account|
          account.css('closed').text.to_i == 0
        end.map do |account|
          [
            account.css('category').text.to_i,
            account.css('name').text,
            account.css('number').text,
            account.css('associate').text
          ]
        end.sort_by(&:first).map{ |a| a.join(',') }
        ([header] + accounts).join("\n")
      end
    end
  end
end
