CC=gcc
TARGET=interprete

all: $(TARGET)

$(TARGET): src/parser.y src/lexer.l
	bison -d -o src/parser.tab.c src/parser.y
	flex -o src/lex.yy.c src/lexer.l
	$(CC) -I src -o $(TARGET) src/parser.tab.c src/lex.yy.c

clean:
	rm -f $(TARGET) src/parser.tab.* src/lex.yy.c
