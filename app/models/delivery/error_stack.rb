class Delivery::ErrorStack
  include Mongoid::Document
  include Mongoid::Timestamps

  field :sender, type: String
  field :description, type: String
  field :filename, type: String
  field :message, type: String
  field :number, type: Integer

  before_create :set_number

  def by_number
    asc(:number)
  end

  private

  def set_number
    self.number = DbaSequence.next('Delivery::ErrorStack')
  end
end
