class Account::DocumentTagsController < Account::AccountController
  layout nil
  
  def show
    
    document_ids = ""
    params[:tags].split(':_:').each_with_index do |tag,index|
      if index == 0
        DocumentTag.where(:name => /\w*#{tag}\w*/, :user_id => current_user.id).each do |document_tag|
          document_ids += " #{document_tag.document_id}"
        end
      else
        document_ids_2 = document_ids
        document_ids_2.split.each do |document_id|
          if (DocumentTag.where(:document_id => document_id, :name => /\w*#{tag}\w*/).first).nil?
            document_ids = document_ids.gsub(/#{document_id}/,'')
          end
        end
      end
    end
    @documents = Document.any_in(:_id => document_ids.split).entries
    
  end
  
  def create
    sous = ""
    add = ""
    params[:tags].downcase.split.each do |tag|
      if tag.match(/^([a-z]|[0-9]|-|_)+$/)
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
            document_tag.save!
          end
        end
        old_document_tags = DocumentTag.where(:user_id => current_user.id, :document_id => document.id).first
        if old_document_tags
          old_document_tags.name += add
          old_document_tags.save!
        else
          new_document_tags = DocumentTag.new
          new_document_tags.name = add
          new_document_tags.document = document.id
          new_document_tags.user = current_user.id
          new_document_tags.save!
        end
      end
    end
    respond_to do |format|
      format.json{ render :json => {}, :status => :ok }
      format.html{ redirect_to account_document_tags_path }
    end
  end

end
