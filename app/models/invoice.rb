# -*- encoding : UTF-8 -*-
class Invoice < ApplicationRecord
  has_one_attached :cloud_content
  
  has_attached_file :content,
                            styles: {
                              thumb: ['46x67>', :png]
                            },
                            path: ':rails_root/files/:rails_env/:class/:attachment/:id/:style/:filename',
                            url: '/account/invoices/:id/download/:style'
  do_not_validate_attachment_file_type :content


  validates_presence_of   :number
  validates_uniqueness_of :number


  before_validation :set_number


  belongs_to :organization, optional: true
  # INFO : keeping those 3 relations for backward compatibility
  belongs_to :user, optional: true
  belongs_to :period, optional: true
  belongs_to :subscription, optional: true


  def self.search(contains)
    invoices = Invoice.all.includes(:organization, :user)

    invoices = invoices.where("number LIKE ?", "%#{contains[:number]}%") unless contains[:number].blank?

    if contains[:amount_in_cents_w_vat].present?
      comparison_operator = contains[:amount_in_cents_w_vat_comparison_operator]
      if comparison_operator.in?(%w(= <= >=))
        invoices = invoices.where("amount_in_cents_w_vat #{comparison_operator} ?", contains[:amount_in_cents_w_vat])
      end
    end

    if contains[:user_contains] && contains[:user_contains][:code].present?
      user = User.where(code: contains[:user_contains][:code]).first

      invoices = invoices.where(user_id: user.id) if user
    end

    if contains[:organization_contains] && contains[:organization_contains][:name].present?
      organizations = Organization.where("name LIKE ?", "%#{contains[:organization_contains][:name]}%")

      invoices = invoices.where(organization_id: organizations.pluck(:id))
    end


    if contains[:created_at]
      contains[:created_at].each do |operator, value|
        invoices = invoices.where("created_at #{operator} ?", value) if operator.in?(['>=', '<='])
      end
    end

    invoices
  end


  def self.archive(time = Time.now)
    invoices   = Invoice.where("created_at >= ? AND created_at <= ?", time.beginning_of_month, time.end_of_month)
    file_path  = archive_path archive_name(time - 1.month)
    files_path = invoices.map { |e| e.content.path }

    DocumentTools.archive(file_path, files_path)
  end


  def self.archive_name(time = Time.now)
    "invoices_#{time.strftime('%Y%m')}.zip"
  end


  def self.archive_path(file_name)
    _file_name = File.basename file_name

    File.join Rails.root, 'files', Rails.env, 'archives', 'invoices', _file_name
  end

  private


  def set_number
    unless number
      prefix = 1.month.ago.strftime('%Y%m')
      txt = DbaSequence.next('invoice_' + prefix)
      self.number = prefix + ('%0.4d' % txt)
    end
  end
end
