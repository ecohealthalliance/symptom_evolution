import json
import contextlib
import urllib2
from urllib2 import urlopen
from urllib import urlencode
import sys

if __name__ == '__main__':

    fileName = sys.argv[1]

    diagnoses = {}

    with open(fileName) as f:
        content = f.read()
        content = json.loads(content)

        nodes = content.get('nodes')

        dates = list(set([node.get('promed_id').split('.')[0] for node in nodes]))
        #dateIncrement = (int(max(dates)) - int(min(dates))) / 3
        #minDate = int(min(dates))
        #maxDate = max(dates)
        #diagnoseDates = [str(minDate), str(minDate + dateIncrement), str(minDate + dateIncrement * 2), maxDate]
        dateIncrement = len(dates)/3
        diagnoseDates = [dates[0], dates[dateIncrement], dates[dateIncrement * 2], dates[-1]]
        
        symptomDates = {}
        for match in nodes:
            for symptom in match.get('symptoms'):
                if not symptomDates.get(symptom):
                    symptomDates[symptom] = []
                symptomDates[symptom].append(match.get('promed_id').split('.')[0])

        firstDates = [min(values) for key, values in symptomDates.iteritems()]
        lastDates = [max(values) for key, values in symptomDates.iteritems()]

        diagnoseSymptoms = {}
        for date in diagnoseDates:
            symptoms = symptomDates.keys()
            for index, symptom in enumerate(symptoms):
                if (date >= firstDates[index] and date <= lastDates[index]):
                    if not diagnoseSymptoms.get(date):
                        diagnoseSymptoms[date] = []
                    diagnoseSymptoms[date].append(symptom)

        for date in diagnoseDates:
            url = 'http://54.237.77.59/diagnose'
            data = {'text': ' '.join(diagnoseSymptoms.get(date) or [])}

            passman = urllib2.HTTPPasswordMgrWithDefaultRealm()
            passman.add_password(None, url, 'grits', 'portfolios4grits')
            urllib2.install_opener(urllib2.build_opener(urllib2.HTTPBasicAuthHandler(passman)))

            req = urllib2.Request(url)

            try:
                with contextlib.closing(urlopen(req, urlencode(data))) as response:
                    content = response.read()
                    diagnosis = json.loads(content)
                    diagnoses[date] = diagnosis
            except Exception:
                import pdb
                pdb.set_trace()

    print json.dumps({'nodes': nodes, 'diagnoses': diagnoses})
