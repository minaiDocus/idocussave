# -*- encoding : UTF-8 -*-
class DebitMandateResponseService
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
      else
        @order_reference = client.create_sepa_order @debit_mandate unless @order_reference && @order_reference.try(:[], 'state') == 'open.running'
        @checkout_iframe_64 = client.get_checkout_frame
        @checkout_uri = client.get_checkout_uri_redirection
      end
    rescue => e
      @errors = e.message
    end
  end

  def confirm_payment
    fetch_order_infos

    if @mandate && @bank_account
      @debit_mandate.transactionStatus = 'success'
      @debit_mandate.signatureDate = Time.now.strftime('%Y-%m-%d')
      @debit_mandate.RUM = @mandate['rum']
      @debit_mandate.iban = @bank_account['iban']
      @debit_mandate.bic = @bank_account['bic']
      @debit_mandate.save

      @debit_mandate.organization.update(is_suspended: false) if @debit_mandate.organization.is_suspended
    elsif @order_reference && @order_reference.try(:[], 'state').match(/closed[.]aborted/)
      @debit_mandate.transactionStatus = nil
      @debit_mandate.reference = nil
      @debit_mandate.save
    end
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

      if @order_reference['state'] == 'closed.completed'
        @mandate = client.get_mandate
        @bank_account = client.get_bank_account
      end
    end
  end

private

  #NOTE: only used by administrator
  def revoke_payment
    fetch_order_infos

    if @mandate && @bank_account
      begin
        if client.revoke_mandate.try(:[], 'state') == 'revoked'
          @debit_mandate.transactionStatus = nil
          @debit_mandate.reference = nil

          @debit_mandate.RUM = nil
          @debit_mandate.iban = nil
          @debit_mandate.bic = nil

          @debit_mandate.save
          true
        else
          p @errors = 'Impossible de supprimer le payment!'
          false
        end
      rescue => e
        p @errors = "Impossible de supprimer le payment! (#{e.message})"
        false
      end
    end
  end

  def client
    @client ||= SlimpayCheckout::Client.new
  end

end
