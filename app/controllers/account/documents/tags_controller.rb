# -*- encoding : UTF-8 -*-
class Account::Documents::TagsController < Account::AccountController
  before_filter :load_user_and_role
  
  def update_multiple
    sous = ""
    add = ""
    params[:tags].downcase.split.each do |tag|
      if tag.match(/-*\w*/)
        if tag[0] == '-'
          sous += " #{tag.sub("-","").sub("*","(.*)")}"
          else
          add += " #{tag}"
        end
      end
    end
    params[:document_ids].each do |document_id|
      document = Document.find(document_id)
      if document && document.pack.users.include?(@user)
        sous.split.each do |s|
          DocumentTag.where(:name => / #{s}( |$)/, :document_id => document.id).each do |document_tag|
            document_tag.name = document_tag.name.gsub(/ #{s}( |$)/,'')
            document_tag.save
          end
        end
        old_document_tags = DocumentTag.where(:user_id => @user.id, :document_id => document.id).first
        if old_document_tags
          old_document_tags.name += add
          old_document_tags.save!
        else
          new_document_tags = DocumentTag.new
          new_document_tags.name = add
          new_document_tags.document = document
          new_document_tags.pack = document.pack
          new_document_tags.user = @user
          new_document_tags.save
        end
      end
    end
    respond_to do |format|
      format.json{ render :json => {}, :status => :ok }
      format.html{ redirect_to account_documents_path }
    end
  end
    
end
