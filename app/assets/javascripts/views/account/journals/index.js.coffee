class Idocus.Views.Account.Journals.Index extends Backbone.View

  template: JST['account/journals/index']

  events:
    'click #assignation_tab a': 'reinit'
    'keypress #main-search': 'filterMainBoard'
    'keypress #main-user-search': 'filterMainUserBoard'
    'click #main-remove': 'removeMainFilter'
    'click #main-user-remove': 'removeMainUserFilter'
    'keypress #second-search': 'filterSecondBoard'
    'click #second-remove': 'removeSecondFilter'
    'click #journals_list .sort i': 'jSort'
    'click #users_list .sort i': 'uSort'
    'mouseenter #journals_list .sort td': 'showJSortDirection'
    'mouseleave #journals_list .sort td': 'hideJSortDirection'
    'click #show_details': 'toggleShowDetails'
    'click #show_not_editable': 'toggleShowNotEditable'

  initialize: ->
    @jSortDirection = 'desc'
    @jSortColumn = 'is_default'

    @uSortDirection = 'asc'
    @uSortColumn = 'code'

    @showDetails = true
    @showNotEditable = true

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
    this

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
    this

  hideJSortDirection: (e) ->
    unless $(e.target).hasClass(@jSortColumn)
      $(e.target).find('i').addClass('hide')
    this

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
    @selectItem()
    this

  addOneJ: (item) ->
    view = new Idocus.Views.Account.Journals.Journal(model: item, showDetails: @showDetails)
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
    @selectItem()
    this

  addOneU: (item) ->
    if item.get('is_editable') || @showNotEditable
      view = new Idocus.Views.Account.Journals.User(model: item)
      $('#users_list tbody').append(view.render().el)
    this

  selectItem: ->
    if @current_model_name == 'Journal'
      id = '#journal_' + @journal.get('id')
      $tr = $(id).parents('tr')
      $tr.addClass('current')
      $tr.find('input[type=radio]').attr('checked','checked')
      @showUsersList(@journal)
    else if @current_model_name == 'User'
      id = '#user_' + @user.get('id')
      $tr = $(id).parents('tr')
      $tr.addClass('current')
      $tr.find('input[type=radio]').attr('checked','checked')
      @showJournalsList(@user)
    this

  clean: ->
    $('input[type=radio]').removeAttr('checked')
    $('#journals_list tr.current, #users_list tr.current').removeClass('current')
    @cleanSecondBoard()
    this

  cleanSecondBoard: ->
    $('h3.assigned').text('')
    $('h3.not_assigned').text('')
    $('#assigned').html('')
    $('#not_assigned').html('')
    this

  stopLoading: ->
    @stopJournalsLoading()
    @stopUsersLoading()
    this

  showUsersList: (model) ->
    @current_model_name = 'Journal'
    @journal = model
    id = model.get('id')
    @cleanSecondBoard()

    collection
    filter = $('#second-search').val()
    if filter.length > 0
      collection = _.filter @uCollection.models, (e)->
        pattern = new RegExp(filter, 'gi')
        name = "#{e.get('code')} #{e.get('first_name')} #{e.get('last_name')} #{e.get('company')}"
        return pattern.test(name)
    else
      collection = @uCollection

    showNotEditable = @showNotEditable
    assignedCount = 0
    notAssignedCount = 0
    collection.forEach (user) ->
      if user.get('is_editable') || showNotEditable
        name = 'not_assigned'
        isUp = true
        isWaiting = false
        isIncluded = user.get('account_book_type_ids').some (e, i, a) -> return e == id
        isIncludedInRequested = user.get('requested_account_book_type_ids').some (e, i, a) -> return e == id
        if isIncludedInRequested
          name = 'assigned'
          isUp = false
          assignedCount += 1
        else
          notAssignedCount += 1
        if isIncluded != isIncludedInRequested
          isWaiting = true

        view = new Idocus.Views.Account.Journals.User2(model: user, isUp: isUp, type: name, isWaiting: isWaiting)
        $('#'+name).append(view.render().el)

    $('h3.assigned').text("Journal #{@journal.get('name')} affecté aux clients suivants (#{assignedCount}) :")
    $('h3.not_assigned').text("Journal #{@journal.get('name')} non affecté aux clients suivants (#{notAssignedCount}) :")
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
    @cleanSecondBoard()
    @user = model
    id = model.get('id')
    $('#user_'+id).parents('tr').addClass('current')

    collection
    filter = $('#second-search').val()
    if filter.length > 0
      collection = _.filter @jCollection.models, (e)->
        pattern = new RegExp(filter, 'gi')
        name = "#{e.get('name')} #{e.get('description')}"
        return pattern.test(name)
    else
      collection = @jCollection

    showDetails = @showDetails
    assignedCount = 0
    notAssignedCount = 0
    isAssignmentLocked = !@user.get('is_editable')
    collection.forEach (journal) ->
      name = 'not_assigned'
      isUp = true
      isWaiting = false
      isIncluded = journal.get('client_ids').some (e, i, a) -> return e == id
      isIncludedInRequested = journal.get('requested_client_ids').some (e, i, a) -> return e == id
      if isIncludedInRequested
        name = 'assigned'
        isUp = false
        assignedCount += 1
      else
        notAssignedCount += 1
      if isIncluded != isIncludedInRequested
        isWaiting = true

      view = new Idocus.Views.Account.Journals.Journal2(model: journal, is_up: isUp, type: name, showDetails: showDetails, isWaiting: isWaiting, isAssignmentLocked: isAssignmentLocked)
      $('#'+name).append(view.render().el)

    $('h3.assigned').text("Client #{@user.get('code')} affecté aux journaux suivants (#{assignedCount}) :")
    $('h3.not_assigned').text("Client #{@user.get('code')} non affecté aux journaux suivants (#{notAssignedCount}):")
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

  mainFilter: ->
    filter = $('#main-search').val()
    jCollection = @jCollection
    if filter.length > 0
      jCollection = _.filter @jCollection.models, (e) ->
        pattern = new RegExp(filter, 'gi')
        name = "#{e.get('name')} #{e.get('description')}"
        return pattern.test(name)
    @setJCollection(jCollection)
    this

  filterMainBoard: (e)->
    if e == undefined || (e != undefined && e.keyCode == 13)
      @mainFilter()
      @unSelect()
    this

  removeMainFilter: ->
    $('#main-search').val('')
    @filterMainBoard()
    this

  mainUserFilter: ->
    filter = $('#main-user-search').val()
    uCollection = @uCollection
    if filter.length > 0
      uCollection = _.filter @uCollection.models, (e) ->
        pattern = new RegExp(filter, 'gi')
        name = "#{e.get('code')} #{e.get('first_name')} #{e.get('last_name')} #{e.get('company')}"
        return pattern.test(name)
    @setUCollection(uCollection)
    this

  filterMainUserBoard: (e)->
    if e == undefined || (e != undefined && e.keyCode == 13)
      @mainUserFilter()
      @unSelect()
    this

  removeMainUserFilter: ->
    $('#main-user-search').val('')
    @filterMainUserBoard()
    this

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
    this

  reinit: ->
    $('#main-search').val('')
    $('#main-user-search').val('')
    @filterMainBoard()
    @filterMainUserBoard()
    @unSelect()
    this

  unSelect: ->
    @current_model_name = undefined
    @model = undefined
    $selector = $('input[type=radio]')
    $selector.removeAttr('checked')
    $selector.parents('tr').removeClass('current')
    $('#second-search').val('')
    @cleanSecondBoard()
    this

  toggleShowDetails: ->
    if @showDetails
      @showDetails = false
    else
      @showDetails = true
    @mainFilter()
    @mainUserFilter()
    this

  toggleShowNotEditable: ->
    if @showNotEditable
      @showNotEditable = false
    else
      @showNotEditable = true
    @mainFilter()
    @mainUserFilter()
    this