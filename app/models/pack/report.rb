# -*- encoding : UTF-8 -*-
class Pack::Report
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :organization,                                        inverse_of: :report
  belongs_to :user,                                                inverse_of: :pack_reports
  belongs_to :pack,                                                inverse_of: :report
  belongs_to :document,    class_name: 'Scan::Document',           inverse_of: :report
  has_many   :expenses,    class_name: "Pack::Report::Expense",    inverse_of: :report, dependent: :delete
  has_many   :preseizures, class_name: 'Pack::Report::Preseizure', inverse_of: :report, dependent: :delete
  has_many   :remote_files, as: :remotable, dependent: :destroy

  field :type, type: String # NDF / AC / CB / VT
  field :is_delivered, type: Boolean, default: false

  scope :preseizures, not_in: { type: ['NDF'] }
  scope :expenses, where: { type: 'NDF' }

  def to_csv(outputter=pack.owner.csv_outputter!, ps=self.preseizures, is_access_url=true)
    outputter.format(ps, is_access_url)
  end

  def generate_files(user=pack.owner)
    # TODO implement me
    generate_csv_files(user)
  end
  
  def generate_csv_files(user=pack.owner)
    outputter = pack.owner.csv_outputter!
    filespath = []
    if type != 'NDF'
      tmp = self.preseizures.group_by { |p| p.created_at.strftime("%Y%m%d") }
      tab = tmp.values
      tab.each do |pre|
        idx = pre.map(&:_id)
        date = pre[0].created_at
        data = to_csv(outputter, self.preseizures.any_in(_id: idx), user.is_access_by_token_active)
        basename = self.pack.name.sub(' all','').gsub(' ','_')
        file= File.new("/tmp/#{basename}_L#{date.strftime("%Y%m%d")}.csv", "w")
        file.write(data)
        file.close
        filespath << file.path
      end
    end
    filespath
  end

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
                report.type = "NDF"
                report.user = pack.owner
                report.pack = pack
                report.organization = pack.owner.organization
                report.document = pack.periodic_metadata.for_time(Time.now.beginning_of_month,Time.now.end_of_month).first
                report.document ||= pack.periodic_metadata.desc(:created_at).first
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
                    expense.position               = piece.position
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
                report.document.period.update_information!
              end
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
                preseizures = []
                name = lot['name'].gsub('_',' ') + ' all'
                pack = Pack.find_by_name(name)
                if pack
                  report = pack.report || Pack::Report.new
                  report.type = e
                  report.user = pack.owner
                  report.pack = pack
                  report.organization = pack.owner.organization
                  report.document = pack.periodic_metadata.for_time(Time.now.beginning_of_month,Time.now.end_of_month).first
                  report.document ||= pack.periodic_metadata.desc(:created_at).first
                  lot.css('piece').each do |part|
                    part_name = part['number'].gsub('_',' ')
                    piece = pack.pieces.where(name: part_name).first
                    if piece
                      preseizure                 = Pack::Report::Preseizure.new
                      preseizure.report          = report
                      preseizure.piece           = piece
                      preseizure.piece_number    = part.css('numero_piece').first.try(:content)
                      preseizure.amount          = to_float(part.css('montant_origine').first.try(:content))
                      preseizure.currency        = part.css('devise').first.try(:content)
                      preseizure.conversion_rate = to_float(part.css('taux_conversion').first.try(:content))
                      preseizure.third_party     = part.css('tiers').first.try(:content)
                      preseizure.date            = part.css('date').first.try(:content).try(:to_date)
                      preseizure.deadline_date   = part.css('echeance').first.try(:content).try(:to_date)
                      preseizure.observation     = part.css('remarque').first.try(:content)
                      preseizure.position        = piece.position
                      preseizure.save
                      preseizures << preseizure
                      part.css('account').each do |account|
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
                    end
                  end
                  report.save
                  report.document.period.update_information!
                  if preseizures.any?
                    if report.organization && report.organization.ibiza && report.organization.ibiza.is_configured? && report.organization.ibiza.is_auto_deliver
                      report.organization.ibiza.export(preseizures)
                    else
                      report.update_attribute(:is_delivered, false)
                    end
                  end
                  FileDeliveryInit.prepare(report)
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
