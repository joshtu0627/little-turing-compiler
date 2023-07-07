parser: lex.yy.c y.tab.c
	g++ lex.yy.c  y.tab.c -o parser

scanner: 

lex.yy.c: y.tab.h scanner_p3.l
	lex scanner_p3.l

y.tab.h: parser.y
	yacc -d -y parser.y

clean:
	rm -f lex.yy.c y.tab.c parser y.tab.h