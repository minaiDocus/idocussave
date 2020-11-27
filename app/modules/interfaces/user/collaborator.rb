module Interfaces::User::Collaborator  
  def collaborator?
    is_prescriber
  end  
end