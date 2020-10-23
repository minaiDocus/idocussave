class PreAssignment::Builder::ExactOnline < PreAssignment::Builder::DataService
  def self.execute(delivery)
    new(delivery).run
  end

  def initialize(delivery)
    super

    @software = @delivery.user.exact_online
  end

  private

  def execute
    @delivery.building_data
    response = ExactOnlineLib::DataBuilder.new(@delivery).execute

    if response[:data_built]
      save_data_to_storage(response[:data], 'txt')

      data = JSON.parse response[:data]
      building_success data["payload"].count
    else
      building_failed response[:error_messages]
    end
  end
end