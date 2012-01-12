class Account::Documents::UploadsController < Account::AccountController
  
  skip_before_filter :verify_authenticity_token, :only => %w(create)

  def create
    if params[:file] && [".pdf",".bmp",".jpeg",".jpg",".png","tiff",".tif",".gif"].include?(File.extname(params[:file].original_filename))
      month = Time.now.month.to_s.length == 1 ? "0"+Time.now.month.to_s : Time.now.month.to_s
      
      type = Reporting.where(:client_ids => current_user.id).first.user.account_book_types.where(:name => params[:type]).first.name rescue nil
      
      if type
        basename = current_user.code.to_s+"_"+type+"_"+Time.now.year.to_s+month
        
        Dir.chdir("#{Rails.root}/tmp/input_pdf_auto/ocr_tasks")
        
        checkpoint_number = Dir.entries('.').select{|d| d.match(/^#{basename}/)}.sort.last.split('_')[3].sub('.pdf','').to_i + 1 rescue 0
        if checkpoint_number == 0
          nb = Dir.entries('..').select{|d| d.match(/^#{basename}/)}.sort.last.split('_')[3].sub('.pdf','').to_i + 1 rescue 500
          (nb < 500) ? checkpoint_number = 500 : checkpoint_number = nb
        end
        
        file_name = basename + "_" + ("0"*(3 - checkpoint_number.to_s.length)) + checkpoint_number.to_s + File.extname(params[:file].original_filename)
        
        file = File.new(file_name,'w+')
        FileUtils.copy_stream(params[:file].tempfile,file)
        file.rewind

        respond_to do |format|
          format.json{ render :json => {:success => true, :file_name => file_name} }
          # this one is for IE8 who is really dumb...
          format.html{ render :json => {:success => true, :file_name => file_name} }
        end
      end
    else
      respond_to do |format|
        format.json{ render :json => {:success => false, :file_name => file_name} }
        # this one is for IE8 who is really dumb...
        format.html{ render :json => {:success => false, :file_name => file_name} }
      end
    end
  end
end
