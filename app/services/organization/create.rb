class Organization::Create
  def initialize(params)
    @params = params
  end

  def execute
    organization = Organization.new @params
    ActiveRecord::Base.transaction do
      if organization.save
        DebitMandate.create!(organization: organization)
      end
    end
    organization
  end
end
