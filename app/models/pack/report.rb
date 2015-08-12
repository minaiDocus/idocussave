# -*- encoding : UTF-8 -*-
class Pack::Report
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :organization,                                        inverse_of: :report
  belongs_to :user,                                                inverse_of: :pack_reports
  belongs_to :pack,                                                inverse_of: :report
  belongs_to :document,    class_name: 'PeriodDocument',           inverse_of: :report
  has_many   :expenses,    class_name: "Pack::Report::Expense",    inverse_of: :report, dependent: :destroy
  has_many   :preseizures, class_name: 'Pack::Report::Preseizure', inverse_of: :report, dependent: :destroy
  has_many   :remote_files, as: :remotable, dependent: :destroy
  has_many   :pre_assignment_deliveries

  field :name
  field :type # NDF / AC / CB / VT / FLUX
  field :is_delivered,      type: Boolean, default: false
  field :delivery_tried_at, type: Time
  field :delivery_message
  field :is_locked,         type: Boolean, default: false

  scope :preseizures, -> { not_in(type: ['NDF']) }
  scope :expenses,    -> { where(type: 'NDF') }

  scope :locked,     -> { where(is_locked: true) }
  scope :not_locked, -> { where(is_locked: false) }

  def journal
    result = name.split[1]
    if user
      user.account_book_types.where(name: result).first.try(:get_name) || result
    else
      result
    end
  end

  class << self
    def failed_delivery(user_ids=[], limit=0)
      match = { '$match' => { 'delivery_message' => { '$ne' => '', '$exists' => true } } }
      match['$match']['user_id'] = { '$in' => user_ids } if user_ids.present?
      group = { '$group' => {
          '_id'       => { 'report_id' => '$report_id', 'delivery_message' => '$delivery_message' },
          'count'     => { '$sum' => 1 },
          'failed_at' => { '$max' => '$delivery_tried_at' }
        }
      }
      sort = { '$sort' => { 'failed_at' => -1 } }
      params = [match, group, sort]
      params << { '$limit' => limit } if limit > 0
      Pack::Report::Preseizure.collection.aggregate(*params).map do |delivery|
        object = OpenStruct.new
        object.date           = delivery['failed_at'].try(:localtime)
        object.document_count = delivery['count'].to_i
        object.name           = Pack::Report.find(delivery['_id']['report_id']).name
        object.message        = delivery['_id']['delivery_message']
        object
      end
    end

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
                period = pack.owner.subscription.find_or_create_period(Time.now)
                document = Reporting.find_or_create_period_document(pack, period)
                report = document.report
                unless report
                  report = Pack::Report.new
                  report.organization = pack.owner.organization
                  report.user         = pack.owner
                  report.pack         = pack
                  report.document     = document
                  report.type         = 'NDF'
                  report.name         = pack.name.sub(/ all\z/, '')
                  report.save
                end
                lot.css('piece').each do |part|
                  part_name = part['number'].gsub('_',' ')
                  piece = pack.pieces.where(name: part_name).first
                  if piece and piece.expense.nil?
                    obs = part.css('obs').first
                    expense                        = Pack::Report::Expense.new
                    expense.report                 = report
                    expense.piece                  = piece
                    expense.user                   = report.user
                    expense.organization           = report.organization
                    expense.amount_in_cents_wo_vat = to_float(part.css('ht').first.try(:content))
                    expense.amount_in_cents_w_vat  = to_float(part.css('ttc').first.try(:content))
                    expense.vat                    = to_float(part.css('tva').first.try(:content))
                    expense.date                   = part.css('date').first.try(:content).try(:to_date)
                    expense.type                   = part.css('type').first.try(:content)
                    expense.origin                 = part.css('source').first.try(:content)
                    expense.obs_type               = obs['type'].to_i
                    expense.position               = piece.position
                    expense.save
                    piece.update(is_awaiting_pre_assignment: false, pre_assignment_comment: nil)

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
                UpdatePeriodDataService.new(period).execute
                UpdatePeriodPriceService.new(period).execute
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
                  period = pack.owner.subscription.find_or_create_period(Time.now)
                  document = Reporting.find_or_create_period_document(pack, period)
                  report = document.report
                  unless report
                    report = Pack::Report.new
                    report.organization = pack.owner.organization
                    report.user         = pack.owner
                    report.pack         = pack
                    report.document     = document
                    report.type         = e
                    report.name         = pack.name.sub(/ all\z/, '')
                    report.save
                  end
                  lot.css('piece').each do |part|
                    part_name = part['number'].gsub('_',' ')
                    piece = pack.pieces.where(name: part_name).first
                    if piece
                      preseizure                 = Pack::Report::Preseizure.new
                      preseizure.report          = report
                      preseizure.piece           = piece
                      preseizure.user            = report.user
                      preseizure.organization    = report.organization
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
                      piece.update(is_awaiting_pre_assignment: false, pre_assignment_comment: nil)
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
                  UpdatePeriodDataService.new(period).execute
                  UpdatePeriodPriceService.new(period).execute
                  CreatePreAssignmentDeliveryService.new(preseizures, true).execute
                  # For manual delivery
                  if report.preseizures.not_delivered.not_locked.count > 0
                    report.update_attribute(:is_delivered, false)
                  end
                  FileDeliveryInit.prepare(report)
                  FileDeliveryInit.prepare(pack)
                end
              end
            end
          end
        end
      end
    end

    def output_path
      File.join([PrepaCompta.pre_assignments_dir, 'output'])
    end

    def directories
      Dir.entries(output_path).
          select { |e| e.match(/\A\d{8}\z/) }
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
