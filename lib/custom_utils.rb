class CustomUtils

  class << self
    def replace_code_of(code) #replace old code 'AC0162' with 'MVN%GRHCONSULT'
      code.match(/^AC0162/) ? code.gsub('AC0162', 'MVN%GRHCONSULT') : code
    end

  end
end