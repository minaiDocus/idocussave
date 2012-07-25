# -*- encoding : UTF-8 -*-
class Backup
	include Mongoid::Document
	include Mongoid::Timestamps
	
	referenced_in :user
	
	field :account_number, :type => Integer
  field :account_name, :type => String
  field :login, :type => String
  field :password, :type => String
	field :space, :type => Integer
  field :state, :type => String
	field :type, :type => String, :default => ""
  field :expiration_date, :type => Date
  field :fictive_expiration_date, :type => Date
  field :pack, :type => String
  field :is_unlocker, :type => Boolean
  field :is_local, :type => Boolean
  field :is_dd, :type => Boolean
  field :is_multi, :type => Boolean, :default => false
  field :deleted, :type => Boolean, :default => false
  
  validates_presence_of :account_number
  
  before_destroy :delete_account
  
protected
  def delete_account
    NeobeApi.delete_account account_number.to_s
  end

public
  # Initialisation du compte
  def init space, recipient, password, expiration, unlocker=false, local=true, dd=false
    result = NeobeApi.add_account(space, recipient, password, expiration, unlocker, local, dd)
    if result[:success]
      self["account_number"] = result[:value]
      self["account_name"] = recipient
      self["password"] = password
      self["space"] = space
      self["state"] = "AC"
      self["expiration_date"] = expiration
      self["is_unlocker"] = unlocker
      self["is_local"] = local
      self["is_dd"] = dd
      self.save ? true : false
    else
      result
    end
  end
  
  def s_login
    response = NeobeApi.get_login self.account_number
    if response[:success]
      self.update_attributes(:login => response[:value])
    else
      response
    end
  end
  
  def s_password
    response = NeobeApi.get_password self.account_number
    if response[:success]
      self.update_attributes(:password => response[:value])
    else
      response
    end
  end
  
  def s_comment
    response = NeobeApi.get_comment self.account_number
    if response[:success]
      self.update_attributes(:account_name => response[:value])
    else
      response
    end
  end
  
  def s_space
    response = NeobeApi.get_space self.account_number
    if response[:success]
      self.update_attributes(:space => response[:value])
    else
      response
    end
  end
  
  def s_etat
    response = NeobeApi.get_etat self.account_number
    if response[:success]
      value = ""
      if response[:value][0..1].downcase == "ac"
        value = "AP"
      elsif response[:value][0..1].downcase == "de"
        value = "DE"
      else
        value = "EP"
      end
      self.update_attributes(:state => value)
    else
      response
    end
  end
  
  def s_last_saving
    NeobeApi.get_last_saving self.account_number
  end
  
  def s_used_space
    NeobeApi.get_used_space self.account_number
  end
  
  def s_delay_of_last_activity
    NeobeApi.get_delay_of_last_activity self.account_number
  end
  
  def s_exp
    response = NeobeApi.get_exp self.account_number
    if response[:success]
      self.update_attributes(:expiration_date => response[:value])
    else
      response
    end
  end
  
  def s_exp_f
    response = NeobeApi.get_exp_f self.account_number
    if response[:success]
      self.update_attributes(:fictive_expiration_date => response[:value])
    else
      response
    end
  end
  
  def s_id_machine
    NeobeApi.get_id_machine self.account_number
  end
  
  def s_nb_files
    NeobeApi.get_nb_files self.account_number
  end
  
  def s_nb_files_max
    NeobeApi.get_nb_files_max self.account_number
  end
  
  def s_pack
    response = NeobeApi.get_pack self.account_number
    if response[:success]
      self.update_attributes(:pack => response[:value])
    else
      response
    end
  end
  
  def s_is_dd
    response = NeobeApi.is_dd self.account_number
    if response[:success]
      self.update_attributes(:is_dd => response[:value])
    else
      response
    end
  end
  
  def s_is_local
    response = NeobeApi.is_local self.account_number
    if response[:success]
      self.update_attributes(:is_local => response[:value])
    else
      response
    end
  end
  
  def s_is_multi
    response = NeobeApi.is_multi self.account_number
    if response[:success]
      self.update_attributes(:is_multi => response[:value])
    else
      response
    end
  end
  
  def s_is_unlocker
    response = NeobeApi.is_unlocker self.account_number
    if response[:success]
      self.update_attributes(:is_unlocker => response[:value])
    else
      response
    end
  end
  
  def delete_account
    result = NeobeApi.delete_account self.account_number
    if result[:success]
      self.update_attributes(:deleted => true)
    else
      result
    end
  end
  
  def delete_id_machine
    NeobeApi.delete_id_machine self.account_number
  end
  
  def clean_account
    NeobeApi.clean_account self.account_number
  end
  
  # mise à jour du mots de passe
  def password= password
    result = NeobeApi.set_password self.account_number, password
    if result[:success]
      self["password"] = password.to_s
      self.save ? true : false
    else
      result
    end
  end
  
  # mise à jour du commentaire
  def account_name= comment
    result = NeobeApi.set_comment self.account_number, comment
    if result[:success]
      self["account_name"] = comment.to_s
      self.save ? true : false
    else
      result
    end
  end
  
  # mise à jour de l'espace
  def space= space
    result = NeobeApi.set_space self.account_number, space
    if result[:success]
      self["space"] = space.to_i
      self.save ? true : false
    else
      result
    end
  end
  
  # mise à jour de l'état
  def state= state
    result = NeobeApi.set_etat self.account_number, state
    if result[:success]
      self["state"] = state
      self.save ? true : false
    else
      result
    end
  end
  
  # mise à jour de la date d'expiration
  def expiration_date= date
    result = NeobeApi.set_date self.account_number, date
    if result[:success]
      self["expiration_date"] = date
      self.save ? true : false
    else
      result
    end
  end
  
  # mise à jour de la date d'expiration fictive
  def fictive_expiration_date= date
    result = NeobeApi.set_date_f self.account_number, date
    if result[:success]
      self["fictive_expiration_date"] = date
      self.save ? true : false
    else
      result
    end
  end
  
  # mise à jour du pack
  def pack= pack
    result = NeobeApi.set_pack self.account_number, pack
    if result[:success]
      self["pack"] = pack
      self.save ? true : false
    else
      result
    end
  end
  
  # mise à jour de l'option de sauvegarde des fichiers ouverts
  def is_unlocker= flag
    result = NeobeApi.set_unlocker self.account_number, flag
    if result[:success]
      self["is_unlocker"] = flag
      self.save ? true : false
    else
      result
    end
  end
  
  # mise à jour de l'option de sauvegarde locale
  def is_local= flag
    result = NeobeApi.set_local self.account_number, flag
    if result[:success]
      self["is_local"] = flag
      self.save ? true : false
    else
      result
    end
  end
  
  # mise à jour de l'option de disque dur en ligne
  def is_dd= flag
    result = NeobeApi.set_dd self.account_number, flag
    if result[:success]
      self["is_dd"] = flag
      self.save ? true : false
    else
      result
    end
  end
  
  # mise à jour de l'option multi-compte
  def is_multi= flag
    result = NeobeApi.set_multi self.account_number, flag
    if result[:success]
      self["is_multi"] = flag
      self.save ? true : false
    else
      result
    end
  end
  
end
