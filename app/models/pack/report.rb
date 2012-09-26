# -*- encoding : UTF-8 -*-
class Pack::Report
  include Mongoid::Document
  include Mongoid::Timestamps

  referenced_in :pack, inverse_of: :report
  referenced_in :document, class_name: 'Scan::Document', inverse_of: :report
  references_many :expenses, class_name: "Pack::Report::Expense", inverse_of: :report

  field :type, type: String # NDF / AC / VT

  class << self
    # fetch PreSaisie info
    def fetch(time=Time.now)
      not_processed_dirs.each do |dir|
        fetch_expense(dir)
        fetch_buying(dir)
        fetch_selling(dir)
        mark_processed(dir)
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
              report = Pack::Report.new
              report.type = "NDF"
              report.pack = pack
              report.document = pack.scan_documents.for_time(Time.now.beginning_of_month,Time.now.end_of_month).first
              lot.css('piece').each do |part|
                part_name = part['number'].gsub('_',' ')
                piece = pack.pieces.where(name: part_name).first
                if piece
                  obs = part.css('obs').first
                  expense                        = Pack::Report::Expense.new
                  expense.report                 = report
                  expense.piece                  = piece
                  expense.amount_in_cents_wo_vat = part.css('ht').first.content.sub(',','.').to_f rescue nil
                  expense.amount_in_cents_w_vat  = part.css('ttc').first.content.sub(',','.').to_f rescue nil
                  expense.vat                    = part.css('tva').first.content.sub(',','.').to_f rescue nil
                  expense.date                   = part.css('date').first.content.to_date rescue nil
                  expense.type                   = part.css('type').first.content rescue nil
                  expense.origin                 = part.css('source').first.content rescue nil
                  expense.obs_type               = obs['type'].to_i rescue nil
                  expense.save
                  report.expenses << expense

                  observation = Pack::Report::Observation.new
                  observation.expense = expense
                  observation.save
                  if expense.obs_type == 2
                    obs.css('guest').each do |guest|
                      g = Pack::Report::Observation::Guest.new
                      g.observation = observation
                      g.first_name = guest.css('first_name').first.content rescue nil
                      g.last_name  = guest.css('last_name').first.content rescue nil
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

    def fetch_buying(dir)
      filepath = File.join([output_path,dir,'AC.xml'])
      #TODO not implemented yet
    end

    def fetch_selling(dir)
      filepath = File.join([output_path,dir,'VT.xml'])
      #TODO not implemented yet
    end

    def output_path
      File.join([PreSaisie::ROOT_DIR,'output'])
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
