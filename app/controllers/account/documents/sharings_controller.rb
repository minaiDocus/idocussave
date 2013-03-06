# -*- encoding : UTF-8 -*-
class Account::Documents::SharingsController < Account::AccountController
  before_filter :load_user_and_role
  
  def create
    users = User.find_by_emails(params[:email].split()) - [@user]
    
    packs = Pack.find(params[:pack_ids].split()).select { |p| p.owner == @user }
    
    packs.each do |pack|
      users.each do |user|
        if user.packs.where(:_id => pack.id).empty?
          user.packs << pack
          user.save
          tags = ""
          pack.documents.each_with_index do |document,i|
            if i == 0
              document_tag = DocumentTag.create(:document_id => document.id, :pack_id => document.pack.id, :user_id => user.id)
              tags = document_tag.generate
            else
              document_tag = DocumentTag.create(:document_id => document.id, :pack_id => document.pack.id, :user_id => user.id, :name => tags)
            end
          end
          pack.save
        end
      end
    end
    
    respond_to do |format|
      format.json{ render :json => {}, :status => :ok }
    end
  end
  
  def destroy_multiple_selected
  end
  
  def destroy_multiple
    packs = @user.packs.find(params[:pack_ids]).select{|p| p.owner != @user} rescue []
    
    packs.each do |pack|
      @user.packs.delete pack
      DocumentTag.where(:pack_id => pack.id, :user_id => @user.id).delete_all
    end
    
    respond_to do |format|
      format.json{ render :json => {}, :status => :ok }
    end
  end
end
