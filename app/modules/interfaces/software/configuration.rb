module Interfaces::Software::Configuration
  SOFTWARES = ['ibiza', 'exact_online', 'my_unisoft', 'coala', 'quadratus', 'cegid', 'fec_agiris', 'csv_descriptor']
  TABLE_NAME_WITH_SOFTWARES_USING_API = ['software_ibizas', 'software_exact_online', 'software_my_unisofts']
  SOFTWARES_OBJECTS = [::Software::Ibiza, ::Software::ExactOnline, ::Software::Cegid, ::Software::Coala, ::Software::FecAgiris, ::Software::Quadratus, ::Software::CsvDescriptor, ::Software::MyUnisoft]

  def self.softwares
    {
      ibiza:          Software::Ibiza,
      exact_online:   Software::ExactOnline,
      cegid:          Software::Cegid,
      coala:          Software::Coala,
      fec_agiris:     Software::FecAgiris,
      quadratus:      Software::Quadratus,
      csv_descriptor: Software::CsvDescriptor,
      my_unisoft:     Software::MyUnisoft
    }
  end

  def self.h_softwares
    {
      ibiza:          'ibiza',
      exact_online:   'exact_online',
      my_unisoft:     'my_unisoft',
      coala:          'coala',
      quadratus:      'quadratus',
      cegid:          'cegid',
      fec_agiris:     'fec_agiris',
      csv_descriptor: 'csv_descriptor'
    }.with_indifferent_access
  end

  def self.softwares_table_name
    {
      ibiza:          'software_ibizas',
      exact_online:   'software_exact_online',
      my_unisoft:     'software_my_unisofts',
      coala:          'software_coalas',
      quadratus:      'software_quadratus',
      cegid:          'software_cegids',
      fec_agiris:     'software_fec_agiris',
      csv_descriptor: 'software_csv_descriptors'
    }.with_indifferent_access
  end

  def self.software_object_name
    {
      'Software::Ibiza'         => 'ibiza',
      'Software::ExactOnline'   => 'exact_online',
      'Software::Cegid'         => 'cegid',
      'Software::Coala'         => 'coala',
      'Software::FecAgiris'     => 'fec_agiris',
      'Software::Quadratus'     => 'quadratus',
      'Software::CsvDescriptor' => 'csv_descriptor',
      'Software::MyUnisoft'     => 'my_unisoft'
    }
  end

  def auto_deliver?
    (self.owner.is_a?(User) && auto_deliver == -1) ? self.owner.organization.auto_deliver?(self) : (auto_deliver == 1)
  end

  def used?
    if self.is_a?(Software::Ibiza)
      is_used || access_token.present? || access_token_2.present?
    else
      is_used
    end
  end
end