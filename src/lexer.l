%option noyywrap nounput noinput yylineno
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "parser.tab.h"

extern int errores;
%}

%%
[ \t\r\n]+              ;
"#".*                   ;

"imprimir"              return IMPRIMIR;
"si"                    return SI;
"sino"                  return SINO;
"mientras"              return MIENTRAS;
"reporte"               return REPORTE;
"y"                     return AND;
"o"                     return OR;
"no"                    return NO;

"=="                    return EQ;
"!="                    return NE;
"<="                    return LE;
">="                    return GE;

[0-9]+(\.[0-9]+)?       { yylval.num = atof(yytext); return NUM; }
\"[^\"\n]*\"            { yylval.str = strndup(yytext + 1, yyleng - 2); return CADENA; }
\"[^\"\n]*              { fprintf(stderr, "Error léxico (línea %d): cadena sin cerrar\n", yylineno); errores++; }
[A-Za-z_][A-Za-z0-9_]*  { yylval.str = strdup(yytext); return ID; }

[-+*/=<>(){};:,%]       return yytext[0];

.                       { fprintf(stderr, "Error léxico (línea %d): carácter inválido '%s'\n", yylineno, yytext); errores++; }
%%
