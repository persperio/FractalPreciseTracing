unit LongArithmetics;

interface

uses SysUtils;

type

PCardinal = ^Cardinal;

TLongNumber = class(TObject)
  private
    FEqualsZero: Boolean;
    FIsInfinity: Boolean;
    FIsPositive: Boolean;
    FNumeratorLength: integer;
    FDenominatorLength: integer;
    FIntegralPartLength: integer;

    FNumerator: PCardinal;
    FDenominator: PCardinal;
    FIntegralPart: PCardinal;

    FNumber: array of Cardinal;
    procedure SetIsPositive(const Value: Boolean);
    //function FGetDigit(P: PCardinal; Index: Cardinal): Cardinal;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Negate;
    function DoubleValue: Double;
    procedure AddValue(Value: TLongNumber);
    property IsPositive: Boolean read FIsPositive write SetIsPositive;
  end;

implementation

function AddTo(Value, Increment:PCardinal; DigitCount:Cardinal): Boolean;
asm
        PUSH  EBX
        XOR   BX, BX
@L:
        ADD   [EAX], BL
        MOV   EBX, [EDX]
        JC    @CR
        ADD   [EAX],  EBX
        SETC  BL
        JMP   @CONT
@CR:    ADD   [EAX],  EBX
        MOV   BL, 1
@CONT:  ADD   EAX, 4
        ADD   EDX, 4
        LOOP  @L
        MOV   AL, BL
        POP   EBX
end;

{ TLongNumber }

procedure TLongNumber.AddValue(Value: TLongNumber);
begin
  if FIntegralPartLength < Value.FIntegralPartLength then
    begin
      ReallocMem(FIntegralPart, 4 * Value.FIntegralPartLength);

    end;

  if AddTo(FIntegralPart,Value.FIntegralPart, FIntegralPartLength) then
    begin
      ReallocMem(FIntegralPart, 4 * Value.FIntegralPartLength);
    end;
end;

constructor TLongNumber.Create;
begin
  FEqualsZero:= True;
  FIsInfinity:= False;
  FIsPositive:= True;

  FNumeratorLength:= 0;
  FDenominatorLength:= 0;
  FIntegralPartLength:= 0;

  FNumerator:= nil;
  FDenominator:= nil;
  FIntegralPart:= nil;
end;

destructor TLongNumber.Destroy;
begin
  SetLength(fNumber, 0);
  inherited;
end;

function TLongNumber.DoubleValue: Double;
begin
Result:= 1.;
  if fEqualsZero then
    begin
      Result:= 0.;
      Exit;
    end;
end;

{
function TLongNumber.FGetDigit(P: PCardinal; Index: Cardinal): Cardinal;
begin
  Result:=PCardinal(Cardinal(P) + 4 * Index)^;
end;
}

procedure TLongNumber.Negate;
begin
  fIsPositive:= not fIsPositive;
end;

procedure TLongNumber.SetIsPositive(const Value: Boolean);
begin
  FIsPositive := Value;
end;

end.
