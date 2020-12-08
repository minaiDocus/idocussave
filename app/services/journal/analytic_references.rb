# -*- encoding : UTF-8 -*-
class Journal::AnalyticReferences
  def initialize(journal)
    @journal  = journal
    @user     = @journal.user
  end

  def add(analytic)
    @errors = []

    analytic_validator = IbizaLib::Analytic::Validator.new(@user, analytic)
    @errors << ['Paramètre analytiques invalide'] unless analytic_validator.valid_analytic_presence?
    @errors << ['Paramètre ventilation invalide'] unless analytic_validator.valid_analytic_ventilation?

    if @errors.empty?
      if analytic_validator.analytic_params_present?
        IbizaLib::Analytic.add_analytic_to_journal analytic, @journal
      else
        remove
      end
      true
    else
      false
    end
  end

  def remove
    analytic = @journal.analytic_reference
    if analytic 
      @journal.analytic_reference = nil
      analytic.destroy unless analytic.is_used_by_other_than?({ journals: [@journal.id] })
      @journal.save
    end
  end

  def synchronize
    if valid?
      @errors << ['Aucune donnée analytique trouvée chez ibiza']
      false
      # client.request.clear
      # client.company(@user.try(:ibiza).try(:ibiza_id)).analyzes.complete
      # client.request.run

      # if client.response.success?
      #   analytic = fetch_ibiza_analytic(Nokogiri::XML(client.response.body.force_encoding('UTF-8')))
      #   if analytic['1'][:name].present? || analytic['2'][:name].present? || analytic['3'][:name].present?
      #     add(analytic)
      #   else
      #     @errors << ['Aucune donnée analytique trouvée chez ibiza']
      #     false
      #   end
      # else
      #   @errors << [client.response.body.force_encoding('UTF-8')]
      #   false
      # end
    else
      false
    end
  end

  def get_analytic_references
    analytic = @journal.analytic_reference || nil
    result = nil

    if analytic
      result =  {
                  a1_name:       analytic['a1_name'].presence,
                  a1_references: JSON.parse(analytic['a1_references']),
                  a2_name:       analytic['a2_name'].presence,
                  a2_references: JSON.parse(analytic['a2_references']),
                  a3_name:       analytic['a3_name'].presence,
                  a3_references: JSON.parse(analytic['a3_references']),
                }.with_indifferent_access
    end

    result
  end

  def error_messages
    @errors.join(', ')
  end

  private

  def valid?
    @errors = []
    @errors << ['Ibiza non configuré sur le dossier'] unless @user.uses?(:ibiza)
    @errors << ['Paramètre analytiques non configurées sur le dossier'] unless @user.uses_ibiza_analytics?
    @errors.empty?
  end

  def fetch_ibiza_analytic(xml_data)
  end

  def client
    @client ||= @user.organization.ibiza.first_client
  end
end