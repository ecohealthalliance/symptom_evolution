# DocPad Configuration File
# http://docpad.org/docs/config

# Define the DocPad Configuration
docpadConfig = {
	# ...
	templateData:
		site:

			styles: [
				'/vendor/jqueryui.css'
				'/style.css'
			]

			scripts: [
				'/vendor/jquery.js'
				'/vendor/jqueryui.js'
				'/vendor/underscore.js'
				'/vendor/d3.js'
				'/promed.js'
				'/symptom_graph_figure.js'
			]
}

# Export the DocPad Configuration
module.exports = docpadConfig