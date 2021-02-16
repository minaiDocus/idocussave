module Interfaces::User::Collaborator  
  def collaborator?
    is_prescriber
  end

  def admin?
    is_admin
  end
end