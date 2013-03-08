class Idocus.Collections.Users extends Backbone.Collection

  url: 'customers.json'
  model: Idocus.Models.User

  comparator: (user) ->
    user.get("code")

  strategies:
    asc:
      code: (user) ->
        user.get("code")
    desc:
      code: (user) ->
        @negative_string user.get("code")

  negative_string: (string) ->
    str = string
    str = str.toLowerCase()
    str = str.split("")
    str = _.map str, (letter) ->
      String.fromCharCode(-(letter.charCodeAt(0)))
    str

  changeSort: (sortProperty, sortDirection) ->
    @comparator = @strategies[sortDirection][sortProperty]