# -*- encoding : UTF-8 -*-
class AccountBookTypeWriter
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
      UpdateJournalRelationService.new(@journal).execute

      EventCreateService.add_journal(@journal, @owner, @current_user, path: @request.path, ip_address: @request.remote_ip)

      @owner.dematbox.subscribe if @owner.dematbox.try(:is_configured)

      DropboxImport.changed(@owner)
    end

    @journal
  end

  def update
    @journal.assign_attributes(@params)
    changes  = @journal.changes.dup
    customer = @journal.user 

    @journal.save

    if customer
      UpdateJournalRelationService.new(@journal).execute

      EventCreateService.journal_update(@journal, customer, changes, @current_user, path: @request.path, ip_address: @request.remote_ip)

      if changes['name'].present? && @journal.user.dematbox.try(:is_configured)
        customer.dematbox.subscribe
      end

      DropboxImport.changed(customer)
    end

    @journal
  end

  def destroy
    customer = @journal.user
    @journal.destroy

    if customer
      UpdateJournalRelationService.new(@journal).execute

      EventCreateService.remove_journal(@journal, customer, @current_user, path: @request.path, ip_address: @request.remote_ip)

      customer.dematbox.subscribe if customer.dematbox.try(:is_configured)

      DropboxImport.changed(customer)
    end
  end
end