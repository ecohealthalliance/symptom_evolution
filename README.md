symptom_evolution
=================


setup
=====

* npm install -g coffee-script jade stylus
* mkdir built


build
=====

* js: coffee --output built/ src/
* html: jade --out built/ src/
* css: stylus --out built/ src/

run
===

* python -m SimpleHTTPServer
* go to http://localhost:8000/built/
