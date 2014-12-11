# -*- encoding : UTF-8 -*-
require 'barby'
require 'barby/barcode/code_39'
require 'barby/outputter/png_outputter'

module BarCode
  TEMPDIR_PATH = "#{Rails.root}/tmp/barcode"

  class << self
    def init
      unless File.exist?(TEMPDIR_PATH)
        Dir.mkdir TEMPDIR_PATH
      else
        system "rm #{TEMPDIR_PATH}/*.png"
      end
    end

    def generate_png(text, height = 50, margin = 5)
      tempfile_path = "#{TEMPDIR_PATH}/#{text.gsub(" ","_")}.png"

      barcode = Barby::Code39.new text
      File.open tempfile_path, 'w' do |f|
        f.write barcode.to_png height: height, margin: margin
      end

      tempfile_path
    end
  end
end
