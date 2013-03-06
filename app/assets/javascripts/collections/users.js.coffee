class Idocus.Collections.Users extends Backbone.Collection

  url: 'customers.json?sort=code'
  model: Idocus.Models.User