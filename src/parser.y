%{
#include <stdio.h>
#include <stdlib.h>
int yylex();
void yyerror(const char *s) { fprintf(stderr, "Error: %s\n", s); }
%}
%token NUM
%left '+' '-'
%left '*' '/'
%%
input:
      /* vacío */
    | input linea
    ;
linea:
      '\n'
    | expr '\n'  { printf("Resultado: %d\n", $1); }
    ;
expr:
      NUM
    | expr '+' expr { $$ = $1 + $3; }
    | expr '-' expr { $$ = $1 - $3; }
    | expr '*' expr { $$ = $1 * $3; }
    | expr '/' expr { $$ = $1 / $3; }
    | '(' expr ')'  { $$ = $2; }
    ;
%%
int main() { return yyparse(); }
