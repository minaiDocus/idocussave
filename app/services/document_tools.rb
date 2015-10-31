# -*- encoding : UTF-8 -*-
class DocumentTools
  class << self
    def system(command)
      success = nil
      silence_stream(STDOUT) do
        success = POSIX::Spawn::system(command)
      end
      success
    end

    def pages_number(file_path)
      document = nil
      silence_stream(STDERR) do
        document = Poppler::Document.new(file_path)
      end
      document.pages.count
    end

    def to_pdf(file_path, output_file_path)
      system "convert '#{file_path}' 'pdf:#{output_file_path}' 2>&1"
    end

    def modifiable?(file_path, strict=true)
      if completed? file_path, strict
        begin
          document = nil
          silence_stream(STDERR) do
            document = Poppler::Document.new(file_path)
          end
          document.permissions.full?
        rescue GLib::Error
          false
        end
      else
        false
      end
    end

    def completed?(file_path, strict=true)
      is_ok = true
      begin
        silence_stream(STDERR) do
          Poppler::Document.new(file_path)
        end
      rescue GLib::Error
        is_ok = false
      end
      if strict
        success = system "#{Pdftk.config[:exe_path]} '#{file_path}' dump_data 2>&1"
        is_ok = false unless success
      end
      # consumes too much cpu cycle
      # is_ok = false unless system("identify #{file_path}")
      is_ok
    end

    def corrupted?(file_path)
      !completed? file_path
    end

    def printable?(file_path)
      begin
        silence_stream(STDERR) do
          document = Poppler::Document.new(file_path)
          document.permissions.ok_to_print?
        end
      rescue GLib::Error
        false
      end
    end

    def is_printable_only?(file_path)
      begin
        silence_stream(STDERR) do
          document = Poppler::Document.new(file_path)
          document.permissions.ok_to_print? && !document.permissions.full?
        end
      rescue GLib::Error
        nil
      end
    end

    def remove_pdf_security(file_path, new_file_path)
      system "gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile='#{new_file_path}' -c .setpdfwrite -f '#{file_path}' 2>&1"
    end

    def need_ocr?(file_path)
      tempfile = Tempfile.new('ocr_result')
      success = system "pdftotext -raw -nopgbrk -q '#{file_path}' '#{tempfile.path}' 2>&1"
      if success
        text = tempfile.readlines.join
        tempfile.unlink
        tempfile.close
        text.blank?
      else
        nil
      end
    end

    def pack_name(file_path)
      file_path.sub(/\.pdf\z/i, '').gsub('_',' ').sub(/\s\d{3}\z/,'') + ' all'
    end

    def name_with_position(name, position, size=3)
      "#{name} #{("%0#{size}d" % position)}"
    end

    def file_name(name)
      name.gsub(' ', '_') + '.pdf'
    end

    def stamp_name(pattern, name, origin='scan')
      info = name.split
      case origin
      when 'scan'
        info << 'PAP'
      when 'upload'
        info << 'UPL'
      when 'dematbox_scan'
        info << 'BOX'
      else
        info << ''
      end

      pattern.gsub(':code', info[0]).
              gsub(':account_book', info[1]).
              gsub(':period', info[2]).
              gsub(':piece_num', info[3]).
              gsub(':origin', info[4])
    end

    def create_stamp_file(name, target_file_path, dir='/tmp', is_stamp_background_filled=false)
      file_path = File.join(dir, 'stamp.pdf')
      sizes = Poppler::Document.new(target_file_path).pages.map(&:size)
      Prawn::Document.generate file_path, page_size: sizes.first, top_margin: 10 do
        sizes.each_with_index do |size, index|
          start_new_page(size: size) if index != 0
          begin
            if is_stamp_background_filled
              bounding_box([0, bounds.height], :width => bounds.width) do
                table([[name]], position: :center) do
                  style(row(0), border_color: 'FF0000', text_color: 'FFFFFF', background_color: 'FF0000')
                  style(columns(0), background_color: 'FF0000', border_color: 'FF0000', align: :center)
                end
              end
            else
              fill_color 'FF0000'
              text name, size: 10, :align => :center
            end
          rescue Prawn::Errors::CannotFit
            puts "Prawn::Errors::CannotFit - DocumentTools.create_stamp_file '#{name}' (#{size.join(':')})"
          end
        end
      end
      file_path
    end

    def create_stamped_file(file_path, output_file_path, pattern, name, options={})
      dir = options[:dir] || '/tmp'
      origin = options[:origin] || 'scan'
      is_stamp_background_filled = options[:is_stamp_background_filled] || false

      name = stamp_name(pattern, name, origin)
      stamp_file_path = create_stamp_file(name, file_path, dir, is_stamp_background_filled)
      Pdftk.new.stamp(file_path, stamp_file_path, output_file_path)
      output_file_path
    end

    def archive(file_path, files_path)
      clean_files_path = files_path.map { |e| "'#{e}'" }.join(' ')
      system "zip -j '#{file_path}' #{clean_files_path} 2>&1"
      file_path
    end

    def to_period(name)
      part = name.split[2]
      year = part[0..3].to_i
      month = part[4..5]
      case month
      when "T1"
        month = 1
      when "T2"
        month = 4
      when "T3"
        month = 7
      when "T4"
        month = 10
      else
        month = month.to_i
      end
      Date.new(year, month, 1)
    end

    def mimetype(filename)
      extension = File.extname(filename)
      case extension
      when '.pdf'
        'application/pdf'
      when '.csv'
        'text/csv'
      else
        nil
      end
    end
  end
end
