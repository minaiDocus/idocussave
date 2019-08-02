# -*- encoding : UTF-8 -*-
class CegidZipService
  def initialize(user, preseizures, options={})
    @preseizures = preseizures
    @user = user
  end

  def execute
    base_name = @preseizures.first.report.name.tr(' ', '_').tr('%', '_')
    # initialising a temp dir into rails_app insted of /tmp
    dir = Dir.mktmpdir(nil, "#{Rails.root}/tmp")
    FileUtils.chmod(0755, dir)

    CegidZipService.delay_for(6.hours).remove_temp_dir(dir)

    data = PreseizuresToCsv.new(@user, @preseizures, 'cegid').execute
    file = File.open("#{dir}/#{base_name}.csv", 'w')
    file.write(data)
    file_path = file.path
    file.close

    file_path
  end

  class << self
    def remove_temp_dir(dir)
      FileUtils.remove_dir dir if File.exist? dir
    end
  end
end
