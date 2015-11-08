JISON?=../node_modules/jison/lib/cli.js

json-grammar.js: json-grammar.jison
	$(JISON) $^ -o $@ -p lalr

ShExJ-validator.js: ShExJ.jsg json-grammar.js
	node json-grammar $<

test: ShExJ-validator.js
