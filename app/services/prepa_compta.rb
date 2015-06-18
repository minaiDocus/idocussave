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
          File.basename(e).match /\A\d{4}-\d{2}-\d{2}(_\d+)*\z/
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

      def fetch
        Dir.glob(Rails.root.join('data/compta/abbyy/output/*.xml')).each do |file_path|
          if File.atime(file_path) < 5.seconds.ago
            file = File.open(file_path)
            doc = Nokogiri::XML(file)
            file.close
            schema = Nokogiri::XML::Schema(File.read(Rails.root.join('lib/xsd/pre_assignment.xsd')))
            if schema.validate(doc).map(&:to_s).empty?
              piece_data = doc.css('piece').first
              piece_name = piece_data['name'].gsub('_', ' ')
              piece = Pack::Piece.where(name: piece_name).first
              if piece
                pack = piece.pack
                user = pack.owner
                period = user.subscription.find_or_create_period(Time.now)
                document = Reporting.find_or_create_period_document(pack, period)
                report = document.report
                unless report
                  journal = user.account_book_types.where(name: piece_name.split[1]).first
                  report = Pack::Report.new
                  report.organization = user.organization
                  report.user         = user
                  report.pack         = pack
                  report.document     = document
                  report.type         = journal.compta_type
                  report.name         = pack.name.sub(/ all\z/, '')
                  report.save
                end

                preseizure                 = Pack::Report::Preseizure.new
                preseizure.report          = report
                preseizure.piece           = piece
                preseizure.user            = user
                preseizure.organization    = user.organization
                preseizure.piece_number    = piece_data.css('numero_piece').first.try(:content)
                preseizure.amount          = to_float(piece_data.css('montant_origine').first.try(:content))
                preseizure.currency        = piece_data.css('devise').first.try(:content)
                preseizure.conversion_rate = to_float(piece_data.css('taux_conversion').first.try(:content))
                preseizure.third_party     = piece_data.css('tiers').first.try(:content)
                preseizure.date            = piece_data.css('date').first.try(:content).try(:to_date)
                preseizure.deadline_date   = piece_data.css('echeance').first.try(:content).try(:to_date)
                preseizure.observation     = piece_data.css('remarque').first.try(:content)
                preseizure.position        = piece.position
                preseizure.save
                piece.update(is_awaiting_pre_assignment: false, pre_assignment_comment: nil)
                piece_data.css('account').each do |account|
                  paccount            = Pack::Report::Preseizure::Account.new
                  paccount.type       = Pack::Report::Preseizure::Account.get_type(account['type'])
                  paccount.number     = account['number']
                  paccount.lettering  = account.css('lettrage').first.try(:content)
                  account.css('debit').each do |debit|
                    entry        = Pack::Report::Preseizure::Entry.new
                    entry.type   = Pack::Report::Preseizure::Entry::DEBIT
                    entry.number = debit['number'].to_i
                    entry.amount = to_float(debit.content)
                    entry.save
                    paccount.entries << entry
                    preseizure.entries << entry
                  end
                  account.css('credit').each do |credit|
                    entry        = Pack::Report::Preseizure::Entry.new
                    entry.type   = Pack::Report::Preseizure::Entry::CREDIT
                    entry.number = credit['number'].to_i
                    entry.amount = to_float(credit.content)
                    entry.save
                    paccount.entries << entry
                    preseizure.entries << entry
                  end
                  paccount.save
                  preseizure.accounts << paccount
                end

                UpdatePeriodDataService.new(period).execute
                UpdatePeriodPriceService.new(period).execute
                CreatePreAssignmentDeliveryService.new(preseizure, true).execute
                # For manual delivery
                if report.preseizures.not_delivered.not_locked.count > 0
                  report.update_attribute(:is_delivered, false)
                end
                FileDeliveryInit.prepare(report)
                FileDeliveryInit.prepare(pack)
                path = Rails.root.join("data/compta/abbyy/processed/#{Time.now.strftime("%Y-%m-%d")}")
                FileUtils.mkdir_p path
                FileUtils.mv file_path, path
              else
                FileUtils.mv file_path, Rails.root.join('data/compta/abbyy/errors')
              end
            else
              FileUtils.mv file_path, Rails.root.join('data/compta/abbyy/errors')
            end
          end
        end
      end

      def to_float(txt)
        if txt.presence
          txt.sub(',','.').to_f
        else
          nil
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
        data = []
        grouped_users = users.group_by(&:organization)
        grouped_users.each do |organization, customers|
          if organization.try(:ibiza).try(:is_configured?)
            client = organization.ibiza.client
            customers.each do |customer|
              if customer.ibiza_id.present?
                xml_data = get_ibiza_accounting_plan(client, customer.ibiza_id)
                csv_data = ibiza_accounting_plan_to_csv(customer.code, xml_data) if xml_data
                data << [customer, xml_data, csv_data] if xml_data
              end
            end
          else
            customers.each do |customer|
              xml_data = accounting_plan_to_xml(customer.accounting_plan)
              csv_data = accounting_plan_to_csv(customer.code, customer.accounting_plan)
            end
          end
        end
        write_xml_accounting_plan(data)
        write_csv_accounting_plan(data)
        true
      end

      def write_xml_accounting_plan(data)
        data.each do |customer, xml_data, _|
          File.open(Rails.root.join("data/compta/mapping/#{customer.code}.xml"), 'w') do |f|
            f.write xml_data
          end
        end
      end

      def write_csv_accounting_plan(data)
        raw = [['category', 'name', 'number', 'associate', 'customer_code'].join(',')]
        raw += data.map{ |e| e[2] }
        File.open(Rails.root.join("data/compta/abbyy/comptes.csv"), 'w') do |f|
          f.write raw.join("\n")
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

      def accounting_plan_to_csv(customer_code, accounting_plan)
        data = []
        [[1, accounting_plan.customers], [2, accounting_plan.providers]].each do |category, accounts|
          accounts.each do |account|
            data << [
              category,
              account.third_party_name,
              account.third_party_account,
              account.conterpart_account,
              customer_code
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

      def ibiza_accounting_plan_to_csv(customer_code, xml_data)
        Nokogiri::XML(xml_data).css('wsAccounts').select do |account|
          account.css('closed').text.to_i == 0 && account.css('category').text.to_i.in?([1,2])
        end.map do |account|
          [
            account.css('category').text.to_i,
            account.css('name').text,
            account.css('number').text,
            account.css('associate').text,
            customer_code
          ]
        end.sort_by(&:first).
            map{ |a| a.join(',') }.
            join("\n")
      end
    end
  end
end
