class EmailedDocument::Configuration
  attr_accessor :address, :port, :user_name, :password, :enable_ssl


  def initialize
    @enable_ssl = true
  end
end
