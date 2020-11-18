# -*- encoding : UTF-8 -*-
class PonctualScripts::Archive::BudgeaTransactionFetcher
    def initialize(user, account_ids = [], min_date=nil, max_date=nil)
      @user = user
      @account_ids = Array(account_ids)

      @min_date = min_date
      @max_date = max_date

      @message = ''
    end

    def execute
      new_operations_count = new_bank_account_count = 0
      operations_fetched_count = 0
      deleted_operations_count = deleted_bank_account_count = 0

      log_message = "------------[#{@user.try(:code)} - #{@account_ids.to_s} - #{@min_date} - #{@max_date}]---------------\n"

      if client && @user
        if @min_date && @max_date && @account_ids.present?
          @accounts = client.get_accounts

          if @accounts.present? && !(@accounts =~ /unauthorized/)
            @accounts.each do |account|
              next unless @account_ids.include? "#{account['id']}"

              retriever = @user.retrievers.where(budgea_id: account['id_connection']).order(created_at: :asc).first

              if retriever
                bank_account = @user.bank_accounts.where(
                  'api_id = ? OR (name = ? AND number = ?)',
                  account['id'],
                  account['name'],
                  account['number']
                ).first

                @transactions = client.get_transactions account['id'], @min_date, @max_date

                if bank_account && @transactions.present?
                  @transactions.each do |transaction|
                    operations_fetched_count += 1

                    operation = bank_account.operations.where(api_id: transaction['id'], api_name: 'budgea').first

                    if operation
                      if transaction['deleted'].present? && operation.processed_at.nil?
                        operation.destroy
                        deleted_operations_count += 1
                      else
                        assign_attributes(bank_account, operation, transaction)
                        operation.save if operation.changed?
                      end
                    else
                      orphaned_operation = find_orphaned_operation(bank_account, transaction)

                      if orphaned_operation
                        orphaned_operation.bank_account = bank_account
                        new_operations_count += 1 unless orphaned_operation.processed_at.present?

                        assign_attributes(bank_account, orphaned_operation, transaction)
                        orphaned_operation.api_id = transaction['id']
                        orphaned_operation.save
                      elsif transaction['deleted'].nil?
                        operation = Operation.new(bank_account_id: bank_account.id)
                        operation.organization = @user.organization
                        operation.user         = @user
                        operation.api_id       = transaction['id']
                        operation.api_name     = 'budgea'
                        assign_attributes(bank_account, operation, transaction)
                        operation.save

                        new_operations_count += 1
                      end
                    end
                  end
                end
              else
                log_message += "[BudgeaTransactionFetcher][#{@user.code}] - No retriever found, for connection id: #{account['id_connection']}\n"
              end
            end
          else
            log_message += "[BudgeaTransactionFetcher][#{@user.code}] - No bank accounts found! OR Unauthorized => #{@accounts.to_s}"
            System::Log.info('budgea_fetch_processing', log_message)
            return log_message
          end
        else
          log_message += "[BudgeaTransactionFetcher][#{@user.code}] - Parameters invalid!"
          System::Log.info('budgea_fetch_processing', log_message)
          return log_message
        end
      else
        log_message += "[BudgeaTransactionFetcher][#{@user.try(:code)}] - Budgea client invalid! - no budgea account configured for the user"
        System::Log.info('budgea_fetch_processing', log_message)
        return log_message
      end
      log_message += "[BudgeaTransactionFetcher][#{@user.try(:code)}] - New operations: #{new_operations_count} / Deleted operations: #{deleted_operations_count} / Total operations fetched: #{operations_fetched_count}"
      System::Log.info('budgea_fetch_processing', log_message)
      return log_message
    end

  private

    def find_orphaned_operation(bank_account, transaction)
      operations = bank_account.user.operations

      orphaned_operation = operations.where(
        date:       transaction['date'],
        value_date: transaction['rdate'],
        amount:     set_transaction_value(bank_account, transaction),
        comment:    transaction['comment'],
        api_id:     nil
      )

      if bank_account.type_name != 'card' && transaction['type'] == 'deferred_card'
        orphaned_operation = orphaned_operation.where(
          operations.arel_table[:label].eq(transaction['original_wording']).or(
            operations.arel_table[:label].eq('[CB] ' + transaction['original_wording'])
          )
        )
      else
        orphaned_operation = orphaned_operation.where(label: transaction['original_wording'])
      end

      orphaned_operation.first
    end

    def assign_attributes(bank_account, operation, transaction)
      operation.date        = transaction['date']
      operation.value_date  = transaction['rdate']
      operation.currency    = bank_account.original_currency
      if bank_account.type_name != 'card' && transaction['type'] == 'deferred_card'
        operation.label     = '[CB] ' + transaction['original_wording']
      else
        operation.label     = transaction['original_wording']
      end
      operation.amount      = set_transaction_value(bank_account, transaction)
      operation.comment     = transaction['comment']
      operation.type_name   = transaction['type']
      operation.category_id = transaction['id_category']
      operation.category    = Transaction::BankOperationCategory.find(transaction['id_category']).try(:[], 'name')
      operation.deleted_at  = Time.parse(transaction['deleted']) if transaction['deleted'].present?
      if operation.class == Operation && operation.processed_at.nil?
        operation.is_coming = transaction['coming']
        if lock_operation?(bank_account, operation)
          operation.is_locked = true
        else
          operation.is_locked = !(bank_account.is_used && bank_account.configured?)
        end
      end
    end

    def lock_operation?(bank_account, operation)
      (bank_account.start_date.present? && operation.date < bank_account.start_date) ||
        operation.date < Date.parse('2017-01-01') ||
        operation.is_coming ||
        is_operation_old?(bank_account, operation)
    end

    def is_operation_old?(bank_account, operation)
      bank_account.lock_old_operation &&
        bank_account.created_at < 1.month.ago &&
        operation.date < bank_account.permitted_late_days.days.ago.to_date
    end

    def client
      token = @user.try(:budgea_account).try(:access_token)

      unless @client
        @client = token.nil? ? nil : Budgea::Client.new(token)
      end
      @client
    end

    def set_transaction_value(bank_account, transaction)
      if (transaction['value'].nil? && bank_account.bank_name.downcase == 'paypal rest api')
        transaction['gross_value'] + transaction['commission'] if (transaction['gross_value'].present? && transaction['commission'].present?)
      else
        transaction['value']
      end
    end

end