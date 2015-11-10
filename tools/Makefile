JISON?=../node_modules/jison/lib/cli.js

json-grammar.js: json-grammar.jison
	$(JISON) $^ -o $@ -p lalr

ShExJ-validator.js: ShExJ.jsg ShExJ_all.json json-grammar.js
	node json-grammar $< ShExJ_all.json

test: ShExJ-validator.js
