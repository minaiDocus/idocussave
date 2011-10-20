xml.instruct! 'xml-stylesheet', {:href=>'/stylesheets/document_order.css', :type=>'text/css'}

xml.table do
  xml.row do
  	xml.cell "numero"
    xml.cell "Utilisateur"
    xml.cell "Date"
    xml.cell "Document"
    xml.cell "Nombre de page"
    xml.cell "Taille du fichier en Ko"
  end

  @all_orders = Order.with_state([:scanned]).order_by(:number.desc)
  
  @all_orders.each do |order|
    xml.row do
      xml.cell order.number rescue ""
      xml.cell order.user.email rescue ""
      xml.cell order.created_at.strftime("%Y %m %d - %H:%M:%S") rescue ""
      xml.cell order.document_name rescue ""
      xml.cell order.documents.size - 1 rescue ""
      xml.cell order.original_document.content_file_size rescue ""
    end
  end
  
  xml.row do
    xml.cell "Document"
    xml.cell "Propiétaire"
    xml.cell "Observeur(s)"
  end

  order_ids = SharedDocument.all.distinct(:order_id)
  
  order_ids.each do |order_id|
  	shared_orders = SharedDocument.where(:order_id => order_id)
    
    shared_orders.each do |shared_order|
    	xml.row do
    		xml.cell Order.find(shared_order.order_id).document_name rescue ""
    		xml.cell User.find(shared_order.owner).email rescue ""
    		xml.cell User.find(shared_order.observer).email rescue ""
  		end
    end
  end
  
end
