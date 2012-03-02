class Reporting
  include Mongoid::Document
  include Mongoid::Timestamps
  
  references_and_referenced_in_many :viewer, :class_name => "User", :inverse_of => :reportings
  references_many :monthly, :class_name => "Reporting::Monthly", :inverse_of => :reporting
  references_one :customer, :class_name => "Reporting::Customer", :inverse_of => :reporting
  
public
  def find_or_create_monthly_by_date date
    find_or_create_monthly date.year, date.month
  end
  
  def find_or_create_monthly_for year, month
    find_or_create_monthly year, month
  end
  
  def find_or_create_current_monthly
    find_or_create_monthly Time.now.year, Time.now.month
  end
  
protected
  def find_or_create_monthly year, month
    monthly = self.monthly.where(:month => month, :year => year).first
    if monthly
      monthly
    else
      monthly = self.monthly.new
      monthly.month = month
      monthly.year = year
      monthly.save ? monthly : nil
    end
  end
end
