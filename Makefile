CC     = gcc
CFLAGS = -Wall -Wno-unused-function -I src
SRC    = src

interprete: $(SRC)/parser.tab.c $(SRC)/lex.yy.c
	$(CC) $(CFLAGS) -o $@ $^ -lm

$(SRC)/parser.tab.c $(SRC)/parser.tab.h: $(SRC)/parser.y $(SRC)/ast.h
	bison -d -o $(SRC)/parser.tab.c $(SRC)/parser.y

$(SRC)/lex.yy.c: $(SRC)/lexer.l $(SRC)/parser.tab.h
	flex -o $@ $(SRC)/lexer.l

test: interprete
	./interprete ejemplos/ejemplo1.cal
	./interprete ejemplos/ejemplo2.cal

clean:
	rm -f interprete $(SRC)/parser.tab.* $(SRC)/lex.yy.c

.PHONY: test clean
