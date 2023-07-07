%{
#include "symtab.h"
#include "y.tab.h"
#include<string>
#include<iostream>

#define LIST     strcat(buf,yytext)
#define token(t) {LIST; return(t);}
#define tokenInteger(t,i) {LIST; return(t);}
#define tokenFloat(t,f) {LIST;return(t);}
#define tokenString(t,s) {LIST; return(t);}

#define MAX_LINE_LENG 256

int linenum = 1;
char* symbolTable[MAX_LINE_LENG];
int nextIndex;
char buf[MAX_LINE_LENG];

// extern YYSTYPE yylval;
%}
%x  COMMENT_1
%x  COMMENT_2
%x  STRING

digit   [0-9]
digits  {digit}+
letter  [A-Za-z]
identifier {letter}({digit}|{letter}|"_")*
optional_fraction   ("."{digits})?
fraction   ("."{digits})
integer ({digits}|0)
real ({digit}|{digits}){fraction}

%%
".." {token(RANGE);}
"." {token(PERIOD);}
"," {token(COMMA);}
":" {token(COLON);}
";" {token(SEMICOLON);}
"(" {token(LPAREN);}
")" {token(RPAREN);}
"[" {token(LBRACKET);}
"]" {token(RBRACKET);}
"{" {token(LBRACE);}
"}" {token(RBRACE);}

"+" {token(PLUS);}
"-" {token(MINUS);}
"*" {token(MULT);}
"/" {token(DIV);}
"mod" {token(MOD);}
":=" {token(ASSIGN);}
"<" {token(LT);}
"<=" {token(LE);}
">=" {token(GE);}
">" {token(GT);}
"=" {token(EQ);}
"not=" {token(NEQ);}
"and" {token(AND);}
"or" {token(OR);}
"not" {token(NOT);}

"array" {token(ARRAY);}
"begin" {token(BEGI);}
"bool" {token(BOOL);}
"char" {token(CHAR);}
"const" {token(CONST);}
"decreasing" {token(DECREASING);}
"default" {token(DEFAULT);}
"do" {token(DO);}
"else" {token(ELSE);}
"end" {token(EN);}
"exit" {token(EXIT);}
"false" {token(FALSE);}
"for" {token(FOR);}
"function" {token(FUNCTION);}
"get" {token(GET);}
"if" {token(IF);}
"int" {token(INT);}
"loop" {token(LOOP);}
"of" {token(OF);}
"put" {token(PUT);}
"procedure" {token(PROCEDURE);}
"real" {token(REAL);}
"result" {token(RESULT);}
"return" {token(RETURN);}
"skip" {token(SKIP);}
"string" {token(STRIN);}
"then" {token(THEN);}
"true" {token(TRUE);}
"var" {token(VAR);}
"when" {token(WHEN);}

{integer}{identifier} {
                    LIST;
                    printf("bad character:'%s'\n",yytext);
                    // printf("%d:%s\n", linenum, buf);
                    exit(-1);
                }
{identifier}    {
                    // std::string temp(yytext);
                    // yylval.s=str;
                    // yylval.a=new std::string("123");
                    // yylval.temp=10;
                    yylval.name=strdup(yytext);
                    // printf("succes");
                    // printf("%d",yylval.sym->val.int_value);
                    tokenString(IDNAME, yytext);
                }
{integer}    {
                yylval.int_value=atoi(yytext);
                // printf("bbbbb%d",yylval.int_value);
                tokenInteger(INTEGER, atoi(yytext));
            }
{real}    {tokenFloat(REALNUMBER, atof(yytext));}

\n      {
        LIST;
        // printf("\n %s",  buf);
        buf[0] = '\0';
        token(NEWLINE);
        }

[ \t]*  {LIST;}

\"  {
    LIST;
    BEGIN(STRING);
    }
<STRING>[^\"]*  {yymore();}
<STRING>\"\"    {
                yymore();
                }

<STRING>\"  {
            LIST;
            yytext[yyleng - 1] = '\0';
            // printf("<string:");
            // for(int i=0;i<yyleng;i++){
            //     if(i<yyleng-1&&yytext[i]=='"'&&yytext[i+1]=='"'){
            //         printf("\"");
            //         i+=1;
            //     }
            //     else{
            //         printf("%c",yytext[i]);
            //     }
            // }
            // printf(">\n");
            // token(NEWLINE)
            BEGIN(0);
            // std::string a=std::string(yytext);
            yylval.string_value=strdup(yytext);
            token(STR);
            }

"{%" {
        LIST;
        BEGIN(COMMENT_2);
    }
<COMMENT_2>.*"%}\n"   {
                LIST;
                // printf("%d: %s", linenum++, buf);
                buf[0] = '\0';
                BEGIN(0);
                }

<COMMENT_2>.*\n   {
                LIST;
                // printf("%d: %s", linenum++, buf);
                buf[0] = '\0';
                }

"%" {   
        LIST;
        BEGIN(COMMENT_1);
    }

<COMMENT_1>.*\n   {
                LIST;
                // printf("%d: %s", linenum++, buf);
                buf[0] = '\0';
                BEGIN(0);
                }

.       {
        LIST;
        // printf("%d:%s\n", linenum, buf);
        printf("bad character:'%s'\n",yytext);
        exit(-1);
        }
%%
int yywrap(){
    return(1);
}
/* int main(int argc,char *argv[]){
    yyin=fopen(argv[1],"r");
    create();
    yylex();
    fclose(yyin);
    dump();
    exit(0);

}

void create(){
    nextIndex=0;
}
int lookup(char* s){
    for(int i=0;i<nextIndex;i++){
        if(strcmp( symbolTable[i], s)==0){
            return i;
        }
    }
    return -1;
}
int insert(char* s){
    // symbolTable[nextIndex]="";
    symbolTable[nextIndex]=malloc(((strlen(s)/sizeof(char))+1)*sizeof(char));
    strcpy(symbolTable[nextIndex],s);
    // printf("inserting %s in index %d\n",symbolTable[nextIndex],nextIndex);
    nextIndex+=1;
    return nextIndex-1;
}
void dump(){
    printf("\nSymbol Table:\n");
    // printf("len: %d\n",nextIndex);
    for(int i=0;i<nextIndex;i++){
        printf("%s\n",symbolTable[i]);
        // int p=0;
        // while(symbolTable[i][p]!='\0'){
        //     printf("%c",symbolTable[i][p]);
        //     p+=1;
        // }
        // printf("\n");
    }
} */
