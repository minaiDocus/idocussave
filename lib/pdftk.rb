# -*- encoding : UTF-8 -*-
class Pdftk
  include POSIX::Spawn


  EXE_NAME = 'pdftk'.freeze
  @@config = {}
  cattr_accessor :config


  def initialize(execute_path = nil)
    @exe_path = execute_path || find_binary_path
    raise "Location of #{EXE_NAME} unknow" if @exe_path.empty?
    raise "Bad location of #{EXE_NAME}'s path" unless File.exist?(@exe_path)
    raise "#{EXE_NAME} is not executable" unless File.executable?(@exe_path)
  end

  def merge(source_array, destination_path, merge_type = 'append')
    command = "#{@exe_path} #{source_array.join(' ')} cat output #{destination_path}"
    `#{command}`

    return true if File.exist?(destination_path) && destination_path.size > 0 && DocumentTools.modifiable?(destination_path)
    FileUtils.rm destination_path, force: true

    if merge_type == 'append'
      source_array[1] = DocumentTools.force_correct_pdf(source_array.last)[:output_file]
    else
      source_array[0] = DocumentTools.force_correct_pdf(source_array.first)[:output_file]
    end

    command = "#{@exe_path} #{source_array.join(' ')} cat output #{destination_path}"
    `#{command}`

    return true if File.exist?(destination_path) && destination_path.size > 0 && DocumentTools.modifiable?(destination_path)
    return false
  end

  def burst(file_path, path = '/tmp', prefix = 'page', counter_size = 3, remake = false)
    @path      = path
    @prefix    = prefix
    @file_path = file_path
    @counter_size = counter_size
    @path_with_prefix = File.join(@path, @prefix)

    command = "#{@exe_path} #{@file_path} burst output #{@path_with_prefix}_%0#{@counter_size}d.pdf"
    is_bursted = system "#{command}"

    unless remake
      unless is_bursted
        @tmp_file_remake = Tempfile.new('tmp_pdf').path
        success = DocumentTools.to_pdf_hight_quality file_path, @tmp_file_remake
        is_bursted = burst @tmp_file_remake, @path, @prefix, @counter_size, true
      end
    else
      File.unlink @tmp_file_remake if File.exist? @tmp_file_remake
    end

    is_bursted
  rescue Exception => e
    raise "Failed to execute:\n#{command}\nError: #{e}"
  end


  def stamp(file_path, stamp_file_path, output_file_path)
    @file_path = file_path
    @stamp_file_path  = stamp_file_path
    @output_file_path = output_file_path

    command = "#{@exe_path} #{@file_path} multistamp #{@stamp_file_path} output #{@output_file_path}"
    `#{command}`
  rescue Exception => e
    raise "Failed to execute:\n#{command}\nError: #{e}"
  end

  private


  def find_binary_path
    possible_locations = (ENV['PATH'].split(':') + %w(/usr/bin /usr/local/bin ~/bin)).uniq
    exe_path ||= Pdftk.config[:exe_path] unless Pdftk.config.empty?
    exe_path ||= possible_locations.map { |l| File.expand_path("#{l}/#{EXE_NAME}") }.find { |location| File.exist? location }
    exe_path || ''
  end
end
