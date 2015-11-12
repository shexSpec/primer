JSON-GRAMMAR?=../node_modules/json-grammar/lib/cli.js

all: ShExJ.jsg ShExJ_all.json
	node $(JSON-GRAMMAR) $^

empty: ShExJ.jsg empty.json
	node $(JSON-GRAMMAR) $^

test: all empty
