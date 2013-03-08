class Idocus.Collections.Journals extends Backbone.Collection

  url: 'journals.json'
  model: Idocus.Models.Journal

  comparator: (journal) ->
    !journal.get("is_default")

  strategies:
    asc:
      name: (journal) ->
        journal.get("name")
      is_default: (journal) ->
        journal.get("is_default")
    desc:
      name: (journal) ->
        @negative_string journal.get("name")
      is_default: (journal) ->
        !journal.get("is_default")

  negative_string: (string) ->
    str = string
    str = str.toLowerCase()
    str = str.split("")
    str = _.map str, (letter) ->
      String.fromCharCode(-(letter.charCodeAt(0)))
    str

  changeSort: (sortProperty, sortDirection) ->
    @comparator = @strategies[sortDirection][sortProperty]