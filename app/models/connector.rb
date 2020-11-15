# -*- encoding : UTF-8 -*-
class Connector < ApplicationRecord
  audited

  has_many :retrievers

  serialize :capabilities, Array
  serialize :apis, Array
  serialize :active_apis, Array
  serialize :combined_fields, Hash
  serialize :urls, Array

  # field 'fiduceo_ref' contains real id or the name of one field inside combined_fields

  # example of field 'combined_fields'
  # {
  #   login: {
  #      label:        'Identifiant',
  #      type:         'text',
  #      regex:        '...',
  #      budgea_name:  'login',
  #      fiduceo_name: 'login'
  #    },
  #   password: {
  #      label:        'Mot de passe',
  #      type:         'password',
  #      regex:        '...',
  #      budgea_name:  'password',
  #      fiduceo_name: 'pass'
  #    },
  #   website: {
  #      label: 'Type de compte',
  #      type:  'list',
  #      regex: nil,
  #      budgea_name:  'website',
  #      fiduceo_name: nil,
  #      values: [
  #        { 'value' => 'par', label: 'Particuliers',   fiduceo_id: 'xxx' },
  #        { 'value' => 'pro', label: 'Professionnels', fiduceo_id: 'yyy' },
  #        { 'value' => 'ent', label: 'Entreprises',    fiduceo_id: 'zzz' }
  #      ]
  #    },
  # ...
  # }.stringify_keys

  validates_presence_of :name, :capabilities, :apis, :active_apis
  validates_presence_of :combined_fields, unless: Proc.new { |c| 'idocus'.in?(c.apis) }
  validates_presence_of :budgea_id,   if: Proc.new { |c| c.fiduceo_ref.nil? && !'idocus'.in?(c.apis) }
  validates_presence_of :fiduceo_ref, if: Proc.new { |c| c.budgea_id.nil? && !'idocus'.in?(c.apis) }
  validates_inclusion_of :capabilities, in: [['document'], ['bank'], ['document', 'bank'], ['bank', 'document']]
  validates_inclusion_of :apis,         in: [['budgea'], ['fiduceo'], ['budgea', 'fiduceo'], ['fiduceo', 'budgea'], ['idocus'], ['idocus', 'budgea']]
  validates_inclusion_of :active_apis,  in: [['budgea'], ['fiduceo'], ['budgea', 'fiduceo'], ['fiduceo', 'budgea'], ['idocus'], ['idocus', 'budgea']]

  scope :idocus,              -> { where("apis LIKE '%idocus%'") }
  scope :budgea,              -> { where("apis LIKE '%budgea%'") }
  scope :fiduceo,             -> { where("apis LIKE '%fiduceo%'") }
  scope :budgea_and_fiduceo,  -> { where("apis LIKE '%budgea%' AND apis LIKE '%fiduceo%'") }
  scope :providers,           -> { where("capabilities LIKE '%document%'") }
  scope :banks,               -> { where("capabilities LIKE '%bank%'") }
  scope :providers_and_banks, -> { where("capabilities LIKE '%bank%' AND capabilities LIKE '%document%'") }

  def self.list
    relation.map(&:public_attributes)
  end

  def fiduceo_id(value=nil)
    if value && fiduceo_ref.match(/param/)
      fields[fiduceo_ref]['values'][value]['fiduceo_id']
    else
      fiduceo_ref
    end
  end

  def is_idocus_active?
    active_apis.include? 'idocus'
  end

  def is_budgea_active?
    active_apis.include? 'budgea'
  end

  def is_fiduceo_active?
    active_apis.include? 'fiduceo'
  end

  def budgea_connector
    BudgeaConnector.find(budgea_id)
  end

  def fiduceo_connector(value=nil)
    FiduceoConnector.find(fiduceo_id(value))
  end

  def public_fields
    hsh = {}
    combined_fields.each do |key, field|
      hsh[key] = field.slice(:name, :label, :type, :values)
    end
    hsh
  end

  def public_attributes
    {
      id:           id.to_s,
      name:         name,
      capabilities: capabilities,
      fields:       public_fields,
      urls:         urls
    }
  end

  def provider?
    capabilities == ['document']
  end

  def bank?
    capabilities == ['bank']
  end

  def provider_and_bank?
    capabilities.include?('bank') && capabilities.include?('document')
  end
end
