module GoogleDrive
  class << self
    attr_reader :config
  end

  def self.configure
    yield config
  end

  def self.config
    @@config ||= Configuration.new
  end
end
