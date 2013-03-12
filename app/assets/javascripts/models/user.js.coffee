class Idocus.Models.User extends Backbone.Model

  urlRoot: 'customers'

  unassigningJournals: ->
    _.difference(@get('account_book_type_ids'), @get('requested_account_book_type_ids'))

  assigningJournals: ->
    _.difference(@get('requested_account_book_type_ids'), @get('account_book_type_ids'))

  requestType: ->
    if @get('request_type') != 'adding' && @get('request_type') != 'removing'
      if @assigningJournals().length > 0 || @unassigningJournals().length > 0
        'updating'
      else
        ''
    else
      @get('request_type')