window.eha ?= {}
window.eha.promed = {}

getDate = (reportNode) ->
  dateString = parseInt(reportNode.promed_id.split('.')[0])
  year = Math.floor(dateString / 10000)
  monthAndDate = dateString - year * 10000
  month = Math.floor(monthAndDate / 100) - 1
  date = monthAndDate - (month + 1) * 100
  new Date(year, month, date)

getMatches = (disease, nodes) ->
  (node for node in nodes when new RegExp(disease, 'i').test(node.disease))

window.eha.promed.getSymptomDates = (disease, nodes) ->
  symptomDates = {}
  for match in getMatches(disease, nodes)
    for symptom in match.symptoms
      symptomDates[symptom] ?= []
      symptomDates[symptom].push getDate(match)
  symptomDates

window.eha.promed.getReports = (disease, nodes) ->
  reports = {}
  for match in getMatches(disease, nodes)
    reports[match.title] =
      date: getDate(match)
      symptoms: match.symptoms
  reports

window.eha.promed.getSymptomCounts = (disease, nodes) ->
  symptomCounts = []
  symptomsSeen = []
  for match in _.sortBy getMatches(disease, nodes), getDate
    symptomsSeen = _.uniq symptomsSeen.concat(match.symptoms)
    symptomCounts.push {date: getDate(match), count: symptomsSeen.length}
  symptomCounts
