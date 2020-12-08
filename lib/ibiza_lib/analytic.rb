# TODO : handle failures
module IbizaLib
  class Analytic

    def initialize(id, access_token, specific_url_options, expires_in=2.minutes)
      @id                   = id
      @access_token         = access_token
      @expires_in           = expires_in
      @specific_url_options = specific_url_options
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
                  next if !analytic.try(:[], axis) || !section || section['closed'].to_i == 1
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

          3.times do |a|
            j = (a+1).to_s
            [:axis1, :axis2, :axis3].each do |axis|
              if data["#{i}#{j}"][axis].present?
                if analytic[axis].present?
                  return false unless analytic[axis][:sections].map { |s| s[:code] }.include?(data["#{i}#{j}"][axis])
                else
                  return false
                end
              end
            end
          end
        end
      end
      true
    end

    class << self
      def analytic_attributes(analytic)
        analytics = {}

        3.times do |e|
          i = (e+1).to_s
          analytics["a#{i}_name"] = analytic[i][:name].presence
          references = []
          3.times do |a|
            j = (a+1).to_s
            references << {
                            ventilation: analytic["#{i}#{j}"][:ventilation].presence,
                            axis1:       analytic["#{i}#{j}"][:axis1].presence,
                            axis2:       analytic["#{i}#{j}"][:axis2].presence,
                            axis3:       analytic["#{i}#{j}"][:axis3].presence,
                          }
          end
          analytics["a#{i}_references"] = references.to_json.to_s
        end

        analytics.with_indifferent_access
      end

      def add_analytic_to_temp_document(analytic, temp_document)
        current_analytic = temp_document.analytic_reference

        if current_analytic
          if current_analytic.is_used_by_other_than?({ temp_documents: [temp_document.id] })
            new_analytic = AnalyticReference.create(analytic_attributes(analytic))
          else
            current_analytic.update_attributes(analytic_attributes(analytic))
            new_analytic = current_analytic
          end
        else
          new_analytic = AnalyticReference.create(analytic_attributes(analytic))
        end

        temp_document.update(analytic_reference: new_analytic)
      end

      def add_analytic_to_journal(analytic, journal)
        journal_analytic = journal.analytic_reference
        if journal_analytic
          journal_analytic.assign_attributes(analytic_attributes(analytic))
          journal_analytic.save
        else
          journal.update(analytic_reference: AnalyticReference.create(analytic_attributes(analytic)))
        end
      end

      def add_analytic_to_pieces(analytic, _pieces)
        pieces = Array(_pieces)
        pieces_ids = pieces.collect(&:id)
        analytic_to_delete = []
        piece_not_modifiable_count = 0

        new_analytic = nil
        new_analytic = AnalyticReference.create(analytic_attributes(analytic)) if analytic.present?

        pieces.each do |pi|
          if pi.preseizures.delivered('ibiza').count.to_i > 0
            piece_not_modifiable_count += 1
            next
          end

          current_analytic = pi.analytic_reference

          if current_analytic && !current_analytic.is_used_by_other_than?({ pieces: pieces_ids })
            analytic_to_delete << current_analytic
          end
          
          pi.update(analytic_reference: new_analytic)
        end

        analytic_to_delete.uniq!
        analytic_to_delete.each(&:destroy)

        piece_not_modifiable_count
      end
    end

    private

    def client
      @client ||= IbizaLib::Api::Client.new(@access_token, @specific_url_options)
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
          IbizaLib::Analytic.new(@user.try(:ibiza).try(:ibiza_id), @user.organization.ibiza.access_token, @user.organization.ibiza.specific_url_options).exists?(@analytic)
        elsif !@params_valid
          false
        else
          true
        end
      end

      def valid_analytic_ventilation?
        if analytic_params_present?
          3.times do |e|
            i = (e+1).to_s
            total_ventilation = 0
            with_analytics = false
            3.times do |a|
              j = (a+1).to_s
              analytic_exist = @analytic.try(:[], i).try(:[], :name).present? && (@analytic.try(:[], "#{i}#{j}").try(:[], :axis1).present? || @analytic.try(:[], "#{i}#{j}").try(:[], :axis2).present? || @analytic.try(:[], "#{i}#{j}").try(:[], :axis3).present?)

              total_ventilation += @analytic["#{i}#{j}"][:ventilation].to_f || 0 if analytic_exist

              with_analytics ||= analytic_exist
              return false if @analytic["#{i}#{j}"][:ventilation].to_f == 0 && analytic_exist
            end
            return false if total_ventilation != 100 && with_analytics
          end
          true
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
          counter_false = 0
          3.times do |a|
            j = (a+1).to_s
            @params_exist ||= @analytic.try(:[], i).try(:[], :name).present? && (@analytic.try(:[], "#{i}#{j}").try(:[], :axis1).present? || @analytic.try(:[], "#{i}#{j}").try(:[], :axis2).present? || @analytic.try(:[], "#{i}#{j}").try(:[], :axis3).present?)

            counter_false += 1 if @analytic.try(:[], i).try(:[], :name).present? && !@analytic.try(:[], "#{i}#{j}").try(:[], :axis1).present? && !@analytic.try(:[], "#{i}#{j}").try(:[], :axis2).present? && !@analytic.try(:[], "#{i}#{j}").try(:[], :axis3).present?
          end
          @params_valid = false if counter_false >= 3
        end
      end

    end
  end
end