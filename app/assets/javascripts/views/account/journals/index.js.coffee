class Idocus.Views.Account.Journals.Index extends Backbone.View

  template: JST['account/journals/index']

  events:
    'keypress #main-search': 'filterMainBoard'
    'click #main-remove': 'removeMainFilter'
    'keypress #second-search': 'filterSecondBoard'
    'click #second-remove': 'removeSecondFilter'

  initialize: ->
    _.bindAll(this, "showUsersList")
    Idocus.vent.bind("showUsersList", @showUsersList)
    _.bindAll(this, "addUser")
    Idocus.vent.bind("addUser", @addUser)
    _.bindAll(this, "removeUser")
    Idocus.vent.bind("removeUser", @removeUser)

    _.bindAll(this, "showJournalsList")
    Idocus.vent.bind("showJournalsList", @showJournalsList)
    _.bindAll(this, "addJournal")
    Idocus.vent.bind("addJournal", @addJournal)
    _.bindAll(this, "removeJournal")
    Idocus.vent.bind("removeJournal", @removeJournal)

    @jCollection = new Idocus.Collections.Journals()
    @uCollection = new Idocus.Collections.Users()
    @jCollection.on 'reset', @setJCollection, this
    @uCollection.on 'reset', @setUCollection, this
    @jCollection.fetch()
    @uCollection.fetch()
    window.uc = @uCollection
    window.jc = @jCollection

  render: ->
    @$el.html(@template)
    this

  cleanJView: ->
    $('#journals_list').html('')

  setJCollection: (collection)->
    @cleanJView()
    if collection != undefined
      collection.forEach(@addOneJ, this)
    else
      @jCollection.forEach(@addOneJ, this)

  addOneJ: (item) ->
    view = new Idocus.Views.Account.Journals.Journal(model: item)
    $('#journals_list').append(view.render().el)


  cleanUView: ->
    $('#users_list').html('')

  setUCollection: (collection)->
    @cleanUView()
    if collection != undefined
      collection.forEach(@addOneU, this)
    else
      @uCollection.forEach(@addOneU, this)

  addOneU: (item) ->
    view = new Idocus.Views.Account.Journals.User(model: item)
    $('#users_list').append(view.render().el)

  clean: ->
    $('#assigned').html('')
    $('#unassigning').html('')
    $('#assigning').html('')
    $('#not_assigned').html('')

  showUsersList: (model) ->
    @current_model_name = 'Journal'
    @clean()
    @journal = model
    id = model.get('id')
    $('#journals_list li a.assign, #users_list li a.assign').removeClass('label')
    $('#journal_'+id).addClass('label')

    collection
    filter = $('#second-search').val()
    if filter.length > 0
      collection = _.filter @uCollection.models, (e)->
        pattern = new RegExp(filter, 'gi')
        name = "#{e.get('code')} #{e.get('first_name')} #{e.get('last_name')} #{e.get('company')}"
        return pattern.test(name)
    else
      collection = @uCollection

    collection.forEach (user) ->
      name = 'not_assigned'
      is_up = true
      is_include = user.get('account_book_type_ids').some (e, i, a) -> return e == id
      is_include2 = user.get('requested_account_book_type_ids').some (e, i, a) -> return e == id
      if is_include && is_include2
        name = 'assigned'
        is_up = false
      else
        diff = _.difference(user.get('account_book_type_ids'),user.get('requested_account_book_type_ids'))
        is_include = diff.some (e, i, a) -> return e == id
        if is_include
          name = 'unassigning'
          is_up = true
        else
          diff = _.difference(user.get('requested_account_book_type_ids'),user.get('account_book_type_ids'))
          is_include = diff.some (e, i, a) -> return e == id
          if is_include
            name = 'assigning'
            is_up = false

      view = new Idocus.Views.Account.Journals.User2(model: user, is_up: is_up, type: name)
      $('#'+name).append(view.render().el)

  addUser: (model) ->
    new_account_book_type_ids = _.union(model.get('requested_account_book_type_ids'), [@journal.get('id')])
    model.set(requested_account_book_type_ids: new_account_book_type_ids)

    new_client_ids = _.union(@journal.get('requested_client_ids'), [model.get('id')])
    @journal.set(requested_client_ids: new_client_ids)

    @showUsersList(@journal)
    @journal.update_requested_users()

    false
  removeUser: (model) ->
    new_account_book_type_ids = _.without(model.get('requested_account_book_type_ids'), @journal.get('id'))
    model.set(requested_account_book_type_ids: new_account_book_type_ids)

    new_client_ids = _.without(@journal.get('requested_client_ids'), model.get('id'))
    @journal.set(requested_client_ids: new_client_ids)

    @showUsersList(@journal)
    @journal.update_requested_users()

    false

  showJournalsList: (model) ->
    @current_model_name = 'User'
    @clean()
    @user = model
    id = model.get('id')
    $('#journals_list li a.assign, #users_list li a.assign').removeClass('label')
    $('#user_'+id).addClass('label')

    collection
    filter = $('#second-search').val()
    if filter.length > 0
      collection = _.filter @jCollection.models, (e)->
        pattern = new RegExp(filter, 'gi')
        name = "#{e.get('name')} #{e.get('description')}"
        return pattern.test(name)
    else
      collection = @jCollection

    collection.forEach (journal) ->
      name = 'not_assigned'
      is_up = true
      is_include = journal.get('client_ids').some (e, i, a) -> return e == id
      is_include2 = journal.get('requested_client_ids').some (e, i, a) -> return e == id
      if is_include && is_include2
        name = 'assigned'
        is_up = false
      else
        diff = _.difference(journal.get('client_ids'),journal.get('requested_client_ids'))
        is_include = diff.some (e, i, a) -> return e == id
        if is_include
          name = 'unassigning'
          is_up = true
        else
          diff = _.difference(journal.get('requested_client_ids'),journal.get('client_ids'))
          is_include = diff.some (e, i, a) -> return e == id
          if is_include
            name = 'assigning'
            is_up = false

      view = new Idocus.Views.Account.Journals.Journal2(model: journal, is_up: is_up, type: name)
      $('#'+name).append(view.render().el)

  addJournal: (model) ->
    new_client_ids = _.union(model.get('requested_client_ids'), [@user.get('id')])
    model.set(requested_client_ids: new_client_ids)

    new_account_book_type_ids = _.union(@user.get('requested_account_book_type_ids'), [model.get('id')])
    @user.set(requested_account_book_type_ids: new_account_book_type_ids)

    @showJournalsList(@user)
    model.update_requested_users()

    false
  removeJournal: (model) ->
    new_client_ids = _.without(model.get('requested_client_ids'), @user.get('id'))
    model.set(requested_client_ids: new_client_ids)

    new_account_book_type_ids = _.without(@user.get('requested_account_book_type_ids'), model.get('id'))
    @user.set(requested_account_book_type_ids: new_account_book_type_ids)

    @showJournalsList(@user)
    model.update_requested_users()

    false

  filterMainBoard: (e)->
    if e == undefined || (e != undefined && e.keyCode == 13)
      filter = $('#main-search').val()
      if filter.length > 0
        collection = _.filter @jCollection.models, (e)->
          pattern = new RegExp(filter, 'gi')
          name = "#{e.get('name')} #{e.get('description')}"
          return pattern.test(name)
        @setJCollection(collection)

        collection = _.filter @uCollection.models, (e)->
          pattern = new RegExp(filter, 'gi')
          name = "#{e.get('code')} #{e.get('first_name')} #{e.get('last_name')} #{e.get('company')}"
          return pattern.test(name)
        @setUCollection(collection)
      else
        @setJCollection()
        @setUCollection()
      @clean()
      
  removeMainFilter: ->
    $('#main-search').val('')
    @filterMainBoard()

  filterSecondBoard: (e)->
    if e == undefined || (e != undefined && e.keyCode == 13)
      if @current_model_name == 'Journal'
        @showUsersList(@journal)
      else if @current_model_name == 'User'
        @showJournalsList(@user)

  removeSecondFilter: ->
    $('#second-search').val('')
    @filterSecondBoard()

#  sync: (method, model, options) ->
#    data = JSON.stringify model.toJSON()
#    if (method == "create" || method == "update")
#      json = model.attributes
#      json = _.extend json, {tags_attributes: model.tags.toJSON()}
#      data = JSON.stringify json
#
#      options.data = data
#      options.contentType = 'application/json'
#      Backbone.sync method, model, options