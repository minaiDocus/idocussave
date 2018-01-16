module Account::DocumentsHelper
  def calculate_page_number(document)
    if document.is_a_cover
      document.position + 3
    else
      page_number = document.content_file_name.scan(/(\d{1,4}).pdf/)[0][0].to_i rescue 1
      page_number += 2 if document.pack.has_cover?
      page_number
    end
  end

  def document_thumb_url(document)
    if document.dirty || !File.exist?(document.content.path(:medium))
      'application/processing.png'
    else
      document.content.url(:medium)
    end
  end
end
