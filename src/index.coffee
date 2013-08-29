processPromed = (promedData) ->
  nodes = promedData.nodes
  diseases = _.uniq(node.disease for node in nodes)


  drawGraph = (disease) ->
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

    highlightSymptoms = (d) ->
      d3.select(this).attr('fill', 'steelblue')
      symptoms = reports[d].symptoms

      d3.selectAll('text')
        .filter((d) -> d in symptoms isnt true)
        .attr('fill-opacity', 0.05)
      d3.selectAll('rect')
        .filter((d) -> d in symptoms isnt true)
        .attr('fill-opacity', 0.05)

    removeHighlight = (d) ->
      d3.selectAll('circle').attr('fill', 'black')
      d3.selectAll('text').attr('fill-opacity', 1)
      d3.selectAll('rect').attr('fill-opacity', 1)

    reportDots.selectAll('circle')
      .data(_.keys(reports))
      .enter()
      .append('circle')
      .attr('cx', (d) -> scale(reports[d].date) + 125)
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
      .text((d) -> d)
      .attr('x', 0)
      .attr('y', (d, i) -> (i * 25) + 15)
      .attr('width', 50)
      .attr('height', 20)
      .style('fill', colors)

    graph.selectAll('rect')
      .data(dataset)
      .enter()
      .append('rect')
      .attr('x', (d, i) -> scale(firstDates[i]) + 125)
      .attr('y', (d, i) -> i * 25)
      .attr('width', (d, i) -> scale(lastDates[i]) - scale(firstDates[i]) + 5)
      .attr('height', 20)
      .style('fill', colors)

    graph.append('g')
      .attr('transform', "translate(100,#{25*dataset.length})")
      .attr('width', 500)
      .call(axis)

  $('#disease-field').autocomplete({
    source: diseases
    select: (event, ui) ->
      drawGraph ui.item.value
  })

  $('#disease-field').keyup((event) ->
    if event.keyCode is 13
      drawGraph $(event.target).val()
      $(event.target).autocomplete('close')
  )

$(document).ready () ->

  $.getJSON("promed_symptoms.json").done(processPromed)