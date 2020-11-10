# -*- encoding : UTF-8 -*-
class Journal::Handling
  def initialize(options)
    @params       = options[:params]
    @current_user = options[:current_user]
    @request      = options[:request]

    @owner        = options[:owner] #Insertion params
    @journal      = options[:journal] #Update OR Deletion params
  end

  def insert
    @journal = AccountBookType.new @params
    @owner.account_book_types << @journal

    @journal.save

    if @owner.class == User
      Journal::UpdateRelation.new(@journal).execute

      CreateEvent.add_journal(@journal, @owner, @current_user, path: @request.path, ip_address: @request.remote_ip)

      @owner.dematbox.subscribe if @owner.dematbox.try(:is_configured)

      FileImport::Dropbox.changed(@owner)
    end

    @journal
  end

  def update
    @journal.assign_attributes(@params)
    changes  = @journal.changes.dup
    customer = @journal.user

    @journal.save

    if customer
      Journal::UpdateRelation.new(@journal).execute

      CreateEvent.journal_update(@journal, customer, changes, @current_user, path: @request.path, ip_address: @request.remote_ip)

      if changes['name'].present? && @journal.user.dematbox.try(:is_configured)
        customer.dematbox.subscribe
      end

      FileImport::Dropbox.changed(customer)
    end

    @journal
  end

  def destroy
    customer = @journal.user
    @journal.destroy

    if customer
      Journal::UpdateRelation.new(@journal).execute

      CreateEvent.remove_journal(@journal, customer, @current_user, path: @request.path, ip_address: @request.remote_ip)

      customer.dematbox.subscribe if customer.dematbox.try(:is_configured)

      FileImport::Dropbox.changed(customer)
    end
  end
end