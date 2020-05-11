# frozen_string_literal: true

class ReturnLabelsController < PaperProcessesController
  layout false

  # GET /scans/return_labels
  def show
    filepath = ReturnLabels::FILE_PATH

    if File.exist?(filepath)
      filename = File.basename(filepath)

      send_file(filepath, type: 'application/pdf', filename: filename, x_sendfile: true, disposition: 'inline')
    else
      render body: nil, status: 404
    end
  end

  # GET /scans/return_labels/new
  def new
    # @scanned_by = @user.scanning_provider.name if @user || nil 'ppp'
    @scanned_by = 'ppp'

    @return_labels = ReturnLabels.new(scanned_by: @scanned_by, time: @current_time)

    @customers = @return_labels.users.sort_by do |e|
      (e.is_return_label_generated_today? ? '1_' : '0_') + e.code
    end
  end

  # POST /scans/return_labels
  def create
    if params[:return_labels] && params[:return_labels][:customers]
      @return_labels = ReturnLabels.new(params[:return_labels].merge(time: @current_time))
      @return_labels.render_pdf
    end
    redirect_to '/scans/return_labels'
  end
end
