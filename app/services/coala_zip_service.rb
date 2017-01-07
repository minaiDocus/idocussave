# -*- encoding : UTF-8 -*-
class CoalaZipService
  def initialize(user, preseizures)
    @preseizures = preseizures
    @user = user
  end

  def execute
    base_name = @preseizures.first.report.name.gsub(' ', '_')
    # initialising a temp dir into rails_app insted of /tmp
    dir = Dir.mktmpdir(nil, "#{Rails.root}/tmp")
    FileUtils.chmod(0755, dir)

    CoalaZipService.delay_for(6.hours).remove_temp_dir(dir)
    data = PreseizuresToCsv.new(@user, @preseizures, true).execute
    File.open("#{dir}/#{base_name}.csv", 'w') do |f|
      f.write(data)
    end
    @preseizures.each do |preseizure|
      entry = preseizure.entries.first
      file_name = preseizure.coala_piece_name + '.pdf'
      FileUtils.cp preseizure.piece.content.path, File.join(dir, file_name) if preseizure.type.nil? && File.exist?(preseizure.piece.try(:content).try(:path).to_s)
    end
    file_path = File.join(dir, base_name + '.zip')
    Dir.chdir dir
    POSIX::Spawn::system "zip #{file_path} *"
    file_path
  end

  class << self
    def remove_temp_dir(dir)
      FileUtils.remove_dir dir if File.exist? dir
    end
  end
end
