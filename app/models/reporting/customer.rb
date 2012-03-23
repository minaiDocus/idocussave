class Reporting::Customer
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :reporting
  referenced_in :original_user, :class_name => "User", :inverse_of => :copy
  
  field :email, :type => String
  field :first_name, :type => String
  field :last_name, :type => String
  field :code, :type => String
  field :company, :type => String
  field :inactive_at, :type => Time
  
  after_create :set_attributes
  
  def set_attributes
    self.email = original_user.email
    self.first_name = original_user.first_name
    self.last_name = original_user.last_name
    self.code = original_user.code
    self.company = original_user.company
    self.inactive_at = original_user.inactive_at
    self.save
  end

  def active
    self.inactive_at.nil?
  end
  
  def is_active_at year, month
    if inactive_at.nil?
      true
    else
      if inactive_at.year > year
        true
      elsif inactive_at.year == year and inactive_at.month > month
        true
      else
        false
      end
    end
  end
  
end
