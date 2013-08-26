processPromed = (promedData) ->
  nodes = promedData.nodes
  diseases = _.uniq(node.disease for node in nodes)


  drawGraph = (disease) ->
    matches = (node for node in nodes when new RegExp(disease, 'i').test(node.disease))

    symptomDates = {}
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

    symptoms = _.sortBy(_.keys(symptomDates), (symptom) ->
      _.min(symptomDates[symptom])
    )
    
    firstDates = (_.min(values) for key, values of symptomDates)
    lastDates = (_.max(values) for key, values of symptomDates)

    minDate = _.min(firstDates)
    maxDate = _.max(lastDates)

    dataset = _.keys(symptomDates)

    scale = d3.scale.linear()
      .domain([0, maxDate - minDate])
      .range([0, 500])

    timeFormatter = d3.time.format('%b %Y')
    formatAsTime = (timeDiff) ->
      time = new Date(minDate.getTime() + timeDiff)
      timeFormatter(time)

    axis = d3.svg.axis()
      .scale(scale)
      .orient('bottom')
      .tickFormat(formatAsTime)

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

    graph.selectAll('rect')
      .data(dataset)
      .enter()
      .append('rect')
      .attr('x', (d, i) -> scale(firstDates[i] - minDate) + 100)
      .attr('y', (d, i) -> i * 25)
      .attr('width', (d, i) -> scale(lastDates[i] - minDate) + 5)
      .attr('height', 20)

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