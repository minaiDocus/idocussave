class Idocus.Routers.PreAssignmentsRouter extends Backbone.Router

  routes:
    '': 'pack_reports'
    ':view': 'pack_reports'
    ':view/page/:page': 'pack_reports'

    ':view/search/': 'search_pack_reports'
    ':view/search/:query': 'search_pack_reports'
    ':view/search/:query/page/:page': 'search_pack_reports'

    ':view/:pack_report_id': 'preseizures'
    ':view/:pack_report_id/page/:page': 'preseizures'

    ':view/:pack_report_id/search/:query': 'search_preseizures'
    ':view/:pack_report_id/search/:query/page/:page': 'search_preseizures'

    ':view/:pack_report_id/:preseizure_id': 'preseizure_accounts'

  pack_reports: (view, page) ->
    @view = view || 'all'
    $('#preseizures .content').html('')
    $('#preseizure_accounts .content').html('')
    if @index == undefined
      @index = new Idocus.Views.PackReportsIndex (el: $('#pack_reports .content'), view: @view, query: '')
      @index.render()
    $(@index.el).find('input[name=pack_reports_search]').val('')
    @index.update(@view, null, page)

  search_pack_reports: (view, query, page) ->
    @view = view || 'all'
    $('#preseizures .content').html('')
    $('#preseizure_accounts .content').html('')
    if query == '' || query == undefined
      Backbone.history.navigate("#{@view}", true)
    else
      if @index == undefined
        @index = new Idocus.Views.PackReportsIndex (el: $('#pack_reports .content'))
        @index.render()
        $(@index.el).find('input[name=pack_reports_search]').val(query)
      @index.update(@view, query, page)

  preseizures: (view, pack_report_id, page) ->
    @view = view || 'all'
    if @index == undefined
      Backbone.history.navigate("#{@view}", true)
    else
      $('#preseizure_accounts .content').html('')
      @preseizuresIndex = new Idocus.Views.PreseizuresIndex (el: $('#preseizures .content'), view: @view, query: '', pack_report_id: pack_report_id, page: page)
      @preseizuresIndex.render()

  search_preseizures: (view, pack_report_id, query, page) ->
    @view = view || 'all'
    @query = query || ''
    if @index == undefined
      if @query != '' && @query != undefined
        Backbone.history.navigate("#{@view}/search/{@query}", true)
      else
        Backbone.history.navigate("#{@view}", true)
    else
      $('#preseizure_accounts .content').html('')
      @preseizuresIndex = new Idocus.Views.PreseizuresIndex (el: $('#preseizures .content'), view: @view, query: @query, pack_report_id: pack_report_id, page: page)
      @preseizuresIndex.render()

  preseizure_accounts: (view, pack_report_id, preseizure_id) ->
    @view = view || 'all'
    if @index == undefined
      Backbone.history.navigate("#{@view}", true)
    else
      @preseizureAccountsIndex = new Idocus.Views.PreseizureAccountsIndex (el: $('#preseizure_accounts .content'), view: @view, pack_report_id: pack_report_id, preseizure_id: preseizure_id)
      @preseizureAccountsIndex.render()
