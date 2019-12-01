module Account::DocumentsHelper
  def calculate_page_number(document)
    # if document.is_a_cover
    #   document.position + 3
    # else
    #   page_number = document.content_file_name.scan(/(\d{1,4}).pdf/)[0][0].to_i rescue 1
    #   page_number += 2 if document.pack.has_cover?
    #   page_number
    # end
    1
  end

  def document_thumb_url(document)
    if File.exist?(document.content.path(:medium))
      document.content.url(:medium)
    else
      'application/processing.png'
    end
  end

  def temp_document_thumb_url(document)
    if File.exist?(document.content.path(:medium))
      document.content.url(:medium)
    else
      'application/processing.png'
    end
  end

  def document_delivery_label(document)
    delivered = true

    document.preseizures.each do |preseizure|
      delivered = false unless preseizure.is_delivered? || preseizure.is_exported?
      break unless delivered
    end

    if delivered
      label = document.preseizures.first.is_delivered? ? 'Transmis' : 'Téléchargé'

      "<span class='preseizure_status label label-success'>#{label}</span>".html_safe
    else
      "<span class='preseizure_status label label-warning'>Non récupéré</span>".html_safe
    end
  end

  def analytics_of(preseizure)
    analytics = preseizure.analytic_reference
    data_analytics = []
    if analytics 
      3.times do |i|
        j = i + 1
        references = analytics.send("a#{j}_references")
        name       = analytics.send("a#{j}_name")
        if references.present?
          references = JSON.parse(references)
          references.each do |ref|
            data_analytics << { name: name, ventilation: ref['ventilation'], axis1: ref['axis1'], axis2: ref['axis2'], axis3: ref['axis3'] } if name.present? && ref['ventilation'].present? && (ref['axis1'].present? || ref['axis2'].present? || ref['axis3'].present?)
          end
        end
      end
    end

    data_analytics
  end
end
