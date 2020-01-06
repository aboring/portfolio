 /* Andrew Boring       */
 /* CSc 453             */
 /* Prof. Saumya Debray */
 /* Program 4a          */

%{
# include "compile.h"
# include "compile.tab.h"
%}

%option noyywrap
%option yylineno

 /* Definitions */

LETTER	[A-Za-z]
DIGIT	[0-9]
CH	[[:print:]]{-}[\\']

%x 	COMMENTS

%%

extern                                  { return EXT; }
void                                    { return VOID; }
char                                    { return CHAR; }
int                                     { return INT; }
while                                   { return WHILE; }
for                                     { return FOR; }
return                                  { return RETURN; }
if                                      { return IF; }
else                                    { return ELSE; }

"=="                                    { return EQU; }
"!="                                    { return NEQ; }
"<="                                    { return LTE; }
">="                                    { return GTE; }
"&&"                                    { return AND; }
"||"                                    { return OR; }
 
"++"                                    { return INC; }
"--"                                    { return DEC; }

{LETTER}({LETTER}|{DIGIT}|_)*		{ yylval.idName = strdup(yytext); return ID; }
{DIGIT}+				{ yylval.iVal = atoi(yytext); return INTCON; }
'{CH}'					{ yylval.iVal = yytext[1]; return CHARCON; }
'\\n'					{ yylval.iVal = '\n'; return CHARCON; }
'\\0'					{ yylval.iVal = '\0'; return CHARCON; }

"/*"					{ BEGIN(COMMENTS); }
<COMMENTS>"*/"				{ BEGIN(INITIAL); }
<COMMENTS><<EOF>>			{ yyerror(); return yytext[0]; }
<COMMENTS>.|\n                          { /* do nothing */ }


[[:space:]]				{ /* do nothing */ }

.					{ return yytext[0]; }

%%


