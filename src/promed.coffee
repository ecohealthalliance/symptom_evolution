window.eha ?= {}
window.eha.promed = {}

window.eha.promed.getDate = (reportNode) ->
  dateString = parseInt(reportNode.promed_id.split('.')[0])
  year = Math.floor(dateString / 10000)
  monthAndDate = dateString - year * 10000
  month = Math.floor(monthAndDate / 100) - 1
  date = monthAndDate - (month + 1) * 100
  new Date(year, month, date)
