class Idocus.Routers.PreAssignmentsRouter extends Backbone.Router

  routes:
    '': 'pack_reports'
    'page/:page': 'pack_reports'
    'search/': 'search_pack_reports'
    'search/:query': 'search_pack_reports'
    'search/:query/page/:page': 'search_pack_reports'
    ':packName': 'preseizures'
    ':packName/page/:page': 'preseizures'
    ':packName/:position': 'preseizure_accounts'

  pack_reports: (page) ->
    $('#preseizures .content').html('')
    $('#preseizure_accounts .content').html('')
    if @index == undefined
      @index = new Idocus.Views.PackReportsIndex (el: $('#pack_reports .content'))
      @index.render()
    $(@index.el).find('input[name=pack_reports_search]').val('')
    @index.update(null, page)

  search_pack_reports: (query, page) ->
    $('#preseizures .content').html('')
    $('#preseizure_accounts .content').html('')
    if query == '' || query == undefined
      Backbone.history.navigate('', true)
    else
      if @index == undefined
        @index = new Idocus.Views.PackReportsIndex (el: $('#pack_reports .content'))
        @index.render()
        $(@index.el).find('input[name=pack_reports_search]').val(query)
      @index.update(query, page)

  preseizures: (packName, page) ->
    if @index == undefined
      Backbone.history.navigate('', true)
    else
      $('#preseizure_accounts .content').html('')
      @preseizuresIndex = new Idocus.Views.PreseizuresIndex (el: $('#preseizures .content'), packName: packName, page: page)
      @preseizuresIndex.render()

  preseizure_accounts: (packName, position) ->
    if @index == undefined
      Backbone.history.navigate('', true)
    else
      @preseizureAccountsIndex = new Idocus.Views.PreseizureAccountsIndex (el: $('#preseizure_accounts .content'), packName: packName, position: position)
      @preseizureAccountsIndex.render()
