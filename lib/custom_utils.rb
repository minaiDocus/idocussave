class CustomUtils

  class << self
    def replace_code_of(code) #replace old code 'AC0162' with 'MVN%GRHCONSULT'
      if code.match(/^AC0162/)
        code.gsub('AC0162', 'MVN%GRHCONSULT')
      elsif code.match(/^MFA[%]ADAPTO/)
        code.gsub('MFA%ADAPTO', 'ACC%0455')
      else
        code
      end
    end

    def manual_scans_codes
      ['AC0162', 'MFA%ADAPTO']
    end

    def add_chmod_access_into(type, nfs_directory)
      FileUtils.chmod(type, nfs_directory)
    end
  end
end