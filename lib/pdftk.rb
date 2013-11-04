# -*- encoding : UTF-8 -*-
class Pdftk
  EXE_NAME = "pdftk"
  @@config = {}
  cattr_accessor :config

  def initialize(execute_path = nil)
    @exe_path = execute_path || find_binary_path
    raise "Location of #{EXE_NAME} unknow" if @exe_path.empty?
    raise "Bad location of #{EXE_NAME}'s path" unless File.exists?(@exe_path)
    raise "#{EXE_NAME} is not executable" unless File.executable?(@exe_path)
  end

  def merge(source_array, destination_path)
    @source_files = source_array
    @merged_file_path =  destination_path

    command = "#{@exe_path} #{@source_files.join(' ')} cat output #{@merged_file_path}"
    `#{command}`
  rescue Exception => e
    raise "Failed to execute:\n#{command}\nError: #{e}"
  end

  def burst(file_path, path='/tmp', prefix='page', counter_size=3)
    @file_path = file_path
    @prefix = prefix
    @path = path
    @counter_size = counter_size
    @path_with_prefix = File.join(@path, @prefix)
    command = "#{@exe_path} #{@file_path} burst output #{@path_with_prefix}_%0#{@counter_size}d.pdf"
    `#{command}`
  rescue Exception => e
    raise "Failed to execute:\n#{command}\nError: #{e}"
  end

  def stamp(file_path, stamp_file_path, output_file_path)
    @file_path = file_path
    @stamp_file_path = stamp_file_path
    @output_file_path = output_file_path
    command = "#{@exe_path} #{@file_path} multistamp #{@stamp_file_path} output #{@output_file_path}"
    `#{command}`
  rescue Exception => e
    raise "Failed to execute:\n#{command}\nError: #{e}"
  end

private

  def find_binary_path
    possible_locations = (ENV['PATH'].split(':')+%w[/usr/bin /usr/local/bin ~/bin]).uniq
    exe_path ||= Pdftk.config[:exe_path] unless Pdftk.config.empty?
    exe_path ||= possible_locations.map{|l| File.expand_path("#{l}/#{EXE_NAME}") }.find{|location| File.exists? location}
    exe_path || ''
  end
end
