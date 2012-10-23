# -*- encoding : UTF-8 -*-
class Pack::Report::Expense
  include Mongoid::Document
  include Mongoid::Timestamps

  referenced_in :report, class_name: "Pack::Report", inverse_of: :expenses
  referenced_in :piece, class_name: "Pack::Piece", inverse_of: :expense
  references_one :observation, class_name: "Pack::Report::Observation", inverse_of: :expense, dependent: :destroy

  field :amount_in_cents_wo_vat, type: Float
  field :amount_in_cents_w_vat,  type: Float
  field :vat,                    type: Float
  field :date,                   type: Date
  field :type,                   type: String
  field :origin,                 type: String
  field :obs_type,               type: Integer

  scope :perso, where: { origin: /^perso$/i }
  scope :pro,   where: { origin: /^pro$/i }

  scope :abnormal, where:  { obs_type: 0 }
  scope :normal,   not_in: { obs_type: [0] }

  class << self
    def table(sheet,title,data,x_margin=0,y=0,format1={ :weight => :bold },format2={})
      a_margin = [''] * x_margin
      margin = x_margin - 1
      tmp_y = y

      # Header
      sheet.row(tmp_y).concat ["",title,"","","","","","(en €)"]
      format = Spreadsheet::Format.new({ :weight => :bold }.merge(format1))
      sheet.row(tmp_y).set_format(margin + 1,format)
      format = Spreadsheet::Format.new :align => :right
      sheet.row(tmp_y).set_format(margin + 7,format)
      tmp_y += 2

      # Body
      format = Spreadsheet::Format.new({ :weight => :bold }.merge(format1))
      sheet.row(tmp_y).set_format(margin + 1, format)
      sheet.row(tmp_y).set_format(margin + 2, format)
      sheet.row(tmp_y).set_format(margin + 3, format)
      sheet.row(tmp_y).set_format(margin + 4, format)
      format = Spreadsheet::Format.new({ :align => :right }.merge(format1))
      sheet.row(tmp_y).set_format(margin + 5, format)
      sheet.row(tmp_y).set_format(margin + 6, format)
      sheet.row(tmp_y).set_format(margin + 7, format)
      sheet.row(tmp_y).concat(a_margin + ["Nom de la pièce (url)","Date","Observations","Type de dépense","HT","TVA","TTC"])
      tmp_y += 1
      data[0].each do |d|
        format = Spreadsheet::Format.new({ :left_color => :blue }.merge(format2))
        sheet.row(tmp_y).set_format(margin + 1, format)
        format = Spreadsheet::Format.new({ :align => :right, :number_format => "#,##0.00" }.merge(format2))
        sheet.row(tmp_y).set_format(margin + 5, format)
        sheet.row(tmp_y).set_format(margin + 6, format)
        sheet.row(tmp_y).set_format(margin + 7, format)
        sheet.row(tmp_y).concat(a_margin + d)
        tmp_y += 1
      end

      # Footer
      format = Spreadsheet::Format.new({ :align => :right, :number_format => "#,##0.00" }.merge(format1))
      sheet.row(tmp_y).set_format(margin + 5, format)
      sheet.row(tmp_y).set_format(margin + 6, format)
      sheet.row(tmp_y).set_format(margin + 7, format)
      sheet.row(tmp_y).concat(a_margin + ([''] * 4) + data[1])
      tmp_y
    end

    def render_xls
      report = self.first.report
      pack = report.pack
      book_name = pack.name.gsub(' ','_').sub('_all','')
      book = Spreadsheet::Workbook.new
      sheet = book.create_worksheet :name => book_name
      nb = 2

      aligncenter = Spreadsheet::Format.new :align => :center
      alignright = Spreadsheet::Format.new :align => :right

      sheet.column(1).width = 39
      sheet.column(3).width = 35
      sheet.column(4).width = 25

      ############################## Total ##############################
      format1 = { :pattern => 1, :pattern_fg_color => :orange, :color => :white }

      sheet.row(nb).concat ["","","","","Total","","","(en €)"]
      format = Spreadsheet::Format.new({ :weight => :bold }.merge(format1))
      sheet.row(nb).set_format(4,format)
      sheet.row(nb).set_format(7,alignright)
      nb += 2

      sheet.row(nb).concat ["","","","","Type de dépense","HT","TVA","TTC"]
      format = Spreadsheet::Format.new({ :weight => :bold }.merge(format1))
      sheet.row(nb).set_format(4, format)
      format = Spreadsheet::Format.new({ :weight => :bold, :align => :right }.merge(format1))
      sheet.row(nb).set_format(5, format)
      sheet.row(nb).set_format(6, format)
      sheet.row(nb).set_format(7, format)
      nb += 1

      format = Spreadsheet::Format.new :number_format => "#,##0.00"
      self.distinct_type.each do |type|
        expenses = self.of_type(type)
        data = expenses.to_row
        sheet.row(nb).concat (([''] * 4) + [type] + data)
        sheet.row(nb).set_format(5,format)
        sheet.row(nb).set_format(6,format)
        sheet.row(nb).set_format(7,format)
        nb += 1
      end
      sheet.row(nb).concat ["","","","","",self.total_amount_in_cents_wo_vat,self.total_vat,self.total_amount_in_cents_w_vat]
      format = Spreadsheet::Format.new ({ :weight => :bold, :number_format => "#,##0.00" }.merge(format1))
      sheet.row(nb).set_format(5,format)
      sheet.row(nb).set_format(6,format)
      sheet.row(nb).set_format(7,format)

      ############################### Pro ###############################
      nb += 4

      format1 = { :pattern => 1, :pattern_fg_color => :green, :color => :white }
      data = []
      data << self.pro.map { |e| e.to_row }
      data << [self.pro.total_amount_in_cents_wo_vat,self.pro.total_vat,self.pro.total_amount_in_cents_w_vat]
      nb = table(sheet,"Dépenses avec le compte professionnel",data,1,nb,format1)

      ############################## Perso ##############################
      nb += 4

      format1 = { :pattern => 1, :pattern_fg_color => :blue, :color => :white }
      data = []
      data << self.perso.map { |e| e.to_row }
      data << [self.perso.total_amount_in_cents_wo_vat,self.perso.total_vat,self.perso.total_amount_in_cents_w_vat]
      nb = table(sheet,"Dépenses avec le compte personnel",data,1,nb,format1)

      ############################## Info ###############################

      full_name = pack.owner.name
      period = ::I18n.t('date.month_names')[report.created_at.month].capitalize + " " + report.created_at.year.to_s

      sheet[2,1] = "Notes de frais"
      sheet[4,1] = full_name
      sheet[6,1] = period
      format = Spreadsheet::Format.new :weight => :bold, :align => :center
      sheet.row(2).set_format(1,format)
      sheet.row(4).set_format(1,aligncenter)
      sheet.row(6).set_format(1,aligncenter)

      io = StringIO.new('')
      book.write(io)
      io.string
    end

    def total_amount_in_cents_wo_vat
      sum(:amount_in_cents_wo_vat) || 0
    end

    def total_amount_in_cents_w_vat
      sum(:amount_in_cents_w_vat) || 0
    end

    def total_vat
      sum(:vat) || 0
    end

    def distinct_type
      all.distinct(:type)
    end

    def of_type(type)
      where(type: type)
    end

    def to_row
      [
          self.total_amount_in_cents_wo_vat,
          self.total_vat,
          self.total_amount_in_cents_w_vat
      ]
    end
  end

  def to_row
    [
      (Spreadsheet::Link.new(File.join(["http://www.idocus.com",piece.get_access_url]), piece.content_file_name) rescue nil),
      (self.date.strftime('%d/%m/%Y') rescue nil),
      observation.to_s,
      self.type,
      self.amount_in_cents_wo_vat,
      self.vat,
      self.amount_in_cents_w_vat
    ]
  end
end
