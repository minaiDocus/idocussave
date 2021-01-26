class SpecModule
  @@dir = nil

  class << self
    def create_tmp_dir
      CustomUtils.mktmpdir('spec_module', "/nfs/tmp/knowings/") do |dir|
        @@dir = dir
      end
    end

    def remove_tmp_dir
      FileUtils.rm @@dir, force: true
    end
  end

  def use_file(file)
    if File.exists?(@@dir.to_s)
      dir = "#{@@dir}/#{Time.now.strftime('%s')}"
      filename = File.basename(file)

      FileUtils.makedirs(dir)
      FileUtils.chmod(0755, dir)

      FileUtils.cp file, "#{dir}/#{filename}"
      File.open("#{dir}/#{filename}", 'r')
    else
      raise "No temp dir initialized (Call SpecModule.create_tmp_dir before using use_file method, don't foget to call SpecModule.remove_tmp_dir)"
    end
  end
end