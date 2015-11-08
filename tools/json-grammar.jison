%{
  function makeGrammar (decls, terminals) {
    var m = { };
    var o = [ ];
    decls.concat(terminals).forEach(function (elt) {
      m[elt.id] = elt;
      o.push(elt.id)
    });
    return { start: o[0], order: o, type: "schema", map: m };
  }
  function logret (x) {
    console.warn(x);
    return x;
  }
%}

%lex

COMMENT			('//'|'#') [^\u000a\u000d]*
ID                      [a-zA-Z_]+
STRING                  '"' ([^\"]|'\\"')* '"'
%%

\s+|{COMMENT} /**/
"@terminals" return 'GT_AT_terminals';
":"          return 'GT_COLON';
"$"          return 'GT_DOLLAR';
"="          return 'GT_EQUAL';
"["          return 'GT_LBRACKET';
"]"          return 'GT_RBRACKET';
"("          return 'GT_LPAREN';
")"          return 'GT_RPAREN';
"->"         return 'GT_MINUS_GT';
"?"          return 'GT_OPT';
"|"          return 'GT_PIPE';
"+"          return 'GT_PLUS';
";"          return 'GT_SEMI';
"*"          return 'GT_TIMES';
{ID}         return 'ID';
{STRING}     return 'STRING';
.            return 'invalid character '+yytext;

/lex

/* operator associations and precedence */

%start grammarDef

%% /* language grammar */

grammarDef:
    _Q_O_QobjectDef_E_Or_QnonObject_E_C_E_Star GT_AT_terminals _Qterminal_E_Star	{
      return makeGrammar($1, $3);
    }
  ;

_O_QobjectDef_E_Or_QnonObject_E_C:
    objectDef	
    | nonObject	
  ;

_Q_O_QobjectDef_E_Or_QnonObject_E_C_E_Star:
      -> []
    | _Q_O_QobjectDef_E_Or_QnonObject_E_C_E_Star _O_QobjectDef_E_Or_QnonObject_E_C	-> $1.concat($2)
  ;

_Qterminal_E_Star:
      -> []
    | _Qterminal_E_Star terminal	-> $1.concat($2)
  ;

objectDef:
    ID GT_COLON _resolve_Qparticle_E_Plus _Q_O_QGT_PIPE_E_S_Qparticle_E_Star_C_E_Star GT_SEMI	
    -> { type: "object", id: $1, expr: $4.length ? { type: "or", exprs: [$3].concat($4) } : $3 }
  ;

_resolve_Qparticle_E_Plus:
    _Qparticle_E_Plus	-> $1.length > 1 ? { type: "propertyList", exprs: $1 } : $1[0]
  ;

_Qparticle_E_Plus:
    particle	-> [ $1 ]
    | _Qparticle_E_Plus particle	-> $1.concat($2)
  ;

_Qparticle_E_Star:
      -> []
    | _Qparticle_E_Star particle	-> $1.concat($2)
  ;

_O_QGT_PIPE_E_S_Qparticle_E_Star_C:
    GT_PIPE _Qparticle_E_Star	
    -> $2.length === 0 ? { type: "epsilon" } : $2.length === 1 ? $2 : { type: "propertyList", exprs: $2 }
  ;

_Q_O_QGT_PIPE_E_S_Qparticle_E_Star_C_E_Star:
      -> []
    | _Q_O_QGT_PIPE_E_S_Qparticle_E_Star_C_E_Star _O_QGT_PIPE_E_S_Qparticle_E_Star_C	-> $1.concat($2)
  ;

particle:
      ID _Qcardinality_E_Opt	-> { type: "reference", id: $1, card: $2 }
    | propertyOrGroup
  ;

_Qcardinality_E_Opt:
      -> ""
    | cardinality	;

propertyOrGroup:
      ID GT_COLON propertyType _Qcardinality_E_Opt	// !!! GT_OPT_OPT 'cause single predicate
      -> { type: "property", id: $1, propertyType: $3, card: $4 }
    | GT_LPAREN ID _Q_O_QGT_PIPE_E_S_QID_E_C_E_Plus GT_RPAREN GT_COLON propertyType _Qcardinality_E_Opt	
      -> { type: "propertyEnumeration", ids: [$2].concat($3), propertyType: $6, card: $7 }
    | GT_LPAREN _resolve_QpropertyOrGroup_E_Plus _Q_O_QGT_PIPE_E_S_QpropertyOrGroup_E_Plus_C_E_Plus GT_RPAREN	
      -> { type: "or", exprs: [$2].concat($3) }
  ;

_O_QGT_PIPE_E_S_QID_E_C:
    GT_PIPE ID	-> $2
  ;

_Q_O_QGT_PIPE_E_S_QID_E_C_E_Plus:
      _O_QGT_PIPE_E_S_QID_E_C	-> [$1]
    | _Q_O_QGT_PIPE_E_S_QID_E_C_E_Plus _O_QGT_PIPE_E_S_QID_E_C	-> $1.concat($2)
  ;

_resolve_QpropertyOrGroup_E_Plus:
      _QpropertyOrGroup_E_Plus	-> $1.length > 1 ? { type: "propertyList", exprs: $1 } : $1[0]
  ;

_QpropertyOrGroup_E_Plus:
      propertyOrGroup	-> [$1]
    | _QpropertyOrGroup_E_Plus propertyOrGroup	-> $1.concat($1)
  ;

_O_QGT_PIPE_E_S_QpropertyOrGroup_E_Plus_C:
    GT_PIPE _resolve_QpropertyOrGroup_E_Plus	-> $2
  ;

_Q_O_QGT_PIPE_E_S_QpropertyOrGroup_E_Plus_C_E_Plus:
    _O_QGT_PIPE_E_S_QpropertyOrGroup_E_Plus_C	-> [$1];
    | _Q_O_QGT_PIPE_E_S_QpropertyOrGroup_E_Plus_C_E_Plus _O_QGT_PIPE_E_S_QpropertyOrGroup_E_Plus_C	-> $1.concat($2)
  ;

propertyType:
    ID	
    | STRING	
    | GT_LBRACKET ID _Q_O_QGT_MINUS_GT_E_S_QID_E_C_E_Opt GT_RBRACKET	-> $3 === null ? { type: "array", of: $2 } : { type: "map", from: $2, to: $3 }
    | GT_LPAREN typeAlternatives GT_RPAREN	-> $2
  ;

_O_QGT_MINUS_GT_E_S_QID_E_C:
    GT_MINUS_GT ID	-> $2
  ;

_Q_O_QGT_MINUS_GT_E_S_QID_E_C_E_Opt:
      -> null
    | _O_QGT_MINUS_GT_E_S_QID_E_C	-> $1
  ;

typeAlternatives:
    ID _Q_O_QGT_PIPE_E_S_QSTRING_E_C_E_Plus	-> [$1].concat($2)
    | STRING _Q_O_QGT_PIPE_E_S_QSTRING_E_C_E_Plus	-> [$1].concat($2)
  ;

_O_QGT_PIPE_E_S_QSTRING_E_C:
    GT_PIPE STRING	-> $2
  ;

_Q_O_QGT_PIPE_E_S_QSTRING_E_C_E_Plus:
    _O_QGT_PIPE_E_S_QSTRING_E_C	-> [$1]
    | _Q_O_QGT_PIPE_E_S_QSTRING_E_C_E_Plus _O_QGT_PIPE_E_S_QSTRING_E_C	-> $1.concat($2)
  ;

nonObject:
    //ID GT_EQUAL _Qparticle_E_Plus _Q_O_QGT_PIPE_E_S_Qparticle_E_Star_C_E_Star GT_SEMI	
    ID GT_EQUAL _resolve_Qparticle_E_Plus _Q_O_QGT_PIPE_E_S_Qparticle_E_Star_C_E_Star GT_SEMI	
    -> { type: "nonObject", id: $1, expr: $4.length ? { type: "or", exprs: [$3].concat($4) } : $3 }
    //-> { type: "nonObject", id: $1, vals: [$3].concat($4) }
  ;

// nonObject:
//     ID GT_EQUAL ID _Q_O_QGT_PIPE_E_S_QID_E_C_E_Star GT_SEMI	-> { type: "nonObject", id: $1, vals: [$3].concat($4) }
//   ;

// _Q_O_QGT_PIPE_E_S_QID_E_C_E_Star:
//       -> []
//     | _Q_O_QGT_PIPE_E_S_QID_E_C_E_Star _O_QGT_PIPE_E_S_QID_E_C	-> $1.concat($2)
//   ;

terminal:
    ID GT_EQUAL STRING _Q_O_QGT_PLUS_E_S_QSTRING_E_C_E_Star	-> { type: "terminal", id: $1, regexp: $3.slice(1, -1).concat($4.map(function (s) { return s.slice(1, -1); }).join('')) }
  ;

_O_QGT_PLUS_E_S_QSTRING_E_C:
    GT_PLUS STRING	-> $2
  ;

_Q_O_QGT_PLUS_E_S_QSTRING_E_C_E_Star:
      -> []
    | _Q_O_QGT_PLUS_E_S_QSTRING_E_C_E_Star _O_QGT_PLUS_E_S_QSTRING_E_C	-> $1.concat($2)
  ;

cardinality:
    GT_OPT	
    | GT_TIMES	;
