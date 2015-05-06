function draw_vertical_bar_graph(container, data) {
  var category_height = 115;
  var margin = { top: 50, right: 80, bottom: category_height+10, left: 82 },
    width = 80*data.length - margin.left - margin.right,
    height = 500 - margin.top - margin.bottom;

  if (width < 80) {
    width = 80;
  }

  var x = d3.scale.ordinal()
      .rangeRoundBands([0, width], .03);

  var y = d3.scale.linear()
      .range([height, 0]);

  var xAxis = d3.svg.axis()
      .scale(x)
      .orient('bottom');

  var yAxis = d3.svg.axis()
      .scale(y)
      .orient('left')
      .ticks(15);

  var tip = d3.tip()
    .attr('class', 'd3-tip')
    .offset([-10, 0])
    .html(function(d) {
      return '<strong>Montant:</strong> ' + d.amount + ' €';
  });

  var chart = d3.select(container)
      .attr('width', width + margin.left + margin.right)
      .attr('height', height + margin.top + margin.bottom)
    .append('g')
      .attr('transform', 'translate(' + margin.left + ',' + margin.top + ')');

  var values_extent = d3.extent(data, function(d) { return d.amount; }),
      min_value = values_extent[0],
      max_value = values_extent[1];

  if (min_value > 0 && max_value > 0) {
    min_value = 0;
  }
  if (min_value < 0 && max_value < 0) {
    max_value = 0;
  }
  if (min_value == 0 && max_value == 0) {
    max_value = 100;
  }

  var medium_value = min_value > 0 ? min_value : 0,
      axis_distance = 20;

  x.domain(data.map(function(d) { return d.name; }));
  y.domain([min_value, max_value]);

  chart.call(tip);

  chart.append('g')
      .attr('class', 'x axis')
      .attr('transform', 'translate(0,' + height + ')')
      .call(xAxis);

  var tick = chart.select('.x.axis')
      .selectAll('.tick')
      .attr('transform', function(d) { return 'translate(' + x(d) + ',0)'; });

  tick.selectAll('text').remove();
  tick.selectAll('line').remove();

  tick.append('foreignObject')
      .attr('width', x.rangeBand())
      .attr('height', category_height)
    .append('xhtml:body')
      .style('text-align', 'center')
      .html(function(d) { return "<p style='word-wrap:break-word;'>" + d + "</p>"; });

  var xAxis2 = chart.append('g')
      .attr('class', 'x axis');

  xAxis2.append('line')
      .attr('x1', x(0))
      .attr('y1', y(medium_value))
      .attr('x2', width)
      .attr('y2', y(medium_value));

  xAxis2.append('text')
      .attr('y', y(medium_value)-4)
      .attr('x', width+margin.left-10)
      .attr('dy', '.71em')
      .style('text-anchor', 'end')
      .text('Catégories');

  var yaxis = chart.append('g')
      .attr('class', 'y axis')
      .attr('transform', 'translate(-' + axis_distance + ',0)')
      .call(yAxis)

  yaxis.append('text')
      .attr('transform', 'rotate(-90)')
      .attr('y', 3)
      .attr('x', -3)
      .attr('dy', '.71em')
      .style('text-anchor', 'end')
      .text('Montant (€)');

  yaxis.append('line')
      .attr('x1', 0)
      .attr('y1', y(medium_value))
      .attr('x2', axis_distance*3)
      .attr('y2', y(medium_value));

  chart.selectAll('.bar')
      .data(data)
    .enter().append('rect')
      .attr('class', 'bar')
      .attr('x', function(d) { return x(d.name) })
      .attr('y', function(d) { return d.amount > 0 ? y(d.amount) : y(medium_value); })
      .attr('height', function(d) { return Math.abs(y(d.amount) - y(medium_value)); })
      .attr('width', x.rangeBand())
      .on('mouseover', tip.show)
      .on('mouseout', tip.hide);
}

function draw_horizontal_bar_graph(container, data) {
  var category_width = 150;
  var margin = { top: 20, right: 80, bottom: 40, left: 20+category_width },
    width = 960 - margin.left - margin.right,
    height = 50*data.length - margin.top - margin.bottom;

  if (height < 50) {
    height = 50;
  }

  var x = d3.scale.linear()
      .range([0, width]);

  var y = d3.scale.ordinal()
      .rangeRoundBands([0, height], .03);

  var xAxis = d3.svg.axis()
      .scale(x)
      .orient("top");

  var yAxis = d3.svg.axis()
      .scale(y)
      .orient('left')
      .ticks(15);

  var chart = d3.select(container)
      .attr('width', width + margin.left + margin.right)
      .attr('height', height + margin.top + margin.bottom)
    .append('g')
      .attr('transform', 'translate(' + margin.left + ',' + margin.top + ')');

  var values_extent = d3.extent(data, function(d) { return d.amount; }),
      min_value = values_extent[0],
      max_value = values_extent[1];

  if (min_value > 0 && max_value > 0) {
    min_value = 0;
  }
  if (min_value < 0 && max_value < 0) {
    max_value = 0;
  }
  if (min_value == 0 && max_value == 0) {
    max_value = 100;
  }

  var medium_value = min_value > 0 ? min_value : 0;

  x.domain([min_value, max_value]);
  y.domain(data.map(function(d) { return d.name; }));

  var xaxis = chart.append('g')
      .attr('class', 'x axis')
      .call(xAxis);

  xaxis.append('g')
      .attr('transform', 'translate(' + x(max_value) + ',0)')
    .append('text')
      .attr('y', 3)
      .attr('dy', ".71em")
      .style('text-anchor', 'end')
      .text('Montant (€)');

  xaxis.append('line')
    .attr('x1', x(0))
    .attr('x2', width);

  chart.append('g')
      .attr('class', 'y axis')
      .call(yAxis)
    .append('text')
      .attr('y', y(data[data.length -1].name)+60)
      .attr('x', 27)
      .attr('dy', '.71em')
      .style('text-anchor', 'end')
      .text('Catégories (' + data.length + ')');

  var tick = chart.select('.y.axis')
      .selectAll('.tick')
      .attr('transform', function(d) { return 'translate(-' + (category_width+10) + ',' + y(d) + ')'; });

  tick.selectAll('text').remove();
  tick.selectAll('line').remove();

  tick.append('foreignObject')
      .attr('width', category_width)
      .attr('height', y.rangeBand())
    .append('xhtml:body')
      .style('text-align', 'right')
      .style('height', y.rangeBand() + 'px')
      .style('width', category_width + 'px')
      .style('display', 'table')
      .html(function(d) { return "<p style='display:table-cell;vertical-align:middle;word-wrap:break-word;'>" + d + "</p>"; });

  chart.selectAll('.bar')
      .data(data)
    .enter().append('rect')
      .attr('class', 'bar')
      .attr('x', 0)
      .attr('y', function(d) { return y(d.name); })
      .attr('width', function(d) { return x(d.amount); })
      .attr('height', y.rangeBand())
      .on('mouseenter', function(d) {
          d.active = true;
          showDetail(d);
      })
      .on('mouseout', function(d) {
        if (d.active) {
          hideDetail();
          d.active = false;
        }
      })
      .on('click touch', function(d) {
        if (d.active) {
          showDetail(d);
        } else {
          hideDetail();
        }
      });

  function showDetail(d) {
    chart.append('g')
        .attr('class', 'detail')
        .attr(
          'transform',
            function() {
              var result = 'translate(';

              result += x(d.amount) + 5;
              result += ', ';
              result += y(d.name) + y.rangeBand()/2 + 3;
              result += ')';

              return result;
            }
        )
      .append('text')
        .attr( 'class', 'bubble-value' )
        .text(d.amount + ' €');
  }

  function hideDetail(d) {
    chart.selectAll('.detail').remove();
  }
}

function draw_line_graph(container, data) {
  var margin = { top: 70, right: 50, bottom: 30, left: 50 },
    width = 960 - margin.left - margin.right,
    height = 600 - margin.top - margin.bottom;

  var detailWidth  = 98,
      detailHeight = 55,
      detailMargin = 10;

  var dateFormat = d3.time.format('%Y-%m-%d');
  var parseDate = dateFormat.parse;

  var x = d3.time.scale()
      .range([0, width]);

  var y = d3.scale.linear()
      .range([height, 0]);

  var xAxis = d3.svg.axis()
      .scale(x)
      .orient('bottom')
      .tickFormat(d3.time.format('%Y-%m-%d'));

  var yAxis = d3.svg.axis()
      .scale(y)
      .orient('left');

  var line = d3.svg.line()
      .x(function(d) { return x(d.date); })
      .y(function(d) { return y(d.amount); });

  var chart = d3.select(container)
      .attr('width', width + margin.left + margin.right)
      .attr('height', height + margin.top + margin.bottom)
    .append('g')
      .attr('transform', 'translate(' + margin.left + ',' + margin.top + ')');

  data.forEach(function(d) {
    d.date = parseDate(d.date);
    d.amount = +d.amount;
  });

  var xvalues_extent = d3.extent(data, function(d) { return d.date; }),
      min_xvalue = xvalues_extent[0],
      max_xvalue = xvalues_extent[1];
  var yvalues_extent = d3.extent(data, function(d) { return d.amount; }),
      min_yvalue = yvalues_extent[0],
      max_yvalue = yvalues_extent[1];

  if (min_yvalue > 0 && max_yvalue > 0) {
    min_yvalue = 0;
  }
  if (min_yvalue < 0 && max_yvalue < 0) {
    max_yvalue = 0;
  }
  if (min_yvalue == 0 && max_yvalue == 0) {
    max_yvalue = 100;
  }

  var medium_value = min_yvalue > 0 ? min_yvalue : 0;

  x.domain([min_xvalue, max_xvalue]);
  y.domain([min_yvalue, max_yvalue]);

  chart.append('g')
      .attr('class', 'x axis')
      .attr('transform', 'translate(0,' + height + ')')
      .call(xAxis);

  var xAxis2 = chart.append('g')
      .attr('class', 'x axis');

  xAxis2.append('line')
      .attr('x1', x(min_xvalue))
      .attr('y1', y(medium_value))
      .attr('x2', width)
      .attr('y2', y(medium_value));

  xAxis2.append('text')
      .attr('y', y(medium_value)-4)
      .attr('x', width+25)
      .attr('dy', '.71em')
      .style('text-anchor', 'end')
      .text('Date');

  chart.append('g')
      .attr('class', 'y axis')
      .call(yAxis)
    .append('text')
      .attr('transform', 'rotate(-90)')
      .attr('y', 6)
      .attr('x', -6)
      .attr('dy', '.71em')
      .style('text-anchor', 'end')
      .text('Solde (€)');

  chart.append('path')
      .datum(data)
      .attr('class', 'line')
      .attr('d', line)
      .transition()
      .each('end', function() {
        drawCircles(data);
      });

  function drawCircle(datum,index) {
    circleContainer.datum(datum)
                  .append('circle')
                  .attr('class', 'circle')
                  .attr('r', 0)
                  .attr(
                    'cx',
                    function(d) {
                      return x(d.date);
                    }
                 )
                  .attr(
                    'cy',
                    function(d) {
                      return y(d.amount);
                    }
                 )
                  .on('mouseenter', function(d) {
                    d3.select(this)
                      .attr(
                        'class',
                        'circle circle-highlighted'
                     )
                      .attr('r', 7);

                      d.active = true;

                      showCircleDetail(d);
                  })
                  .on('mouseout', function(d) {
                    d3.select(this)
                      .attr(
                        'class',
                        'circle'
                     )
                      .attr('r', 6);

                    if (d.active) {
                      hideCircleDetails();

                      d.active = false;
                    }
                  })
                  .on('click touch', function(d) {
                    if (d.active) {
                      showCircleDetail(d)
                    } else {
                      hideCircleDetails();
                    }
                  })
                  .attr('r', 6);
  }

  function drawCircles(data) {
    circleContainer = chart.append('g');

    data.forEach(function(datum, index) {
      drawCircle(datum, index);
    });
  }

  function hideCircleDetails() {
    circleContainer.selectAll('.bubble')
                    .remove();
  }

  function showCircleDetail(data) {
    var details = circleContainer.append('g')
                      .attr('class', 'bubble')
                      .attr(
                        'transform',
                        function() {
                          var result = 'translate(';

                          result += x(data.date) - detailWidth / 2;
                          result += ', ';
                          result += y(data.amount) - detailHeight - detailMargin;
                          result += ')';

                          return result;
                        }
                     );

    details.append('path')
            .attr('d', 'M2.99990186,0 C1.34310181,0 0,1.34216977 0,2.99898218 L0,47.6680579 C0,49.32435 1.34136094,50.6670401 3.00074875,50.6670401 L44.4095996,50.6670401 C48.9775098,54.3898926 44.4672607,50.6057129 49,54.46875 C53.4190918,50.6962891 49.0050244,54.4362793 53.501875,50.6670401 L94.9943116,50.6670401 C96.6543075,50.6670401 98,49.3248703 98,47.6680579 L98,2.99898218 C98,1.34269006 96.651936,0 95.0000981,0 L2.99990186,0 Z M2.99990186,0')
            .attr('width', detailWidth)
            .attr('height', detailHeight);

    var text = details.append('text')
                      .attr('class', 'bubble-text');

    text.append('tspan')
        .attr('class', 'bubble-label')
        .attr('x', detailWidth / 2)
        .attr('y', detailHeight / 3)
        .attr('text-anchor', 'middle')
        .text(dateFormat(data.date));

    text.append('tspan')
        .attr('class', 'bubble-value')
        .attr('x', detailWidth / 2)
        .attr('y', detailHeight / 4 * 3)
        .attr('text-anchor', 'middle')
        .text(data.amount + ' €');
  }
}

function chart_alert(type, message) {
  $('.chart_alert').addClass(type).text(message);
}

function load_chart(type) {
  $chart = $('#chart')
  bank_account_id = $chart.data('bankAccountId');
  start_date = $chart.data('startDate');
  end_date = $chart.data('endDate');

  $.ajax({
    url: type + '.json?bank_account_id='+bank_account_id+'&start_date='+start_date+'&end_date='+end_date,
    dataType: 'json',
    type: 'GET',
    complete: function() {
      $('.load_container').hide();
    },
    success: function(data) {
      if (data.length > 0) {
        if (type == 'operations') {
          draw_horizontal_bar_graph('.chart', data);
        } else if (type == 'balances') {
          draw_line_graph('.chart', data);
        }
      } else {
        chart_alert('notice', 'Aucune donnée disponible.')
      }
    },
    error: function(data, e, message) {
      chart_alert('error', data.responseText)
    }
  });
}
