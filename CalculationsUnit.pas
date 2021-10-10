unit CalculationsUnit;

interface

uses
    SysUtils, Classes, Windows,
    CustomTypesUnit, BorderTraceUnit, LongNumbers, LongNumberConversion, CustomRoutinesUnit;

type

  TThreadParameters = record
    ContainerArray: TContainerArray;
    CalculationParameters: TCalculationParameters;
  end;

  TCalculationThread = class(TBorderTraceThread)
  private
    FMaxIterations: Integer;
    FMaxRadius: Integer;
    procedure PrepareCalculationParameters(var Center: TCoordinate; var Scale: TScale); virtual; abstract;
    procedure SetBoundaries(const MaxX, MaxY: Integer;
      var ZeroOrdinateNegativeValueIndex: Integer); virtual; abstract;
  public
    procedure SetThreadParameters(var Value: TThreadParameters);
  end;

  TFastCalculationThread = class(TCalculationThread)
  private
    FScale: TFastScale;
    FCenter: TFastCoordinate;
    FScaleDiv2: TFastScale;
    FDelta: TFastDelta;
    FMaxRadiusSquared: TStorageUnit;
    procedure PrepareCalculationParameters(var Center: TCoordinate; var Scale: TScale); override;
    procedure SetBoundaries(const MaxX, MaxY: Integer;
      var ZeroOrdinateNegativeValueIndex: Integer); override;
  protected
    function GetLeaveIteration (const XIndex, YIndex: Integer): Integer; override;
  end;

  TPreciseCalculationThread = class(TCalculationThread)
  private
    FScale: TScale;
    FCenter: TCoordinate;
    FScaleDiv2: TScale;
    FDelta: TDelta;
    FMaxRadiusSquared: TLongNumber;
    procedure PrepareCalculationParameters(var Center: TCoordinate; var Scale: TScale); override;
    procedure SetBoundaries(const MaxX, MaxY: Integer;
      var ZeroOrdinateNegativeValueIndex: Integer); override;
  protected
    function GetLeaveIteration (const XIndex, YIndex: Integer): Integer; override;
  end;

implementation

{ TCalculationThread }

procedure TCalculationThread.SetThreadParameters(var Value: TThreadParameters);
var
  FScale: TScale;
begin
  ContainerArray := Value.ContainerArray;
  with Value.CalculationParameters do
    begin
      Self.AutoFillIntermediateValues := AutoFillIntermediateValues;
      FMaxIterations := MaxIterations;
      FMaxRadius := MaxRadius;
      FScale := Scale;
      if KeepAspectRatio then ModifyScaleToKeepRatio(FScale, ColumnCount, RowCount);
      PrepareCalculationParameters(Center, FScale);
    end;
  SetBoundaries(ColumnCount - 1, RowCount - 1, FZeroOrdinateNegativeValueIndex);
end;

{ TFastCalculationThread }

function TFastCalculationThread.GetLeaveIteration(const XIndex, YIndex: Integer): Integer;
var
  P, Q: TStorageUnit;
  X, Y, T, U: TStorageUnit;
  i: Integer;
begin
  P := FCenter.X - FScaleDiv2.X + FDelta.P * XIndex;
  Q := FCenter.Y - FScaleDiv2.Y + FDelta.Q * YIndex;
  X := P;
  Y := Q;
  for i := 1 to FMaxIterations do
    begin
      T := X * X;
      U := Y * Y;
      if T + U > FMaxRadiusSquared then
        begin
          Result := i;
          Exit;
        end;
      T := T - U + P;
      Y := 2 * X * Y + Q;
      X := T;
    end;
  Result := -1;
end;

procedure TFastCalculationThread.PrepareCalculationParameters(var Center: TCoordinate; var Scale: TScale);
begin
  FMaxRadiusSquared := Sqr(FMaxRadius);
  with FScale do
   begin
     LongNumberToExtended(Scale.X, X);
     LongNumberToExtended(Scale.Y, Y);
    end;
  with FCenter do
    begin
      LongNumberToExtended(Center.X, X);
      LongNumberToExtended(Center.Y, Y);
    end;
  with FScaleDiv2 do
    begin
      X := FScale.X / 2.;
      Y := FScale.Y / 2.;
    end;
end;

procedure TFastCalculationThread.SetBoundaries(const MaxX, MaxY: Integer;
  var ZeroOrdinateNegativeValueIndex: Integer);
begin
  FDelta.P := FScale.X / MaxX;
  FDelta.Q := FScale.Y / MaxY;
  if Abs(FCenter.Y) < FScaleDiv2.Y
    then ZeroOrdinateNegativeValueIndex := Trunc((FScaleDiv2.Y - FCenter.Y) / FDelta.Q);
end;

{ TPreciseCalculationThread }

function TPreciseCalculationThread.GetLeaveIteration(const XIndex, YIndex: Integer): Integer;
var
  P, Q: TLongNumber;
  X, Y, T, U, V: TLongNumber;
  i: Integer;
begin
  MultiplyByInteger(FDelta.P, P, XIndex);
  AddNumber(P, FCenter.X);
  SubtractNumber(P, FScaleDiv2.X);

  MultiplyByInteger(FDelta.Q, Q, YIndex);
  AddNumber(Q, FCenter.Y);
  SubtractNumber(Q, FScaleDiv2.Y);

  X := P;
  Y := Q;

  for i := 1 to FMaxIterations do
    begin
      MultiplyNumbers(X, X, T);
      MultiplyNumbers(Y, Y, U);
      V := T;
      AddNumber(V, U);
      if ByModuloSecondIsGreater(FMaxRadiusSquared, V) then
        begin
          Result := i;
          Exit;
        end;
      SubtractNumber(T, U);
      AddNumber(T, P);

      MultiplyByCardinal(Y, Y, 2);
      MultiplyNumbers(Y, X, Y);
      AddNumber(Y, Q);
      X := T;
    end;
  Result := -1;
end;

procedure TPreciseCalculationThread.PrepareCalculationParameters(var Center: TCoordinate; var Scale: TScale);
begin
  IntegerToLongNumber(FMaxRadius, FMaxRadiusSquared);
  MultiplyByInteger(FMaxRadiusSquared, FMaxRadiusSquared, FMaxRadius);
  FScale := Scale;
  FCenter := Center;
  with FScaleDiv2 do
    begin
      DivideByCardinal(FScale.X, X, 2);
      DivideByCardinal(FScale.Y, Y, 2);
    end;
end;

procedure TPreciseCalculationThread.SetBoundaries(const MaxX,
  MaxY: Integer; var ZeroOrdinateNegativeValueIndex: Integer);
var
  t: TLongNumber;
begin
  DivideByInteger(FScale.X, FDelta.P, MaxX);
  DivideByInteger(FScale.Y, FDelta.Q, MaxY);
  t := FCenter.Y;
  MultiplyByCardinal(t, t, 2);                          // t := t * 2
  if ByModuloSecondIsGreater(t, FScale.Y)
    then
      begin
        t := FScaleDiv2.Y;
        SubtractNumber(t, FCenter.Y);
        DivideNumberByNumber(t, FDelta.Q, t);           // t := t /  FDelta.Q
        ZeroOrdinateNegativeValueIndex := TruncateLongNumber(t);
      end;
end;

end.
