# TODO : handle failures
class IbizaAnalytic

  def initialize(id, access_token, expires_in=15.minutes)
    @id = id
    @access_token = access_token
    @expires_in = expires_in
  end

  def list
    Rails.cache.fetch ['ibiza_analytics', @id], expires_in: @expires_in do
      client.company(@id).analyzes.complete?

      if client.response.success? && client.response.data.present?
        analytics = []

        client.response.data.each do |data|
          analytic = {
            id:               data['analysisID'],
            name:             data['analysisName'],
            description:      data['analysisDescription'],
            software:         data['software'],
            ventilation_kind: data['ventilationKind']
          }

          [:axis1, :axis2, :axis3].each do |axis|
            if data[axis.to_s].present?
              analytic[axis] = {
                id:       data[axis.to_s],
                name:     data["#{axis}Name"],
                sections: []
              }
            else
              analytic[axis] = nil
            end
          end

          analytics << analytic
        end

        analytics.each do |analytic|
          client.request.clear
          client.company(@id).analyzes(analytic[:id]).sections?
          if client.response.success?
            client.response.data.each do |data|
              axis = [:axis1, :axis2, :axis3].select do |axis_name|
                analytic[axis_name] && analytic[axis_name][:id] == data['axis']
              end.first
              sections = data.dig('analyticalSections', 'analyticalSection')
              sections = [sections] if sections.is_a?(Hash)
              sections.each do |section|
                next if section['closed'].to_i == 1
                analytic[axis][:sections] << { code: section['code'], description: section['description'] || section['code'] }
              end
            end
          end
        end
      end
    end
  end

  def exists?(data)
    return false unless list
    3.times do |e|
      i = (e+1).to_s
      if data[i][:name].present?
        analytic = list.select { |analytic| analytic[:name] == data[i][:name] }.first
        return false unless analytic
        [:axis1, :axis2, :axis3].each do |axis|
          if data[i][axis].present?
            if analytic[axis].present?
              return false unless analytic[axis][:sections].map { |s| s[:code] }.include?(data[i][axis])
            else
              return false
            end
          end
        end
      end
    end
    true
  end

  def self.add_analytic_to_temp_document(analytic, temp_document)
    analytic_reference = AnalyticReference.create(
      a1_name:         analytic['1'][:name].presence,
      a1_ventilation:  analytic['1'][:ventilation].presence,
      a1_axis1:        analytic['1'][:axis1].presence,
      a1_axis2:        analytic['1'][:axis2].presence,
      a1_axis3:        analytic['1'][:axis3].presence,
      a2_name:         analytic['2'][:name].presence,
      a2_ventilation:  analytic['2'][:ventilation].presence,
      a2_axis1:        analytic['2'][:axis1].presence,
      a2_axis2:        analytic['2'][:axis2].presence,
      a2_axis3:        analytic['2'][:axis3].presence,
      a3_name:         analytic['3'][:name].presence,
      a3_ventilation:  analytic['3'][:ventilation].presence,
      a3_axis1:        analytic['3'][:axis1].presence,
      a3_axis2:        analytic['3'][:axis2].presence,
      a3_axis3:        analytic['3'][:axis3].presence
    )
    temp_document.update(analytic_reference: analytic_reference)
  end

  private

  def client
    @client ||= IbizaAPI::Client.new(@access_token)
  end


  class Validator
    def initialize(user, analytic)
      @user = user
      @analytic = analytic
      check_params_analytic
    end

    def analytic_params_present?
      @params_exist && @params_valid
    end

    def valid_analytic_presence?
      if analytic_params_present?
        IbizaAnalytic.new(@user.ibiza_id, @user.organization.ibiza.access_token).exists?(@analytic)
      elsif !@params_valid
        false
      else
        true
      end
    end

    def valid_analytic_ventilation?
      if analytic_params_present?
        total_ventilation = 0

        3.times do |e|
          i = (e+1).to_s
          analytic_exist = @analytic.try(:[], i).try(:[], :name).present? && (@analytic[i][:axis1].present? || @analytic[i][:axis2].present? || @analytic[i][:axis3].present?)

          total_ventilation += @analytic[i][:ventilation].to_f || 0 if analytic_exist

          return false if @analytic[i][:ventilation].to_f == 0 && analytic_exist
        end

        total_ventilation == 100
      elsif !@params_valid
        false
      else
        true
      end
    end

    private

    def check_params_analytic
      @params_valid = true

      3.times do |e|
        i = (e+1).to_s
        @params_exist ||= @analytic.try(:[], i).try(:[], :name).present? && (@analytic[i][:axis1].present? || @analytic[i][:axis2].present? || @analytic[i][:axis3].present?)

        if @analytic.try(:[], i).try(:[], :name).present? && !@analytic[i][:axis1].present? && !@analytic[i][:axis2].present? && !@analytic[i][:axis3].present?
          @params_valid = false
        end
      end
    end

  end
end
