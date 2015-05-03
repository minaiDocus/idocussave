# # -*- encoding : UTF-8 -*-
class SubscriptionStatsService
  def to_xls
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet name: 'Statistique des abonnements'

    sheet.row(0).concat ['Type', 'Groupe', 'Libellé', 'Montant', 'Abonnés']

    options.each_with_index do |option, index|
      sheet.row(index+1).replace(option)
    end

    io = StringIO.new('')
    book.write(io)
    io.string
  end

private

  def top_groups(product)
    product.product_groups.by_position.where(:product_supergroup_ids.with_size => 0)
  end

  def options
    options = []
    Product.by_position.each do |product|
      groups = top_groups(product)
      groups.each do |group|
        options += walk_into_group(product, group)
      end
    end
    options
  end

  def walk_into_group(product, group)
    _options = []
    group.product_subgroups.by_position.each do |subgroup|
      _options += walk_into_group(product, subgroup)
    end
    _options += options_of_group(product, group)
    _options
  end

  def options_of_group(product, group)
    group.product_options.by_position.select do |option|
      option.subscribers.size > 0
    end.map do |option|
      [
        product.title,
        group.title,
        option.title,
        option.price_in_cents_wo_vat,
        option.subscriber_ids.size
      ]
    end
  end
end
