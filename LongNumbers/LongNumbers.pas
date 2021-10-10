unit LongNumbers;

interface

uses
  LongData;


const
  SIGN_BIT = $80000000;
  EXPONENT_BITS = $7FFFFFFF;
  EXPONENT_BIAS = $3FFFFFFF;

type
  TLongNumber = record
    Data: TDataArray;
    SignExponent: Cardinal;
  end;


procedure InitializeLongNumber(var Number: TLongNumber);

function  ByModuloSecondIsGreater(var FirstNumber, SecondNumber: TLongNumber): Boolean;
function  SecondIsGreater(var FirstNumber, SecondNumber: TLongNumber): Boolean;

procedure NormalizeNumber(var Number: TLongNumber);

procedure AddModuloToModulo(var Number, Addition: TLongNumber);
procedure SubtractModuloFromModulo(var Number, Subtrahend: TLongNumber);

procedure AddNumber(var Item, Summand: TLongNumber);
procedure SubtractNumber(var Minuend, Subtrahend: TLongNumber);

procedure MultiplyByCardinal(var Multiplicand: TLongNumber; out Product: TLongNumber; const Multiplier: Cardinal);
procedure MultiplyByInteger(var Multiplicand: TLongNumber; out Product: TLongNumber; const Multiplier: Integer);
procedure MultiplyNumbers(var Multiplicand, Multiplier: TLongNumber; out Product: TLongNumber);

procedure  DivideByCardinal(var Dividend: TLongNumber; out Quotient: TLongNumber; const Divisor: Cardinal);
procedure  DivideByInteger(var Dividend: TLongNumber; out Quotient: TLongNumber; const Divisor: Integer);

procedure DivideNumberByNumber(var Dividend, Divisor: TLongNumber; out Quotient: TLongNumber);

implementation

procedure InitializeLongNumber(var Number: TLongNumber);
asm
          MOV   ECX, DATA_SIZE + 1
@L:       MOV   [EAX + 4 * ECX - 4], 0
          LOOP @L
end;


function  ByModuloSecondIsGreater(var FirstNumber, SecondNumber: TLongNumber): Boolean;
asm
          MOV   ECX, [EAX + 4 * DATA_SIZE]
          CMP   [EDX + 4 * DATA_SIZE], ECX
          JZ    @COMP
          SETNC AL
          RET
@COMP:    PUSH  ESI
          PUSH  EDI
          SUB   ESP, 4 * DATA_SIZE
          MOV   ESI, EAX
          MOV   EDI, ESP
          MOV   ECX, DATA_SIZE
    REP   MOVSD
          MOV   EAX, ESP
          CALL  DecreaseData
          ADD   ESP, 4 * DATA_SIZE
          POP   EDI
          POP   ESI
end;


function  SecondIsGreater(var FirstNumber, SecondNumber: TLongNumber): Boolean;
asm
          MOV   ECX, [EAX + 4 * DATA_SIZE]
          XOR   ECX, [EDX + 4 * DATA_SIZE]
          SHR   ECX, 31
          JNZ   @EXIT                     //exit if different signs
          PUSH  ECX
          CALL  ByModuloSecondIsGreater
          POP   ECX
          XOR   AL, CL
          RET
@EXIT:    MOV   AL, CL
end;

procedure NormalizeNumber(var Number: TLongNumber);
asm
          MOV   ECX,  [EAX + 4 * DATA_SIZE]
          AND   ECX, EXPONENT_BITS
          PUSH  EAX
          PUSH  ECX
          CALL  GetNormalizableBitCount
          CMP   EAX, -1
          JNE   @NOZERO
          MOV   EAX, [ESP + 4]
          AND  [EAX + 4 * DATA_SIZE], SIGN_BIT
          ADD   ESP, 8
          RET
@NOZERO:  MOV   EDX, [ESP]
          SUB   EDX, EAX
          JAE   @NORM
          MOV   EAX, [ESP]                        //DENORMALIZED
          XOR   EDX, EDX
@NORM:    MOV   ECX, [ESP + 4]
          AND   [ECX + 4 * DATA_SIZE], SIGN_BIT
          OR    [ECX + 4 * DATA_SIZE], EDX
          MOV   EDX, EAX
          MOV   EAX, ECX
          ADD   ESP, 8
          CALL  ShiftLeftBinary
end;

procedure AddModuloToModulo(var Number, Addition: TLongNumber);
asm
          MOV   ECX, [EAX + 4 * DATA_SIZE]
          AND   ECX, EXPONENT_BITS
          PUSH  EDX
          MOV   EDX, [EDX + 4 * DATA_SIZE]
          AND   EDX, EXPONENT_BITS
          SUB   ECX, EDX
          JNS   @NOXCH
          SUB   [EAX + 4 * DATA_SIZE], ECX
@NOXCH:   MOV   EDX, [ESP]
          MOV   [ESP], EAX
          CALL  IncreaseDataBySHRIncrement
          TEST  AL, AL
          JZ    @EXIT                 // EXIT IF NO CARRY, NO NEED IN HAVING EAX RESTORED
          MOV   EAX, [ESP]
          INC   [EAX + 4 * DATA_SIZE] //INCREMENTING  EXPONENT
          MOV   EDX, 1                // SHIFTING BY ONE UNIT
          CALL  ShiftRightBinaryAndApproximate
          MOV   EAX, [ESP]
          OR   [EAX + 4 * DATA_SIZE - 4], $80000000  // SETTING CARRIED BIT
@EXIT:    ADD   ESP, 4
end;

procedure SubtractModuloFromModulo(var Number, Subtrahend: TLongNumber);
asm
          MOV   ECX, [EAX + 4 * DATA_SIZE]
          AND   ECX, EXPONENT_BITS
          PUSH  EDX
          MOV   EDX, [EDX + 4 * DATA_SIZE]
          AND   EDX, EXPONENT_BITS
          SUB   ECX, EDX
          JNS   @NOXCH
          SUB   [EAX + 4 * DATA_SIZE], ECX
@NOXCH:   MOV   EDX, [ESP]
          MOV   [ESP], EAX
          CALL  DecreaseDataBySHRIncrement
          TEST  AL, AL
          JZ    @EXIT                 // EXIT IF NO CARRY
          MOV   EAX, [ESP]
          XOR   [EAX + 4 * DATA_SIZE], SIGN_BIT
          CALL  DataTwosComplement
@EXIT:    POP   EAX
          CALL  NormalizeNumber
end;

procedure AddNumber(var Item, Summand: TLongNumber);
asm
          MOV   ECX, [EAX + 4 * DATA_SIZE]
          XOR   ECX, [EDX + 4 * DATA_SIZE]
          JNS   @EQUSGN
          CALL  SubtractModuloFromModulo
          RET
@EQUSGN:  CALL  AddModuloToModulo
end;

procedure SubtractNumber(var Minuend, Subtrahend: TLongNumber);
asm
          MOV   ECX, [EAX + 4 * DATA_SIZE]
          XOR   ECX, [EDX + 4 * DATA_SIZE]
          JNS   @EQUSGN
          CALL  AddModuloToModulo
          RET
@EQUSGN:  CALL  SubtractModuloFromModulo
end;

procedure MultiplyByCardinal(var Multiplicand: TLongNumber; out Product: TLongNumber; const Multiplier: Cardinal);
asm
          TEST  ECX, ECX
          JNZ   @CALC
          MOV   ECX, [EAX + 4 * DATA_SIZE]
          AND   ECX, SIGN_BIT
          PUSH  ECX
          MOV   EAX, EDX
          CALL  InitializeLongNumber
          POP   ECX
          MOV   [EAX + 4 * DATA_SIZE], ECX
          RET
@CALC:    PUSH  ECX
          MOV   ECX, [EAX + 4 * DATA_SIZE]
          MOV   [EDX + 4 * DATA_SIZE], ECX
          POP   ECX
          PUSH  EDX
          CALL MultiplyByUnit
          TEST  EAX, EAX
          JZ    @EXIT
          PUSH  EAX            // PUSH HIGHER UNIT
          CALL  GetInitialZeroBitCount
          NEG   AL
          ADD   AL, 32
          POP   ECX            // POP  HIGHER UNIT
          XCHG  ECX, EAX       // EAX = HIGHER UNIT; ECX = BITSHIFT
          ROR   EAX, CL        // SHIFT HIGHER UNIT
          XCHG  EAX, [ESP]     // EAX = @PRODUCT; [ESP] = SHIFTED HIGHER UNIT
          PUSH  EAX
          MOVZX EDX, CL
          PUSH  EDX            // EDX = SHIFT
          CALL  ShiftRightBinaryAndApproximate
          POP   EDX            //EDX = SHIFT
          POP   EAX            //EAX = @PRODUCT
          POP   ECX            //ECX = SHIFTED HIGHER UNIT
          ADD   [EAX + 4 * DATA_SIZE], EDX   //SHIFTING EXPONENT
          OR    [EAX + 4 * DATA_SIZE - 4], ECX
          RET
@EXIT:    ADD   ESP, 4         // IF MULTIPLIED BY ONE OR DENORMALIZED
end;

procedure MultiplyByInteger(var Multiplicand: TLongNumber; out Product: TLongNumber; const Multiplier: Integer);
asm
          TEST  ECX, ECX
          JS    @HASSIGN
          CALL  MultiplyByCardinal
          RET
@HASSIGN: NEG   ECX
          PUSH  EDX
          CALL  MultiplyByCardinal
          POP   EDX
          XOR   [EDX + 4 * DATA_SIZE], SIGN_BIT
end;

procedure MultiplyNumbers(var Multiplicand, Multiplier: TLongNumber; out Product: TLongNumber);
asm
          PUSH  EBX
          PUSH  ECX                         // ECX = @PRODUCT
          MOV   ECX, [EAX + 4 * DATA_SIZE]
          MOV   EBX, ECX
          AND   EBX, EXPONENT_BITS
          XOR   ECX, [EDX + 4 * DATA_SIZE]
          AND   ECX, SIGN_BIT
          PUSH  ECX                         //PUSH SIGN BIT
          MOV   ECX, [EDX + 4 * DATA_SIZE]
          AND   ECX, EXPONENT_BITS
          ADD   EBX, ECX
          SUB   EBX, EXPONENT_BIAS          //= (EXP1 + BIAS) + (EXP2 + BIAS) - BIAS = EXP1 + EXP2 + BIAS
          CMP   EBX, EXPONENT_BITS
          MOV   ECX, [ESP + 4]              // ECX = @PRODUCT
          JL    @NO_OVFL                    // JUMP IF NO OVERFLOW
          MOV   EAX, ECX                    // EAX = @PRODUCT
          CALL  ClearData                   // CLEAR INFINITY DATA
          MOV   EBX, EXPONENT_BITS          // EXP0NENT OF AN INFINITY = $7FFFFFFF
          JMP   @SKIP
@NO_OVFL: CALL  MultiplyDataByDataTruncated // EAX = SHIFTED BITS COUNT
          CMP   EAX, -1
          JE    @EQUZERO                    // JUMP IF DATA == 0
          INC   EBX                    
          SUB   EBX, EAX
          JGE   @SKIP                       // JUMP IF EXPONENT IS GREATER OR EQUAL TO ZERO
          CMP   EBX, - 4 * DATA_SIZE
          JG    @CANNORM                    // IF ABS(EBX) < 4 * DATA_SIZE, WE CAN NORMALIZE THIS NUMBER
          MOV   EAX, [ESP + 4]              // ECX = @PRODUCT
          CALL  ClearData                   // CLEAR INFINITY DATA
          JMP   @EQUZERO
@CANNORM: MOV   EAX, [ESP + 4]
          NEG   EBX
          MOV   EDX, EBX                        // WE NEED TO SHIFT RIGHT BY EBX BITS, DENORMALIZING THE NUMBER IN THE PROCESS
          CALL  ShiftRightBinaryAndApproximate  // EXPONENT IS ZERO, DATA IS NOT ZERO
@EQUZERO: XOR   EBX, EBX                        // EXP0NENT OF A ZERO = $00000000
@SKIP:    POP   EDX                             // EDX = SIGN BIT
          POP   EAX                             // EAX = @PRODUCT
          OR    EDX, EBX
          MOV   [EAX + 4 * DATA_SIZE], EDX
          POP   EBX
end;

procedure  DivideByCardinal(var Dividend: TLongNumber; out Quotient: TLongNumber; const Divisor: Cardinal);
asm
          PUSH    ECX
          MOV     ECX,  [EAX + 4 * DATA_SIZE]
          MOV     [EDX + 4 * DATA_SIZE],  ECX
          MOV     ECX, [ESP]
          MOV     [ESP],EDX
          CALL    DivideDataNorm
          POP     EDX
          CMP     EAX, -1
          JE      @ISZERO
          MOV     ECX, [EDX + 4 * DATA_SIZE]
          AND     ECX, EXPONENT_BITS
          SUB     ECX, EAX
          JGE     @ABOVE
          NEG     ECX
          PUSH    EDX
          MOV     EAX, EDX
          MOV     EDX, ECX
          CALL    ShiftRightBinaryAndApproximate
          POP     EDX
          XOR     ECX, ECX
@ABOVE:   AND     [EDX + 4 * DATA_SIZE], SIGN_BIT
          OR      [EDX + 4 * DATA_SIZE], ECX
@ISZERO:
end;

procedure DivideByInteger(var Dividend: TLongNumber; out Quotient: TLongNumber; const Divisor: Integer);
asm
         TEST   ECX, ECX
         JS     @HAS_SGN
         CALL   DivideByCardinal
         RET
@HAS_SGN:PUSH   EDX                                 //EDX = @Quotient
         NEG    ECX                                 //NEGATING DIVISOR
         CALL   DivideByCardinal
         POP    EDX                                 //EDX=@Quotient
         XOR    [EDX + 4 * DATA_SIZE], SIGN_BIT     //SWITCHING THE BIT
end;

procedure DivideNumberByNumber(var Dividend, Divisor: TLongNumber; out Quotient: TLongNumber);
asm
         XCHG   EDX,  ECX
         PUSH   EAX                           // [ESP + $10] = @Dividend
         PUSH   EDX                           // [ESP + $0C] = @Quotient
         PUSH   ECX                           // [ESP + $08] = @Divisor

         MOV    EAX,  [EAX + 4 * DATA_SIZE]
         MOV    ECX,  [ECX + 4 * DATA_SIZE]

         PUSH   EAX
         XOR    [ESP],  ECX
         AND    [ESP],  SIGN_BIT              // [ESP + 4] = SIGN

         AND    EAX,  EXPONENT_BITS
         AND    ECX,  EXPONENT_BITS
         SUB    EAX,  ECX
         ADD    EAX,  EXPONENT_BIAS           // BIASED EXPONENT

         CMP    EAX,  EXPONENT_BITS
         JAE    @OVRFLW
         PUSH   EAX                           // [ESP] = BIASED EXPONENT

         MOV    EAX,  [ESP + $10]
         MOV    ECX,  [ESP + 8]
         CALL   DivideDataByData

         CMP    EAX,  $7FFFFFFF
         JE     @DIVZERO
         SUB    [ESP],  EAX

         MOV    EAX, [ESP]
         OR     EAX, [ESP + 4]

         MOV    EDX, [ESP + $0C]
         MOV    [EDX + 4 * DATA_SIZE], EAX

         ADD    ESP, $14
         RET
@DIVZERO:
         MOV    EAX, [ESP + $04]
         MOV    EDX, [ESP + $0C]
         MOV    [EDX + 4 * DATA_SIZE], EAX
         ADD    ESP, $14
         RET
@OVRFLW:
         ADD    ESP, $10
end;

end.
