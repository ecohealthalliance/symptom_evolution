drawGraph = (disease, nodes) ->
  matches = (node for node in nodes when new RegExp(disease, 'i').test(node.disease))

  symptomDates = {}
  reports = {}
  for match in matches
    dateString = parseInt(match.promed_id.split('.')[0])
    year = Math.floor(dateString / 10000)
    monthAndDate = dateString - year * 10000
    month = Math.floor(monthAndDate / 100) - 1
    date = monthAndDate - (month + 1) * 100
    dateObject = new Date(year, month, date)

    for symptom in match.symptoms
      symptomDates[symptom] ?= []
      symptomDates[symptom].push dateObject

    reports[match.title] = {date: dateObject, symptoms: match.symptoms}

  symptoms = _.sortBy(_.keys(symptomDates), (symptom) ->
    _.min(symptomDates[symptom])
  )
    
  firstDates = (_.min(values) for key, values of symptomDates)
  lastDates = (_.max(values) for key, values of symptomDates)

  minDate = _.min(firstDates)
  maxDate = _.max(lastDates)

  dataset = _.keys(symptomDates)
  colors = new d3.scale.category20().domain(symptoms)


  scale = d3.time.scale()
    .domain([minDate, maxDate])
    .range([0, 500])

  timeFormatter = d3.time.format('%b %y')

  axis = d3.svg.axis()
    .scale(scale)
    .orient('bottom')
    .tickFormat(timeFormatter)
    .ticks(d3.time.month)

  $('#reports').empty()
  reportDots = d3.select('#reports').append('svg')
    .attr('height', _.keys(reports).length + 20)

  highlightSymptoms = (title) ->
    d3.selectAll('.report')
      .filter((d) -> d isnt title)
      .attr('fill-opacity', 0.05)
    symptoms = reports[title].symptoms

    d3.selectAll('.symptom')
      .filter((d) -> d in symptoms isnt true)
      .attr('fill-opacity', 0.05)
    d3.selectAll('.symptom-dates')
      .filter((d) -> d in symptoms isnt true)
      .attr('fill-opacity', 0.05)

  removeHighlight = (d) ->
    d3.selectAll('.report').attr('fill-opacity', 1)
    d3.selectAll('.symptom').attr('fill-opacity', 1)
    d3.selectAll('.symptom-dates').attr('fill-opacity', 1)

  reportDots.selectAll('circle')
    .data(_.keys(reports))
    .enter()
    .append('circle')
    .classed('report', true)
    .attr('cx', (d) -> scale(reports[d].date) + 130)
    .attr('cy', (d, i) -> i + 10)
    .attr('r', 10)
    .on('mouseover', highlightSymptoms)
    .on('mouseout', removeHighlight)

  $('#graph').empty()
  graph = d3.select('#graph').append('svg')

  graph.selectAll('text')
    .data(dataset)
    .enter()
    .append('text')
    .classed('symptom', true)
    .text((d) -> d)
    .attr('x', 0)
    .attr('y', (d, i) -> (i * 25) + 15)
    .attr('width', 50)
    .attr('height', 20)
    .style('fill', colors)

  symptomContainers = graph.selectAll('g')
    .data(dataset)
    .enter()
    .append('g')

  symptomContainers.append('rect')
    .classed('symptom-dates', true)
    .attr('x', (d, i) -> scale(firstDates[i]) + 125)
    .attr('y', (d, i) -> i * 25)
    .attr('width', (d, i) -> scale(lastDates[i]) - scale(firstDates[i]) + 5)
    .attr('height', 20)
    .style('fill', colors)

  highlightReports = (symptom) ->
    d3.selectAll('.symptom')
      .filter((d) -> d isnt symptom)
      .attr('fill-opacity', 0.05)
    d3.selectAll('.symptom-dates')
      .filter((d) -> d isnt symptom)
      .attr('fill-opacity', 0.05)

    d3.selectAll('.report')
      .filter((d) -> symptom in reports[d].symptoms isnt true)
      .attr('fill-opacity', 0.05)

  symptomContainers.append('rect')
    .classed('symptom-container', true)
    .attr('x', 0)
    .attr('y', (d, i) -> i * 25)
    .attr('width', (d, i) -> scale(maxDate) + 130)
    .attr('height', 25)
    .style('fill-opacity', 0)
    .on('mouseover', highlightReports)
    .on('mouseout', removeHighlight)

  graph.append('g')
    .attr('transform', "translate(130,#{25*dataset.length})")
    .attr('width', 500)
    .call(axis)


loadFigures = (promedData) ->
  nodes = promedData.nodes
  diseases = _.uniq(node.disease for node in nodes)


  $('#disease-field').autocomplete({
    source: diseases
    select: (event, ui) ->
      drawGraph ui.item.value, nodes
  })

  $('#disease-field').keyup((event) ->
    if event.keyCode is 13
      drawGraph $(event.target).val(), nodes
      $(event.target).autocomplete('close')
  )

$(document).ready () ->

  $.getJSON("promed_symptoms.json").done(loadFigures)