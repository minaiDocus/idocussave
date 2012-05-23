class Account::Documents::DocumentsController < Account::AccountController
  layout "inner", :only => %w(index reporting reporting2)
  
  before_filter :find_last_composition, :only => %w(index)

protected  
  def find_last_composition
    @last_composition = current_user.composition
  end

public
  def index
    @packs = Pack.any_in(:user_ids => [current_user.id]).desc(:created_at).paginate :page => params[:page], :per_page => 20
    if @last_composition
      @composition = Document.any_in(:_id => @last_composition.document_ids)
    end
  end
  
  def show
    @documents = current_user.packs.find(params[:id]).documents.without_original.sort { |a,b| a.position <=> b.position } rescue []
    
    if params[:filtre]
      @user = current_user
      queries = params[:filtre].split(':_:')
      document_ids = []
      queries.each_with_index do |query,index|
        f_document_ids = []
        t_document_ids = []
        if index == 0
          f_document_ids = Document::Index.find_document_ids [query], @user
          t_document_ids = Document.find_ids_by_tags [query], @user
          document_ids = f_document_ids + t_document_ids
        else
          f_document_ids = Document.any_in(:_id => document_ids).any_in(:_id => Document::Index.find_document_ids([query], @user)).distinct(:_id)
          t_document_ids = Document.any_in(:_id => document_ids).any_in(:_id => Document.find_ids_by_tags([query], @user)).distinct(:_id)
          document_ids = f_document_ids + t_document_ids
        end
      end
      ids = @documents.map { |d| d.id }
      @documents = Document.any_in(:_id => document_ids).asc(:position).find_all { |document| ids.include? document.id }
    end

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
    @user = current_user
    
    if params[:filtre]
      queries = params[:filtre].split(':_:')
      pack_ids = []
      queries.each_with_index do |query,index|
        f_pack_ids = []
        t_pack_ids = []
        if index == 0
          f_pack_ids = Document::Index.find_pack_ids [query], @user
          t_pack_ids = Pack.find_ids_by_tags [query], @user
          pack_ids = f_pack_ids + t_pack_ids
        else
          f_pack_ids = Pack.any_in(:_id => pack_ids).any_in(:_id => Document::Index.find_pack_ids([query], @user)).distinct(:_id)
          t_pack_ids = Pack.any_in(:_id => pack_ids).any_in(:_id => Pack.find_ids_by_tags([query], @user)).distinct(:_id)
          pack_ids = f_pack_ids + t_pack_ids
        end
      end
      @packs = Pack.any_in(:_id => pack_ids)
    else
      @packs = @user.packs
    end
    @packs = @packs.order_by([[:created_at, :desc]])
    
    if params[:view] == "self"
      @packs = @packs.select { |pack| pack.order.user == @user }
    elsif params[:view] != "all" and params[:view] != ""
      @other_user = User.find(params[:view])
      @packs = @packs.where(:owner_id => @other_user.id)
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
        render :pdf => "#{@invoice.number}", :template => "/account/documents/documents/invoice.html.haml"
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
      results = Document::Index.search query, current_user
      
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
    @documents += Document::Index.find_document(query, current_user).entries
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
    
    if pack.divisions.sheets.count > 0
      unless File.directory?("#{Rails.root}/public/system/archive/#{current_user.id}")
        Dir.mkdir("#{Rails.root}/public/system/archive/#{current_user.id}")
      end
      
      pack.divisions.sheets.each do |sheet|
        filename = sheet.name.gsub(/\s/,'_')
        start_number = sheet.start
        end_number = sheet.end
        
        part = (start_number == end_number) ? start_number.to_s : start_number.to_s+"-"+end_number.to_s
        
        url = "#{Rails.root}/public#{pack.documents.where(:is_an_original => true).first.content.url.sub(/\.pdf.*/,'.pdf')}"
        cmd = "pdftk A=#{url} cat A#{part} output #{Rails.root}/public/system/archive/#{current_user.id}/#{filename}.pdf"
        system(cmd)
      end
      
      new_name = pack.name.gsub(/\s/,'_')
    
      Dir.chdir("#{Rails.root}/public/system/archive/#{current_user.id}/")
      system("rm *.zip") rescue nil # suppression du précèdent zip
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
          render :json => 'Ce document ne contient aucune information de hashage'.to_json, :status => :error
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
    @prescriber = @user.prescriber ? @user.prescriber : @user
    @year = params[:year].to_i if !params[:year].blank?
    @year ||= Time.now.year
    @monthlies = @user.all_monthly.of(@year).asc(:month).entries
    @clients = @user.all_clients_sorted.entries
    @customers = @user.all_customers_sorted.entries
    
    respond_to do |format|
      format.html
      format.xls do
        send_data(render_to_xls(@monthlies), :type=> "application/vnd.ms-excel", :filename => "reporting_iDocus_#{Time.now.year}#{"%0.2d" % Time.now.month}#{"%0.2d" % Time.now.day}.xls")
      end
    end
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
  
private
  def render_to_xls monthlies
    book = Spreadsheet::Workbook.new
    
    # Document
    sheet1 = book.create_worksheet :name => "Production"
    sheet1.row(0).concat ["Mois", "Année", "Code client", "Société", "Nom du document", "Piéces total", "Piéces numérisées", "Piéces versées", "Feuilles total", "Feuilles numérisées", "Pages total", "Pages numérisées", "Pages versées", "Attache" ,"Hors format"]
    
    nb = 1
    monthlies.each do |monthly|
      monthly.documents.each do |document|
        data = [
                    monthly.month,
                    monthly.year,
                    monthly.reporting.customer.code,
                    monthly.reporting.customer.company,
                    document.name,
                    document.pieces,
                    document.scanned_pieces,
                    document.uploaded_pieces,
                    document.sheets,
                    document.scanned_sheets,
                    document.pages,
                    document.scanned_pages,
                    document.uploaded_pages,
                    document.clip,
                    document.oversize
                  ]
        sheet1.row(nb).replace data
        nb += 1
      end
    end
    
    # Invoice
    sheet2 = book.create_worksheet :name => "Facturation"
    sheet2.row(0).concat ["Mois", "Année", "Code client", "Nom du client", "Paramètre", "Valeur", "Prix HT"]
    
    nb = 1
    monthlies.each do |monthly|
      poos = monthly.subscription_detail.product_order.product_option_orders rescue []
      unless poos.empty?
        poos.each do |poo|
          data = [
                      monthly.month,
                      monthly.year,
                      monthly.reporting.customer.code,
                      monthly.reporting.customer.name,
                      poo.group,
                      poo.title,
                      format_price_00(poo.price_in_cents_wo_vat)
                    ]
          sheet2.row(nb).replace data
          nb += 1
          end
      end
      data = [
                  monthly.month,
                  monthly.year,
                  monthly.reporting.customer.code,
                  monthly.reporting.customer.name,
                  "Dépassement",
                  "",
                  format_price_00(monthly.total_price_in_cents)
                ]
      sheet2.row(nb).replace data
      nb += 1
    end
    
    io = StringIO.new('')
    book.write(io)
    io.string
  end
  
  def render_to_xls_simple monthlies
    documents = []
    monthlies.each { |monthly| documents = documents + monthly.documents }
    
    documents.to_xls  :name => "Documents",
                                :headers => ["Mois", "Année", "Code client", "Société", "Nom du document", "Piéces total", "Piéces versé", "Feuilles total", "Feuilles numérisé", "Pages total", "Pages numérisé", "Attache" ,"Hors format"],
                                :columns => [{:monthly => [:month, :year, { :reporting => { :customer => [:code, :company]}}]}, :name, :pieces, :uploaded_pieces, :sheets, :scanned_sheets, :pages, :scanned_pages, :clip, :oversize]
  end
  
end
