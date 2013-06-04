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
  @preseizures.count
end

node :description_keys do
  description_keys(@user.organization.ibiza)
end

node :description_separator do
  @user.organization.ibiza.try(:description_separator) || Ibiza.fields['description_separator'].options[:default]
end