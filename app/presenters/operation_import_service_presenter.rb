# -*- encoding : UTF-8 -*-
class OperationImportServicePresenter < BasePresenter
  presents :operation_import_service
  delegate :operations, :errors, to: :operation_import_service

  def service
    operation_import_service
  end


  def message
    h.content_tag :message do
      service.errors.empty? ? success_message : failure_message
    end
  end


  def success_message
    h.content_tag :success, "#{service.operations.size} operation(s) added."
  end


  def failure_message
    h.content_tag :errors do
      service.errors.sum do |error|
        h.content_tag :error, error
      end
    end
  end
end
