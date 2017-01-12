class AddIsCoalaUsedToOrganizations < ActiveRecord::Migration
  def up
    execute('alter table organizations add column is_coala_used boolean default false not null after is_csv_descriptor_used')
  end

  def down
    execute('alter table organizations drop column is_coala_used')
  end
end
