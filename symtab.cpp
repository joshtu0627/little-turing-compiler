#include"symtab.h"

using symbol_table_t = std::unordered_map<std::string, Symbol*>;
using symbol_stack_t = std::stack<std::unordered_map<std::string, Symbol*>>;

using function_table_t = std::unordered_map<std::string, FunctionSymbol*>;
// using function_stack_t = std::stack<std::unordered_map<std::string, FunctionSymbol*>>;

symbol_table_t global_symbol_table;
symbol_stack_t symbol_stack;

function_table_t global_function_table;
// function_stack_t function_stack;

Symbol* lookupGlobal(std::string name){
    if(global_symbol_table.count(name)>0){
        return global_symbol_table[name];
    }
    else{
        return NULL;
    }
}

FunctionSymbol* lookupGlobalFunc(std::string name){
    if(global_function_table.count(name)>0){
        return global_function_table[name];
    }
    else{
        return NULL;
    }
}

int countLocalIndex(){
    if(symbol_stack.size()==1){
        return 0;
    }
    int total=0;
    total=symbol_stack.top().size();
    std::unordered_map<std::string, Symbol*> tempTable=symbol_stack.top();
    symbol_stack.pop();
    int res = total+countLocalIndex();
    symbol_stack.push(tempTable);
    return res;
}
Symbol* recursiveLookUpLocal(std::string name){
    if(symbol_stack.empty()){
        return NULL;
    }
    if(symbol_stack.top().count(name)>0){
        return symbol_stack.top()[name];
    }
    std::unordered_map<std::string, Symbol*> tempTable=symbol_stack.top();
    symbol_stack.pop();
    Symbol* res=recursiveLookUpLocal(name);
    symbol_stack.push(tempTable);
    return res;
}
Symbol* lookupLocal(std::string name,bool recursive=true){
    if(symbol_stack.top().count(name)>0){
        return symbol_stack.top()[name];
    }
    if(!recursive) return NULL;
    return recursiveLookUpLocal(name);
}

// FunctionSymbol* lookupLocalFunc(std::string name){
//     if(function_stack.top().count(name)>0){
//         return function_stack.top()[name];
//     }
//     else{
//         return NULL;
//     }
// }

void insert(Symbol symbol){
    // Symbol* sym=new Symbol();
    // sym->name=name;
    // sym->type=type;
    // sym->datatype=datatype;
    // switch (datatype)
    // {
    // case 0:
    //    if (type==0){
    //     sym->val.int_value=int_value;
    //    }
    //    else if(type==1){
    //     sym->arr_value=std::vector<Value>(arr_len,Value());
    //    }
    //     break;
    // case 1:
    //    if (type==0){
    //     sym->val.float_value=float_value;
    //    }
    //    else if(type==1){
    //     sym->arr_value=std::vector<Value>(arr_len,Value());
    //    }
    //     break;
    // case 2:
    //    if (type==0){
    //     sym->val.bool_value=bool_value;
    //    }
    //    else if(type==1){
    //     sym->arr_value=std::vector<Value>(arr_len,Value());
    //    }
    //     break;
    // case 3:
    //    if (type==0){
    //     sym->val.str_value=str_val;
    //    }
    //    else if(type==1){
    //     sym->arr_value=std::vector<Value>(arr_len,Value());
    //    }
    //     break;
    // // 目前就賭沒有二維陣列
    // default:
    //     break;
    // }
    std::cout<<"val: "<<symbol.val.int_value<<std::endl;
    Symbol* new_sym = new Symbol(symbol);
    new_sym->index=countLocalIndex();
    // std::cout<<symbol.datatype<<std::endl;
    if(symbol_stack.size()==1){
        new_sym->is_global=true;
        std::cout<<new_sym->is_global<<" inserting"<<std::endl;
        global_symbol_table[new_sym->name]=new_sym;
    }
    else{
        new_sym->is_global=false;
    }
    symbol_stack.top()[new_sym->name]=new_sym;
}

void insertFunc(FunctionSymbol symbol){
    FunctionSymbol* sym=new FunctionSymbol();
    sym->name=symbol.name;
    sym-> num_args= symbol.num_args;
    sym->arg_types.assign(symbol.arg_types.begin(),symbol.arg_types.end());
    sym->return_datatype=symbol.return_datatype;
    sym->return_type=symbol.return_type;
    sym->is_procedure=symbol.is_procedure;
    global_function_table[sym->name]=sym;
}

void dumpLocal(){
    std::cout<<std::endl<<"local table: "<<std::endl;
    if (!symbol_stack.empty()) {
        // std::cout << std::endl;
        const symbol_table_t& top_table = symbol_stack.top();
        if(top_table.empty()){
            std::cout<<"top table is empty"<<std::endl;
            return;
        }
        for (const auto& entry : top_table) {
            const Symbol* symbol = entry.second;
            std::cout << "Name: " << symbol->name << ", Datatype: ";
            switch (symbol->datatype) {
                case 0:
                    std::cout << "int";
                    std::cout<<", Value:"<<symbol->val.int_value;
                    break;
                case 1:
                    std::cout << "real";
                    std::cout<<", Value:"<<symbol->val.float_value;
                    break;
                case 2:
                    std::cout << "bool";
                    std::cout<<", Value:"<<symbol->val.bool_value;
                    break;
                case 3:
                    std::cout << "string";
                    std::cout<<", Value:"<<symbol->val.str_value;
                    break;
                default:
                    std::cout << "unknown";
                    break;
            }

            if (symbol->type == 1) {
                std::cout << ", Type: array";
            } else {
                std::cout << ", Type: var";
            }
            if (symbol->is_const) {
                std::cout << ", Const: true";
            } else {
                std::cout << ", Const: false";
            }
            std::cout << ", index: "<<symbol->index;
            std::cout<<"is_global "<<symbol->is_global<<std::endl;
            std::cout << std::endl;
        }
    }
    else{
        std::cout<<"local table is empty"<<std::endl;
    }
}

void dumpGlobal(){
    std::cout<<std::endl<<"global table: "<<std::endl;
    if (!global_symbol_table.empty()) {
        std::cout << std::endl;
        std::cout << std::endl;
        for (const auto& entry : global_symbol_table) {
            const Symbol* symbol = entry.second;
            std::cout << "Name: " << symbol->name << ", Datatype: ";
            switch (symbol->datatype) {
                case 0:
                    std::cout << "int";
                    std::cout<<", Value:"<<symbol->val.int_value;
                    break;
                case 1:
                    std::cout << "real";
                    std::cout<<", Value:"<<symbol->val.float_value;
                    break;
                case 2:
                    std::cout << "bool";
                    std::cout<<", Value:"<<symbol->val.bool_value;
                    break;
                case 3:
                    std::cout << "string";
                    std::cout<<", Value:"<<symbol->val.str_value;
                    break;
                default:
                    std::cout << "unknown";
                    break;
            }
            if (symbol->type == 1) {
                std::cout << ", Type: array";
            } else {
                std::cout << ", Type: var";
            }
            if (symbol->is_const) {
                std::cout << ", Const: true";
            } else {
                std::cout << ", Const: false";
            }
            std::cout<<" is_global "<<symbol->is_global<<std::endl;
            std::cout << std::endl;
        }
    }
    else{
        std::cout<<"global table is empty"<<std::endl;
    }
}
void dumpFunction() {
    std::cout<<std::endl<<"function table: "<<std::endl;
    if (!global_function_table.empty()) {
        for (const auto& entry : global_function_table) {
            const FunctionSymbol* function = entry.second;
            std::cout << "Function Name: " << function->name << std::endl;
            std::cout << "Number of Arguments: " << function->num_args << std::endl;
            
            std::cout << "Argument Types: ";
            // std::cout<<function->arg_types.size()<<std::endl;
            for (int arg_type : function->arg_types) {
                switch (arg_type) {
                    case 0:
                        std::cout << "int ";
                        break;
                    case 1:
                        std::cout << "real ";
                        break;
                    case 2:
                        std::cout << "bool ";
                        break;
                    case 3:
                        std::cout << "string ";
                        break;
                    default:
                        std::cout << "unknown ";
                        break;
                }
            }
            std::cout << std::endl;

            std::cout << "Return Data Type: ";
            switch (function->return_datatype) {
                case 0:
                    std::cout << "int";
                    break;
                case 1:
                    std::cout << "real";
                    break;
                case 2:
                    std::cout << "bool";
                    break;
                case 3:
                    std::cout << "string";
                    break;
                default:
                    std::cout << "unknown";
                    break;
            }
            std::cout << std::endl;

            std::cout << "Return Type: ";
            if (function->return_type == 1) {
                std::cout << "array";
            } else {
                std::cout << "var";
            }
            std::cout << std::endl;
            
            std::cout << "Function Type: ";
            if (function->is_procedure) {
                std::cout << "Procedure";
            } else {
                std::cout << "Function";
            }
            std::cout << std::endl;
            std::cout << std::endl;
        }
    } else {
        std::cout << "Global function table is empty" << std::endl;
    }
}
