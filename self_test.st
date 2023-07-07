var a: int := 5
var b: int
var c: bool :=true
var d: bool
var e:=9
const k:=8

% function declaration
function add_func (a: int, b: int, c: int) : int
    result a+b
end add_func

function compose_func (a: int, b: int, c:int) : int
    result a*100+b*10+c
end compose_func

function logic_func (a: bool, b: bool, c:bool) : bool
    put a
    put " and "
    put b
    put " = "
    put a and b
    if a and b = false then
      put "correct!"
    else
      put "wrong!"
    end if
    skip

    put a
    put " or "
    put b
    put " = "
    put a or b
    if a or b = true then
      put "correct!"
    else
      put "wrong!"
    end if
    skip

    put " not "
    put a
    put " = "
    put not a
    if not a = false then
      put "correct!"
    else
      put "wrong!"
    end if
    skip

    put "a:"
    put a
    skip
    put "b:"
    put b
    skip
    put "c:"
    put c
    skip
    put "a and (b or c) and a and not c:"
    put a and (b or c) and a and not c
    if a and (b or c) and a and not c = false then
      put "correct!"
    else
      put "wrong!"
    end if
    skip

    put "a and not not c:"
    put a and not not c
    if a and not not c=true then
      put "correct!"
    else
      put "wrong!"
    end if
    skip

    result a and b
end logic_func

function fib (n: int) : int
  var Fn: int
  var FNminus1: int
  var temp: int

  Fn := 1
  FNminus1 := 1
  loop
    exit when (n <= 2) 
    temp := Fn
    Fn := Fn + FNminus1
    FNminus1 := temp
    n := n - 1
  end loop
  result Fn
end fib

procedure add_b_to_a ()
    put a
    put "a = a + 3"
    b:=3
    a:=a+b
    put a
  return
end add_b_to_a

% simple calculation
put "simple calculation"

put "3*(9 mod 7)/3*(2+(2*2))"
if 3*(9 mod 7)/3*(2+(2*2)) = 12 then
  put "correct!"
else
  put "wrong!"
end if

put "a:=5"
put "b:=3"
a:=5
b:=3
put "a*b/(b+a)-(a*a*a+b*b*b*b)"
if a*b/(b+a)-(a*a*a+b*b*b*b) = -205 then
  put "correct!"
else
  put "wrong!"
end if
skip

% nested block
put "nested block"
begin
    var a:int:=6
    var k:=9
    begin
        var a:bool
        a:=true
        begin
          var a:int
          a:=7
          put "calculate local variable"
          if a*k = 63 then
            put "correct!"
          else
            put "wrong!"
          end if
        end
    end
    a:=7
    put "assign local variable"
    if a = 7 then
      put "correct!"
    else
      put "wrong!"
    end if
end
skip

% nested if and loop
put "nested if and loop"
a:=5
if a > 5 then
  put "wrong!"
else
  if a=5 then
    a:= a+1
    if a=5 then
      put "wrong!"
    else
      put "correct"
      var c:int
      put "print nested loop"
      for c : 5 .. 10
        var d:int
        for d : 8 .. 9
          var i:int:=7
          put "first loop"
          loop
            put compose_func(c,d,i)
            exit when i>=3
          end loop
          put "second loop"
          loop
            put compose_func(c,d,i)
            exit when i>=9
            i:=i+1
          end loop
          skip
        end for
      end for
    end if
  else
  end if
end if
skip

% function call
put "function call"
put "fib(5)*fib(e), e=9"
if fib(5)*fib(e) not= 170 then
  put "wrong!"
else
  put "correct!"
end if
skip

put "logic test"
if logic_func(true,false,c) = true then
  put "logic_func return test"
  put "wrong!"
else
  put "correct!"
end if

put "fib(e), e=9"
if fib(e) not= 34 then
  put "wrong!"
else
  put "correct!"
end if

put "fib(5)>fib(e), e=9"
if not fib(5)>fib(e) then
  put "correct!"
else
  put "wrong!"
end if