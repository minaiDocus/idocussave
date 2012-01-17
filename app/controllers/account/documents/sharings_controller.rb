class Account::Documents::SharingsController < Account::AccountController
  
  def create
    users = User.find_by_emails(params[:email].split()) - [current_user]
    
    packs = Pack.find(params[:pack_ids].split()).select{|p| p.order.user == current_user}
    
    packs.each do |pack|
      users.each do |user|
        if user.packs.where(:_id => pack.id).empty?
          user.packs << pack
          user.save
          tags = ""
          pack.documents.each_with_index do |document,i|
            if i == 0
              document_tag = DocumentTag.create(:document_id => document.id, :user_id => user.id)
              tags = document_tag.generate
            else
              document_tag = DocumentTag.create(:document_id => document.id, :user_id => user.id, :name => tags)
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
    packs = current_user.packs.find(params[:pack_ids].split('_')).select{|p| p.order.user != current_user} rescue []
    
    packs.each do |pack|
      current_user.packs -= [pack]
      pack.users -= [current_user]
      current_user.save
      pack.save
      pack.documents.each do |document|
        DocumentTag.where(:document_id => document.id, :user_id => current_user.id).delete
      end
    end
    
    current_user.document_content_index.try("remove",packs.collect{|p| p.id})
    
    respond_to do |format|
      format.json{ render :json => {}, :status => :ok }
    end
  end
end
