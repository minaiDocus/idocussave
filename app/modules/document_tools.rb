# -*- encoding : UTF-8 -*-
class DocumentTools
  def self.system(command)
    success = nil
    success = POSIX::Spawn.system(command)

    success
  end


  def self.pages_number(file_path)
    begin
      extension = File.extname(file_path).downcase
      return 0 if extension != '.pdf'

      document = nil
      document = Poppler::Document.new(file_path)

      document.pages.count
    rescue => e
      System::Log.info('poppler_errors', "[pages_number] - #{file_path.to_s} - #{e.to_s}")
      0
    end
  end

  def self.to_pdf(file_path, output_file_path, tmp_dir = nil)
    extension = File.extname(file_path).downcase
    filename  = File.basename(file_path).downcase
    dirname   = tmp_dir || File.dirname(file_path)

    if extension == '.pdf'
      output_file_path = file_path
    else
      tmp_file_path = file_path

      if extension == '.heic'
        filename = filename.gsub('.heic', '.jpg')
        jpg_file_path = File.join(dirname, "heic_jpg_#{filename}")
        DocumentTools.convert_heic_to_jpg(tmp_file_path, jpg_file_path)

        tmp_file_path = jpg_file_path if File.exist?(jpg_file_path)
      end

      begin
        geometry = Paperclip::Geometry.from_file tmp_file_path
        if geometry.height > 2000 || geometry.width > 2000
          resized_file_path = File.join(dirname, "resized_#{filename}")
          DocumentTools.resize_img(tmp_file_path, resized_file_path)
          tmp_file_path = resized_file_path if File.exist?(resized_file_path)
        end
      rescue => e
        tmp_file_path ||= file_path
      end

      system 'convert "' + tmp_file_path + '" -quality 100 "pdf:' + output_file_path + '" 2>&1'

      return output_file_path
    end
  end

  def self.to_pdf_hight_quality(file_path, output_file_path)
    system 'convert -density 200 "' + file_path + '" -quality 100 "pdf:' + output_file_path + '" 2>&1'
  end

  def self.to_a4_pdf(file_path, output_file_path)
    system 'convert -page A4+0+350 "' + file_path + '" "pdf:' + output_file_path + '" 2>&1'
  end

  def self.resize_img(file_path, output_file_path)
    system 'convert "' + file_path + '" -resize 2000x2000\\> "' + output_file_path + '"'
  end

  def self.sign_pdf(file_path, output_file_path)
    system '/usr/local/bin/PortableSigner -p "1d0cu5" -n -s /usr/local/PortableSigner/idocus.p12 -t "' + file_path + '" -o "' + output_file_path + '"'
  end

  def self.convert_heic_to_jpg(input_file_path, output_file_path)
    system 'heif-convert "' + input_file_path + '" "' + output_file_path + '"'
  end

  def self.is_mergeable?(file_path)
    merge_tester_file = Rails.root.join('spec', 'support', 'files', 'upload.pdf')
    output_file = File.dirname(file_path) + "/test_merge_#{Time.now.strftime('%Y%m%d%H%M%S')}.pdf"

    is_merged = Pdftk.new.merge([file_path, merge_tester_file], output_file)

    FileUtils.rm output_file, force: true

    return is_merged
  end

  def self.force_correct_pdf(input_file_path)
    input_images       = []
    corrected          = false
    errors             = ''
    extension          = File.extname input_file_path
    pdf_to_correct_jpg = input_file_path.to_s.gsub('.pdf','_corrected.jpg')
    pdf_corrected      = pdf_to_correct_jpg.to_s.gsub('.jpg','.pdf')

    begin
      if extension != '.pdf'
        output_file_path = input_file_path.to_s.gsub(extension,'_out.pdf')
        DocumentTools.to_pdf input_file_path, output_file_path
        pdf_corrected = output_file_path
      else
        page_number = DocumentTools.pages_number(input_file_path)
        safe_time   = page_number > 0 ? (page_number * 25) : 10
        safe_time   = safe_time > 70 ? 70 : safe_time

        Timeout::timeout safe_time do
          command = 'convert -density 400 -colorspace rgb "' + input_file_path + '" "' + pdf_to_correct_jpg + '"'
          `#{command}`

          if page_number > 1
            page_number.times do |i|
              input_images << pdf_to_correct_jpg.to_s.gsub('.jpg', "-#{i}.jpg")
            end
          else
            input_images = [pdf_to_correct_jpg]
          end

          command = 'convert -density 500 #{input_images.join(' ')} -quality 100 "pdf:' + pdf_corrected + '" 2>&1'
          `#{command}`
          corrected = true

          unless File.exist?(pdf_corrected)
            errors        = "#{pdf_corrected} : Output file not created"
            corrected     = false
            pdf_corrected = input_file_path
          end
        end
      end

      pdf_corrected
    rescue => e
      System::Log.info('poppler_errors', "[force_correct_pdf] - #{input_file_path.to_s} - #{e.to_s}")
      errors        = e.to_s
      pdf_corrected = input_file_path
    end

    input_images.each do |file|
      FileUtils.rm file, force: true
    end

    return { corrected: corrected, output_file: pdf_corrected, errors: errors }
  end

  def self.modifiable?(file_path, strict = true)
    if completed? file_path, strict
      begin
        document = nil
        document = Poppler::Document.new(file_path)

        document.permissions.full?
      rescue => e
        System::Log.info('poppler_errors', "[modifiable?] - #{file_path.to_s} - #{e.to_s}")
        false
      end
    else
      false
    end
  end


  def self.completed?(file_path, strict = true)
    is_ok = true

    begin
      Poppler::Document.new(file_path)
    rescue => e
      System::Log.info('poppler_errors', "[completed?] - #{file_path.to_s} - #{e.to_s}")
      is_ok    = false
      # dir      = "#{Rails.root}/files/temp_pack_processor/poppler_error/"

      # FileUtils.makedirs(dir)
      # FileUtils.chmod(0755, dir)

      # filename        = File.basename(file_path)
      # file_error_path = File.join(dir, filename)

      # FileUtils.copy file_path, file_error_path if File.exist? file_path
    end

    if strict
      success = system Pdftk.config[:exe_path].to_s + ' "' + file_path + '" dump_data 2>&1'
      
      is_ok = false unless success
    end
    
    is_ok
  end


  def self.corrupted?(file_path)
    !completed? file_path
  end

  def self.gs_error_found?(file_path)
    verification = ''

    CustomUtils.mktmpdir('document_tools') do |dir|
      verification = `gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile="/#{dir}/verif_gs_#{Time.now.strftime('%Y%m%d%H%M%S')}.pdf" #{file_path}`
    end

    verification.match(/Error:/)
  end


  def self.printable?(file_path)
    begin
      document = Poppler::Document.new(file_path)
      document.permissions.ok_to_print?

    rescue => e
      System::Log.info('poppler_errors', "[printable?] - #{file_path.to_s} - #{e.to_s}")
      false
    end
  end


  def self.is_printable_only?(file_path)
    begin
      document = Poppler::Document.new(file_path)
      document.permissions.ok_to_print? && !document.permissions.full?

    rescue => e
      System::Log.info('poppler_errors', "[is_printable_only?] - #{file_path.to_s} - #{e.to_s}")
      nil
    end
  end

  def self.protected?(file_path)
    completed?(file_path, false) && !completed?(file_path)
  end


  def self.remove_pdf_security(file_path, new_file_path)
    system 'gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile="' + new_file_path + '" -c .setpdfwrite -f "' + file_path + '" 2>&1'
  end

  def self.correct_pdf_if_needed(file_path)
    unless system(Pdftk.config[:exe_path].to_s + ' "' + file_path + '" dump_data')
      # NOTE : the original name with the character "%" is problematic with GhostScript, so we use a simple naming "CORRECTED.pdf"
      corrected_file_path = File.dirname(file_path) + '/CORRECTED.pdf'
      if system 'gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile="' + corrected_file_path + '" "' + file_path + '"'
        FileUtils.mv corrected_file_path, file_path
      end
    end
  end

  def self.need_ocr?(file_path)
    tempfile = Tempfile.new('ocr_result')
    success = system 'pdftotext -raw -nopgbrk -q "' + file_path + '" "' + tempfile.path + '" 2>&1'

    if success
      text = tempfile.readlines.join

      tempfile.unlink

      tempfile.close

      text.blank?
    end
  end


  def self.pack_name(file_path)
    file_path.sub(/\.pdf\z/i, '').tr('_', ' ').sub(/\s\d{3}\z/, '') + ' all'
  end


  def self.name_with_position(name, position, size = 3)
    "#{name} #{("%0#{size}d" % position)}"
  end


  def self.file_name(name)
    name.tr(' ', '_') + '.pdf'
  end


  def self.stamp_name(pattern, name, origin = 'scan')
    info = name.split
    info << case origin
            when 'scan'
              'PAP'
            when 'upload'
              'UPL'
            when 'dematbox_scan'
              'BOX'
            else
              ''
            end

    pattern.gsub(':code', info[0])
           .gsub(':account_book', info[1])
           .gsub(':period', info[2])
           .gsub(':piece_num', info[3])
           .gsub(':origin', info[4])
  end


  def self.create_stamp_file(name, target_file_path, dir = '/tmp', is_stamp_background_filled = false, font_size = 10)
    sizes     = Poppler::Document.new(target_file_path).pages.map(&:size)
    file_path = File.join(dir, 'stamp.pdf')
    
    Prawn::Document.generate file_path, page_size: sizes.first, top_margin: 10 do
      sizes.each_with_index do |size, index|
        start_new_page(size: size) if index != 0

        begin
          if is_stamp_background_filled
            bounding_box([0, bounds.height], width: bounds.width) do
              table([[name]], size: font_size, position: :center) do
                style(row(0), border_color: 'FF0000', text_color: 'FFFFFF', background_color: 'FF0000')
                style(columns(0), background_color: 'FF0000', border_color: 'FF0000', align: :center)
              end
            end
          else
            fill_color 'FF0000'
            text name, size: font_size, align: :center
          end
        rescue Prawn::Errors::CannotFit
          System::Log.info('document_processor', "Prawn::Errors::CannotFit - DocumentTools.create_stamp_file '#{name}' (#{size.join(':')})")
        end
      end
    end

    file_path
  end


  def self.create_stamped_file(file_path, output_file_path, pattern, name, options = {})
    dir     = options[:dir] || '/tmp'
    origin = options[:origin] || 'scan'
    is_stamp_background_filled = options[:is_stamp_background_filled] || false

    name = stamp_name(pattern, name, origin)

    stamp_file_path = create_stamp_file(name, file_path, dir, is_stamp_background_filled, stamp_font_size(file_path))

    Pdftk.new.stamp(file_path, stamp_file_path, output_file_path)

    output_file_path
  end

  def self.stamp_font_size(file_path)
    begin
      geometry = Paperclip::Geometry.from_file(file_path)
      base = geometry.height > geometry.width ? geometry.height : geometry.width
      (base * 30 / 1500) < 10 ? 10 : (base * 30 / 1500)
    rescue Paperclip::Errors::NotIdentifiedByImageMagickError
      10
    end
  end


  def self.archive(file_path, files_path)
    clean_files_path = files_path.map { |e| '"' + e.to_s + '"' }.join(' ')

    system 'zip -j "' + file_path + '" ' + clean_files_path + ' 2>&1'

    file_path
  end


  def self.to_period(name)
    part = name.split[2]

    year = part[0..3].to_i

    month = part[4..5]
    month = '1' unless month.present?

    month = case month
                when 'T1'
                  1
                when 'T2'
                  4
                when 'T3'
                  7
                when 'T4'
                  10
                else
                  month.to_i
                end

    Date.new(year, month, 1)
  end

  def self.mimetype(filename)
    extension = File.extname(filename)
    case extension
    when '.pdf'
      'application/pdf'
    when '.csv'
      'text/csv'
    end
  end

  def self.checksum(file_path)
    `md5sum "#{file_path}"`.split[0]
  end

  def self.is_utf8(file_path)
    is = `file -i #{file_path}`

    is.match(/utf-8/) || is.match(/us-ascii/)
  end
end
