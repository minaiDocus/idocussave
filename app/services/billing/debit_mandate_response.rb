# -*- encoding : UTF-8 -*-
class Billing::DebitMandateResponse
  attr_accessor :errors

  def initialize(debit_mandate=nil)
    @debit_mandate = debit_mandate
    @checkout_iframe_64 = nil
    @checkout_uri = nil
    @order_reference = nil
    @mandate = nil
    @bank_account = nil
    @errors = nil
  end

  def prepare_order
    begin
      fetch_order_infos

      if @debit_mandate.configured? || (@order_reference && @order_reference.try(:[], 'state') == 'closed.completed')
        @errors = "Vous avez déjà configurer votre prélèvement. Pour toutes modifications ou renouvellement de compte, veuillez contacter notre équipe d'assistance au support@idocus.com"

        if !@debit_mandate.RUM.present? && !@debit_mandate.iban.present? && !@debit_mandate.bic.present?
          if @mandate['rum'].present? && @bank_account['iban'].present? && @bank_account['bic'].present?
            @debit_mandate.transactionStatus = 'success'
            @debit_mandate.signatureDate = Time.now.strftime('%Y-%m-%d')
            @debit_mandate.RUM = @mandate['rum']
            @debit_mandate.iban = @bank_account['iban']
            @debit_mandate.bic = @bank_account['bic']
            @debit_mandate.save

            @debit_mandate.organization.update(is_suspended: false) if @debit_mandate.organization.is_suspended

            System::Log.info('slimpay', "[Slimpay: #{@debit_mandate.id} - #{@debit_mandate.reference}] - Refilled : Order state : #{@order_reference['state']}")
          end
        end
      else
        @order_reference = client.create_sepa_order @debit_mandate unless @order_reference && @order_reference.try(:[], 'state') == 'open.running'
        @checkout_iframe_64 = client.get_checkout_frame
        @checkout_uri = client.get_checkout_uri_redirection

        System::Log.info('slimpay', "[Slimpay: #{@debit_mandate.id} - #{@debit_mandate.reference}] - Started : Order state : #{@order_reference['state']}")
      end
    rescue => e
      @errors = e.message

      log_document = {
        subject: "[Billing::DebitMandateResponse] error slimpay #{@errors}",
        name: "DebitMandateResponseService",
        error_group: "[debit-mandates-response-service] error slimpay",
        erreur_type: "Error Slimpay",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          debit_mandate: @debit_mandate.inspect,
          error: e.message
        }
      }

      ErrorScriptMailer.error_notification(log_document).deliver
    end
  end

  def confirm_payment
    sleep 3 #wait for slimpay to update order state
    fetch_order_infos
    finished = false

    if @mandate && @bank_account
      @debit_mandate.transactionStatus = 'success'
      @debit_mandate.signatureDate = Time.now.strftime('%Y-%m-%d')
      @debit_mandate.RUM = @mandate['rum']
      @debit_mandate.iban = @bank_account['iban']
      @debit_mandate.bic = @bank_account['bic']
      @debit_mandate.save

      @debit_mandate.organization.update(is_suspended: false) if @debit_mandate.organization.is_suspended

      finished = true
    elsif @order_reference && @order_reference.try(:[], 'state').match(/closed[.]aborted/)
      @debit_mandate.transactionStatus = nil
      @debit_mandate.reference = nil
      @debit_mandate.save
    end

    System::Log.info('slimpay', "[Slimpay: #{@debit_mandate.id} - #{@debit_mandate.reference}] - Finished : Order state : #{@order_reference['state']} - closed : #{finished.to_s}")
  end

  def get_frame
    @checkout_iframe_64
  end

  def get_redirect_uri
    @checkout_uri
  end

  def order_reference
    if @order_reference.try(:[], 'reference').present?
      @order_reference['reference']
    else
      @errors = "Une erreur s'est produite, Veuillez réessayer ultérieurement"
    end
  end


  def fetch_order_infos
    if @debit_mandate.reference.present?
      @order_reference = client.get_order @debit_mandate

      System::Log.info('slimpay', "[Slimpay: #{@debit_mandate.id} - #{@debit_mandate.reference}] - Order state : #{@order_reference['state']}")

      if @order_reference['state'] == 'closed.completed'
        @mandate = client.get_mandate
        @bank_account = client.get_bank_account

        System::Log.info('slimpay', "[Slimpay: #{@debit_mandate.id} - #{@debit_mandate.reference}] - RUM : #{@mandate['rum']}")
        System::Log.info('slimpay', "[Slimpay: #{@debit_mandate.id} - #{@debit_mandate.reference}] - IBAN : #{@bank_account['iban']}")
        System::Log.info('slimpay', "[Slimpay: #{@debit_mandate.id} - #{@debit_mandate.reference}] - bic : #{@bank_account['bic']}")
      end
    end
  end

private

  #NOTE: keep this method private : only used by administrator
  def revoke_payment
    begin
      fetch_order_infos

      if @mandate && @bank_account
          if client.revoke_mandate.try(:[], 'state') == 'revoked'
            reset_mandate
            nil #need to return nil if success
          else
            'Impossible de supprimer le mandat!'
          end
      else
        reset_mandate
        nil #need to return nil if success
      end
    rescue => e
      "Impossible de supprimer le mandat! (#{e.message})"
    end
  end

  def reset_mandate
    @debit_mandate.transactionStatus = nil
    @debit_mandate.reference = nil

    @debit_mandate.RUM = nil
    @debit_mandate.iban = nil
    @debit_mandate.bic = nil

    @debit_mandate.save
  end

  def client
    @client ||= SlimpayCheckout::Client.new
  end
end
