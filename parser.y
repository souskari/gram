%{
#include "polynomial.h"
#include <string>
#include <iostream>
#include <vector>
#include <map>

extern int yylex(); // Функция лексера
extern int yylineno; // Номер текущей строки
extern char *yytext; // Текущий токен (текст)
extern FILE *yyin; // Входной поток для лексера

void yyerror(const char *s);

// таблица : ключ - имя LET переменной, заечение - полином
std::map<std::string, Polynomial> symbolTable;

void printPolynomial(const Polynomial& p);

Polynomial getVariableValue(const std::string& name);
bool g_was_lexical_error = false;

%}

/* Объявление типов для семантических значений ($$, $1, ...) */
%union {
    Polynomial* poly; //для полинома
    std::string* sval; //для строк (переменные)
}

/* Токены */
%token <poly> NUMBER VARIABLE
%token <sval> USER_VARIABLE
%token PRINT ADD SUB MUL POW ASSIGN LPAREN RPAREN SEMICOLON UNARY_MINUS LEXICAL_ERROR

%type <poly> expression term factor primary

/* приоритеты (от низших к высшим) */
%left ADD SUB              /* Бинарные +, - */
%left MUL IMPLICIT_MUL   /* *, неявное умножение */
%right POW                 /* ^ */


%%

/* Грамматика */

program:
    /* Пустая программа */
  | statement_list
  ;

statement_list:
    statement //один оператор
  | statement_list statement //список операторов за которым идем 1 оператор
  ;

statement:
  print_statement SEMICOLON    { g_was_lexical_error = false; } // (PRINT ...)
  | USER_VARIABLE ASSIGN expression SEMICOLON {
        // Действие для присваивания: $1=USER_VARIABLE(sval*), $3=expression(poly*)
        symbolTable[*$1] = *$3;
        //std::cout << "$" << *$1 << " = " << *$3 << std::endl;
        delete $1;
        delete $3;
        g_was_lexical_error = false;
    }
  | error SEMICOLON              { yyerrok; }
  ;

print_statement:
    PRINT expression { printPolynomial(*$2); delete $2; }
  ;

/* Грамматика выражений*/
expression:
    term
  | expression ADD term            { $$ = new Polynomial(*$1 + *$3); delete $1; delete $3; }
  | expression SUB term            { $$ = new Polynomial(*$1 - *$3); delete $1; delete $3; } // Только БИНАРНЫЙ SUB
  ;

term:
    factor
  | term MUL factor                { $$ = new Polynomial(*$1 * *$3); delete $1; delete $3; }
  | term factor %prec IMPLICIT_MUL { $$ = new Polynomial(*$1 * *$2); delete $1; delete $2; }
  ;

factor:
    primary
  | primary POW factor   {
                            // $1 - base (Polynomial*)
                            // $3 - exponent (Polynomial*)

                            double exp_val = 0.0;

                            if ($3->terms.empty()) {
                                exp_val = 0.0;
                            } else if ($3->terms.size() == 1 && $3->terms.count(Monom())) {
                                exp_val = $3->terms.at(Monom());
                            } else {
                                yyerror("[Semantic error]: Even an orc from Mordor knows that the degree must be a number.");
                                delete $1; delete $3;
                                YYERROR;
                            }


                            const double EXP_EPSILON = 1e-9;
                            if (exp_val < -EXP_EPSILON) {
                                yyerror("[Semantic error]: Is it minus on the speedometer? You can't win the race that way.");
                                delete $1; delete $3;
                                YYERROR;
                            }

                            if (std::fabs(exp_val - std::round(exp_val)) > EXP_EPSILON) {
                                yyerror("[Semantic error]: You can't raise a sail and a half! The degree must be an integer");
                                delete $1; delete $3;
                                YYERROR;
                            }

                            int exponent = static_cast<int>(std::round(exp_val));

                            $$ = new Polynomial($1->power(exponent));

                            delete $1;
                            delete $3;
                         }
  | UNARY_MINUS factor   { $$ = new Polynomial(-(*$2)); delete $2; }
  ;

primary:
    NUMBER                         { $$ = $1; }
    | VARIABLE                     { $$ = $1; }
    | USER_VARIABLE                { $$ = new Polynomial(getVariableValue(*$1)); delete $1; }
    | LPAREN expression RPAREN     { $$ = $2; } //выражения в скобках
  ;

%%

#include <cstdio>
#include <cstring>

void printPolynomial(const Polynomial& p) {
    std::cout << p << std::endl;
}

// Функция получения значения переменной из таблицы символов
Polynomial getVariableValue(const std::string& name) {
    if (symbolTable.find(name) == symbolTable.end()) {
        char msg[256];
        snprintf(msg, sizeof(msg), "[Semantic error]: $%s? Captain Jack approves of rum, gold, and pistols, but not this variable.", name.c_str());
        yyerror(msg);
        return Polynomial();
    }
    return symbolTable[name];
}

void yyerror(const char *s) {
    fprintf(stderr, "[Error in line] %d: %s", yylineno, s);

    if (s && strcmp(s, "syntax error") == 0 && !g_was_lexical_error) {
          fprintf(stderr, ": Skipped ';' at the end of the line %d or an error in the structure of the expression next to '%s'\n", yylineno,
                  yytext ? yytext : "<unknown token>");
    } else {
        fprintf(stderr, "\n");
    }
}