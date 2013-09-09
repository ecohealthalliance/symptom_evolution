drawGraph = (disease, selector, nodes, showReports=true, showLabels=true) ->
  symptomDates = window.eha.promed.getSymptomDates disease, nodes
  reports = window.eha.promed.getReports disease, nodes

  symptoms = _.sortBy(_.keys(symptomDates), (symptom) ->
    _.min(symptomDates[symptom])
  )
    
  firstDates = (_.min(values) for key, values of symptomDates)
  lastDates = (_.max(values) for key, values of symptomDates)

  minDate = _.min(firstDates)
  maxDate = _.max(lastDates)

  dataset = symptoms
  colors = new d3.scale.category20().domain(symptoms)

  highlightSymptoms = (title) ->
    svg = $(this).parents('svg')
    d3.selectAll(svg.find('.report'))
      .filter((d) -> d isnt title)
      .attr('fill-opacity', 0.05)
    symptoms = reports[title].symptoms

    d3.selectAll(svg.find('.symptom'))
      .filter((d) -> d in symptoms isnt true)
      .attr('fill-opacity', 0.05)
    d3.selectAll(svg.find('.symptom-dates'))
      .filter((d) -> d in symptoms isnt true)
      .attr('fill-opacity', 0.05)

  highlightReports = (symptom) ->
    svg = $(this).parents('svg')
    d3.selectAll(svg.find('.symptom'))
      .filter((d) -> d isnt symptom)
      .attr('fill-opacity', 0.05)
    d3.selectAll(svg.find('.symptom-dates'))
      .filter((d) -> d isnt symptom)
      .attr('fill-opacity', 0.05)

    d3.selectAll(svg.find('.report'))
      .filter((d) -> symptom in reports[d].symptoms isnt true)
      .attr('fill-opacity', 0.05)

  removeHighlight = (d) ->
    svg = $(this).parents('svg')
    d3.selectAll(svg.find('.report')).attr('fill-opacity', 1)
    d3.selectAll(svg.find('.symptom')).attr('fill-opacity', 1)
    d3.selectAll(svg.find('.symptom-dates')).attr('fill-opacity', 1)

  $(selector).empty()
  width = $(selector).width()
  height = $(selector).height()
  labelsWidth = if showLabels then width * 0.2 else 0

  figure = d3.select(selector).append('svg')

  figure.append('text')
    .classed('figure-title', true)
    .text(disease)
    .attr('x', 5)
    .attr('y', 40)

  xScale = d3.time.scale()
    .domain([minDate, maxDate])
    .range([labelsWidth, width - labelsWidth])

  timeFormatter = d3.time.format('%b %y')

  axis = d3.svg.axis()
    .scale(xScale)
    .orient('bottom')
    .tickFormat(timeFormatter)
    .ticks(d3.time.month)

  reportsHeight = if showReports then height * 0.1 else 20
  reportsYScale = d3.scale.linear()
    .domain([0, _.keys(reports).length])
    .range([20, reportsHeight])

  if showReports
    figure.append('g')
      .attr('height', reportsHeight)
      .selectAll('circle')
      .data(_.keys(reports))
      .enter()
      .append('circle')
      .classed('report', true)
      .attr('cx', (d) -> xScale(reports[d].date))
      .attr('cy', (d, i) -> reportsYScale(i))
      .attr('r', _.min([width, height]) / 50)
      .on('mouseover', highlightSymptoms)
      .on('mouseout', removeHighlight)

  symptomsHeight = if showReports then height * 0.7 else height * 0.9
  barHeight = (symptomsHeight / dataset.length) - 2
  symptomsYScale = d3.scale.linear()
    .domain([0, dataset.length])
    .range([reportsHeight + 25, symptomsHeight + reportsHeight + 25])
  graph = figure.append('g')

  if showLabels
    graph.selectAll('text')
      .data(dataset)
      .enter()
      .append('text')
      .classed('symptom', true)
      .text((d) -> d)
      .attr('x', 0)
      .attr('y', (d, i) -> symptomsYScale(i) + barHeight)
      .attr('width', labelsWidth)
      .attr('height', barHeight)
      .style('fill', colors)

  symptomContainers = graph.selectAll('g')
    .data(dataset)
    .enter()
    .append('g')

  symptomContainers.append('rect')
    .classed('symptom-dates', true)
    .attr('x', (d, i) -> xScale(firstDates[i]))
    .attr('y', (d, i) -> symptomsYScale(i))
    .attr('width', (d, i) -> _.max([xScale(lastDates[i]) - xScale(firstDates[i]), 5]))
    .attr('height', barHeight)
    .style('fill', colors)

  symptomContainers.append('rect')
    .classed('symptom-container', true)
    .attr('x', 0)
    .attr('y', (d, i) -> symptomsYScale(i))
    .attr('width', (d, i) -> xScale(maxDate) + 5)
    .attr('height', barHeight + 2)
    .style('fill-opacity', 0)
    .on('mouseover', highlightReports)
    .on('mouseout', removeHighlight)

  if showLabels
    graph.append('g')
      .attr('transform', "translate(0,#{symptomsHeight + reportsHeight + 25})")
      .attr('width', width - labelsWidth)
      .call(axis)


drawCumulativeSymptomGraph = (diseases, selector, nodes) ->
  diseaseSymptomCounts = {}

  for disease in diseases
    diseaseSymptomCounts[disease] = eha.promed.getSymptomCounts disease, nodes

  firstDates = _.map diseaseSymptomCounts, (list) -> _.first(list).date
  lastDates = _.map diseaseSymptomCounts, (list) -> _.last(list).date
  maxCounts = _.map diseaseSymptomCounts, (list) -> _.last(list).count

  colors = new d3.scale.category20().domain(diseases)

  xScale = d3.time.scale()
    .domain([_.min(firstDates), _.max(lastDates)])
    .range([0, 500])

  yScale = d3.scale.linear()
    .domain([0, _.max(maxCounts)])
    .range([500, 0])

  timeFormatter = d3.time.format('%b %y')

  xAxis = d3.svg.axis()
    .scale(xScale)
    .orient('bottom')
    .tickFormat(timeFormatter)
    .ticks(d3.time.month)

  yAxis = d3.svg.axis()
    .scale(yScale)
    .orient('right')

  $(selector).empty()
  figure = d3.select(selector).append('svg')

  line = d3.svg.line()
    .x((d) -> xScale(d.date))
    .y((d) -> yScale(d.count))

  disease = figure.selectAll('path')
    .data(_.keys(diseaseSymptomCounts))
    .enter()
    .append('path')
    .attr('d', (d) -> line(diseaseSymptomCounts[d]))
    .attr('stroke', colors)
    .attr('stroke-width', 5)
    .attr('fill', 'none')

  legend = figure.selectAll('text')
    .data(_.keys(diseaseSymptomCounts))
    .enter()
    .append('text')
    .text((d) -> d)
    .attr('stroke', colors)
    .attr('x', 5)
    .attr('y', (d, i) -> i * 25 + 50)

  figure.append('text')
    .attr('x', 5)
    .attr('y', 20)
    .text('Cumulative symptom counts')
    .classed('figure-title', true)

  figure.append('g')
    .call(xAxis)
    .attr('transform', 'translate(0,500)')

  figure.append('g')
    .call(yAxis)
    .attr('transform', 'translate(500,0)')


loadFigures = (promedData) ->
  nodes = promedData.nodes
  diseases = _.uniq(node.disease for node in nodes)


  $('#disease-field').autocomplete({
    source: diseases
    select: (event, ui) ->
      drawGraph ui.item.value, '#graph', nodes
  })

  $('#disease-field').keyup (event) ->
    if event.keyCode is 13
      drawGraph $(event.target).val(), '#graph', nodes
      $(event.target).autocomplete('close')

  $('.symptom-graph-figure').each (i, figure) ->
    showReports = $(figure).hasClass('symptom-graph-reports')
    showLabels = $(figure).hasClass('symptom-graph-labels')
    drawGraph $(figure).attr('disease'), figure, nodes, showReports, showLabels

  $('.cumulative-symptom-figure').each (i, figure) ->
    diseases = $(figure).attr('diseases').split(',')
    drawCumulativeSymptomGraph diseases, figure, nodes

$(document).ready () ->

  $.getJSON("../data/promed_symptoms.json").done(loadFigures)