class Account::Documents::DocumentsController < Account::AccountController
  layout "inner", :only => %w(index)
  before_filter :find_last_composition, :only => %w(index)

protected  
  def find_last_composition
    return if self.controller_name == 'document_tags'
    @last_composition = current_user.composition
  end

public
  def index
    @packs_count = current_user.packs.count
    @packs = current_user.packs.order_by(:created_at, :desc).paginate :page => params[:page], :per_page => 20
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
    pack_ids = []
    
    if params[:view] == "all" || params[:view] == "self"
      if !params[:filtre]
        current_user.orders.with_state([:paid]).desc(:created_at).each do |order|
          order.packs.each{|p| pack_ids << p.id}
        end
      end
      current_user.orders.with_state([:scanned]).desc(:created_at).each do |order|
        order.packs.each{|p| pack_ids << p.id if p.match_tags params[:filtre], current_user}
      end
    end
    
    if params[:view] != "self"
      order_ids = []
      Order.where(:user_id => current_user.id).each{|o| order_ids << o.id}
      Pack.where(:user_ids => current_user.id).not_in(:order_id => order_ids).entries.each do |pack|
        unless pack.documents.empty?
          pack_ids << pack.id if pack.match_tags params[:filtre], current_user
        end
      end
      if params[:view] != "all"
        order2_ids = []
        Order.where(:user_id => (User.find(params[:view])).id).each{|o| order2_ids << o.id}
        Pack.where(:user_ids => current_user.id).not_in(:order_id => order_ids).any_in(:order_id => order2_ids).each do |pack|
          unless pack.documents.empty?
            pack_ids << pack.id if pack.match_tags params[:filtre], current_user
          end
        end
      end
    end
    
    @packs = []
    
    if params[:filtre]
      @packs = Pack.find_by_content params[:filtre], current_user
    end
    
    unless pack_ids.empty?
      @packs = @packs + Pack.any_in(:_id => pack_ids).desc(:created_at)
      @packs = @packs.uniq
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
    @tags = Array.new
    @document_contents = Array.new
    
    query = Iconv.iconv('UTF-8', 'ISO-8859-1', params[:q]).join()
    
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
      result = Pack.find_content query, current_user
      if result
        result.each do |word|
          @document_contents << {"id" => "#{word[0] ? 0 : 2}", "name" => "#{word[1]}"}
        end
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
    document_ids = ""
    Iconv.iconv('UTF-8', 'ISO-8859-1', params[:having]).join().split(':_:').each_with_index do |tag,index|
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
    
    Iconv.iconv('UTF-8', 'ISO-8859-1', params[:having]).join().split(':_:').join(" ")
    
    
    @documents = Document.any_in(:_id => document_ids.split).entries
    @documents = @documents + Pack.find_document(params[:having], current_user)
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
    
    pack.get_division_from_pdf if pack.division.empty?
    number_of_page = pack.division[1]
    
    unless File.directory?("#{Rails.root}/public/system/archive/#{current_user.id}")
      Dir.mkdir("#{Rails.root}/public/system/archive/#{current_user.id}")
    end
    
    pack.division[2].each_with_index do |partie,index|
      filename = partie[0].gsub(/\s/,'_')
      level = partie[1]
      start_number = partie[2]
      end_number = partie[3]
      
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
  end
  
  def reporting
    @user = nil
    if params[:email] && current_user.is_admin
      @user = User.find_by_email(params[:email])
    end
    unless @user
      @user = current_user
    end
    @year = params[:year] ? params[:year].to_i : Time.now.year
    unless @user.reporting
      @user.reporting = Reporting.new
      @user.save
      @user.reporting.save
    end
    @clients = @user.reporting.clients + [@user]
    @clients = @clients.sort do |a,b|
      if a.code != b.code
        a.code <=> b.code
      elsif a.company != b.company
        a.company <=> b.company
      elsif (a.first_name + " " + a.last_name) != (b.first_name + " " + b.last_name)
        (a.first_name + " " + a.last_name) <=> (b.first_name + " " + b.last_name)
      else
        a.email <=> b.email
      end
    end
    
    @packs = []
    if orders = (@user.reporting.orders + @user.orders)
      orders.each{|order| order.packs.each{|p| @packs << p}}
    end
    
    time = Date.new(@year).to_time
    @reporting = {}
    12.times do
      month = { "#{time.month}" => []}
      @reporting.merge!(month)
      
      packs = @packs.select{|p| p["created_at"] >= time && p["created_at"] <= (time.next_month - 1)}
      unless packs.empty?
        packs = packs.sort{|a,b| a.order.created_at <=> b.order.created_at}
        
        @clients.each do |client|
          user = [client.email,client.id]
          docs = packs.select{|p| p.order.user == client }.collect do |p|
            p.get_division_from_pdf if p.division.nil?
            division_level_1 = p.division[2].select{|d| d[1].to_i == 1}
            division_level_2 = nil
            if p.division[0].to_i == 2
              division_level_2 = p.division[2].select{|d| d[1].to_i == 2}
            end
            unless division_level_2
              division_level_2 = division_level_1
            end
            [p.name,division_level_1.length,division_level_2.length,p.documents.size - 1]
          end
          exces = 0
          
          @reporting[time.month.to_s] << [user, docs, exces] if docs.size > 0
        end
      end
      
      time = time.next_month
    end
    
  end
end
