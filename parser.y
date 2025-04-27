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

%}

/* Объявление типов для семантических значений ($$, $1, ...) */
%union {
    Polynomial* poly; //для полинома
    std::string* sval; //для строк (переменные)
}

/* Токены */
%token <poly> NUMBER VARIABLE
%token <sval> USER_VARIABLE
%token LET PRINT
%token ADD SUB MUL POW ASSIGN LPAREN RPAREN SEMICOLON
%token UNARY_MINUS

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
    assignment_statement SEMICOLON { } // (LET ... = ...)
  | print_statement SEMICOLON    { } // (PRINT ...)
  | expression SEMICOLON         { printPolynomial(*$1); delete $1; } // просто выражение вида x+y*2 с ;
  | error SEMICOLON              { yyerrok; }
  ;

assignment_statement:
    LET USER_VARIABLE ASSIGN expression {

        /* LET $имя = значение;.

        $1: Токен LET

        $2: Токен USER_VARIABLE - имя переменной

        $3: Токен ASSIGN (=)

        $4: Нетерминал expression - результат вычисления полинома */

        symbolTable[*$2] = *$4;
        std::cout << "$" << *$2 << " = "; // Печать имени переменной
        printPolynomial(symbolTable[*$2]); // Печать результата
        delete $2;
    }
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
                            // $1 - primary (база, Polynomial*)
                            // $3 - factor (показатель степени, Polynomial*)

                            if ($3->terms.size() != 1 || !$3->terms.count(Monom())) {
                                yyerror("[Semantic error]: Даже орк из Мордора знает, что степень должна быть числом");
                                delete $1; delete $3;
                                YYERROR;
                            }

                            double exp_val = $3->terms.at(Monom());

                            const double EXP_EPSILON = 1e-9;

                            if (exp_val < -EXP_EPSILON) {
                                yyerror("[Semantic error]: На спидометре минус? Так гонку не выиграть");
                                delete $1; delete $3;
                                YYERROR;
                            }

                            if (std::fabs(exp_val - std::round(exp_val)) > EXP_EPSILON) {
                                yyerror("[Semantic error]: Нельзя поднять полтора паруса! Степень должна быть целой");
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

void printPolynomial(const Polynomial& p) {
    std::cout << "Result: " << p << std::endl;
}

// Функция получения значения переменной из таблицы символов
Polynomial getVariableValue(const std::string& name) {
    if (symbolTable.find(name) == symbolTable.end()) {
        char msg[256];
        snprintf(msg, sizeof(msg), "[Semantic error]: $%s? Капитан Джек одобряет ром, золото и пистолеты, но не эту переменную", name.c_str());
        yyerror(msg);
        return Polynomial();
    }
    return symbolTable[name];
}

void yyerror(const char *s) {
    fprintf(stderr, "[Error in line] %d: %s\n", yylineno, s);
    if (yytext && *yytext) { // Проверяем, что yytext не пуст
    }
}
