module PdfDocument
  module Utils
    def self.generate_tiff_file(file_path, temp_path)
      system("gs -o #{temp_path} -sDEVICE=tiff32nc -sCompression=lzw -r200 #{file_path}")
    end
  end
end
