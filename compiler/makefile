# Andrew Boring
# CS 453
# Assignment 4a

CC = gcc
CFLAGS = -g -O2 -DYYDEBUG

# HFILES = compile.tab.h
CFILES = compile.lex.c compile.tab.c
BISOND = compile.y compile.h
FLEXD = compile.l compile.tab.h compile.h

compile: $(CFILES)
	$(CC) $(CFLAGS) $(CFILES) -lfl -o compile

compile.lex.c : ${FLEXD}
	flex -o compile.lex.c compile.l

compile.tab.h : $(BISOND)
	bison -dv compile.y

compile.tab.c : $(BISOND)
	bison -dv compile.y

clean :
	/bin/rm -f compile compile.lex.c compile.tab.c compile.tab.h *.o compile.output	
