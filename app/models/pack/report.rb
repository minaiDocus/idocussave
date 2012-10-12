# -*- encoding : UTF-8 -*-
class Pack::Report
  include Mongoid::Document
  include Mongoid::Timestamps

  referenced_in :pack, inverse_of: :report
  referenced_in :document, class_name: 'Scan::Document', inverse_of: :report
  references_many :expenses, class_name: "Pack::Report::Expense", inverse_of: :report, dependent: :delete
  references_many :preseizures, class_name: 'Pack::Report::Preseizure', inverse_of: :report, dependent: :delete

  field :type, type: String # NDF / AC / CB / VT

  class << self
    # fetch Compta info
    def fetch(time=Time.now)
      not_processed_dirs.each do |dir|
        fetch_expense(dir)
        fetch_preseizure(dir)
        mark_processed(dir)
      end
    end

    def to_float(txt)
      if txt.presence
        txt.sub(',','.').to_f
      else
        nil
      end
    end

    def fetch_expense(dir)
      filepath = File.join([output_path,dir,'NDF.xml'])
      file = File.open(filepath)
      doc = Nokogiri::XML(file)
      doc.css('customer').each do |customer|
        code = customer['code']
        user = User.find_by_code(code)
        if user
          customer.css('lot').each do |lot|
            name = lot['name'].gsub('_',' ') + ' all'
            pack = Pack.find_by_name(name)
            if pack
              report = pack.report || Pack::Report.new
              report.type = "NDF"
              report.pack = pack
              report.document = pack.scan_documents.for_time(Time.now.beginning_of_month,Time.now.end_of_month).first
              lot.css('piece').each do |part|
                part_name = part['number'].gsub('_',' ')
                piece = pack.pieces.where(name: part_name).first
                if piece and piece.expense.nil?
                  obs = part.css('obs').first
                  expense                        = Pack::Report::Expense.new
                  expense.report                 = report
                  expense.piece                  = piece
                  expense.amount_in_cents_wo_vat = to_float(part.css('ht').first.try(:content))
                  expense.amount_in_cents_w_vat  = to_float(part.css('ttc').first.try(:content))
                  expense.vat                    = to_float(part.css('tva').first.try(:content))
                  expense.date                   = part.css('date').first.try(:content).try(:to_date)
                  expense.type                   = part.css('type').first.try(:content)
                  expense.origin                 = part.css('source').first.try(:content)
                  expense.obs_type               = obs['type'].to_i
                  expense.save
                  report.expenses << expense

                  observation         = Pack::Report::Observation.new
                  observation.expense = expense
                  observation.comment = obs.css('comment').first.try(:content)
                  observation.save
                  obs.css('guest').each do |guest|
                    first_name = guest.css('first_name').first.try(:content)
                    last_name  = guest.css('last_name').first.try(:content)
                    if first_name.present? || last_name.present?
                      g = Pack::Report::Observation::Guest.new
                      g.observation = observation
                      g.first_name  = first_name
                      g.last_name   = last_name
                      g.save
                    end
                  end
                end
              end
              report.save
            end
          end
        end
      end
    end

    def fetch_preseizure(dir)
      %w(AC CB VT).each do |e|
        filepath = File.join([output_path,dir,"#{e}.xml"])
        file = File.open(filepath) rescue nil
        if file
          doc = Nokogiri::XML(file)
          doc.css('customer').each do |customer|
            code = customer['code']
            user = User.find_by_code(code)
            if user
              customer.css('lot').each do |lot|
                name = lot['name'].gsub('_',' ') + ' all'
                pack = Pack.find_by_name(name)
                if pack
                  report = pack.report || Pack::Report.new
                  report.type = e
                  report.pack = pack
                  report.document = pack.scan_documents.for_time(Time.now.beginning_of_month,Time.now.end_of_month).first
                  report.save
                  report.document.save
                  lot.css('piece').each_with_index do |part,index|
                    part_name = part['number'].gsub('_',' ')
                    piece = pack.pieces.where(name: part_name).first
                    if piece and piece.preseizure.nil?
                      preseizure               = Pack::Report::Preseizure.new
                      preseizure.piece         = piece
                      preseizure.date          = part.css('date').first.try(:content).try(:to_date)
                      preseizure.deadline_date = part.css('echeance').first.try(:content).try(:to_date)
                      preseizure.observation   = part.css('remarque').first.try(:content)
                      preseizure.position      = index + 1
                      preseizure.save
                      report.preseizures << preseizure
                      part.css('account').each_with_index do |account,index|
                        paccount            = Pack::Report::Preseizure::Account.new
                        paccount.title      = account['title']
                        paccount.number     = account['number']
                        paccount.credit     = to_float(account.css('credit').first.try(:content))
                        paccount.debit      = to_float(account.css('debit').first.try(:content))
                        paccount.lettering  = account.css('lettrage').first.try(:content)
                        paccount.position   = index + 1
                        paccount.save
                        preseizure.accounts << paccount
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    def output_path
      File.join([Compta::ROOT_DIR,'output'])
    end

    def directories
      Dir.entries(output_path).
          select { |e| e.match(/^\d{8}$/) }
    end

    def processed_dirs
      Dir.entries(output_path).
          select { |e| File.extname(e) == '.txt' }.
          map { |e| File.basename(e,'.txt') }
    end

    def not_processed_dirs
      directories - processed_dirs
    end

    def mark_processed(dir)
      File.new(File.join([output_path,dir + '.txt']), 'w')
    end
  end
end
