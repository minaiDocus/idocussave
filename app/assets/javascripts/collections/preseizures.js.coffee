class Idocus.Collections.Preseizures extends Backbone.Collection

  url: 'preseizures.json'
  model: Idocus.Models.Preseizure

  parse: (resp) ->
    window.precol = @
    @page = parseInt(resp.page) || 0
    @perPage = parseInt(resp.per_page) || 0
    @total = parseInt(resp.total) || 0
    lastPage = @lastPage(@total, @perPage)
    @pages = {
      first: 1
      last: lastPage
    }
    resp.items.forEach (e, i, a) ->
      e.description_keys = resp.description_keys
      e.description_separator = resp.description_separator
    resp.items

  pageRange: ->
    lastPage = @lastPage(@total, @perPage)
    first = @page - 4
    first = 1 if first < 1
    last = @page + 4
    last = lastPage if last > lastPage

    range = []
    for i in [first..last] by 1
      range.push(i)
    range

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
