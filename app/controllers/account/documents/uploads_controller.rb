class Account::Documents::UploadsController < Account::AccountController
  helper :all
  
  skip_before_filter :verify_authenticity_token, :only => %w(create)

  def create
    type = current_user.prescriber.account_book_types.where(:name => params[:account_book_type]).first.name rescue nil
    
    data = []
    hsh = {}
    
    if type && !current_user.code.blank? && params[:files][0].original_filename && params[:files][0].tempfile
      uploaded_file = current_user.uploaded_files.create(:original_filename => params[:files][0].original_filename, :account_book_type => params[:account_book_type])
      if uploaded_file.persisted?
        uploaded_file.moov_file params[:files][0].tempfile
        if uploaded_file.is_password_protected?
          uploaded_file.delete_file
          uploaded_file.delete
          hsh[:name] = params[:files][0].original_filename
          hsh[:error] = "document protégé"
          data << hsh
        else
          hsh[:created_at] = l(uploaded_file.created_at)
          hsh[:name] = uploaded_file.original_filename
          hsh[:new_name] = uploaded_file.pack_name.to_s + ".pdf"
          data << hsh
        end
      else
        hsh[:name] = params[:files][0].original_filename
        hsh[:error] = "document non valide"
        data << hsh
      end
      
      respond_to do |format|
        format.json{ render :json => data }
        # this one is for IE8 who is really dumb...
        format.html{ render :json => data }
      end
    else
      hsh[:name] = params[:files][0].original_filename
      hsh[:error] = "document non valide"
      data << hsh
      
      respond_to do |format|
        format.json{ render :json => data }
        # this one is for IE8 who is really dumb...
        format.html{ render :json => data }
      end
    end
  end
end
