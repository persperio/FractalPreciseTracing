unit CalculationThread;

interface

uses
  SysUtils, Classes;

type
  TContainerArray = array of array of Integer;

  TCalculationThread = class(TThread)
    private
      FContainerArray : TContainerArray;
      procedure CalculateValue(X, Y: Integer);
      procedure CalculateNeighbour(const XIndex, YIndex: Integer);
      procedure EvaluateFrame;
      procedure InterpolateIterations;
    protected
      FColumnCount: integer;
      FRowCount:integer;
      function GetLeaveIteration(const XIndex, YIndex: Integer): Integer; virtual; abstract;
      function SeparatedByZeroOrdinate(const MaxYIndex: Integer;
        out NegativeValueIndex: integer): Boolean; virtual; abstract;
      procedure Execute; override;
    public
      constructor Create(ContainerArray: TContainerArray; CreateSuspended: Boolean);
    end;

implementation

type

  TAdditionIndexes = record
    i, j : integer;
  end;

var

  _idx : array [-1..8] of TAdditionIndexes;

procedure CreateIndexArray;
var
  a: real;
  k: integer;
begin
  for k := -1 to 8 do
    begin
      a := k * pi / 4.;
      with _idx[k] do
        begin
          i := Round(cos(a));
          j := Round(sin(a));
        end;
    end;
end;

{ TCalculationThread }

procedure TCalculationThread.CalculateNeighbour(const XIndex, YIndex: integer);

type
  TVals = record
    P, Q: integer;
  end;

var
  k: Integer;
  Values: array of TVals;
  m, r: integer;
  X, Y: integer;
  Coords: array [0..7] of TVals;
  IsUndef: array [0..7] of Boolean;
  Differs: array [-1..8] of Boolean;
begin
  if FContainerArray[XIndex, YIndex] <> 0 then Exit;
  SetLength(Values, fColumnCount * fRowCount);
  CalculateValue(XIndex, YIndex);
  Values[0].P := XIndex;
  Values[0].Q := YIndex;
  m:=0;
  repeat
    X := Values[m].P;
    Y := Values[m].Q;
    r := m;
    FillChar(IsUndef, SizeOf(IsUndef), 0);
    FillChar(Differs, SizeOf(Differs), 0);
    for k := 0 to 7 do
      with Coords[k] do
        begin
          P := X + _idx[k].i;
          Q := Y + _idx[k].j;
          if FContainerArray[P, Q] = 0
            then IsUndef[k] := True
            else Differs[k] := FContainerArray[P, Q] <> FContainerArray[X, Y];
        end;
    Differs[-1] := Differs[7]; Differs[8] := Differs[0];
    for k:= 0 to 7 do
      if IsUndef[k] and (Differs[k-1] or Differs[k+1]) then
        begin
          Inc(m);
          Values[m] := Coords[k];
          CalculateValue(Values[m].P, Values[m].Q);
        end;
    if r = m then Dec(m);
  until m < 0;
  SetLength(Values, 0);
end;

procedure TCalculationThread.CalculateValue(X, Y: Integer);
begin
  FContainerArray[X, Y] := GetLeaveIteration(X, Y);
end;

constructor TCalculationThread.Create(ContainerArray: TContainerArray; CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  FContainerArray := ContainerArray;
  FColumnCount := Length(FContainerArray);
  FRowCount := Length(FContainerArray[0]);
end;

procedure TCalculationThread.EvaluateFrame;
var
  i, j, k, m: integer;
begin
  for k := 0 to 1 do
    begin
      j := k * (FRowCount - 1);
      for i := 1 to FColumnCount - 2 do CalculateValue(i, j);
      i := k * (FColumnCount - 1);
      for j := 0 to FRowCount - 1 do CalculateValue(i, j);
    end;

  if SeparatedByZeroOrdinate(FRowCount - 1, m) then
    for k := 0 to 1 do
      begin
        if (m >= 1) and (m <= FRowCount - 2) then
          for i := 1 to FColumnCount - 2 do CalculateValue(i, m);
        if (m > 1) and (m < FRowCount - 2) then
          begin
            j := m - 1 + 2 * k;
            for i := 0 to FColumnCount - 2 do
              if FContainerArray[i, m] <> FContainerArray[i + 1, m] then
                begin
                  CalculateNeighbour(i, j);
                  CalculateNeighbour(i + 1, j);
                end;
          end;
        inc(m);
      end;

  for k :=0 to 1 do
    begin
      j := k * (FRowCount - 1);
      m := j + 1 - 2 * k;
      for i := 0 to FColumnCount - 2 do
        if FContainerArray[i, j] <> FContainerArray[i + 1, j] then
          begin
            CalculateNeighbour(i, m);
            CalculateNeighbour(i + 1, m);
          end;
      i := k * (FColumnCount - 1);
      m := i + 1 - 2 * k;
      for j := 0 to FRowCount - 2 do
       if FContainerArray[i, j] <> FContainerArray[i, j + 1] then
        begin
         CalculateNeighbour(m, j);
         CalculateNeighbour(m, j + 1);
       end;
    end;
end;

procedure TCalculationThread.Execute;
var
  i, j: integer;
begin
  for i:= 0 to FColumnCount - 1 do
    for j:= 0 to FRowCount - 1 do
      FContainerArray[i, j] := 0;
  EvaluateFrame;
  InterpolateIterations;
end;

procedure TCalculationThread.InterpolateIterations;
var
  i, j: integer;
  Value: integer;
begin
  for i:= 1 to FColumnCount - 2 do
    begin
      Value := FContainerArray[i, 0];
      for j := 1 to FRowCount - 2 do
       if FContainerArray[i, j] = 0
         then FContainerArray[i, j] := Value
         else Value := FContainerArray[i, j];
    end;
end;

initialization

  CreateIndexArray;

  { Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure TCalculationThread.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }
end.
