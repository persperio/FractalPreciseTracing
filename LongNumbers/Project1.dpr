program Project1;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  LongData in 'LongData.pas',
  LongNumbers in 'LongNumbers.pas',
  LongNumberConversion in 'LongNumberConversion.pas';

var
  a, b, c, t, u: TLongNumber;
  ae, be, ce: Extended;
  i, j, k, l: Cardinal;
  s: String;
begin

  ae:= 30000;
  be:= 1003;
  ce:= 30000 / 1003.;
  writeln(ce:10:10);


  ExtendedToLongNumber(ae, a);
  ExtendedToLongNumber(be, b);
  ExtendedToLongNumber(ce, c);

  //AddNumber(a, b);

  //AddNumber(a, b);
  writeln(TruncateLongNumber(a));

  DivideNumberByNumber(A, T, B);

  s := LongNumberToString(t, 50, true);
 // FractionToString();
  writeln(s);
  writeln(TryStringToLongNumber(s, u));
 // FractionStringToNumber(s, u);

  s := LongNumberToString(u, 50, true);
  writeln(s);

  write('a     = ');
  PrintLongNumber(a);
  write('b     = ');
  PrintLongNumber(b);
  write('c     = ');
  PrintLongNumber(c);
  write('t     = ');
  PrintLongNumber(t);
  write('u     = ');
  PrintLongNumber(u);

  readln;

end.
