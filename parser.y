%{
    #include<iostream>
    #include<vector>
    #include<unordered_map>
    #include<stack>
    #include<string>
    #include<fstream>
    using namespace std;
    #define Trace(t)        printf(t)
    #include "symtab.cpp"
    
    void yyerror(char *msg);
    extern int yylex();
    
    extern FILE *yyin;
    std::ofstream out;

    extern symbol_table_t global_symbol_table; // global symbol table
    extern symbol_stack_t symbol_stack; // symbol table stack

    extern function_table_t global_function_table; // function table

    int line=1;
    Symbol now_symbol; // the symbol to be inserted
    FunctionSymbol now_function; // the function to be inserted
    FunctionSymbol called_function; // the function now calling
    int now_arg_pos=0; // the arg now reading
    int expression_type=-1; // the state of the expression
    int temp_array_datatype=-1; // just a temp variable
    bool is_constexp=false; // is the expression need to be const
    int result_datatype=-1; // what datatype this function needs to return
    int result_type=-1; // what type this function needs to return
    int temp_type; // just a temp variable
    bool is_declaration_part=true;
    int const_static_value=0;
    bool assign_value=false;
    int label_counter=0;
    bool is_declaring_method=false;
    std::stack<Symbol> for_iterater_symbol; 
    string names[4] = {"int","real","bool""string"};
    string class_name = "abc";
    vector<string> string_const;
%}
%union{
    Symbol* sym;
    char* name;
    int datatype;
    int type;
    bool is_const;
    int int_value;
    bool bool_value;
    char* string_value;
}


/* %token IDNAME */
%token INTEGER
%token REALNUMBER
%token STR
%token PERIOD COMMA COLON SEMICOLON LPAREN RPAREN LBRACKET RBRACKET LBRACE RBRACE NEWLINE
%token PLUS MINUS MULT DIV MOD ASSIGN LT LE GE GT EQ NEQ AND OR NOT RANGE
%token ARRAY BEGI BOOL CHAR CONST DECREASING DEFAULT DO ELSE EN EXIT FALSE FOR FUNCTION GET IF INT LOOP OF PUT PROCEDURE REAL RESULT RETURN SKIP STRIN THEN TRUE VAR WHEN

/* %token <sym->name> IDNAME */
%token IDNAME

%left OR
%left AND
%nonassoc NOT
%left LT LE GE GT EQ NEQ
%left PLUS MINUS
%left MULT DIV MOD
%nonassoc UMINUS

%%

program: {
            symbol_stack.push(symbol_table_t());
            out<<"class "<<class_name<<endl;
            out<<"{"<<endl;
            
        }
        declaration_part 
        {
            cout<<"end of declaration";
            out<<"\tmethod public static void main(java.lang.String[])\n";
            out<<"\tmax_stack 15\n\tmax_locals 15\n";
            out<<"\t{\n";
            is_declaration_part=false;
        }no_declaration_statement_list{dumpGlobal();dumpFunction();
            
            out<<"return"<<endl;
            out<<"\t}\n";
            out<<"}";
        };

declaration_part:   
    newline_optional
    | declaration_part declaration newline_optional
    ;


newline_optional:    /* empty */
    | NEWLINE newline_optional 
        {
            line++;
            std::cout<<std::endl<<"line "<<line<<std::endl;
            expression_type=-1;
            now_symbol=Symbol();
            now_symbol.type=0;
            now_arg_pos=0;
            is_constexp=false;
            assign_value=false;
        }
    ;

statement_list_optional:    /* empty */
    | statement_list

statement_list:   
    newline_optional
    | statement_list statement newline_optional
    ;

no_declaration_statement_list:   
    newline_optional
    | no_declaration_statement_list no_declaration_statement newline_optional
    ;

no_declaration_statement:
    expression
    | selection_statement
    | loop_statement
    | {std::cout<<"PUT ";} PUT{
         out<<"getstatic java.io.PrintStream java.lang.System.out"<<endl;
    } expression {
       if(expression_type==0||expression_type==2){
            out<<"invokevirtual void java.io.PrintStream.println(Int)"<<endl;
       }
        else{
            out<<"invokevirtual void java.io.PrintStream.println(java.lang.String)"<<endl;
        }
    }
    | {std::cout<<"GET ";} GET {std::cout<<"IDNAME ";} IDNAME 
    | {std::cout<<"RESULT ";} RESULT {expression_type=result_datatype;}expression {
        cout<<"returning"<<endl;
        out<<"ireturn"<<endl;
    }
    | {std::cout<<"RETURN ";} RETURN {out<<"return"<<endl;}
    | {std::cout<<"SKIP ";} SKIP{
        out<<"getstatic java.io.PrintStream java.lang.System.out"<<endl;
        out<<"invokevirtual void java.io.PrintStream.println()"<<endl;
    }
    | var_assign
    | start_end_block
    ;

statement:
    declaration
    | expression
    | selection_statement
    | loop_statement
    | {std::cout<<"PUT ";} PUT{
         out<<"getstatic java.io.PrintStream java.lang.System.out"<<endl;
    } expression {
       if(expression_type==0||expression_type==2){
            out<<"invokevirtual void java.io.PrintStream.println(Int)"<<endl;
       }
        else{
            out<<"invokevirtual void java.io.PrintStream.println(java.lang.String)"<<endl;
        }
    }
    | {std::cout<<"GET ";} GET {std::cout<<"IDNAME ";} IDNAME 
    | {std::cout<<"RESULT ";} RESULT {expression_type=result_datatype;}expression {
        cout<<"returning"<<endl;
        out<<"ireturn"<<endl<<endl;
    }
    | {std::cout<<"RETURN ";} RETURN {out<<"return"<<endl;}
    | {std::cout<<"SKIP ";} SKIP{
        out<<"getstatic java.io.PrintStream java.lang.System.out"<<endl;
        out<<"invokevirtual void java.io.PrintStream.println()"<<endl;
    }
    | var_assign
    | start_end_block
    ;


expression:
    arithmetic_expression
    | function_call /* call function */
    | condition
    ;


when_optional:
    | {std::cout<<"WHEN ";} WHEN  expression /* when expression */
    ;

var_assign:  IDNAME assign_value { 
                                    std::cout<<$<name>1;
                                     if(lookupLocal($<name>1)){
                                        now_symbol=*lookupLocal($<name>1);
                                    }
                                    else if(lookupGlobal($<name>1)){
                                        now_symbol=*lookupGlobal($<name>1);
                                    }
                                    else{
                                        std::cout<<"var not exist"<<std::endl;
                                        return 1;
                                    } 
                                    if(now_symbol.is_const){
                                        std::cout<<"can not reassign const"<<std::endl;
                                        return 1;
                                    }
                                    if(expression_type!=now_symbol.datatype || now_symbol.type==1){
                                        cout<<now_symbol.name<<" "<<expression_type<<" "<<now_symbol.datatype<<endl;
                                        std::cout<<"type conflicted"<<std::endl;
                                        return 1;
                                    }

                                    if(now_symbol.is_global){
                                        out<<"putstatic int "<<class_name<<"."<<now_symbol.name<<endl;
                                    }
                                    else{
                                        out<<"istore "<<now_symbol.index<<endl;
                                    }
                                    std::cout<<"var assign";
                                    
                                };/* var id := value */
            | IDNAME LBRACKET expression {
                                            if(expression_type!=0){
                                            std::cout<<"invalid index"<<std::endl;
                                            return 1;
                                            }
                                            std::cout<<$<name>1;
                                            if(lookupLocal($<name>1)){
                                                now_symbol=*lookupLocal($<name>1);
                                            }
                                            else if(lookupGlobal($<name>1)){
                                                now_symbol=*lookupGlobal($<name>1);
                                            }
                                            else{
                                                std::cout<<"var not exist"<<std::endl;
                                                return 1;
                                            }
                                            if(now_symbol.is_const){
                                                std::cout<<"can not reassign const"<<std::endl;
                                                return 1;
                                            }
                                            temp_array_datatype=now_symbol.datatype;
                                            expression_type=-1;
                                            cout<<"datatype "<<temp_array_datatype<<endl;
                                        } RBRACKET assign_value {
                                    
                                    if(temp_array_datatype!=now_symbol.datatype ){
                                        std::cout<<now_symbol.datatype<<" "<<"type conflicted"<<std::endl;
                                        return 1;
                                    }
                                    std::cout<<"var assign to array";
                                }; /* var id[int] := value */
           
function_call:  
    IDNAME LPAREN {
        if(is_constexp){
            std::cout<<"function call in const expression"<<std::endl;
            return 1;
        }
        if(lookupGlobalFunc($<name>1)){
            called_function=*lookupGlobalFunc($<name>1);
        }
        else{
            std::cout<<"function not exist"<<std::endl;
            return 1;
        }
        
    } call_parameter_list {
        if(now_arg_pos<called_function.arg_types.size()){
            std::cout<<"too few args"<<std::endl;
            return 1;
        }
    }RPAREN {std::cout<<"function call";
    if(expression_type!=-1){
            if(expression_type!=called_function.return_datatype){
                std::cout<<"type conflicted"<<std::endl;
                return 1;
            }
        }
        else{
            
            expression_type = called_function.return_datatype;
        }
        
        if(called_function.is_procedure){
            out<<"invokestatic void "<<class_name<<"."<<called_function.name<<"(";
        }
        else{
            out<<"invokestatic int "<<class_name<<"."<<called_function.name<<"(";
        }
        if(called_function.arg_types.size()>0){
            out<<"int";
            for(int i=0;i<called_function.arg_types.size()-1;i++){
                out<<", "<<"int"; 
            }
        }
        out<<")"<<endl;
        now_arg_pos=0;
    }
    ;
    
call_parameter_list:    /* empty */
    |   call_argument 
    |   call_parameter_list {std::cout<<"COMMA ";}COMMA {std::cout<<"last arg ";}call_argument  
    ; /* args list that is called */
    
call_argument:
    primary_expression {
        if(now_arg_pos==called_function.arg_types.size()){
            std::cout<<"too much args"<<std::endl;
            return 1;
        }
        if(expression_type!=called_function.arg_types[now_arg_pos]){
            cout<<called_function.name<<std::endl;
            cout<<expression_type<<" "<<called_function.arg_types[now_arg_pos]<<endl;
            std::cout<<"arg type conflicted"<<std::endl;
            return 1;
        }
        now_arg_pos++;
        expression_type=-1;
    } /* arg that is called */
    ;




primary_expression: 
    IDNAME {    
                Symbol temp_symbol;
                std::cout<<"IDNAME "; 
                if(lookupLocal($<name>1)){
                    temp_symbol=*lookupLocal($<name>1);
                }
                else if(lookupGlobal($<name>1)){
                    temp_symbol=*lookupGlobal($<name>1);
                }
                else{
                    std::cout<<"var not exist"<<std::endl;
                    return 1;
                }
                if(temp_symbol.datatype==3){
                    cout<<"abbbb"<<endl;
                        out<<"ldc \""<<temp_symbol.string_value<<"\" "<<endl;
                    }
                else{
                    if(temp_symbol.is_global){
                        
                        out<<"getstatic int "<<class_name<<"."<<temp_symbol.name<<endl;
                        
                    }
                    else{
                        out<<"iload_"<<temp_symbol.index<<endl;
                    }
                    
                    if(is_constexp&&!temp_symbol.is_const){
                        std::cout<<"var in const expression"<<std::endl;
                        return 1;
                    }
                    if(expression_type!=-1){
                        if(temp_symbol.datatype!=expression_type){
                            std::cout<<"type conflicted"<<std::endl;
                            return 1;
                        }
                    }
                    else{
                        expression_type = temp_symbol.datatype;
                    }
                }
            }
    | {std::cout<<"INTEGER ";}INTEGER {
                                if(expression_type!=-1){
                                    if(expression_type!=0){
                                        std::cout<<"type conflicted"<<std::endl;
                                        return 1;
                                    }
                                }
                                else{
                                    expression_type = 0;
                                }

                                if(!is_declaration_part){
                                    out<<"sipush "<<$<int_value>2<<endl;
                                }
                                else{
                                    const_static_value=$<int_value>2;
                                    if (is_declaring_method){
                                        out<<"sipush "<<$<int_value>2<<endl;
                                    }
                                    
                                }
                                // cout<<"aaaaaaa "<<$<int_value>2<<endl;
                            }
    | {std::cout<<"REALNUMBER ";}REALNUMBER {
                                now_symbol.datatype=1;
                                if(expression_type!=-1){
                                    if(expression_type!=1){
                                        std::cout<<"type conflicted"<<std::endl;
                                        return 1;
                                    }
                                }
                                else{
                                    expression_type = 1;
                                }
                            }
    | {std::cout<<"BOOL ";}TRUE {
                                now_symbol.datatype=2;
                                if(expression_type!=-1){
                                    if(expression_type!=2){
                                        std::cout<<"type conflicted"<<std::endl;
                                        return 1;
                                    }
                                }
                                else{
                                    expression_type = 2;
                                }
                                if(!is_declaration_part){
                                    out<<"iconst_1"<<endl;
                                }
                                else{
                                    const_static_value=1;
                                    if (is_declaring_method){
                                        out<<"iconst_1"<<endl;
                                    }
                                }
                            }
    | {std::cout<<"BOOL ";}FALSE {
                                now_symbol.datatype=2;
                                if(expression_type!=-1){
                                    if(expression_type!=2){
                                        std::cout<<"type conflicted"<<std::endl;
                                        return 1;
                                    }
                                }
                                else{
                                    expression_type = 2;
                                }
                                if(!is_declaration_part){
                                    out<<"iconst_0"<<endl;
                                }
                                else{
                                    const_static_value=0;
                                    if (is_declaring_method){
                                        out<<"iconst_0"<<endl;
                                    }
                                }
                            }
    | {std::cout<<"STR ";}STR{
                                now_symbol.datatype=3;
                                if(expression_type!=-1){
                                    if(expression_type!=3){
                                        std::cout<<"type conflicted"<<std::endl;
                                        return 1;
                                    }
                                }
                                else{
                                    expression_type = 3;
                                }
                                if(assign_value){
                                    now_symbol.string_value=string($<string_value>2);
                                }
                                if(!assign_value){
                                    
                                out<<"ldc \""<<$<string_value>2<<"\""<<endl;
                                }
                               
                            }
    | IDNAME LBRACKET{std::cout<<"LBRACKET ";temp_type=expression_type;expression_type=0;} arithmetic_expression {std::cout<<"RBRACKET ";}RBRACKET {    
                Symbol temp_symbol;
                expression_type=temp_type;
                std::cout<<"IDNAME "; 
                if(lookupLocal($<name>1)){
                    temp_symbol=*lookupLocal($<name>1);
                }
                else if(lookupGlobal($<name>1)){
                    temp_symbol=*lookupGlobal($<name>1);
                }
                else{
                    std::cout<<"var not exist"<<std::endl;
                    return 1;
                }
                if(expression_type!=-1){
                    if(temp_symbol.datatype!=expression_type){
                        std::cout<<"type conflicted"<<std::endl;
                        return 1;
                    }
                }
                else{
                    expression_type = temp_symbol.datatype;
                }
            }
    ;

start_end_block: BEGI{std::cout<<"BEGIN ";} newline_optional block newline_optional EN /* begin statements end */

block: 
    |   {
            symbol_stack.push(symbol_table_t());std::cout<<"enter block, table pushed"<<std::endl;
        }statement_list
        {
            dumpLocal();
            symbol_stack.pop();
            std::cout<<"END block, stack poped "<<std::endl;
        }
    ; /* block */

exit_when_block: 
    |   { 
            label_counter+=1;// 1
            out<<"L"<<label_counter<<":"<<endl; // Lbegin(1)
            out<<"/* for not error */"<<endl;
            out<<"iconst_0"<<endl;
            out<<"pop"<<endl;
            out<<"/* for not error */"<<endl;
            label_counter*=10;
            symbol_stack.push(symbol_table_t());std::cout<<"enter block, table pushed"<<std::endl;
        }statement_list_optional EXIT when_optional
        {
            out<<"ifgt L"<<label_counter/10+1<<endl; // goto exit(2)
        } statement_list_optional
        {
            dumpLocal();
            symbol_stack.pop();
            std::cout<<"END block, stack poped "<<std::endl;
            
            label_counter/=10;
            out<<"goto L"<<label_counter<<endl; // goto Lbegin(1)
            label_counter+=1; // 2
            out<<"L"<<label_counter<<":"<<endl<<endl; // exit(2)
            out<<"/* for not error */"<<endl;
            out<<"iconst_0"<<endl;
            out<<"pop"<<endl;
            out<<"/* for not error */"<<endl;
        }
    ; /* block */


selection_statement:    
    {std::cout<<"IF ";}IF expression  {
        std::cout<<"THEN ";

        label_counter+=1; // 1
        out<<"ifeq L"<<label_counter<<endl; // goto false(1)
        label_counter*=10; // 10
    }THEN newline_optional block {
        label_counter/=10; // 1
        label_counter+=1; // 2
        out<<"goto L"<<label_counter<<endl; // goto exit(2)
        out<<"L"<<label_counter-1<<":"<<endl; // false(1)
        out<<"/* for not error */"<<endl;
        out<<"iconst_0"<<endl;
        out<<"pop"<<endl;
        out<<"/* for not error */"<<endl;
        label_counter*=10; // 20
    }else_optional {std::cout<<"END ";}EN  {std::cout<<"IF ";}IF {
        label_counter/=10; // 2
        out<<"L"<<label_counter<<":"<<endl;
        out<<"/* for not error */"<<endl;
        out<<"iconst_0"<<endl;
        out<<"pop"<<endl;
        out<<"/* for not error */"<<endl;
    } // exit(2)
    // assume there is a else
    ; /* if else statement */

else_optional:  /* empty */
    | {std::cout<<"ELSE ";}ELSE newline_optional block
    ; /* else part */

loop_statement: 
    {std::cout<<"LOOP ";}LOOP newline_optional exit_when_block {std::cout<<"END ";}EN {std::cout<<"LOOP ";}LOOP newline_optional /* loop */
    |   FOR DECREASING IDNAME {std::cout<<"IDNAME ";is_constexp=true;} 
     {std::cout<<"COLON ";}COLON expression {    
                Symbol temp_symbol;
                std::cout<<"IDNAME "; 
                if(lookupLocal($<name>3)){
                    temp_symbol=*lookupLocal($<name>3);
                }
                else if(lookupGlobal($<name>3)){
                    temp_symbol=*lookupGlobal($<name>3);
                }
                else{
                    std::cout<<"var not exist"<<std::endl;
                    return 1;
                }
                for_iterater_symbol.push(temp_symbol);
                if(!for_iterater_symbol.top().is_global){
                    out<<"istore "<<for_iterater_symbol.top().index<<endl;
                }
                else{
                    out<<"putstatic int "<<class_name<<"."<<temp_symbol.name<<endl;
                }
                label_counter+=1;// 1
                out<<"L"<<label_counter<<":"<<endl; // Lcondition(1)
                out<<"/* for not error */"<<endl;
                out<<"iconst_0"<<endl;
                out<<"pop"<<endl;
                out<<"/* for not error */"<<endl;
                if(!for_iterater_symbol.top().is_global){
                    out<<"iload "<<for_iterater_symbol.top().index<<endl;
                }
                else{
                    out<<"getstatic int "<<class_name<<"."<<temp_symbol.name<<endl;
                }
                
                if(temp_symbol.is_const){
                    std::cout<<"const in changing expression"<<std::endl;
                    return 1;
                }
                if(expression_type!=-1){
                    if(temp_symbol.datatype!=expression_type){
                        std::cout<<"type conflicted"<<std::endl;
                        return 1;
                    }
                }
                else{
                    expression_type = temp_symbol.datatype;
                }
            }{std::cout<<"RANGE ";}RANGE expression{
                out<<"isub"<<endl;
                label_counter+=1; // 2
                out<<"iflt L"<<label_counter<<endl;
                out<<"/* for not error */"<<endl;
                out<<"iconst_0"<<endl;
                out<<"pop"<<endl;
                out<<"/* for not error */"<<endl;
            } newline_optional{
        label_counter*=10;
     } block {std::cout<<"END ";}EN {std::cout<<"FOR ";}FOR newline_optional{
        label_counter/=10;
        if(!for_iterater_symbol.top().is_global){
                    out<<"iload "<<for_iterater_symbol.top().index<<endl;
                }
        else{
            out<<"getstatic int "<<class_name<<"."<<for_iterater_symbol.top().name<<endl;
        }
        out<<"iconst_1"<<endl;
        out<<"isub"<<endl;
        if(!for_iterater_symbol.top().is_global){
            out<<"istore "<<for_iterater_symbol.top().index<<endl;
        }
        else{
            out<<"putstatic int "<<class_name<<"."<<for_iterater_symbol.top().name<<endl;
        }
        out<<"goto L"<<label_counter-1<<endl; // goto Lcondition(1)
        out<<"L"<<label_counter<<":"<<endl<<endl; // exit(2)
        out<<"/* for not error */"<<endl;
        out<<"iconst_0"<<endl;
        out<<"pop"<<endl;
        out<<"/* for not error */"<<endl;
        for_iterater_symbol.pop();
     }
    |   FOR IDNAME  {std::cout<<"IDNAME ";is_constexp=true;}
     {std::cout<<"COLON ";}COLON expression {    
                Symbol temp_symbol;
                std::cout<<"IDNAME "; 
                if(lookupLocal($<name>2)){
                    temp_symbol=*lookupLocal($<name>2);
                }
                else if(lookupGlobal($<name>2)){
                    temp_symbol=*lookupGlobal($<name>2);
                }
                else{
                    std::cout<<"var not exist"<<std::endl;
                    return 1;
                }
                for_iterater_symbol.push(temp_symbol);
                if(!for_iterater_symbol.top().is_global){
                    out<<"istore "<<for_iterater_symbol.top().index<<endl;
                }
                else{
                    out<<"putstatic int "<<class_name<<"."<<temp_symbol.name<<endl;
                }
                label_counter+=1;// 1
                out<<"L"<<label_counter<<":"<<endl; // Lcondition(1)
                out<<"/* for not error */"<<endl;
                out<<"iconst_0"<<endl;
                out<<"pop"<<endl;
                out<<"/* for not error */"<<endl;
                if(!for_iterater_symbol.top().is_global){
                    out<<"iload "<<for_iterater_symbol.top().index<<endl;
                }
                else{
                    out<<"getstatic int "<<class_name<<"."<<temp_symbol.name<<endl;
                }
                
                if(temp_symbol.is_const){
                    std::cout<<"const in changing expression"<<std::endl;
                    return 1;
                }
                if(expression_type!=-1){
                    if(temp_symbol.datatype!=expression_type){
                        std::cout<<"type conflicted"<<std::endl;
                        return 1;
                    }
                }
                else{
                    expression_type = temp_symbol.datatype;
                }
            }{std::cout<<"RANGE ";}RANGE expression{
                out<<"isub"<<endl;
                label_counter+=1; // 2
                out<<"ifgt L"<<label_counter<<endl;
                out<<"/* for not error */"<<endl;
                out<<"iconst_0"<<endl;
                out<<"pop"<<endl;
                out<<"/* for not error */"<<endl;
            } newline_optional{
        label_counter*=10;
     } block {std::cout<<"END ";}EN {std::cout<<"FOR ";}FOR newline_optional{
        label_counter/=10;
        if(!for_iterater_symbol.top().is_global){
                    out<<"iload "<<for_iterater_symbol.top().index<<endl;
                }
        else{
            out<<"getstatic int "<<class_name<<"."<<for_iterater_symbol.top().name<<endl;
        }
        out<<"iconst_1"<<endl;
        out<<"iadd"<<endl;
        if(!for_iterater_symbol.top().is_global){
            out<<"istore "<<for_iterater_symbol.top().index<<endl;
        }
        else{
            out<<"putstatic int "<<class_name<<"."<<for_iterater_symbol.top().name<<endl;
        }
        out<<"goto L"<<label_counter-1<<endl; // goto Lcondition(1)
        out<<"L"<<label_counter<<":"<<endl<<endl; // exit(2)
        out<<"/* for not error */"<<endl;
        out<<"iconst_0"<<endl;
        out<<"pop"<<endl;
        out<<"/* for not error */"<<endl;
        for_iterater_symbol.pop();
     }
    
    ; /* for loop */

arithmetic_expression:  
    arithmetic_expression PLUS{std::cout<<"PLUS ";} arithmetic_expression{
        out<<"iadd"<<endl;
    }
    |   arithmetic_expression MINUS{std::cout<<"MINUS ";} arithmetic_expression{
        out<<"isub"<<endl;
    }
    |   arithmetic_expression MULT{std::cout<<"MULT ";} arithmetic_expression{
        out<<"imul"<<endl;
    }
    |   arithmetic_expression DIV{std::cout<<"DIV ";} arithmetic_expression{
        out<<"idiv"<<endl;
    }
    |   arithmetic_expression MOD{std::cout<<"MOD ";} arithmetic_expression{
        out<<"irem"<<endl;
    }
    |   LPAREN arithmetic_expression {std::cout<<"RPAREN ";}RPAREN
    |   primary_expression
    |   MINUS arithmetic_expression {std::cout<<"UMINUS "; out<<"ineg"<<endl;}  %prec UMINUS
    |   function_call
    ; /* arithmetic calculation */

condition:
    expression {std::cout<<"GT ";}GT expression {
        out<<endl<<"isub"<<endl;
        label_counter+=1;
        out<<"ifgt L"<<label_counter<<endl; // goto true(1)
        out<<"iconst_0"<<endl;
        label_counter+=1;
        out<<"goto L"<<label_counter<<endl; // goto exit(2)
        out<<"L"<<label_counter-1<<":"<<endl; // true(1)
        out<<"iconst_1"<<endl;
        out<<"L"<<label_counter<<":"<<endl<<endl; // exit(2) 
        out<<"/* for not error */"<<endl;
        out<<"iconst_0"<<endl;
        out<<"pop"<<endl;
        out<<"/* for not error */"<<endl;
    }
    |   expression {std::cout<<"GE ";}GE expression{
        out<<endl<<"isub"<<endl;
        label_counter+=1;
        out<<"ifge L"<<label_counter<<endl; // goto true(1)
        out<<"iconst_0"<<endl;
        label_counter+=1;
        out<<"goto L"<<label_counter<<endl; // goto exit(2)
        out<<"L"<<label_counter-1<<":"<<endl; // true(1)
        out<<"iconst_1"<<endl;
        out<<"L"<<label_counter<<":"<<endl<<endl; // exit(2) 
        out<<"/* for not error */"<<endl;
        out<<"iconst_0"<<endl;
        out<<"pop"<<endl;
        out<<"/* for not error */"<<endl;
    }
    |   expression {std::cout<<"LT ";}LT expression{
        out<<endl<<"isub"<<endl;
        label_counter+=1;
        out<<"iflt L"<<label_counter<<endl; // goto true(1)
        out<<"iconst_0"<<endl;
        label_counter+=1;
        out<<"goto L"<<label_counter<<endl; // goto exit(2)
        out<<"L"<<label_counter-1<<":"<<endl; // true(1)
        out<<"iconst_1"<<endl;
        out<<"L"<<label_counter<<":"<<endl<<endl; // exit(2) 
        out<<"/* for not error */"<<endl;
        out<<"iconst_0"<<endl;
        out<<"pop"<<endl;
        out<<"/* for not error */"<<endl;
    }
    |   expression {std::cout<<"LE ";}LE expression{
        out<<endl<<"isub"<<endl;
        label_counter+=1;
        out<<"ifle L"<<label_counter<<endl; // goto true(1)
        out<<"iconst_0"<<endl;
        label_counter+=1;
        out<<"goto L"<<label_counter<<endl; // goto exit(2)
        out<<"L"<<label_counter-1<<":"<<endl; // true(1)
        out<<"iconst_1"<<endl;
        out<<"L"<<label_counter<<":"<<endl<<endl; // exit(2) 
        out<<"/* for not error */"<<endl;
        out<<"iconst_0"<<endl;
        out<<"pop"<<endl;
        out<<"/* for not error */"<<endl;
    }
    |   expression {std::cout<<"NEQ ";}NEQ expression{
        out<<endl<<"isub"<<endl;
        label_counter+=1;
        out<<"ifne L"<<label_counter<<endl; // goto true(1)
        out<<"iconst_0"<<endl;
        label_counter+=1;
        out<<"goto L"<<label_counter<<endl; // goto exit(2)
        out<<"L"<<label_counter-1<<":"<<endl; // true(1)
        out<<"iconst_1"<<endl;
        out<<"L"<<label_counter<<":"<<endl<<endl; // exit(2) 
        out<<"/* for not error */"<<endl;
        out<<"iconst_0"<<endl;
        out<<"pop"<<endl;
        out<<"/* for not error */"<<endl;
    }
    |   expression {std::cout<<"EQ ";}EQ expression{
        out<<endl<<"isub"<<endl;
        label_counter+=1;
        out<<"ifeq L"<<label_counter<<endl; // goto true(1)
        out<<"iconst_0"<<endl;
        label_counter+=1;
        out<<"goto L"<<label_counter<<endl; // goto exit(2)
        out<<"L"<<label_counter-1<<":"<<endl; // true(1)
        out<<"iconst_1"<<endl;
        out<<"L"<<label_counter<<":"<<endl<<endl; // exit(2) 
        out<<"/* for not error */"<<endl;
        out<<"iconst_0"<<endl;
        out<<"pop"<<endl;
        out<<"/* for not error */"<<endl;
    }
    |   {std::cout<<"NOT ";}NOT expression{
        out<<"iconst_1"<<endl;
        out<<"ixor"<<endl;
    }
    |   expression {std::cout<<"AND ";}AND expression{
        out<<"iand"<<endl;
    }
    |   expression {std::cout<<"OR ";}OR expression{
        out<<"ior"<<endl;
    }
    |   LPAREN condition RPAREN
    ; /* codition statement */

declaration:    
    var_declaration /* var declaring */
    |   function_declaration /* function declaring */
    |   procedure_declaration /* procedure declaring */
    ;

var_declaration:     
    VAR IDNAME  {is_constexp=true;}assign_var{
                            
                                    // std::cout<<"valaaa "<<$<sym->val.int_value>1;
                             now_symbol.name=std::string($<name>2);
                             now_symbol.is_const=false;
                             if(now_symbol.datatype==-1)
                                now_symbol.datatype=expression_type;
                             std::cout<<now_symbol.name<<" ";
                             std::cout<<now_symbol.datatype<<" ";
                             std::cout<<now_symbol.type<<" ";
                             if(symbol_stack.empty()&&lookupGlobal(now_symbol.name)!=NULL){
                                    std::cout<<"duplicate declaration";
                                    return 1;
                                }
                                
                                if(lookupLocal(now_symbol.name,false)==NULL){
                                    insert(now_symbol);
                                    if(symbol_stack.size()>1){
                                        if(!assign_value){
                                            out<<"iconst_0"<<endl;
                                            out<<"istore "<<symbol_stack.top()[now_symbol.name]->index<<endl;
                                        }
                                        else{
                                            out<<"istore "<<symbol_stack.top()[now_symbol.name]->index<<endl;
                                        }
                                    }
                                }
                                else{
                                    std::cout<<"duplicate declaration";
                                    return 1;
                                }
                            if (now_symbol.datatype != 3){
                                
                                
                                if(symbol_stack.size()==1){
                                    out<<"\tfield static";
                                    if (now_symbol.datatype == 0){
                                        out<<" int ";
                                    }
                                    else if (now_symbol.datatype == 1){
                                        out<<" float ";
                                    }
                                    else if (now_symbol.datatype == 2){
                                        out<<" int ";
                                    }
                                    out<<now_symbol.name;
                                    
                                    if(is_declaration_part&&assign_value){
                                        out<<" = "<<const_static_value<<endl;
                                    }
                                    else{
                                        out<<endl;
                                    }
                                }

                                
                                }
                            } /* var id := value */
    |    CONST IDNAME {is_constexp=true;}assign_var{
                                    now_symbol.name=std::string($<name>2);
                                    now_symbol.is_const=true;
                                    now_symbol.datatype=expression_type;
                                    std::cout<<now_symbol.name<<" ";
                                    std::cout<<now_symbol.datatype<<" ";
                                    std::cout<<now_symbol.type<<" ";
                                    if(symbol_stack.empty()&&lookupGlobal(now_symbol.name)!=NULL){
                                        std::cout<<"duplicate declaration";
                                        return 1;
                                    }
                                    if(lookupLocal(now_symbol.name,false)==NULL){
                                        insert(now_symbol);
                                        if(symbol_stack.size()>1){
                                            if(!assign_value){
                                                out<<"iconst_0"<<endl;
                                                out<<"istore "<<symbol_stack.top()[now_symbol.name]->index<<endl;
                                            }
                                            else{
                                                out<<"istore "<<symbol_stack.top()[now_symbol.name]->index<<endl;
                                            }
                                        }
                                    }
                                    else{
                                        std::cout<<"duplicate declaration";
                                        return 1;
                                    }
                                    if (now_symbol.datatype != 3){
                                    if(symbol_stack.size()==1){
                                        out<<"\tfield static";
                                        if (now_symbol.datatype == 0){
                                            out<<" int ";
                                        }
                                        else if (now_symbol.datatype == 1){
                                            out<<" float ";
                                        }
                                        else if (now_symbol.datatype == 2){
                                            out<<" bool ";
                                        }
                                        else if (now_symbol.datatype == 3){
                                            out<<" string ";
                                        }
                                        out<<now_symbol.name;
                                        
                                        if(is_declaration_part&&assign_value){
                                            out<<" = "<<const_static_value<<endl;
                                        }
                                        else{
                                            out<<endl;
                                        }
                                    }

                                    
                                    }
                                } /* const id := value */
    ;

assign_var:     
    assign_type assign_value /* var id : type := value */
    |   assign_value /* var id := value */
    |   assign_type /* var id : type */
    ;

assign_value:   
     ASSIGN  {std::cout<<"ASSIGN "; 
                if(now_symbol.datatype!=-1){
                    expression_type=now_symbol.datatype;}
                assign_value=true;
                } expression 
    ;

assign_type:    
    {std::cout<<"COLON ";}COLON type_specifier
    ;

function_declaration:   
    FUNCTION IDNAME {std::cout<<"LPAREN ";}LPAREN{
                is_declaring_method=true;
                symbol_stack.push(symbol_table_t());
                std::cout<<"enter function declaration, table pushed";
            } parameter_list {
            if(lookupGlobalFunc($<name>2)){
                std::cout<<"function re-declared"<<std::endl;
                return 1;
            }
            now_function.name=std::string($<name>2);
            
        }
        {std::cout<<"RPAREN ";}RPAREN {std::cout<<"COLON ";}COLON return_type_specifier newline_optional 
        {
            out<<"method public static int "<<now_function.name;
            out<<"(";
            if(now_function.arg_types.size()>0){
                out<<"int";
                for(int i=0;i<now_function.arg_types.size()-1;i++){
                    out<<", "<<"int"; 
                }
            }
            out<<")"<<endl;
            out<<"\tmax_stack 15\n\tmax_locals 15\n";
            out<<"{"<<endl;
        }   
        statement_list {
            std::cout<<"END ";dumpLocal();
            symbol_stack.pop();
            std::cout<<"END function declaration, stack poped ";
            } EN{std::cout<<"IDNAME ";}IDNAME {std::string temp=$<name>19;
            if($<name>2!=temp){std::cout<<"end wrong idname"<<std::endl; return 1;}
            insertFunc(now_function);

            now_function=FunctionSymbol();

            out<<"}"<<endl;
            is_declaring_method=false;
            }
    ;

procedure_declaration: 
    PROCEDURE IDNAME {std::cout<<"LPAREN ";}LPAREN{
                is_declaring_method=true;
                symbol_stack.push(symbol_table_t());
                std::cout<<"enter procedure declaration, table pushed";
            } parameter_list {
            if(lookupGlobalFunc($<name>2)){
                std::cout<<"procedure re-declared"<<std::endl;
                return 1;
            }
            now_function.name=std::string($<name>2);
            now_function.is_procedure=true;
            insertFunc(now_function);
        }
        {std::cout<<"RPAREN ";}RPAREN {std::cout<<"COLON ";} newline_optional{
            out<<"method public static void "<<now_function.name;
            out<<"(";
            if(now_function.arg_types.size()>0){
                out<<"int";
                for(int i=0;i<now_function.arg_types.size()-1;i++){
                    out<<", "<<"int"; 
                }
            }
            out<<")"<<endl;
            out<<"\tmax_stack 15\n\tmax_locals 15\n";
            out<<"{"<<endl;
        } statement_list {
            std::cout<<"END ";dumpLocal();
            symbol_stack.pop();
            std::cout<<"END procedure declaration, stack poped ";
            } EN{std::cout<<"IDNAME ";}IDNAME {
            std::string temp=$<name>17;
            if($<name>2!=temp){std::cout<<"end wrong idname"<<std::endl; return 1;}
            out<<"}"<<endl;
            is_declaring_method=false;
            
            now_function=FunctionSymbol();
        }
    ;

parameter_list:     /* empty */
    |   parameter_declaration {now_function.num_args+=1; now_function.arg_types.push_back(now_symbol.datatype); }
    |   parameter_list {std::cout<<"COMMA ";}COMMA parameter_declaration {now_function.num_args+=1; now_function.arg_types.push_back(now_symbol.datatype);}
    ; /* list of parameters of function declaring */

parameter_declaration:  
    IDNAME{std::cout<<"IDNAME ";} {std::cout<<"COLON ";}COLON type_specifier{
        now_symbol.name=std::string($<name>1);
        now_symbol.is_const=false;
        insert(now_symbol);
    }
    ; /* parameter of function declaring */



type_specifier:     
    INT {std::cout<<"INT ";} {now_symbol.datatype=0; now_symbol.type=0; }
    |   REAL {std::cout<<"REAL ";} {now_symbol.datatype=1;now_symbol.type=0;}
    |   BOOL {std::cout<<"BOOL ";}{now_symbol.datatype=2;now_symbol.type=0;}
    |   STRIN {std::cout<<"STRING ";}{now_symbol.datatype=3;now_symbol.type=0;}
    |   ARRAY {std::cout<<"ARRAY ";}{std::cout<<"INTEGER ";}INTEGER {std::cout<<"RANGE ";}RANGE {std::cout<<"INTEGER ";}INTEGER {std::cout<<"OF";}OF  type_specifier{now_symbol.type=1;}
    ; /* specifier of types */

return_type_specifier:     
    {std::cout<<"INT ";}INT {now_function.return_datatype=0; result_type=0;result_datatype=0;}
    |   {std::cout<<"REAL ";}REAL {now_function.return_datatype=1;result_type=0;result_datatype=1;}
    |   {std::cout<<"BOOL ";}BOOL {now_function.return_datatype=2;result_type=0;result_datatype=2;}
    |   {std::cout<<"STRING ";}STRIN {now_function.return_datatype=3;cout<<"11111 "<<now_function.return_datatype;result_type=0;result_datatype=3;}
    |   {std::cout<<"ARRAY ";}ARRAY {std::cout<<"INTEGER ";}INTEGER {std::cout<<"RANGE ";result_type=1;}RANGE {std::cout<<"INTEGER ";}INTEGER {std::cout<<"OF";}OF return_type_specifier
    ; /* specifier of return types */

%%
/* #include "lex.yy.c" */

void yyerror(char *msg){
    std::cout<<msg<<std::endl;
}

int main(int argc,char *argv[])
{
    /* open the source program file */
    if (argc != 3) {
        printf ("Usage: sc filename\n");
        exit(1);
    }
    yyin = fopen(argv[1], "r");         /* open input file */
    out.open(argv[2]);       /* open output file */

    /* perform parsing */
    std::cout<<"line "<<line<<std::endl;
    if (yyparse() == 1) {

        yyerror("Parsing error !");     /* syntax error */
    }                /* parsing */
    else{
        std::cout<<"Correct"<<endl;
    }
}
