object false

child @preseizures => :items do
  extends 'account/preseizures/show'
end

node :page do
  params[:page] || 1
end

node :per_page do
  params[:per_page] || Kaminari.config.default_per_page
end

node :total do
  @preseizures.try(:total_count) || 0
end

node :description_keys do
  description_keys(@organization.ibiza)
end

node :description_separator do
  @organization.ibiza.try(:description_separator) || ' - '
end
