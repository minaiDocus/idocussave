class Admin::ReminderEmailsController < Admin::AdminController
  before_filter :load_reminder_email, :only => %w(show edit update destroy preview deliver)
  
  layout "admin", :except => %w(preview)

protected

  def load_reminder_email
    @reminder_email = ReminderEmail.find params[:id]
  end

public

  def index
    @reminder_emails = ReminderEmail.all.paginate :page => params[:page], :per_page => 40
  end
  
  def show
  end
  
  def new
    @reminder_email = ReminderEmail.new
  end
  
  def create
    @reminder_email = ReminderEmail.new params[:reminder_email]
    if @reminder_email.save
      flash[:notice] = "Créer avec succès."
      redirect_to admin_reminder_emails_path
    else
      render "new"
    end
  end
  
  def edit
  end
  
  def update
    if @reminder_email.update_attributes(params[:reminder_email])
      @reminder_email.init
      flash[:notice] = "Modifié avec succès."
      redirect_to admin_reminder_emails_path
    else
      render "edit"
    end
  end
  
  def destroy
    if @reminder_email.destroy
      flash[:notice] = "Supprimé avec succès."
      redirect_to admin_reminder_emails_path
    else
      flash[:error] = "Une erreur est survenu lors de la suppression."
      redirect_to admin_reminder_emails_path
    end
  end
  
  def preview
    @reminder_email
  end
  
  def deliver
    result = @reminder_email.deliver
    if result == true
      flash[:notice] = "Délivré avec succès."
    elsif result.is_a? Array and result.empty?
      flash[:notice] = "Les mails ont déjà été envoyé."
    else
      flash[:error] = "Une erreur est survenu lors de la livraison."
    end
    redirect_to admin_reminder_emails_path
  end

end