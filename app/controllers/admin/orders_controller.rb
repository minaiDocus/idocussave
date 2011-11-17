class Admin::OrdersController < Admin::AdminController

  before_filter :load_model, :only => %w(show edit update destroy)
  before_filter :load_order, :only => %w(destroy)


  include Admin::BaseAdminMixin

protected

  def load_order
    @order = Order.find params[:id]
  end
  
  def get_documents user, order
    Dir.chdir("#{Rails.root}/tmp/input_pdf_manuel/")
    
    file_names = []
    Dir.foreach("./") { |file_name|
      file_names << file_name.sub(/.pdf/i,'') if file_name.match(/.pdf/i)
      File.rename(file_name, file_name.sub(/.PDF/,'.pdf')) if file_name.match(/.PDF/)
    }
    
    doc_names = []
    params[:document_names].split(', ').each do |doc_name|
      doc_names << doc_name
    end
    
    valid_names = []
    doc_names.each do |doc_name|
      file_names.each do |file_name|
        if doc_name.match(/[*]/)
          valid_names << file_name if file_name.match(/#{doc_name.sub('*','(.*)')}/i)
        else
          valid_names << file_name if file_name.match(/\A#{doc_name}\z/i)
        end
      end
    end

    valid_names.each do |file_name|
      number = order.packs.count + 1
      File.rename("#{file_name}.pdf","#{order.waybill_number}_#{number}.pdf")
    
      pack = Pack.new
      pack.order = order
      pack.name = file_name.gsub('_',' ')
      pack.users << user
      pack.save!
      pack.get_document "#{order.waybill_number}_#{number}"

      params[:share_with].split(', ').each do |other|
        observer = User.find_by_email other
        unless observer.nil? && observer.id != user.id
          pack.users << observer
        end
      end
      pack.save!
  
      tags = [" "]
      params[:tags].gsub('*','').downcase.split.each do |tag|
        tags << tag
      end

      pack.documents.each do |document|
        document_tag = DocumentTag.new
        document_tag.document = document.id
        document_tag.user = user.id
        g_tags = document_tag.generate
        document_tag.name += tags.join(' ')
        document_tag.save!
        params[:share_with].split(', ').each do |other|
          observer = User.find_by_email other rescue nil
          unless observer.nil?
            document_tag = DocumentTag.new
            document_tag.document = document.id
            document_tag.user = observer.id
            document_tag.name = g_tags + tags.join(' ')
            document_tag.save!
          end
        end
      end
    end
    order.save!
  end

public

  def index
    @orders = Order.order_by(:number.desc, :created_at.asc).paginate :page => params[:page], :per_page => 50
    
    respond_to do |format|
      format.html
      format.xml
    end
  end

  def model_class
    Order
  end

  def new
    @order = Order.new
  end

  def create
    user = User.find_by_email params[:email]
    order = Order.new
    order.user = user
    order.manual = true
    if params[:prescriber_email]
      order.prescriber = user if user = User.find_by_email(params[:prescriber_email])
    end
    order.pay!
    
    get_documents user, order
    flash[:notice] = "Crée avec succès."
    
    redirect_to admin_orders_path
  end
  
  def update
    order = Order.find params[:id]
    user = order.user
    
    if params[:prescriber_email]
      order.prescriber = user if user = User.find_by_email(params[:prescriber_email])
    else
      order.prescriber = nil
      order.save!
    end
    
    get_documents user, order
    flash[:notice] = "Modifiée avec succès."
    
    redirect_to admin_orders_path
  end

  def destroy
    @order.packs.each do |pack|
      pack.documents.each do |document|
        url = document.content.url(:thumb)
        url = url.split('/')
        cmd = "cd #{Rails.root}/public/system/contents/ && rm -r #{url[3]}"
        system(cmd)
        if document_tags = DocumentTag.where(:document_id => document.id)
          document_tags.delete_all
        end
      end
    end
    @order.delete
    flash[:notice] = "Supprimée avec succès."
    
    redirect_to admin_document_orders_path
  end

end