class Idocus.Collections.PackReports extends Backbone.Collection

  url: 'pack_reports.json'
  model: Idocus.Models.PackReport

  parse: (resp) ->
    @page = parseInt(resp.page) || 0
    @perPage = parseInt(resp.per_page) || 0
    @total = parseInt(resp.total) || 0
    lastPage = @lastPage(@total, @perPage)
    @pages = {
      first: 1
      previous: @previousPage(@page)
      next: @nextPage(@page, lastPage)
      last: lastPage
    }
    resp.items

  previousPage: (page) ->
    if page <= 1
      null
    else
      page - 1

  nextPage: (page, lastPage) ->
    if page >= lastPage
      null
    else
      page + 1

  lastPage: (total, perPage) ->
    if total <= perPage
      1
    else
      if total % perPage == 0
        total / perPage
      else
        totalPage = Math.round(total / perPage)
        if totalPage * perPage > total
          totalPage
        else
          totalPage + 1
