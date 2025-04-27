#include <iostream>
#include <fstream>
#include <cstdio>
#include <map>     
#include <string>  
#include "polynomial.h" 
#include "parser.tab.h"

extern int yyparse();
extern FILE *yyin; 
extern int yylineno;
extern std::map<std::string, Polynomial> symbolTable; // таблица символов

int main(int argc, char *argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <input_file>" << std::endl;
        return 1;
    }

    yyin = fopen(argv[1], "r");
    if (!yyin) {
        perror(argv[1]); 
        return 1;
    }

    yylineno = 1;

    int parse_result = yyparse();

    fclose(yyin);

    if (parse_result == 0) {
        std::cout << "Parsing finished successfully." << std::endl;
    } else {
        std::cerr << "Parsing failed with " << parse_result << " error(s)." << std::endl;
    }


    return parse_result; // 0 - успех, >0 - ошибка
}