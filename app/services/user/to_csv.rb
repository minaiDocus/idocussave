# -*- encoding : UTF-8 -*-
# Generates an array from user collection. Array is expected to be used to generate CSV
class User::ToCsv
  def initialize(users)
    @users = users
  end


  def execute
    csv = [
      'Date de création',
      'Organisation',
      'Administrateur',
      'Administrateur de l\'organisation',
      'Collaborateur',
      'Dossier Clôturé',
      'Société',
      'Code',
      'Prénom',
      'Nom',
      'Email'
    ].join(';')

    csv += "\n"

    csv += @users.map do |user|
      [
        I18n.l(user.created_at),
        user.organization.try(:name),
        user.is_admin ? 'Oui' : 'Non',
        user.memberships.admins.present? ? 'Oui' : 'Non',
        user.is_prescriber ? 'Oui' : 'Non',
        user.inactive? ? 'Oui' : 'Non',
        user.company,
        user.code,
        user.first_name,
        user.last_name,
        user.email
      ].join(';')
    end.join("\n")

    csv
  end
end
