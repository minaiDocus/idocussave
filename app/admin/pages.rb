# -*- encoding : UTF-8 -*-
ActiveAdmin.register Page do
  filter :title, as: String, label: 'Titre'
  filter :label, as: String, label: 'Libellé'
  filter :tag, as: String, label: 'Type de contenu'
  
  actions :all, except: [:show]
  
  config.sort_order= "position_asc"
  
  index do
    column :position, sortable: :position do |page|
      page.position
    end
    column 'Titre', sortable: :title do |page|
      page.title
    end
    column :'Libellé', sortable: :label do |page|
      page.label
    end
    column :'Afficher dans le footer ?', sortable: :is_footer do |page|
      page.is_footer ? 'Oui' : 'Non'
    end
    column 'Est visible ?', sortable: :is_invisible do |page|
      page.is_invisible ? 'Non' : 'Oui'
    end
    column 'Type du contenu', sortable: :tag do |page|
      page.tag
    end
    default_actions
  end
  
  controller do
    def update
      @page = Page.find_by_slug params[:id]
      if @page.update_attributes(params[:page])
        flash[:notice] = "Modifié avec succès."
        redirect_to admin_pages_path
      else
        flash[:error] = "Impossible de modifier la pages."
        render action: :edit
      end
    end

    def edit
      @page = Page.find_by_slug params[:id]
    end
    
    def destroy
      @page = Page.find_by_slug params[:id]
      @page.destroy
      flash[:notice] = "Supprimé avec succès"
      redirect_to admin_pages_path
    end
  end
  
  form partial: 'form'
end

