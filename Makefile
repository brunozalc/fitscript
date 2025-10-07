CC = gcc
CFLAGS = -Wall -g

all: fitscript

fitscript.tab.c fitscript.tab.h: fitscript.y
	bison -d fitscript.y

lex.yy.c: fitscript.l fitscript.tab.h
	flex fitscript.l

fitscript: lex.yy.c fitscript.tab.c fitscript.tab.h
	$(CC) $(CFLAGS) -o fitscript lex.yy.c fitscript.tab.c

clean:
	rm -f fitscript lex.yy.c fitscript.tab.c fitscript.tab.h

test: fitscript
	./fitscript test.fit

.PHONY: all clean test
