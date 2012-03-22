class Account::Documents::TagsController < Account::AccountController
  
  def update_multiple
    sous = ""
    add = ""
    Iconv.iconv('UTF-8', 'ISO-8859-1', params[:tags]).join().downcase.split.each do |tag|
      if tag.match(/-*\w*/)
        if tag[0] == 45 # '45' = '-'
          sous += " #{tag.sub("-","").sub("*","(.*)")}"
          else
          add += " #{tag}"
        end
      end
    end
    params[:document_ids].each do |document_id|
      document = Document.find(document_id)
      if document
        sous.split.each do |s|
          DocumentTag.where(:name => / #{s}( |$)/, :document_id => document.id).each do |document_tag|
            document_tag.name = document_tag.name.gsub(/ #{s}( |$)/,'')
            document_tag.save
          end
        end
        old_document_tags = DocumentTag.where(:user_id => current_user.id, :document_id => document.id).first
        if old_document_tags
          old_document_tags.name += add
          old_document_tags.save!
        else
          new_document_tags = DocumentTag.new
          new_document_tags.name = add
          new_document_tags.document = document
          new_document_tags.pack = document.pack
          new_document_tags.user = current_user
          new_document_tags.save
        end
      end
    end
    respond_to do |format|
      format.json{ render :json => {}, :status => :ok }
      format.html{ redirect_to account_document_tags_path }
    end
  end
    
end
