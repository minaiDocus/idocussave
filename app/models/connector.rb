# -*- encoding : UTF-8 -*-
class Connector
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :retrievers

  field :name
  field :capabilities
  field :apis
  field :active_apis
  field :budgea_id,   type: Integer
  field :fiduceo_ref  # real id or the name of one field inside combined_fields

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
  #      values: {
  #        par: { label: 'Particuliers',   fiduceo_id: 'xxx' },
  #        pro: { label: 'Professionnels', fiduceo_id: 'yyy' },
  #        ent: { label: 'Entreprises',    fiduceo_id: 'zzz' }
  #      }
  #    },
  # ...
  # }
  field :combined_fields, type: Hash

  validates_presence_of :name, :capabilities, :apis, :active_apis, :combined_fields
  validates_presence_of :budgea_id,   if: Proc.new { |c| c.fiduceo_ref.nil? }
  validates_presence_of :fiduceo_ref, if: Proc.new { |c| c.budgea_id.nil? }
  validates_inclusion_of :capabilities, in: [['document'], ['bank'], ['document', 'bank'], ['bank', 'document']]
  validates_inclusion_of :apis,         in: [['budgea'], ['fiduceo'], ['budgea', 'fiduceo'], ['fiduceo', 'budgea']]
  validates_inclusion_of :active_apis,  in: [['budgea'], ['fiduceo'], ['budgea', 'fiduceo'], ['fiduceo', 'budgea']]

  scope :budgea,              -> { where(apis: 'budgea' ) }
  scope :fiduceo,             -> { where(apis: 'fiduceo' ) }
  scope :budgea_and_fiduceo,  -> { where(:apis.all => ['budgea', 'fiduceo']) }
  scope :providers,           -> { where(capabilities: 'document' ) }
  scope :banks,               -> { where(capabilities: 'bank' ) }
  scope :providers_and_banks, -> { where(:capabilities.all => ['bank', 'document']) }

  def self.list
    criteria.map(&:public_attributes)
  end

  def fiduceo_id(value=nil)
    if value && fiduceo_ref.match(/param/)
      fields[fiduceo_ref]['values'][value]['fiduceo_id']
    else
      fiduceo_ref
    end
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
      if field['type'] == 'list'
        hsh[key]['values'].each do |value|
          value.slice!(:label)
        end
      end
    end
    hsh
  end

  def public_attributes
    {
      id:           id.to_s,
      name:         name,
      capabilities: capabilities,
      fields:       public_fields
    }
  end
end
