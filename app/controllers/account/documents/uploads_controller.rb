# -*- encoding : UTF-8 -*-
class Account::Documents::UploadsController < Account::AccountController
  helper :all

  def create
    type = current_user.account_book_types.where(:name => params[:account_book_type]).first.name rescue nil
    
    data = []
    hsh = {}
    
    if type && !current_user.code.blank? && params[:files][0].original_filename && params[:files][0].tempfile
      begin
        uploaded_file = UploadedFile.make current_user, type, params[:files][0].original_filename, params[:files][0].tempfile, params[:for_current_period]
        hsh[:created_at] = l(uploaded_file.created_at)
        hsh[:name] = uploaded_file.original_filename
        hsh[:new_name] = uploaded_file.pack_name + ".pdf"
        data << hsh
      # rescue extension
      rescue UploadError::InvalidFormat
        hsh[:name] = params[:files][0].original_filename
        hsh[:error] = "extension non valide"
        data << hsh
      # rescue protected
      rescue UploadError::ProtectedFile
        hsh[:name] = params[:files][0].original_filename
        hsh[:error] = "document protégé"
        data << hsh
      rescue UploadError::UnprocessableEntity
        hsh[:name] = params[:files][0].original_filename
        hsh[:error] = "fichier corrompu"
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
