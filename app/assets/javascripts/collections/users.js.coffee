class Idocus.Collections.Users extends Backbone.Collection

  url: 'customers.json?sort=code&direction=asc'
  model: Idocus.Models.User