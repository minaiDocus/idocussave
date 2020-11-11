# -*- encoding : UTF-8 -*-
require 'barby'
require 'barby/barcode/code_39'
require 'barby/outputter/png_outputter'

module BarCode
  TEMPDIR_PATH = "#{Rails.root}/tmp/barcode".freeze


  def self.init
    if File.exist?(TEMPDIR_PATH)
      system "rm #{TEMPDIR_PATH}/*.png"
    else
      Dir.mkdir TEMPDIR_PATH
    end
  end


  def self.generate_png(text, height = 50, margin = 5)
    tempfile_path = "#{TEMPDIR_PATH}/#{text.tr(' ', '_')}.png"

    barcode = Barby::Code39.new text

    File.open tempfile_path, 'wb' do |f|
      f.write barcode.to_png height: height, margin: margin
    end

    tempfile_path
  end
end
