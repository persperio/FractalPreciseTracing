unit LongNumberConversion;

interface

uses
  LongNumbers, LongData;

procedure PrintLongNumber(var A: TLongNumber);

procedure IntegerToLongNumber(const Value: Integer; out Number: TLongNumber);
procedure CardinalToLongNumber(const Value: Cardinal; out Number: TLongNumber);

procedure ExtendedToLongNumber(var Value: Extended; out Number: TLongNumber);
procedure LongNumberToExtended(var Number: TLongNumber; out Value: Extended);

procedure ChangeSign(var  Number: TLongNumber);
procedure MakePositive(var  Number: TLongNumber);

function  TruncateLongNumber(var  Number: TLongNumber): Integer;
procedure MakeFractionOfLongNumber(var  Number: TLongNumber);

function  FractionToString(var Number: TLongNumber; const MaxFracDigits: Integer = 10 * DATA_SIZE;
  const OnlySignificantDigits: Boolean = False; const RemoveTracingZeroes: Boolean = True): String;

procedure FractionStringToNumber(const Fraction: String; out Number: TLongNumber);

function  LongNumberToString(var Number: TLongNumber; const MaxFracDigits: Integer = 10 * DATA_SIZE ;
  const OnlySignificantDigits: Boolean = False; const RemoveTracingZeroes: Boolean = True): String;

function TryStringToLongNumber(const StrValue: String; out Number: TLongNumber): Boolean;


implementation

uses
  SysUtils, StrUtils;

procedure PrintLongNumber(var A: TLongNumber);
var
  i:integer;
begin
  with A do
    begin
      if SignExponent and SIGN_BIT > 0 then write('-') else write(' ');
      for i:=High(Data) downto Low(Data) do write(IntToHex(Data[i],8):10,' ');
      if  SignExponent and EXPONENT_BITS = 0
        then writeln('2^?')
        else writeln('2^',Integer(SignExponent and EXPONENT_BITS - EXPONENT_BIAS));
    end;
end;


procedure IntegerToLongNumber(const Value: Integer; out Number: TLongNumber);
asm
          XCHG  EAX, EDX
          CALL  InitializeLongNumber
          ADD   [EAX + 4 * DATA_SIZE], EXPONENT_BIAS + $1F
          TEST  EDX, EDX
          JNS   @NOSIGN
          OR    [EAX + 4 * DATA_SIZE], SIGN_BIT
          NEG   EDX
@NOSIGN:  MOV   [EAX + 4 * DATA_SIZE - 4], EDX
          CALL  NormalizeNumber
end;

procedure CardinalToLongNumber(const Value: Cardinal; out Number: TLongNumber);
asm
          XCHG  EAX, EDX
          CALL  InitializeLongNumber
          ADD   [EAX + 4 * DATA_SIZE], EXPONENT_BIAS + $1F
          MOV   [EAX + 4 * DATA_SIZE - 4], EDX
          CALL  NormalizeNumber
end;

procedure ExtendedToLongNumber(var Value: Extended; out Number: TLongNumber);
asm
          XCHG  EAX, EDX
          CALL  InitializeLongNumber

          MOV   ECX,  [EDX]
          MOV   [EAX + 4 * DATA_SIZE - 8], ECX
          MOV   ECX, [EDX + 4]
          MOV   [EAX + 4 * DATA_SIZE - 4], ECX

          MOV   CX, [EDX + 8]
          TEST  CX, CX
          JNS   @NOSIGN
          AND   CX,  $7FFF
          OR    [EAX + 4 * DATA_SIZE], SIGN_BIT
@NOSIGN:  MOVZX ECX, CX
          ADD   ECX, EXPONENT_BIAS - $3FFF
          OR    [EAX + 4 * DATA_SIZE], ECX
          CALL   NormalizeNumber
end;

procedure LongNumberToExtended(var Number: TLongNumber; out Value: Extended);
asm
          MOV   ECX,  [EAX + 4 * DATA_SIZE - 8]
          MOV   [EDX], ECX
          PUSH  ECX
          MOV   ECX, [EAX + 4 * DATA_SIZE - 4]
          MOV   [EDX + 4], ECX
          OR    [ESP], ECX  // [ESP] = OR OF DATA BITS
          MOV   ECX, [EAX + 4 * DATA_SIZE]
          JNZ   @NOZERO
          AND   ECX, SIGN_BIT
          SHR   ECX, 24
          JMP   @FURTHER
@NOZERO:  SUB   ECX, EXPONENT_BIAS - $3FFF
          TEST  ECX, SIGN_BIT
          JS    @HASSGN
          AND   CX, $7FFF
          JMP   @FURTHER
@HASSGN:  OR    CX, $8000
@FURTHER: MOV  [EDX + 8], CX
          ADD   ESP, 4
end;

procedure ChangeSign(var  Number: TLongNumber);
asm
        XOR   [EAX + 4 * DATA_SIZE], SIGN_BIT
end;

procedure MakePositive(var  Number: TLongNumber);
asm
        AND   [EAX + 4 * DATA_SIZE], EXPONENT_BITS
end;

function  IsNegative(var  Number: TLongNumber): Boolean;
asm
         TEST   [EAX + 4 * DATA_SIZE], SIGN_BIT
         SETS   AL             // SET AL = 1 IF NUMBER IS BELOW ZERO
end;

function  TruncateLongNumber(var  Number: TLongNumber): Integer;
asm
          MOV   EDX, [EAX + 4 * DATA_SIZE - 4]
          MOV   EAX, [EAX + 4 * DATA_SIZE]
          MOV   ECX, EAX
          AND   EAX, SIGN_BIT
          AND   ECX, EXPONENT_BITS
          CMP   ECX, EXPONENT_BIAS
          JB    @SETZERO
          SUB   ECX, EXPONENT_BIAS + $1F
          JGE   @SETZERO
          NEG   ECX
          SHR   EDX, CL
          TEST  EAX, EAX
          JNS   @NOSGN
          NEG   EDX
@NOSGN:   MOV   EAX, EDX
          RET
@SETZERO: XOR   EAX, EAX
end;


procedure MakeFractionOfLongNumber(var  Number: TLongNumber);
asm
          MOV   EDX, [EAX + 4 * DATA_SIZE]
          AND   EDX, EXPONENT_BITS
          SUB   EDX, EXPONENT_BIAS
          JL    @ISFRAC
          AND   [EAX + 4 * DATA_SIZE],  SIGN_BIT
          ADD   [EAX + 4 * DATA_SIZE],  EXPONENT_BIAS - 1 // EXPONENT = -1
          INC   EDX
          PUSH  EAX
          CALL  ShiftLeftBinary
          POP   EAX
          CALL  NormalizeNumber
@ISFRAC:
end;

procedure ApproximateDecString(var S: String);
var
  i: Integer;
  b: Byte;
begin
  i := Length(S);
  while i > 0 do
    begin
      b := Ord(S[i]) - Ord('0');
      Inc(b);
      if b = 10
        then S[i] := '0'
        else
          begin
            S[i] := Chr(b + Ord('0'));
            Break;
          end;
      Dec(i);
    end;
end;

function  FractionToString(var Number: TLongNumber; const MaxFracDigits: Integer = 10 * DATA_SIZE;
  const OnlySignificantDigits: Boolean = False; const RemoveTracingZeroes: Boolean = True): String;
var
  t:  TLongNumber;
  s:  String;
  i: Integer;
  Skip: Boolean;
begin
  if DataEqualsZero(Number, DATA_SIZE)
    then
      begin
        Result := '0';
        Exit;
      end;
  Result := '';
  Skip := OnlySignificantDigits;
  t := Number;
  MakeFractionOfLongNumber(t);
  MakePositive(t);

  i := 1;
  repeat
    MultiplyByCardinal(t,t,10);
    Str(TruncateLongNumber(t),s);
    MakeFractionOfLongNumber(t);
    Result := Result + s;
    if Skip then Skip := s = '0';
    if not Skip then Inc(i);
  until i > MaxFracDigits;

  MultiplyByCardinal(t,t,10);
  Str(TruncateLongNumber(t),s);
  if s[1]>='5' then ApproximateDecString(Result);

  if  not RemoveTracingZeroes then Exit;

  i := Length(Result);
  repeat
    if Result[i] <> '0' then Break;
    Dec(i);
  until i < 2;                    // one first zero should remain

  SetLength(Result, i);
end;

procedure FractionStringToNumber(const Fraction: String; out Number: TLongNumber);
var
  i, j, k: Integer;
  s, t: String;
  n: TLongNumber;
begin
  s := Copy(Fraction,1, Length(Fraction));
  CardinalToLongNumber(0, Number);
  j := Length(s) mod 9;
  for i := 1 to 9 - j do  s := s + '0';
  for i := 1 to Length(s) div 9 do
    begin
      t := '';
      for j := 1 to 9 do t := t + s[(i - 1) * 9 + j];
      k := StrToInt(t);
      CardinalToLongNumber(k, n);
      for k := 1 to i do DivideByCardinal(n,n,1000000000);
      AddNumber(Number, n);
    end;
end;

function  LongNumberToString(var Number: TLongNumber; const MaxFracDigits: Integer = 10 * DATA_SIZE ;
  const OnlySignificantDigits: Boolean = False; const RemoveTracingZeroes: Boolean = True): String;
var
  i: Integer;
  IntPart, FracPart: String;
  DecExp: Integer;
  c: Char;
  HasSign: Boolean;
begin
  i := TruncateLongNumber(Number);
  HasSign := IsNegative(Number);
  if  i <> 0
    then
      begin
        IntPart := IntToStr(i);
        FracPart := FractionToString(Number, MaxFracDigits - Length(IntPart), OnlySignificantDigits, RemoveTracingZeroes);
        if  FracPart <> '0' then Result := IntPart + DecimalSeparator + FracPart else Result := IntPart;
      end
    else
      begin
        If HasSign then IntPart := '-' else IntPart:='';
        DecExp := -1;
        FracPart := FractionToString(Number, MaxFracDigits, OnlySignificantDigits, RemoveTracingZeroes);
        if FracPart = '0' then
          begin
            Result := '0';
            Exit;
          end;
        FracPart := ReverseString(FracPart);
        i := Length(FracPart);
        repeat
          if FracPart[i] <> '0' then Break;
          Dec(i);
        until i < 1;
        Dec(DecExp, Length(FracPart) - i);
        SetLength(FracPart, i);
        FracPart := ReverseString(FracPart);
        c :=  FracPart[1];
        FracPart[1] := DecimalSeparator;
        FracPart := c + FracPart;
        Result := IntPart + FracPart + 'E' + IntToStr(DecExp);
      end;
end;

function GetDecimalSeparatorIndex(const S: String): Integer;
var
  st: Set of Char;
begin
  st := ['.', ','];
  Include(st, DecimalSeparator);
  Result := 0;
  repeat
    Inc(Result);
    if S[Result] in st then Break;
  until Result > Length(S);
end;

function  CheckStringConvertability(const S: String): Boolean;
var
  i: Integer;
begin
  Result := True;
  i := 1;
  while Result and (i <= Length(S)) do
    begin
      Result := (S[i]>='0') and (S[i]<='9');
      Inc(i);
    end;
end;

function ShiftDecimalSeperator(var S: String; Index, Shift: Integer): Integer;
var
  i, j: Integer;
  t: Boolean;
  c: Char;
begin
  if Index = 0 then
    begin
      Result := 0;
      Exit;
    end;
  t :=  Shift < 0;
  if t then
    begin
      S := ReverseString(S);
      Shift := - Shift;
      Index := Length(S) - Index + 1
    end;
  i := 1;
  while i <= Shift do
    begin
      if i + Index > Length(S) then S := S + '0';
      c := S[i + Index];
      S[i + Index] := S[i + Index - 1];
      S[i + Index - 1] := c;
      Inc(i);
    end;
  if i + Index > Length(S) then S := S + '0';
  Result := i + Index - 1;
  if t then
    begin
      S := ReverseString(S);
      Result := Length(S) - Result + 1;
    end;
end;

function TryStringToLongNumber(const StrValue: String; out Number: TLongNumber): Boolean;
var
  S, S1: String;
  i: Integer;
  IntPart, FracPart: String;
  t: TLongNumber;
  HasSign: Boolean;
begin
  S := Trim(StrValue);
  Result := True;
  if Length(S) = 0 then
    begin
      CardinalToLongNumber(0, Number);
      Exit;
    end;
  HasSign := S[1] = '-';
  if HasSign then S[1] := '0';
  i := 0;
  repeat
    Inc(i);
    if (S[i] = 'E') or (S[i] = 'e') then Break;
  until i > Length(S);

  if  i < Length(S)
    then
      begin
        S1 := Copy(S, i + 1, Length(S) - i);
        S := Copy(S, 1, i - 1);
        if S1 = ''
          then i := 0
          else Result := TryStrToint(S1, i);
        if not Result then Exit;
      end
    else  i := 0;
  i := ShiftDecimalSeperator(S, GetDecimalSeparatorIndex(S), i);
  IntPart := Copy(S, 1, i - 1);
  FracPart := Copy(S, i + 1, Length(S) - i);
  Result := TryStrToInt(IntPart, i) and CheckStringConvertability(FracPart);
  if not Result then Exit;
  IntegerToLongNumber(i, Number);
  FractionStringToNumber(FracPart, t);
  AddNumber(Number, t);
  if HasSign then ChangeSign(Number);
end;

end.
