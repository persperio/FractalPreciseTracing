unit LongData;

interface

const
  DATA_SIZE = 5;

type

  TDataArray = array [1..DATA_SIZE] of Cardinal;

procedure ClearData(var Data);

function ShiftRightByUnit(var Data; const UnitCount: Cardinal): Cardinal;
function ShiftLeftByUnit(var Data; const UnitCount: Cardinal): Cardinal;

function  ShiftRightBinary(var Data; const BitCount: Cardinal): Cardinal;
function  ShiftLeftBinary(var Data; const BitCount: Cardinal): Cardinal;

function IncreaseData(var DataValue, DataIncrement): Boolean;
function DecreaseData(var DataValue, DataDecrement): Boolean;

function  IncreaseDataByUnit(var DataValue; const UnitValue: Cardinal): Boolean;
function  DecreaseDataByUnit(var DataValue; const UnitValue: Cardinal): Boolean;

function  GetNormalizableBitCount(var Data): Cardinal;

procedure ShiftRightBinaryAndApproximate(var Data; const BitCount: Cardinal);

function  IncreaseDataBySHRIncrement(var DataValue, DataIncrement; const ShiftRight: Integer): Boolean;
function  DecreaseDataBySHRIncrement(var DataValue, DataDecrement; const ShiftRight: Integer): Boolean;

procedure DataOnesComplement(var Data);
procedure DataTwosComplement(var Data);

function GetInitialZeroBitCount(const DoubleWord: Cardinal): Cardinal;

function MultiplyByUnit(var DataSource, DataDest; const Multiplier: Cardinal): Cardinal;

procedure MultiplyDataByData(var Data1, Data2; out DoubleData);
function MultiplyDataByDataTruncated(var Data1, Data2; out SingleData): Cardinal;

function  DivideDataNorm(var DataSource, DataDest; const Divisor: Cardinal): Cardinal;

function  FirstDataAboveOrEqual(var FirstData, SecondData; const Size: Cardinal):Boolean;

procedure SetBit(var  Data; const Index: Cardinal);

function  DivideDataByData(var DataSource, DataDest, DataDivisor): Integer;

procedure CopyUnits(var Source, Dest; Count: Cardinal);

function  DataEqualsZero(var  Data; const Size: Cardinal):Boolean;

implementation

procedure ClearData(var Data);
asm
          MOV   ECX, DATA_SIZE
@L:       MOV   [EAX + 4 * ECX - 4], 0
          LOOP @L
end;

function ShiftRightByUnit(var Data; const UnitCount: Cardinal): Cardinal;
asm
          PUSH  EDI
          MOV   EDI, EAX
          MOV   EAX, EDX
          XOR   EDX, EDX
          MOV   ECX, DATA_SIZE
          DIV   ECX
          XOR   EAX,  EAX
          TEST  EDX, EDX
          JZ    @NOSHIFT
          SUB   ECX, EDX
          PUSH  ESI
          LEA   ESI, [EDI + 4 * EDX]
          PUSH  [ESI - 4]
          CLD
    REP   MOVSD
          MOV   ECX,  EDX
    REP   STOSD
          POP   EAX
          POP   ESI
@NOSHIFT: POP   EDI
end;

function ShiftLeftByUnit(var Data; const UnitCount: Cardinal): Cardinal;
asm
          PUSH  ESI
          MOV   ESI, EAX
          MOV   EAX, EDX
          XOR   EDX, EDX
          MOV   ECX, DATA_SIZE
          DIV   ECX
          XOR   EAX,  EAX
          TEST  EDX, EDX
          JZ    @NOSHIFT
          SUB   ECX, EDX
          PUSH  EDI
          LEA   EDI, [ESI + 4 * DATA_SIZE - 4]
          LEA   ESI, [ESI + 4 * ECX - 4]
          PUSH  [ESI + 4]
          STD
    REP   MOVSD
          MOV   ECX,  EDX
    REP   STOSD
          CLD
          POP   EAX
          POP   EDI
@NOSHIFT: POP   ESI
end;

function  ShiftRightBinary(var Data; const BitCount: Cardinal): Cardinal;
asm
          MOV   ECX, EDX
          AND   ECX, $1F
          SHR   EDX, 5
          JZ    @NOUNIT
          PUSH  EAX
          PUSH  ECX
          CALL  ShiftRightByUnit
          MOV   EDX, EAX
          POP   ECX
          POP   EAX
@NOUNIT:  TEST  CL, CL
          JZ    @NOBIT

          PUSH  ESI
          PUSH  EDI
          PUSH  EBX
          LEA   ESI, [EAX + 4 * DATA_SIZE - 4]
          XOR   EDI, EDI
          MOV   EBX, DATA_SIZE

          SHR   EDX, CL
          PUSH  EDX

@L:       MOV   EAX, [ESI]
          MOV   EDX, EAX
          SHR   EAX, CL
          ROR   EDX, CL
          XOR   EDX, EAX
          OR    EAX, EDI
          MOV   EDI, EDX
          MOV   [ESI], EAX
          SUB   ESI, 4
          DEC   EBX
          TEST  EBX, EBX
          JNZ   @L

          POP   EAX
          OR    EAX, EDI

          POP   EBX
          POP   EDI
          POP   ESI
@NOBIT:
end;

function  ShiftLeftBinary(var Data; const BitCount: Cardinal): Cardinal;
asm
          MOV   ECX, EDX
          AND   ECX, $1F
          SHR   EDX, 5
          JZ    @NOUNIT
          PUSH  EAX
          PUSH  ECX
          CALL  ShiftLeftByUnit
          MOV   EDX, EAX
          POP   ECX
          POP   EAX
@NOUNIT:  TEST  CL, CL
          JZ    @NOBIT

          PUSH  ESI
          PUSH  EDI
          PUSH  EBX
          MOV   ESI, EAX
          XOR   EDI, EDI
          MOV   EBX, DATA_SIZE

          SHL   EDX, CL
          PUSH  EDX

@L:       MOV   EAX, [ESI]
          MOV   EDX, EAX
          SHL   EAX, CL
          ROL   EDX, CL
          XOR   EDX, EAX
          OR    EAX, EDI
          MOV   EDI, EDX
          MOV   [ESI], EAX
          ADD   ESI, 4
          DEC   EBX
          TEST  EBX, EBX
          JNZ   @L

          POP   EAX
          OR    EAX, EDI

          POP   EBX
          POP   EDI
          POP   ESI
@NOBIT:
end;

function IncreaseData(var DataValue, DataIncrement): Boolean;
asm
          PUSH  ESI
          PUSH  EDI
          MOV   ESI, EDX
          MOV   EDI, EAX
          MOV   ECX, DATA_SIZE
          XOR   EDX, EDX
          CLC
@L:       MOV   EAX, [ESI + 4 * EDX]
          ADC   [EDI + 4 * EDX], EAX
          INC   EDX
          LOOP  @L
          SETC  AL
          POP   EDI
          POP   ESI
end;

function DecreaseData(var DataValue, DataDecrement): Boolean;
asm
          PUSH  ESI
          PUSH  EDI
          MOV   ESI, EDX
          MOV   EDI, EAX
          MOV   ECX, DATA_SIZE
          XOR   EDX, EDX
          CLC
@L:       MOV   EAX, [ESI + 4 * EDX]
          SBB   [EDI + 4 * EDX], EAX
          INC   EDX
          LOOP  @L
          SETC  AL
          POP   EDI
          POP   ESI
end;

function  IncreaseDataByUnit(var DataValue; const UnitValue: Cardinal): Boolean;
asm
          ADD   [EAX], EDX
          JNC   @NC
          XOR   EDX, EDX
          STC
          LEA   ECX, [DATA_SIZE - 1]
@L:       INC   EDX
          ADC   [EAX + 4 * EDX], 0
          JNC   @NC
          LOOP  @L
@NC:      SETC  AL
end;

function  DecreaseDataByUnit(var DataValue; const UnitValue: Cardinal): Boolean;
asm
          SUB   [EAX], EDX
          JNC   @NC
          XOR   EDX, EDX
          STC
          LEA   ECX, [DATA_SIZE - 1]
@L:       INC   EDX
          SBB   [EAX + 4 * EDX], 0
          JNC   @NC
          LOOP  @L
@NC:      SETC  AL
end;

function GetInitialZeroUnitCount(var Data): Cardinal;
asm
          MOV     ECX, DATA_SIZE
@L:       MOV     EDX, [EAX + 4 * ECX - 4]
          TEST    EDX, EDX
          JNZ     @FOUND
          LOOP    @L
          MOV     EAX, -1
          RET
@FOUND:   NEG     ECX
          ADD     ECX, DATA_SIZE
          MOV     EAX, ECX
end;

function GetInitialZeroBitCount(const DoubleWord: Cardinal): Cardinal;
asm
          MOV     ECX, 32
          MOV     EDX, EAX
@L:       SHL     EDX, 1
          JC      @FOUND
          LOOP    @L
          MOV     EAX, -1
          RET
@FOUND:   NEG     ECX
          ADD     ECX,  32
          MOV     EAX,  ECX
end;

function  GetNormalizableBitCount(var Data): Cardinal;
asm
          PUSH    EAX
          CALL    GetInitialZeroUnitCount
          CMP     EAX, -1
          JE      @EXIT
          MOV     EDX,  EAX
          SHL     EDX, 5            // * 32
          XCHG    EDX, [ESP]
          NEG     EAX
          LEA     EAX, [EDX + 4 * EAX + 4 * DATA_SIZE - 4]
          MOV     EAX, [EAX]
          CALL    GetInitialZeroBitCount
          CMP     EAX, -1
          JE      @EXIT
          ADD     EAX, [ESP]
@EXIT:    ADD     ESP, 4
end;


procedure ShiftRightBinaryAndApproximate(var Data; const BitCount: Cardinal);
asm
          MOV   ECX, 32 * DATA_SIZE    // TOTAL BIT COUNT
          SUB   ECX, EDX
          JA    @CONT
          CALL  ClearData
          RET
@CONT:    PUSH  EAX
          CALL  ShiftRightBinary
          TEST  EAX, EAX               // CF := LEFTMOST BIT
          JNS   @NS
          POP   EAX
          MOV   EDX, 1
          CALL  IncreaseDataByUnit
          RET
@NS:      ADD   ESP, 4                 // NO SIGN BIT, NOTHING TO DO
end;

function  IncreaseDataBySHRIncrement(var DataValue, DataIncrement; const ShiftRight: Integer): Boolean;
asm
          CMP   ECX, 0
          JG    @SHR_INCR
          JE    @SIMPLE
          PUSH  EAX
          PUSH  EDX
          NEG   ECX
          MOV   EDX, ECX
          CALL  ShiftRightBinaryAndApproximate
          POP   EDX
          POP   EAX
@SIMPLE:  CALL  IncreaseData
          RET
@SHR_INCR:PUSH  ESI
          PUSH  EDI
          SUB   ESP, 4 * DATA_SIZE
          MOV   ESI, EDX
          MOV   EDI, ESP
          PUSH  EAX
          MOV   EAX, EDI
          MOV   EDX, ECX
          MOV   ECX, DATA_SIZE
    REP   MOVSD
          CALL  ShiftRightBinaryAndApproximate
          POP   EAX
          MOV   EDX, ESP
          CALL  IncreaseData
          ADD   ESP, 4 * DATA_SIZE
          POP   EDI
          POP   ESI
end;

function  DecreaseDataBySHRIncrement(var DataValue, DataDecrement; const ShiftRight: Integer): Boolean;
asm
          CMP   ECX, 0
          JG    @SHR_INCR
          JE    @SIMPLE
          PUSH  EAX
          PUSH  EDX
          NEG   ECX
          MOV   EDX, ECX
          CALL  ShiftRightBinaryAndApproximate
          POP   EDX
          POP   EAX
@SIMPLE:  CALL  DecreaseData
          RET
@SHR_INCR:PUSH  ESI
          PUSH  EDI
          SUB   ESP, 4 * DATA_SIZE
          MOV   ESI, EDX
          MOV   EDI, ESP
          PUSH  EAX
          MOV   EAX, EDI
          MOV   EDX, ECX
          MOV   ECX, DATA_SIZE
    REP   MOVSD
          CALL  ShiftRightBinaryAndApproximate
          POP   EAX
          MOV   EDX, ESP
          CALL  DecreaseData
          ADD   ESP, 4 * DATA_SIZE
          POP   EDI
          POP   ESI
end;

procedure DataOnesComplement(var Data);
asm
          MOV   ECX, DATA_SIZE
@L:       NOT   [EAX + 4 * ECX - 4]
          LOOP  @L
end;

procedure DataTwosComplement(var Data);
asm
          CALL  DataOnesComplement
          MOV   EDX, 1
          CALL  IncreaseDataByUnit
end;

function MultiplyByUnit(var DataSource, DataDest; const Multiplier: Cardinal): Cardinal;
asm
          PUSH  ESI
          PUSH  EDI
          PUSH  EBX
          PUSH  ECX
          MOV   ESI, EAX
          MOV   EDI, EDX
          XOR   EBX, EBX
          MOV   ECX, DATA_SIZE
          CLD
@L:       LODSD             //EAX := [ESI]; INC(ESI,4)
          MUL   EAX, [ESP]
          ADD   EAX, EBX
          ADC   EDX, 0
          STOSD             // [EDI] := EAX; INC(EDI,4)
          MOV   EBX, EDX
          LOOP  @L
          MOV   EAX, EBX
          ADD   ESP, 4
          POP   EBX
          POP   EDI
          POP   ESI
end;

procedure MultiplyByUnitExpanded(var DataSource, Multiplier, DataDest);
asm
          PUSH  ESI
          PUSH  EDI
          MOV   ESI, EAX
          MOV   EDI, ECX
          PUSH  EBX
          XOR   EBX, EBX
          PUSH  [EDX]       // PUSH MULTIPLIER
          MOV   ECX, DATA_SIZE
          CLD
@L:       LODSD             //EAX := [ESI]; INC(ESI,4)
          MUL   EAX, [ESP]
          ADD   EAX, EBX
          ADC   EDX, 0
          STOSD             // [EDI] := EAX; INC(EDI,4)
          MOV   EBX, EDX
          LOOP  @L
          MOV   [EDI], EBX
          ADD   ESP, 4      //CLEAR MULTIPLIER
          POP   EBX
          POP   EDI
          POP   ESI
end;

procedure IncreaseDataExpanded(var DataValue, DataIncrement);
asm
          PUSH  ESI
          PUSH  EDI
          MOV   ESI, EDX
          MOV   EDI, EAX
          MOV   ECX, DATA_SIZE + 1
          XOR   EDX, EDX
          CLC
@L:       MOV   EAX, [ESI + 4 * EDX]
          ADC   [EDI + 4 * EDX], EAX
          INC   EDX
          LOOP  @L
          POP   EDI
          POP   ESI
end;

procedure MultiplyDataByData(var Data1, Data2; out DoubleData);
asm
          PUSH  EBX                             // [-0]
          PUSH  ESI                             // -4
          PUSH  EDI                             // -8
          SUB   ESP, 4 * DATA_SIZE + 4

          MOV   EDI, ESP                        // -12 * Datasize - 4
          MOV   ESI, ECX                                 //ECX = @RESULT

          PUSH  EAX                                      //EAX = @DATA1
          PUSH  EDX                                      //EDX = @DATA2[0]

          CALL  MultiplyByUnitExpanded

          MOV   ECX, DATA_SIZE - 1
          XOR   EAX, EAX
@L0:      MOV   [ESI + 4 * ECX + 4 * DATA_SIZE], EAX        // [esi + 4 * DATA_SIZE + 4] <--> [esi + 8 * datasize - 4]
          LOOP  @L0

          MOV   EBX, DATA_SIZE - 1
@L:       MOV   EAX, [ESP + 4]                              // EAX = DATA1
          ADD   [ESP], 4
          MOV   EDX, [ESP]                                  // @DATA2 = @DATA2+4
          MOV   ECX, EDI                                    // ECX = @DATA2
          CALL  MultiplyByUnitExpanded
          ADD   ESI, 4
          MOV   EAX, ESI
          MOV   EDX, EDI
          CALL  IncreaseDataExpanded
          DEC   EBX
          TEST  EBX, EBX
          JNZ   @L

          ADD   ESP, 4 * DATA_SIZE + $0C
          POP   EDI
          POP   ESI
          POP   EBX
end;

function GetInitialZeroUnitCountDouble(var DoubleData): Cardinal;     // DOUBLE
asm
          MOV     ECX, 2 * DATA_SIZE
@L:       MOV     EDX, [EAX + 4 * ECX - 4]
          TEST    EDX, EDX
          JNZ     @FOUND
          LOOP    @L
          MOV     EAX, -1
          RET
@FOUND:   NEG     ECX
          ADD     ECX, 2 * DATA_SIZE
          MOV     EAX, ECX
end;


function  GetNormalizableBitCountDouble(var DoubleData): Cardinal;   //Double
asm
          PUSH    EAX
          CALL    GetInitialZeroUnitCountDouble
          CMP     EAX, -1
          JE      @EXIT
          MOV     EDX,  EAX
          SHL     EDX, 5            // * 32
          XCHG    EDX, [ESP]
          NEG     EAX
          LEA     EAX, [EDX + 4 * EAX + 8 * DATA_SIZE - 4]
          MOV     EAX, [EAX]
          CALL    GetInitialZeroBitCount
          CMP     EAX, -1
          JE      @EXIT
          ADD     EAX, [ESP]
@EXIT:    ADD     ESP, 4
end;

function ShiftLeftByUnitDouble(var DoubleData; const UnitCount: Cardinal): Cardinal;  //Double
asm
          PUSH  ESI
          MOV   ESI, EAX
          MOV   EAX, EDX
          XOR   EDX, EDX
          MOV   ECX, 2 * DATA_SIZE
          DIV   ECX
          XOR   EAX,  EAX
          TEST  EDX, EDX
          JZ    @NOSHIFT
          SUB   ECX, EDX
          PUSH  EDI
          LEA   EDI, [ESI + 8 * DATA_SIZE - 4]
          LEA   ESI, [ESI + 4 * ECX - 4]
          PUSH  [ESI + 4]
          STD
    REP   MOVSD
          MOV   ECX,  EDX
    REP   STOSD
          CLD
          POP   EAX
          POP   EDI
@NOSHIFT: POP   ESI
end;

function  ShiftLeftBinaryDouble(var DoubleData; const BitCount: Cardinal): Cardinal;  //Double
asm
          MOV   ECX, EDX
          AND   ECX, $1F
          SHR   EDX, 5
          JZ    @NOUNIT
          PUSH  EAX
          PUSH  ECX
          CALL  ShiftLeftByUnitDouble
          MOV   EDX, EAX
          POP   ECX
          POP   EAX
@NOUNIT:  TEST  CL, CL
          JZ    @NOBIT

          PUSH  ESI
          PUSH  EDI
          PUSH  EBX
          MOV   ESI, EAX
          XOR   EDI, EDI
          MOV   EBX, 2 * DATA_SIZE

          SHL   EDX, CL
          PUSH  EDX

@L:       MOV   EAX, [ESI]
          MOV   EDX, EAX
          SHL   EAX, CL
          ROL   EDX, CL
          XOR   EDX, EAX
          OR    EAX, EDI
          MOV   EDI, EDX
          MOV   [ESI], EAX
          ADD   ESI, 4
          DEC   EBX
          TEST  EBX, EBX
          JNZ   @L

          POP   EAX
          OR    EAX, EDI

          POP   EBX
          POP   EDI
          POP   ESI
@NOBIT:
end;

function MultiplyDataByDataTruncated(var Data1, Data2; out SingleData): Cardinal;
asm
         PUSH     ECX                   // ECX = @SINGLE DATA
         SUB      ESP, 8 * DATA_SIZE    // [ESP] = @DOUBLE DATA
         MOV      ECX, ESP              // ECX = @DOUBLE DATA
         CALL     MultiplyDataByData
         MOV      EAX, ESP              // EAX = @DOUBLE DATA
         CALL     GetNormalizableBitCountDouble
         CMP      EAX, -1
         JE       @ZERO
         MOV      EDX, EAX              // EDX = SHIFT COUNT
         MOV      EAX, ESP              // EAX = @DOUBLE DATA
         PUSH     EDX                   // [ESP] = SHIFT COUNT
         CALL     ShiftLeftBinaryDouble // SHIFTS DOUBLE DATA AND SHOULD RETURN EAX = 0
         POP      EAX                   // EAX = SHIFT COUNT
         PUSH     ESI                   // [ESP + 4] = @DOUBLE DATA
         PUSH     EDI                   // [ESP + 8] = @DOUBLE DATA
         LEA      ESI, [ESP + 4 * DATA_SIZE + 8] // ESI = @HI-ORDER DOUBLE DATA
         MOV      EDI, [ESI + 4 * DATA_SIZE]     // EDI = @SINGLE DATA
         MOV      ECX, DATA_SIZE
   REP   MOVSD
         POP      EDI
         POP      ESI
         ADD      ESP, 8 * DATA_SIZE + 4
         RET
@ZERO:   MOV      EDX, EAX              // EDX = -1
         ADD      ESP, 8 * DATA_SIZE    // DISPOSE OF DOUBLE DATA
         POP      EAX
         CALL     ClearData     // CLEAR DATA DOESN'T CHANGE EDX
         MOV      EAX, EDX      // OUT = -1
end;

procedure  DivideDataByUnitPlusTwo(var DataSource, DataDestUtil; const Divisor: Cardinal);
asm
          PUSH  ESI
          PUSH  EDI
          LEA   ESI, [EAX + 4 * DATA_SIZE - 4]   // 4 * (DATA_SIZE + 2)  bytes
          LEA   EDI, [EDX + 4 * DATA_SIZE + 4]
          XOR   EDX, EDX
          PUSH  ECX
          MOV   ECX, DATA_SIZE
          STD
@L:       LODSD
          DIV   [ESP]
          STOSD
          LOOP  @L
          MOV   ECX, 2
@L2:      XOR   EAX, EAX
          DIV   [ESP]
          STOSD
          LOOP  @L2
          ADD   ESP, 4
          POP   EDI
          POP   ESI
          CLD
end;

function GetInitialZeroUnitCountPlusTwo(var DataPlusTwo): Cardinal;     // PlusTwo
asm
          MOV     ECX, DATA_SIZE + 2                    // PlusTwo
@L:       MOV     EDX, [EAX + 4 * ECX - 4]
          TEST    EDX, EDX
          JNZ     @FOUND
          LOOP    @L
          MOV     EAX, -1
          RET
@FOUND:   NEG     ECX
          ADD     ECX, DATA_SIZE + 2                    // PlusTwo
          MOV     EAX, ECX
end;


function  GetNormalizableBitCountPlusTwo(var DataPlusTwo): Cardinal;   //PlusTwo
asm
          PUSH    EAX
          CALL    GetInitialZeroUnitCountPlusTwo              // PlusTwo
          CMP     EAX, -1
          JE      @EXIT
          MOV     EDX,  EAX
          SHL     EDX, 5            // * 32
          XCHG    EDX, [ESP]
          NEG     EAX
          LEA     EAX, [EDX + 4 * EAX + 4 * DATA_SIZE + 4]    // PlusTwo
          MOV     EAX, [EAX]
          CALL    GetInitialZeroBitCount
          CMP     EAX, -1
          JE      @EXIT
          ADD     EAX, [ESP]
@EXIT:    ADD     ESP, 4
end;

function ShiftLeftByUnitPlusTwo(var DataPlusTwo; const UnitCount: Cardinal): Cardinal;  //PlusTwo
asm
          PUSH  ESI
          MOV   ESI, EAX
          MOV   EAX, EDX
          XOR   EDX, EDX
          MOV   ECX, DATA_SIZE + 2                    // PlusTwo
          DIV   ECX
          XOR   EAX,  EAX
          TEST  EDX, EDX
          JZ    @NOSHIFT
          SUB   ECX, EDX
          PUSH  EDI
          LEA   EDI, [ESI + 4 * DATA_SIZE + 4]          // PlusTwo
          LEA   ESI, [ESI + 4 * ECX - 4]
          PUSH  [ESI + 4]
          STD
    REP   MOVSD
          MOV   ECX,  EDX
    REP   STOSD
          CLD
          POP   EAX
          POP   EDI
@NOSHIFT: POP   ESI
end;

function  ShiftLeftBinaryPlusTwo(var DataPlusTwo; const BitCount: Cardinal): Cardinal;  //PlusTwo
asm
          MOV   ECX, EDX
          AND   ECX, $1F
          SHR   EDX, 5
          JZ    @NOUNIT
          PUSH  EAX
          PUSH  ECX
          CALL  ShiftLeftByUnitPlusTwo                 // PlusTwo
          MOV   EDX, EAX
          POP   ECX
          POP   EAX
@NOUNIT:  TEST  CL, CL
          JZ    @NOBIT

          PUSH  ESI
          PUSH  EDI
          PUSH  EBX
          MOV   ESI, EAX
          XOR   EDI, EDI
          MOV   EBX, DATA_SIZE + 2                     // PlusTwo

          SHL   EDX, CL
          PUSH  EDX

@L:       MOV   EAX, [ESI]
          MOV   EDX, EAX
          SHL   EAX, CL
          ROL   EDX, CL
          XOR   EDX, EAX
          OR    EAX, EDI
          MOV   EDI, EDX
          MOV   [ESI], EAX
          ADD   ESI, 4
          DEC   EBX
          TEST  EBX, EBX
          JNZ   @L

          POP   EAX
          OR    EAX, EDI

          POP   EBX
          POP   EDI
          POP   ESI
@NOBIT:
end;

function  DivideDataNorm(var DataSource, DataDest; const Divisor: Cardinal): Cardinal;
asm
          SUB     ESP, 4 * DATA_SIZE + 8  // ESP = @DATA_PLUS_TWO
          PUSH    EDX                     // PUSH @DATA_DEST
          LEA     EDX, [ESP + 4]          // EDX = @DATA_PLUS_TWO
          CALL    DivideDataByUnitPlusTwo
          LEA     EAX, [ESP + 4]
          CALL    GetNormalizableBitCountPlusTwo
          CMP     EAX, -1
          JE      @DATAZERO
          PUSH    EAX              // PUSH SHIFT
          MOV     EDX, EAX         // EDX = SHIFT
          LEA     EAX, [ESP + 8]   // EAX = @DATADEST
          CALL    ShiftLeftBinaryPlusTwo
          PUSH    ESI
          PUSH    EDI
          LEA     ESI,  [ESP + $18]    // ESP + $10 + 8 = @HIGHER 4 * DATA_SIZE BYTES
          MOV     EDI,  [ESP + $0C]
          MOV     ECX,  DATA_SIZE
          CLD
          REP     MOVSD
          POP     EDI
          POP     ESI
          TEST    [ESP + $0C], $80000000  // TEST HIGHER BIT OF THE FIRST LOWER UNIT (SECOND IS [ESP + $08])
          JNS     @NOADD
          MOV     EAX,  [ESP + 4]         // EAX = @DATADEST
          MOV     EDX, 1
          CALL    IncreaseDataByUnit
@NOADD:   POP     EAX                         // EAX = SHIFT
          ADD     ESP,  4 * DATA_SIZE + $0C   // DISPOSE OF DATA_PLUS_TWO AND @DATA_DEST
          RET
@DATAZERO:POP     EAX                         // EAX = @DATA_DEST
          CALL    ClearData
          MOV     EAX, -1                     // RETURN = -1
          ADD     ESP, 4 * DATA_SIZE + 8      // DISPOSE OF DATA_PLUS_TWO
end;

function  FirstDataAboveOrEqual(var FirstData, SecondData; const Size: Cardinal):Boolean;
asm
          PUSH    ESI
          PUSH    EDI
          LEA     ESI, [EAX + 4 * ECX - 4]
          LEA     EDI, [EDX + 4 * ECX - 4]
          STD                              //FROM HIGHER BITS DOWNTO LOWER
@L:       CMPSD                            //COMPARE
          JB      @IZBELOW
          LOOP    @L
@IZBELOW: SETAE   AL
          CLD                              //CLEAR DIRECTION FLAG
          POP     EDI
          POP     ESI
end;

function  DataEqualsZero(var  Data; const Size: Cardinal):Boolean;
asm
          MOV     ECX, EDX
          XOR     EDX, EDX
@L:       OR      EDX, [EAX + 4 * ECX - 4]
          LOOP    @L
          TEST    EDX, EDX
          SETZ    AL              // AL = 1 IF ZF IS SET
end;

procedure SetBit(var  Data; const Index: Cardinal);
asm
          DEC     EDX
          MOV     ECX, EDX
          SHR     EDX, 5      // EDX = INDEX DIV 32
          AND     ECX, $1F    // ECX = INDEX MOD 32
          PUSH    EDX
          MOV     EDX, 1
          SHL     EDX, CL
          MOV     ECX, EDX
          POP     EDX
          OR      [EAX + 4 * EDX], ECX
end;

{
procedure SetBit(var  Data; const Index: Cardinal);
asm
          MOV     ECX, EDX
          SHR     EDX, 5      // EDX = INDEX DIV 32
          AND     ECX, $1F    // ECX = INDEX MOD 32
          NEG     EDX
          ADD     EDX, DATA_SIZE
          PUSH    EDX
          MOV     EDX, $80000000
          SHR     EDX, CL
          MOV     ECX, EDX
          POP     EDX
          OR      [EAX + 4 * EDX - 4], ECX
end;
}

procedure CopyUnits(var Source, Dest; Count: Cardinal);
asm
          PUSH    ESI
          PUSH    EDI
          MOV     ESI,  EAX
          MOV     EDI,  EDX
          CLD
REP       MOVSD
          POP     EDI
          POP     ESI
end;

function  DivideDataByData(var DataSource, DataDest, DataDivisor): Integer;
asm
         PUSH     EAX
         PUSH     EDX
         PUSH     ECX
         SUB      ESP,  $0C               // [EBP + $04] = SHIFT_1; +08 = SHIFT_2; +$0C = SHIFT_3
         PUSH     EBP
         MOV      EBP,  ESP               // [EBP + $10] = @DATA_DIVISOR; +$14 = @DataDest; +$18 = @DataSource
         MOV      EAX,  ECX               // EAX = @DataDivisor
         CALL     GetNormalizableBitCount
         CMP      EAX, -1
         JE       @DIVZERO
         MOV      [EBP + $04], EAX        // PUSH SHIFT_1

         SUB      ESP,  4 * DATA_SIZE     // TEMP_1
         MOV      EAX,  [EBP + $10]       // EAX = @DataDivisor
         MOV      EDX,  ESP               // EDX = @TEMP_1_DIVISOR
         MOV      ECX,  DATA_SIZE         // COPY  DATA_SIZE UNITS
         CALL     CopyUnits

         MOV      EAX,  ESP               // EAX = @DataDest
         MOV      EDX,  [EBP + $04]       // EDX = SHIFT_1
         CALL     ShiftLeftBinary

         MOV      EAX, [EBP + $18]        // EAX = @DataSource
         CALL     GetNormalizableBitCount
         CMP      EAX, -1
         JE       @EQUZERO
         MOV      [EBP + $08], EAX        // PUSH SHIFT_2

         SUB      ESP, 4 * DATA_SIZE      // TEMP_2
         MOV      EAX, [EBP + $18]        // EAX = @DataSource
         MOV      EDX, ESP
         MOV      ECX, DATA_SIZE
         CALL     CopyUnits

         MOV      EAX,  ESP
         MOV      EDX,  [EBP + $08]                       // EDX = SHIFT_2
         CALL     ShiftLeftBinary

         MOV      [EBP + $0C], EBX                        //SHIFT_3 = EBX

         MOV      EBX, 32 * DATA_SIZE
         MOV      EAX,  ESP                               // EAX = @TEMP_2_DataSource
         LEA      EDX,  [ESP + 4 * DATA_SIZE]             // EDX = @TEMP_1_DIVISOR
         MOV      ECX,  DATA_SIZE
         CALL     FirstDataAboveOrEqual

         TEST     AL,  AL
         JNZ      @SKIP
         INC      [EBP + $04]                             //INCREASING SHIFT_1
         JMP      @BELOW2

@L:      TEST     EAX,  EAX
         JNZ      @SKIP
         MOV      EAX,  ESP                               // EAX = @TEMP_2_DataSource
         LEA      EDX,  [ESP + 4 * DATA_SIZE]             // EDX = @TEMP_1_DIVISOR
         MOV      ECX,  DATA_SIZE
         CALL     FirstDataAboveOrEqual

         TEST     AL,  AL
         JZ       @BELOW
@SKIP:
         MOV      EAX,  ESP                               // EAX = @TEMP_2_DataSource
         LEA      EDX,  [ESP + 4 * DATA_SIZE]             // EDX = @DataDest = @DATA_DIVISOR
         CALL     DecreaseData

         MOV      EAX,  [EBP + $14]                      // EAX = @DataDest
         MOV      EDX,  EBX                              // CURRENT BIT
         CALL     SetBit

@BELOW:  DEC      EBX
@BELOW2: MOV      EAX,  ESP                              // EAX = @DataSourceCOPY
         MOV      EDX,  1
         CALL     ShiftLeftBinary
         TEST     EBX,  EBX
         JNZ      @L

         //APPROXIMATING THE LAST BIT
         TEST     EAX,  EAX
         JNZ      @ADDBIT
         MOV      EAX,  ESP                               // EAX = @TEMP_2_DataSource
         LEA      EDX,  [ESP + 4 * DATA_SIZE]             // EDX = @TEMP_1_DataDest
         MOV      ECX,  DATA_SIZE
         CALL     FirstDataAboveOrEqual
         TEST     AL,  AL
         JZ       @NOBIT
@ADDBIT: LEA      EAX,  [ESP + 4 * DATA_SIZE]             // EDX = @TEMP_1_DataDest
         MOV      EDX, 1
         CALL     IncreaseDataByUnit
@NOBIT:
         MOV      EAX,  [EBP + $04]
         SUB      EAX,  [EBP + $08]

         MOV      EBX,  [EBP + $0C]

         MOV      EBP,  [EBP]                     // RESTORE EBP
         ADD      ESP,  8 * DATA_SIZE + $1C       // DISPOSE OF STACKED EAX, EDX, ECX, 3xSHIFT, EBP = 24 = $1C BYTES
         RET
@DIVZERO:MOV      EBP,  [EBP]                     // RESTORE EBP
         ADD      ESP,  $1C                       // DISPOSE OF STACKED EAX, EDX, ECX
         MOV      EAX,  $7FFFFFFF
         RET
@EQUZERO:
         MOV      EAX,  [EBP + $14]    // EAX = @DataDest
         CALL     ClearData
         MOV      EBP,  [EBP]          // RESTORE EBP
         ADD      ESP,  $1C            // DISPOSE OF STACKED EAX, EDX, ECX, SHIFT
         XOR      EAX,  EAX
end;
         // EAX, EDX, ECX, [EBP + 8]

end.

