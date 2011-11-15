class Account::DocumentsController < Account::AccountController
  layout "inner", :only => %w(index)
  
  def index
    @packs = current_user.packs.order_by(:created_at, :desc)
    @packs_count = @packs.count
    @packs = @packs.paginate :page => params[:page], :per_page => 20
    if @last_composition
      @composition = Document.any_in(:_id => @last_composition.document_ids)
    end
  end

  def show
    @pack = current_user.packs.where(:_id => params[:id]).first rescue nil
    @documents = @pack.documents.without_original.asc(:position) rescue nil

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
      if !params[:tags]
        current_user.orders.with_state([:paid]).desc(:created_at).each do |order|
          order.packs.each do |pack|
            if matchFilter(pack.documents.first.id)
              pack_ids << pack.id
            end
          end
        end
      end
      current_user.orders.with_state([:scanned]).desc(:created_at).each do |order|
        order.packs.each do |pack|
          if matchFilter(pack.documents.first.id)
            pack_ids << pack.id
          end
        end
      end
    end
    
    if params[:view] != "self"
      order_ids = []
      Order.where(:user_id => current_user.id).each do |order|
        order_ids << order.id
      end
      Pack.where(:user_ids => current_user.id).not_in(:order_id => order_ids).entries.each do |pack|
        if matchFilter(pack.documents.first.id)
          pack_ids << pack.id
        end
      end
      if params[:view] != "all"
        order2_ids = []
        Order.where(:user_id => (User.find(params[:view])).id).each do |order|
          order2_ids << order.id
        end
        Pack.where(:user_ids => current_user.id).not_in(:order_id => order_ids).any_in(:order_id => order2_ids).each do |pack|
          if matchFilter(pack.documents.first.id)
            pack_ids << pack.id
          end
        end
      end
    end
    
    @packs = nil
    unless pack_ids.empty?
      @packs = Pack.any_in(:_id => pack_ids).desc(:created_at)
      @packs_count = @packs.count
      @packs = @packs.paginate :page => params[:page], :per_page => params[:per_page]
    else
      @packs_count = 0;
    end
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
  
    if params[:by] == "tags" || !params[:by]
      @document_tags = DocumentTag.where(:user_id => current_user.id, :name => /\w*#{params[:q]}\w*/)
      
      tags = ""
      @document_tags.each do |document_tag|
        document_tag.name.scan(/\w*#{params[:q]}\w*/).each do |tag|
          if !tags.match(/ #{tag}( )*/)
            tags += " #{tag}"
          end
        end
      end
      
      tags.split.each do |tag|
        @tags << {"id" => "tag", "name" => "#{tag}"}
      end
      
    end
    
    if params[:by] == "ocr_result" || !params[:by]
      words = current_user.document_content.words.where(:content => /\w*#{params[:q]}\w*/).entries rescue Array.new
      words.each do |word|
        @document_contents << {"id" => "content", "name" => "#{word.content}"}
      end
    end
    
    @result = Array.new
    @result = @tags + @document_contents
    
    @result = @result.sort do |a,b|
      a["name"] <=> b["name"]
    end
    
    respond_to do |format|
      format.json{ render :json => @result.to_json, :callback => params[:callback], :status => :ok }
    end
  end
  
  def update_tag
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
  
  def find
    document_ids = ""
    params[:having].split(':_:').each_with_index do |tag,index|
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
    
    params[:having].split(':_:').each_with_index do |tag,index|
      docs = Array.new
      words = current_user.document_content.words.where(:content => /\w*#{tag}\w*/).entries rescue Array.new
      words.each_with_index do |word,index|
        if index == 0
          docs = word.documents
        else
          docs = docs.select do |d|
            if word.documents.include?(d)
              true
            else
              false
            end
          end
        end
      end
      docs.each do |d|
        document_ids += " #{d.id}"
      end
    end
    
    @documents = Document.any_in(:_id => document_ids.split).entries
    
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
  
  def share
    users = []
    params[:email].split().each do |email|
      user = User.find_by_email email
      if user != current_user
        users << user
      end
    end
    
    packs = []
    params[:pack_ids].each do |pack_id|
      pack = Pack.find(pack_id)
      if pack.order.user == current_user
        packs << pack
      end
    end
    
    packs.each do |pack|
      users.each do |user|
        exist = user.packs.find(pack.id) rescue false
        if !exist
          user.packs << pack
          user.save
          pack.documents.each do |document|
            document_tag = DocumentTag.new
            document_tag.document = document.id
            document_tag.user = user.id
            document_tag.generate
            document_tag.save!
          end
        end
      end
    end
    
    respond_to do |format|
      format.json{ render :json => {}, :status => :ok }
    end
  end
    
protected

  def matchFilter document_id
    if params[:tags]
      match_tag = true
      match_content = true

      document_tag = DocumentTag.where(:document_id => document_id, :user_id => current_user.id).first
      if document_tag.nil?
        match_tag = false
      end
      params[:filter].split(':_:').each do |tag|
        unless document_tag.name.match(/ #{tag}/)
          match_tag = false
        end
      end

      params[:filter].split(':_:').each do |filter|
        unless Word.where(:content => filter, :document_ids => document_id).first
          match_content = false
        end
      end

      if match_tag || match_content
        true
      else
        false
      end
    else
      true
    end
  end
end

