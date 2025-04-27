# Makefile для сборки PolyLang

# Компилятор C++
CXX = g++
# Флаги компиляции C++ (включаем C++11 или новее для map и т.д.)
CXXFLAGS = -std=c++11 -Wall -g

# Инструменты Flex и Bison
FLEX = flex
BISON = bison
# Флаги Bison (генерировать заголовочный файл)
BISONFLAGS = -d

# Имя исполняемого файла
TARGET = polylang

# Исходные файлы
LEXER_SRC = lex.yy.c
PARSER_SRC = parser.tab.c
PARSER_HEADER = parser.tab.h
CPP_SRCS = main.cpp polynomial.cpp $(PARSER_SRC) $(LEXER_SRC)
OBJS = $(CPP_SRCS:.cpp=.o) $(PARSER_SRC:.c=.o) $(LEXER_SRC:.c=.o)

# Правила сборки

all: $(TARGET)

$(TARGET): $(OBJS) polynomial.o main.o parser.tab.o lex.yy.o
	$(CXX) $(CXXFLAGS) polynomial.o main.o parser.tab.o lex.yy.o -o $(TARGET)

main.o: main.cpp polynomial.h $(PARSER_HEADER)
	$(CXX) $(CXXFLAGS) -c main.cpp

polynomial.o: polynomial.cpp polynomial.h
	$(CXX) $(CXXFLAGS) -c polynomial.cpp

parser.tab.c parser.tab.h: parser.y polynomial.h
	$(BISON) $(BISONFLAGS) parser.y

parser.tab.o: parser.tab.c polynomial.h
	$(CXX) $(CXXFLAGS) -c parser.tab.c
lex.yy.c: lexer.l $(PARSER_HEADER) polynomial.h
	$(FLEX) lexer.l

lex.yy.o: lex.yy.c $(PARSER_HEADER) polynomial.h
	$(CXX) $(CXXFLAGS) -c lex.yy.c


# Правило для очистки
clean:
	rm -f $(TARGET) $(OBJS) lex.yy.c parser.tab.c parser.tab.h *.o *~
