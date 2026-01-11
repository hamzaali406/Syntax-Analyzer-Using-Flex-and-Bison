%{
#include <stdio.h>
#include <string.h>
#include "y.tab.h"

int line_num = 1;
%}

%option noyywrap
%option nounput

DIGIT   [0-9]
LETTER  [a-zA-Z_]
ID      {LETTER}({LETTER}|{DIGIT})*
NUM     {DIGIT}+(\.{DIGIT}+)?
STR     \"[^\"]*\"
WS      [ \t\r]

%%

[ \t\r]+    { /* skip */ }
\n          { line_num++; }

"start"     { return START; }
"end"       { return END; }
"show"      { return SHOW; }
"ifx"       { return IFX; }
"elsex"     { return ELSEX; }
"loop"      { return LOOP; }
"intx"      { return INTX; }
"floatx"    { return FLOATX; }
"strx"      { return STRX; }

{ID}        { yylval.strval = strdup(yytext); return IDENTIFIER; }
{NUM}       { yylval.strval = strdup(yytext); return NUMBER; }
{STR}       { 
                char* s = strdup(yytext);
                if (strlen(s) > 1) {
                    s[strlen(s)-1] = '\0';
                    memmove(s, s+1, strlen(s));
                }
                yylval.strval = s;
                return STRING;
            }

"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return MULT; }
"/"         { return DIVIDE; }
"="         { return ASSIGN; }  /* THIS IS THE CRITICAL LINE */
"=="        { return EQ; }
"!="        { return NE; }
"<"         { return LT; }
">"         { return GT; }
"<="        { return LE; }
">="        { return GE; }
"&&"        { return AND; }
"||"        { return OR; }

"{"         { return LBRACE; }
"}"         { return RBRACE; }
"("         { return LPAREN; }
")"         { return RPAREN; }
";"         { return SEMICOLON; }

.           { 
                /* Return the character itself if not recognized */
                return yytext[0]; 
            }

%%