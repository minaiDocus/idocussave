# -*- encoding : UTF-8 -*-
class Account::Documents::TagsController < Account::AccountController
  before_filter :load_user_and_role
  
  def update_multiple
    sub = []
    add = []
    params[:tags].downcase.split.each do |tag|
      if tag.match(/-*\w*/)
        if tag[0] == '-'
          sub << tag.sub('-','').sub('*','.*')
        else
          add << tag
        end
      end
    end
    params[:document_ids].each do |document_id|
      document = Document.find(document_id)
      if document && document.pack.owner == @user
        sub.each do |s|
          tags = document.tags
          document.tags.each do |tag|
            tags = tags - [tag] if tag.match /#{s}/
          end
          document.tags = tags
        end
        document.tags = document.tags + add if add.any?
        document.save
      end
    end
    respond_to do |format|
      format.json { render :json => {}, :status => :ok }
      format.html { redirect_to account_documents_path }
    end
  end
end
