%{
#include "parser.tab.h"
%}
%%
[0-9]+      { yylval = atoi(yytext); return NUM; }
[+\-*/()]   { return yytext[0]; }
\n          { return '\n'; }
[ \t]       ;
.           { return yytext[0]; }
%%
int yywrap() { return 1; }
