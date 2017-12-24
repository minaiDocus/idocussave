# TODO : handle failures
class IbizaAnalytic
  def initialize(id, access_token)
    @id = id
    @access_token = access_token
  end

  def execute
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
    else
      false
    end
  end

  private

  def client
    @client ||= IbizaAPI::Client.new(@access_token)
  end
end
