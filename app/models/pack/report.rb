# -*- encoding : UTF-8 -*-
class Pack::Report
  include Mongoid::Document
  include Mongoid::Timestamps

  referenced_in :pack, inverse_of: :report
  references_many :expenses, class_name: "Pack::Report::Expense", inverse_of: :report

  field :type, type: String # NDF / AC / VT

  def to_xls
    book = Spreadsheet::Workbook.new

    sheet = book.create_worksheet :name => pack.name.gsub(' ','_').sub('_all','')
    nb = 0

    sheet.row(nb).concat ["","","","Total","","","","(en €)"]
    nb += 2

    sheet.row(nb).concat ["","","","Type de dépense","HT","TVA","TVA récup.","TTC"]
    nb += 1

    expenses.distinct_type.each do |type|
      temp_type = expenses.of_type(type)
      sheet.row(nb).concat ["","","",type, temp_type.total_amount_in_cents_wo_vat, temp_type.total_vat, temp_type.total_vat_recoverable, temp_type.total_amount_in_cents_w_vat]
      nb += 1
    end

    nb += 4


    sheet.row(nb).concat ["Dépenses avec le compte professionnel","","","","","","","(en €)"]
    nb += 2

    sheet.row(nb).concat ["Nom de la pièce (url)","Date","Observations","Type de dépense","HT","TVA","TVA récup.","TTC"]
    nb += 1

    expenses.pro.each do |expense|
      sheet.row(nb).concat expense.to_row
      nb += 1
    end

    nb += 4

    sheet.row(nb).concat ["Dépenses avec le compte personnel","","","","","","","(en €)"]
    nb += 2

    sheet.row(nb).concat ["Nom de la pièce (url)","Date","Observations","Type de dépense","HT","TVA","TVA récup.","TTC"]
    nb += 1

    expenses.perso.each do |expense|
      sheet.row(nb).concat expense.to_row
      nb += 1
    end

    io = StringIO.new('')
    book.write(io)
    io.string
  end

  class << self
    # fetch prepacompta info
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
                  expense.vat_recoverable        = part.css('tva_r').first.content.sub(',','.').to_f rescue nil
                  expense.date                   = part.css('date').first.content.to_date rescue nil
                  expense.type                   = part.css('type').first.content rescue nil
                  expense.origin                 = part.css('source').first.content rescue nil
                  expense.obs_type               = obs['type'].to_i rescue nil
                  expense.save
                  report.expenses << expense

                  observation = Pack::Report::Observation.new
                  observation.expense = expense
                  observation.save
                  if observation.type == 2
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
      File.join([PrepaCompta::ROOT_DIR,'output'])
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
