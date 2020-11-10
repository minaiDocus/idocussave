# -*- encoding : UTF-8 -*-
class Report::MobileToXls
  def initialize(date)
    @date = date || "#{Date.today.strftime("%Y").to_s}#{Date.today.strftime("%m").to_s}"
  end

  def users_report
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet name: "Reporting Utilisateurs Mobile"

    headers = %w(utilisateur collaborateur email organizations dernière_connexion plateforme documents_téléversés)
    sheet.row(0).replace headers

    mobile_users.each_with_index do |user_connexion, index|
      row_number = index + 1
      user = user_connexion.user

      if user.collaborator?
        user_code = user.memberships.try(:first).try(:code)
        organizations_lists = user.memberships.map{ |member| member.organization.name }.join(' | ')
      else
        user_code = user.code
        organizations_lists = "#{user.company} (#{user.organization.name})"
      end

      cells = [
        user_code,
        user.collaborator? ? 'oui' : 'non',
        user.email,
        organizations_lists,
        user.firebase_tokens.where("platform LIKE '#{user_connexion.platform}%'").order(last_registration_date: :desc).first.try(:last_registration_date),
        user_connexion.platform,
        documents_uploaded_by(user)
      ]

      sheet.row(row_number).replace cells
      sheet.row(row_number).set_format 0, Spreadsheet::Format.new(number_format: 'MMMYY')
    end

    io = StringIO.new('')
    book.write(io)
    io.string
  end

  def documents_report
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet name: "Reporting Documents Mobile"

    headers = %w(code_dossier dossier organization televerser_le televerser_par nom_piece)
    sheet.row(0).replace headers

    mobile_documents.each_with_index do |doc, index|
      row_number = index + 1
      user = doc.user
      piece = doc.piece

      cells = [
        user.code,
        user.company,
        user.organization.name,
        doc.created_at,
        doc.delivered_by,
        piece.name
      ]

      sheet.row(row_number).replace cells
      sheet.row(row_number).set_format 0, Spreadsheet::Format.new(number_format: 'MMMYY')
    end

    io = StringIO.new('')
    book.write(io)
    io.string
  end

  private

  def mobile_users
    @mobile_users ||= MobileConnexion.periode(@date).group(:user_id, :platform).order(:user_id)
  end


  def mobile_documents
    @documents ||= TempDocument.from_mobile.where("DATE_FORMAT(created_at, '%Y%m') = #{@date}")
  end

  def documents_uploaded_by(user)
    if user.collaborator?
      code_lists = user.memberships.map{ |member| "'#{member.code}'" }.join(',')
    else
      code_lists = "'#{user.code}'"
    end

    TempDocument.from_mobile.where("DATE_FORMAT(created_at, '%Y%m') = #{@date} AND delivered_by IN (#{code_lists})").count
  end
end
