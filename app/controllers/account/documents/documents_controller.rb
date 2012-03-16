class Account::Documents::DocumentsController < Account::AccountController
  layout "inner", :only => %w(index reporting)
  
  before_filter :find_last_composition, :only => %w(index)

protected  
  def find_last_composition
    return if self.controller_name == 'document_tags'
    @last_composition = current_user.composition
  end

public
  def index
    @packs_count = current_user.packs.count
    @packs = current_user.packs.desc(:created_at).paginate :page => params[:page], :per_page => 20
    if @last_composition
      @composition = Document.any_in(:_id => @last_composition.document_ids)
    end
  end
  
  def show
    @documents = current_user.packs.find(params[:id]).documents.without_original.asc(:position) rescue nil

    respond_to do |format|
      format.html{}
      format.json do
        render :json => {},
        :status => :ok
      end
      format.pdf do
        render :pdf => "invoice_order_#{@document_pack.to_param}", :template => "/account/documents/receipt.html.haml"
      end
    end
  end
  
  def packs
    @packs = []
      
    if params[:view] == "all" || params[:view].nil?
      @packs = current_user.packs
    elsif params[:view] == "self"
      @packs = current_user.packs.select{|p| p.order.user == current_user}
    else
      order_ids = Order.where(:user_id => (User.find(params[:view])).id).collect{|o| o.id}
      @packs = current_user.packs.any_in(:order_id => order_ids).entries
    end
    
    if params[:filtre]
      # query = Iconv.iconv('UTF-8', 'ISO-8859-1', params[:filtre]).join().split(':_:')
      query = params[:filtre].split(':_:')
      f_pack_ids = current_user.find_pack_ids(query)
      
      @packs1 = @packs.select{|p| f_pack_ids.include?("#{p.id}")}
      @packs2 = @packs.select{|p| p.match_tags(params[:filtre],current_user)}
      @packs = (@packs1 + @packs2).uniq
    end
    
    @packs = @packs.sort do |a,b|
      b.created_at <=> a.created_at
    end
    
    @packs_count = @packs.count
    @packs = @packs.paginate :page => params[:page], :per_page => params[:per_page]
  end
  
  def invoice
    @order = current_user.orders.find params[:id]

    @invoice = @order.invoice || @order.create_invoice

    respond_to do |format|
      format.html{ render :layout => false }
      format.pdf do
        render :pdf => "#{@invoice.number}", :template => "/account/orders/invoice.html.haml"
      end
    end
  end
  
  def search
    @tags = []
    @document_contents = []
    
    # query = Iconv.iconv('UTF-8', 'ISO-8859-1', params[:q]).join()
    query = params[:q]
    
    if params[:by] == "tags" || !params[:by]
      @document_tags = DocumentTag.where(:user_id => current_user.id, :name => /\w*#{query}\w*/)
      
      tags = ""
      @document_tags.each do |document_tag|
        document_tag.name.scan(/\w*#{query}\w*/).each do |tag|
          if !tags.match(/ #{tag}( )*/)
            tags += " #{tag}"
          end
        end
      end
      
      Iconv.iconv('ISO-8859-1', 'UTF-8', tags).join().split.each do |tag|
        @tags << {"id" => "1", "name" => "#{tag}"}
      end
      
    end
    
    if params[:by] == "ocr_result" || !params[:by]
      results = current_user.search_document query
      
      @document_contents = []
      results.each do |r|
        @document_contents << {"id" => "0", "name" => r}
      end
    end
    
    @result = @tags + @document_contents
    
    @result = @result.sort do |a,b|
      a["name"] <=> b["name"]
    end

    respond_to do |format|
      format.json{ render :json => @result.to_json, :callback => params[:callback], :status => :ok }
    end
  end
  
  def find
    # query = Iconv.iconv('UTF-8', 'ISO-8859-1', params[:having]).join().split(':_:')
    query = params[:having].split(':_:')
    
    @documents = []

    document_ids = ""
    query.each_with_index do |tag,index|
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
    
    @documents = Document.any_in(:_id => document_ids.split).without_original.entries
    @documents += current_user.find_document(query).without_original.entries
    @documents = @documents.uniq
    
    render :action => "show"
  end
  
  def reorder
    documents = Document.find(params[:document_ids]).to_a
    params[:document_ids].each_with_index{|id, index|
      document = documents.select{|x| x.id.to_s == id.to_s}.first
      document.update_attributes :position => index
    }

    respond_to do |format|
      format.json{ render :json => {}, :status => :ok }
    end
  end
    
  def archive
    pack = Pack.find(params[:pack_id])
    
    if !pack.information.nil?
      unless File.directory?("#{Rails.root}/public/system/archive/#{current_user.id}")
        Dir.mkdir("#{Rails.root}/public/system/archive/#{current_user.id}")
      end
      
      pack.information["collection"].each_with_index do |one_part,index|
        filename = one_part["name"].gsub(/\s/,'_')
        level = one_part["level"]
        start_number = one_part["start"]
        end_number = one_part["end"]
        
        part = (start_number == end_number) ? start_number.to_s : start_number.to_s+"-"+end_number.to_s
        
        url = "#{Rails.root}/public#{pack.documents.where(:is_an_original => true).first.content.url.sub(/\.pdf.*/,'.pdf')}"
        cmd = "pdftk A=#{url} cat A#{part} output #{Rails.root}/public/system/archive/#{current_user.id}/#{filename}.pdf"
        system(cmd)
      end
      
      new_name = pack.name.gsub(/\s/,'_')
    
      Dir.chdir("#{Rails.root}/public/system/archive/#{current_user.id}/")
      system("rm *.zip") rescue nil # suppression du précédent zip
      system("zip '#{new_name}.zip' *.pdf")
      system("rm *.pdf")
      
      @url = "/system/archive/#{current_user.id}/#{new_name}.zip"
      
      respond_to do |format|
        format.json do
          render :json => @url.to_json, :status => :ok
        end
      end
    else
      respond_to do |format|
        format.json do
          render :json => "Document not ready.".to_json, :status => :error
        end
      end
    end
  end
  
  def reporting
    @user = nil
    if params[:email] && current_user.is_admin
      @user = User.find_by_email(params[:email])
      flash[:notice] = "User unknow : #{params[:email]}" unless @user
    end
    if @user.nil?
      @user = current_user
    end
    @year = params[:year].to_i if !params[:year].blank?
    @year ||= Time.now.year
    @monthlies = @user.all_monthly.of(@year).asc(:month).entries
    @clients = @user.all_clients_sorted.entries
    @customers = @user.all_customers_sorted.entries
  end
  
  def search_user
    @tags = []
    if !params[:q].blank?
      users = User.where(:email => /.*#{params[:q]}.*/)
      
      users.each do |user|
        @tags << {"id" => "#{user.email}", "name" => "#{user.email}"}
      end
    end
    respond_to do |format|
      format.json{ render :json => @tags.to_json, :callback => params[:callback], :status => :ok }
    end
  end
  
end
