#include<stack>
#include<string>
#include<unordered_map>
#include<vector>
#include<iostream>

// 目前假設沒有local function

struct Value{
    Value(int _int_value,double _float_value,bool _bool_value,std::string _str_value){
        int_value=_int_value;
        float_value=_float_value;
        bool_value=_bool_value;
        str_value=_str_value;
    }
    Value(){
        int_value=0;
        float_value=0;
        bool_value=true;
    }
    int int_value=0;
    double float_value=0;
    bool bool_value=false;
    std::string str_value="";
};

struct Symbol
{
    Symbol(){
        name="";
        datatype=-1;
        type=-1;
        is_const=true;
        index = 0;
    }

    void print(){
        std::cout << "Name: " << name << ", Datatype: " << datatype;
            if (type == 1) {
                std::cout << ", Type: array";
            } else {
                std::cout << ", Type: var";
            }
            if (is_const) {
                std::cout << ", Const: true";
            } else {
                std::cout << ", Const: false";
            }
            std::cout << std::endl;
    }

    std::string name;
    int datatype;
    /*
        0: int
        1: real
        2: bool
        3: string
    */

   int type;
   /*
        0: var
        1: array
   */

    bool is_const;
    bool is_global;
    Value val;
    std::vector<Value> arr_value;

    int index;

    int int_value=0;
    double float_value=0;
    bool bool_value=false;
    std::string string_value="";
};

struct FunctionSymbol
{
    std::string name;
    int num_args=0;
    std::vector<int> arg_types;
    int return_datatype;
    /*
        0: int
        1: real
        2: bool
        3: string
    */

   int return_type;
   /*
        0: var
        1: array
   */

    bool is_procedure=false;
};