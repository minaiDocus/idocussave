# -*- encoding : UTF-8 -*-
class Composition < ApplicationRecord
  belongs_to :user

  serialize :document_ids, Array

  def self.create_with_documents(options = {})
    name = options.delete(:name) || 'Undefined'

    name = 'Undefined'.pdf if name == ''

    user_id      = options.delete(:user_id)
    document_ids = options.delete(:document_ids)

    user = User.find user_id
    user = Collaborator.new(user) if user.collaborator?

    accounts = [user] + user.accounts
    documents = Pack::Piece.find(document_ids).select do |document|
      document.user == accounts || (user.collaborator? && user.customers.include?(document.user)) || user.is_admin
    end.sort_by do |x|
      document_ids.index(x.id.to_s)
    end

    if documents.any?
      temp_files = []
      temp_paths = []

      documents.each do |document|
        temp_file = open(document.cloud_content_object.path)
        temp_files << temp_file
        temp_paths << File.expand_path(temp_file.path)
      end

      composition = Composition.where(user_id: user_id).first
      composition = Composition.create(user_id: user_id) unless composition

      cmd = "cd #{Rails.root}/files/compositions && mkdir -p #{composition.id}"
      system(cmd)
      cmd = "cd #{Rails.root}/files/compositions/#{composition.id} && rm *.pdf"
      system(cmd)

      combined_name = "#{Rails.root}/files/compositions/#{composition.id}/#{name}.pdf"
      cmd = "#{Pdftk.config[:exe_path]} #{temp_paths.join(' ')} output #{combined_name}"

      Rails.logger.debug("Will compose new document with #{cmd}")
      system(cmd)

      composition.name = name
      composition.path = combined_name
      composition.document_ids = document_ids

      composition.save
    end
  end
end
