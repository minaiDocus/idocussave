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
              data.dig('analyticalSections', 'analyticalSection').each do |section|
                next if section['closed'].to_i != 0
                analytic[axis][:sections] << { code: section['code'], description: section['description'] }
              end
            end
          end
        end
      end
    end
  end

  def valid?(data)
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

  private

  def client
    @client ||= IbizaAPI::Client.new(@access_token)
  end
end
