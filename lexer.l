%{
#include "polynomial.h"
#include <string>
#include "parser.tab.h"
#include <cstdlib>
#include <cmath>

extern void yyerror(const char *s);
extern int yylineno;

// Состояние лексера для определения типа минуса
// 0 - Начало выражения / после оператора/LPAREN/ASSIGN (ожидаем операнд или унарный минус)
// 1 - После операнда NUMBER/VARIABLE/USER_VARIABLE/RPAREN (ожидаем бинарный оператор или SEMICOLON/RPAREN)
int lexer_state = 0;

%}

/* для подсчета строк и чтобы при ошибке не выводилась дефолтная обработка, а моя кастомная */
%option noyywrap nodefault yylineno 

DIGIT    [0-9]
VARNAME  [a-z]
USERVAR  \$[a-zA-Z_][a-zA-Z0-9_]*

%%

<INITIAL>{
"LET"   { lexer_state = 0; return LET; }    /* переменная */
"PRINT" { lexer_state = 0; return PRINT; }  /* print */

{VARNAME}   {
                yylval.poly = new Polynomial(yytext[0]);
                lexer_state = 1;
                return VARIABLE;
            }

{USERVAR}   {
                yylval.sval = new std::string(yytext + 1);
                lexer_state = 1; 
                return USER_VARIABLE;
            }

{DIGIT}+("."{DIGIT}+)?([eE][+-]?{DIGIT}+)?  {
                yylval.poly = new Polynomial(atof(yytext));
                lexer_state = 1;
                return NUMBER;
            }

"+"     { lexer_state = 0; return ADD; }

"-"     {
            if (lexer_state == 0) {
                lexer_state = 0; /* После унарного минуса ожидаем операнд */
                return UNARY_MINUS;
            } else {
                lexer_state = 0; // После бинарного минуса ожидаем операнд
                return SUB;
            }
        }

"*"     { lexer_state = 0; return MUL; }
"^"     { lexer_state = 0; return POW; }
"("     { lexer_state = 0; return LPAREN; }
")"     { lexer_state = 1; return RPAREN; }
"="     { lexer_state = 0; return ASSIGN; }
";"     { lexer_state = 0; return SEMICOLON;}

[ \t\r]+ { }
\n+      { lexer_state = 0; }
"//".*   { }

.       {
            char msg[256];
            snprintf(msg, sizeof(msg), "[Lexical error]: Одно кольцо чтобы править всеми... Токен '%s' Мордора не пройдёт", yytext);
            yyerror(msg);
        }
}
%%