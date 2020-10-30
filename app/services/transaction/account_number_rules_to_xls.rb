# -*- encoding : UTF-8 -*-
class Transaction::AccountNumberRulesToXls
  def initialize(rules)
    @rules = rules
  end


  def execute
    book = Spreadsheet::Workbook.new

    sheet1 = book.create_worksheet name: 'Règles'

    headers = []

    headers += [
      'PRIORITE',
      'NOM',
      'TYPE',
      'CATEGORISATION',
      'CONTENU_RECHERCHE',
      'NUMERO_COMPTE'
    ]

    sheet1.row(0).concat headers
    
    if @rules.any? 
      list = []

      @rules.each do |rule|
        data = []
        data += [
          rule.priority,
          rule.name,
          rule.rule_type_short_name.to_s.upcase,
          rule.categorization,
          rule.content,
          rule.third_party_account
        ]
        list << data
      end

      list = list.sort do |a, b|
        a[0] <=> b[0]
      end

      list.each_with_index do |data, index|
        sheet1.row(index+1).replace(data)
      end
    end

    io = StringIO.new('')

    book.write(io)
    
    io.string
  end

end
