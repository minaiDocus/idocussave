# -*- encoding : UTF-8 -*-
module AdminHelper
  def array_of_backup_function
    NeobeApi::METHOD_LIST.map{|m| [m,m.sub(/\(.*\)/,'')]}
  end
  
  def last_used_backup_function 
    if params[:function_name]
      name = NeobeApi::METHOD_LIST.select{ |m| m.match(/#{params[:function_name]}.*/) }.first rescue ""
      [name,name.sub(/\(.*\)/,'')]
    else
      []
    end
  end
  
  def users_to_tokeninput_field(users)
    users.map{ |user| "{id: \"#{user.id}\", name: \"#{user.email}\"}"}.join(',')
  end

  def user_codes_to_tokeninput_field users
    users.sort { |a,b|
            if a.code and b.code.blank?
              -1
            elsif a.code.blank? and b.code
              1
            elsif a.code and b.code
              a.code <=> b.code
            end
          }.
          map{ |user| "{id: \"#{user.id}\", name: \"#{user.code.presence || user.email}\"}"}.
          join(',')
  end

  def sortable(column, title=nil, contains={})
    title ||= column.titleize
    direction = 'asc'
    icon = ''
    if column.to_s == sort_column
      direction = sort_direction == 'asc' ? 'desc' : 'asc'
      icon_direction = sort_direction == 'asc' ? 'down' : 'up'
      icon = content_tag( :i, '', class: 'icon-chevron-' + icon_direction)
    end
    options = contains
    options = options.merge(page: params[:page]) if params[:page]
    options = options.merge(per_page: params[:per_page]) if params[:per_page]
    link_to icon + title, { sort: column, direction: direction }.merge(options)
  end

  def get_documents(packs)
    Document.any_in(:pack_id => packs.distinct(:_id))
  end
  
  def is_option_checked?(index, option, options)
    if option.product_group.is_option_dependent
      if options.any?
        options.map{ |option| option[0] }.include?(option.title)
      else
        index == 0 ? true : false
      end
    else
      [option.title, option.price_in_cents_wo_vat].in?(options)
    end
  end

  def csv_outputter_options
    [
        [t('mongoid.models.csv_outputter.attributes.type'),:type],
        [t('mongoid.models.csv_outputter.attributes.client_code'),:client_code],
        [t('mongoid.models.csv_outputter.attributes.journal'),:journal],
        [t('mongoid.models.csv_outputter.attributes.period'),:period],
        [t('mongoid.models.csv_outputter.attributes.piece_number'),:piece_number],
        [t('mongoid.models.csv_outputter.attributes.original_piece_number'),:original_piece_number],
        [t('mongoid.models.csv_outputter.attributes.period'),:period],
        [t('mongoid.models.csv_outputter.attributes.date'),:date],
        [t('mongoid.models.csv_outputter.attributes.relevant_date'),:relevant_date],
        [t('mongoid.models.csv_outputter.attributes.deadline_date'),:deadline_date],
        [t('mongoid.models.csv_outputter.attributes.title'),:title],
        [t('mongoid.models.csv_outputter.attributes.piece'),:piece],
        [t('mongoid.models.csv_outputter.attributes.number'),:number],
        [t('mongoid.models.csv_outputter.attributes.original_amount'),:original_amount],
        [t('mongoid.models.csv_outputter.attributes.currency'),:currency],
        [t('mongoid.models.csv_outputter.attributes.conversion_rate'),:conversion_rate],
        [t('mongoid.models.csv_outputter.attributes.credit'),:credit],
        [t('mongoid.models.csv_outputter.attributes.debit'),:debit],
        [t('mongoid.models.csv_outputter.attributes.lettering'),:lettering],
        [t('mongoid.models.csv_outputter.attributes.piece_url'),:piece_url],
        [t('mongoid.models.csv_outputter.attributes.remark'),:remark],
    ]
  end
end
