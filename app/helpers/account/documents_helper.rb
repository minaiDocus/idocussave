# frozen_string_literal: true

module Account::DocumentsHelper
  def calculate_page_number(_document)
    # if document.is_a_cover
    #   document.position + 3
    # else
    #   page_number = document.content_file_name.scan(/(\d{1,4}).pdf/)[0][0].to_i rescue 1
    #   page_number += 2 if document.pack.has_cover?
    #   page_number
    # end
    1
  end

  #### TO REFACTOR : DUPLICATED ####
  def document_thumb_url(document)
    if document.cloud_content_thumbnail.attached?
      document.cloud_content_thumbnail.service_url
    else
      'application/processing.png'
    end
  end

  #### TO REFACTOR : DUPLICATED ####
  def temp_document_thumb_url(document)
    if document.cloud_content_thumbnail.attached?
      document.cloud_content_thumbnail.service_url
    else
      'application/processing.png'
    end
  end

  def document_delivery_label(document)
    label = ['Non récupéré', 'warning']

    document.preseizures.each do |preseizure|
      if preseizure.is_delivered?
        label = %w[Transmis success]
      elsif preseizure.is_exported?
        label = %w[Téléchargé success]
      end

      break unless label[0] == 'Non récupéré'
    end

    content_tag :span, label[0], class: "preseizure_status text-white badge badge-#{label[1]}"
  end

  def analytics_of(preseizure)
    analytics = preseizure.analytic_reference
    data_analytics = []
    if analytics
      3.times do |i|
        j = i + 1
        references = analytics.send("a#{j}_references")
        name       = analytics.send("a#{j}_name")
        next unless references.present?

        references = JSON.parse(references)
        references.each do |ref|
          if name.present? && ref['ventilation'].present? && (ref['axis1'].present? || ref['axis2'].present? || ref['axis3'].present?)
            data_analytics << { name: name, ventilation: ref['ventilation'], axis1: ref['axis1'], axis2: ref['axis2'], axis3: ref['axis3'] }
            end
        end
      end
    end

    data_analytics
  end
end
