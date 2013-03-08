class Idocus.Views.Account.Journals.Index extends Backbone.View

  template: JST['account/journals/index']

  events:
    'keypress #main-search': 'filterMainBoard'
    'click #main-remove': 'removeMainFilter'
    'keypress #second-search': 'filterSecondBoard'
    'click #second-remove': 'removeSecondFilter'
    'click #journals_list .sort i': 'jSort'
    'click #users_list .sort i': 'uSort'
    'mouseenter #journals_list .sort td': 'showJSortDirection'
    'mouseleave #journals_list .sort td': 'hideJSortDirection'

  initialize: ->
    @jSortDirection = 'desc'
    @jSortColumn = 'is_default'

    @uSortDirection = 'asc'
    @uSortColumn = 'code'

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

    _.bindAll(this, "stopLoading")
    Idocus.vent.bind("stopLoading", @stopLoading)

    @jCollection = new Idocus.Collections.Journals()
    @uCollection = new Idocus.Collections.Users()
    @jCollection.on 'reset', @setJCollection, this
    @uCollection.on 'reset', @setUCollection, this
    @jCollection.fetch()
    @uCollection.fetch()

  render: ->
    @$el.html(@template(jSortDirection: @jSortDirection, jSortColumn: @jSortColumn))
    this

  jSort: (e) ->
    previousSortColumn = @jSortColumn
    if $(e.target).parents('td').hasClass('is_default')
      @jSortColumn = 'is_default'
    else if $(e.target).parents('td').hasClass('name')
      @jSortColumn = 'name'

    @$el.find('#journals_list .sort .asc, #journals_list .sort .desc').addClass('hide')
    if previousSortColumn != @jSortColumn || @jSortDirection == 'desc'
      @$el.find('#journals_list .sort .'+@jSortColumn+' .asc').removeClass('hide')
      @jSortDirection = 'asc'
    else if @jSortDirection == 'asc'
      @$el.find('#journals_list .sort .'+@jSortColumn+' .desc').removeClass('hide')
      @jSortDirection = 'desc'

    @jCollection.changeSort(@jSortColumn, @jSortDirection)
    @jCollection.sort()

    @filterMainBoard()

  uSort: ->
    @$el.find('#users_list .sort .asc, #users_list .sort .desc').addClass('hide')
    if @uSortDirection == 'desc'
      @$el.find('#users_list .sort .'+@uSortColumn+' .asc').removeClass('hide')
      @uSortDirection = 'asc'
    else
      @$el.find('#users_list .sort .'+@uSortColumn+' .desc').removeClass('hide')
      @uSortDirection = 'desc'

    @uCollection.changeSort(@uSortColumn, @uSortDirection)
    @uCollection.sort()

    @filterMainBoard()

  showJSortDirection: (e) ->
    unless $(e.target).hasClass(@jSortColumn)
      $(e.target).find('i.asc').removeClass('hide')

  hideJSortDirection: (e) ->
    unless $(e.target).hasClass(@jSortColumn)
      $(e.target).find('i').addClass('hide')

  cleanJView: ->
    @stopJournalsLoading()
    $('#journals_list tbody').html('')
    this

  startJournalsLoading: ->
    $('.journals.loading').attr('src','/assets/application/spinner_gray_alpha.gif')
    this

  stopJournalsLoading: ->
    $('.journals.loading').attr('src','/assets/application/spinner_stopped_gray_alpha.gif')
    this

  setJCollection: (collection)->
    @cleanJView()
    if collection != undefined
      collection.forEach(@addOneJ, this)
    else
      @jCollection.forEach(@addOneJ, this)
    this

  addOneJ: (item) ->
    view = new Idocus.Views.Account.Journals.Journal(model: item)
    $('#journals_list tbody').append(view.render().el)
    this

  cleanUView: ->
    @stopUsersLoading()
    $('#users_list tbody').html('')
    this

  startUsersLoading: ->
    $('.users.loading').attr('src','/assets/application/spinner_gray_alpha.gif')
    this

  stopUsersLoading: ->
    $('.users.loading').attr('src','/assets/application/spinner_stopped_gray_alpha.gif')
    this

  setUCollection: (collection)->
    @cleanUView()
    if collection != undefined
      collection.forEach(@addOneU, this)
    else
      @uCollection.forEach(@addOneU, this)
    this

  addOneU: (item) ->
    view = new Idocus.Views.Account.Journals.User(model: item)
    $('#users_list tbody').append(view.render().el)
    this

  clean: ->
    $('h3.assigned').text('')
    $('h3.unassigning').text('')
    $('h3.assigning').text('')
    $('h3.not_assigned').text('')
    $('#assigned').html('')
    $('#unassigning').html('')
    $('#assigning').html('')
    $('#not_assigned').html('')
    this

  stopLoading: ->
    @stopJournalsLoading()
    @stopUsersLoading()
    this

  showUsersList: (model) ->
    @current_model_name = 'Journal'
    @clean()
    @journal = model
    id = model.get('id')
    $('#journals_list tr.current, #users_list tr.current').removeClass('current')
    $('#journal_'+id).parents('tr').addClass('current')

    $('h3.assigned').text("Journal #{@journal.get('name')} affecté aux clients suivants :")
    $('h3.unassigning').text("Journal #{@journal.get('name')} retiré des clients suivants (en attente de validation) :")
    $('h3.assigning').text("Journal #{@journal.get('name')} affecté aux clients suivants (en attente de validation) :")
    $('h3.not_assigned').text("Journal #{@journal.get('name')} non affecté aux clients suivants :")

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
    this

  addUser: (model) ->
    @startJournalsLoading()
    new_account_book_type_ids = _.union(model.get('requested_account_book_type_ids'), [@journal.get('id')])
    model.set(requested_account_book_type_ids: new_account_book_type_ids)

    new_client_ids = _.union(@journal.get('requested_client_ids'), [model.get('id')])
    @journal.set(requested_client_ids: new_client_ids)

    @showUsersList(@journal)
    @journal.update_requested_users()

    false

  removeUser: (model) ->
    @startJournalsLoading()
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
    $('#journals_list tr.current, #users_list tr.current').removeClass('current')
    $('#user_'+id).parents('tr').addClass('current')

    $('h3.assigned').text("Client #{@user.get('code')} affecté aux journaux suivants :")
    $('h3.unassigning').text("Client #{@user.get('code')} retiré des journaux suivants (en attente de validation) :")
    $('h3.assigning').text("Client #{@user.get('code')} affecté aux journaux suivants (en attente de validation) :")
    $('h3.not_assigned').text("Client #{@user.get('code')} non affecté aux journaux suivants :")

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
    this

  addJournal: (model) ->
    @startUsersLoading()
    new_client_ids = _.union(model.get('requested_client_ids'), [@user.get('id')])
    model.set(requested_client_ids: new_client_ids)

    new_account_book_type_ids = _.union(@user.get('requested_account_book_type_ids'), [model.get('id')])
    @user.set(requested_account_book_type_ids: new_account_book_type_ids)

    @showJournalsList(@user)
    model.update_requested_users()

    false

  removeJournal: (model) ->
    @startUsersLoading()
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
      jCollection = @jCollection
      uCollection = @uCollection
      if filter.length > 0
        jCollection = _.filter @jCollection.models, (e) ->
          pattern = new RegExp(filter, 'gi')
          name = "#{e.get('name')} #{e.get('description')}"
          return pattern.test(name)

        uCollection = _.filter @uCollection.models, (e) ->
          pattern = new RegExp(filter, 'gi')
          name = "#{e.get('code')} #{e.get('first_name')} #{e.get('last_name')} #{e.get('company')}"
          return pattern.test(name)
      @setJCollection(jCollection)
      @setUCollection(uCollection)
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
    this

  removeSecondFilter: ->
    $('#second-search').val('')
    @filterSecondBoard()