unit BorderTraceUnit;

interface

uses
  SysUtils, Classes, SyncObjs, Windows,
  CustomTypesUnit;

type

  TAdditionIndexes = record
    I, J : integer;
  end;

  TAdditionalIndexesArray = array of TAdditionIndexes;

  TIndexedProcedure = procedure (const Index: Integer) of object;

  TBorderTraceThread = class(TThread)
  private
    FBoundariesIndexes: TIntegerArray;
    FContainerArray : TContainerArray;
    FColumnCount: Integer;
    FRowCount: Integer;
    FLandscapeDivision: Boolean;
    FAutoFillIntermediateValues: Boolean;
    FSubThreadsMaxCount: Integer;
    FCalculateLastBoundary: Boolean;  ///
    FSegmentBoundaryCount: Integer;
    FRunningThreadCount: Integer;
    FSyncEvent: TEvent;
    FGlobalThreadLock: TCriticalSection;
    FIndexedProcedure: TIndexedProcedure;
    FValuesBuffer: array of TAdditionalIndexesArray;
    procedure CalculateBoundary(const Index: Integer);
    procedure CalculateGrid;
    procedure CalculateAreas;
    procedure CalculateSingleArea(const Index: Integer);
    procedure CalculateFramedArea(const X1, Y1, X2, Y2, Index: Integer);
    procedure CalculateStaple(const Index: Integer);
    procedure CalculateValue(const X, Y: Integer);
    procedure EvaluateFrame;
    procedure InterpolateIterations;
    procedure OnBoundariesCalculationThreadTerminate(Sender: TObject);
    procedure SetContainerArray(const Value: TContainerArray);
    procedure TraceBorder(const StartX, StartY, Index: Integer);
  protected
    FZeroOrdinateNegativeValueIndex: Integer;
    procedure Execute; override;
    function GetLeaveIteration (const XIndex, YIndex: Integer): Integer; virtual; abstract;
    property AutoFillIntermediateValues: Boolean read FAutoFillIntermediateValues write FAutoFillIntermediateValues;
    property ColumnCount: Integer read FColumnCount;
    property ContainerArray: TContainerArray write SetContainerArray;
    property RowCount: Integer read FRowCount;
    property SubThreadsMaxCount: Integer read FSubThreadsMaxCount write FSubThreadsMaxCount;
  public
    constructor Create(CreateSuspended: Boolean);
    destructor Destroy; override;
  end;

implementation

type

  TCalculationSubThread = class(TThread)
  private
    FParentThread: TBorderTraceThread;
    FIndex: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: Boolean);
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
          I := Round(cos(a));
          J := Round(sin(a));
        end;
    end;
end;

procedure GetBoundariesIndexes(var Indexes: TIntegerArray; var BoundaryCount: Integer; const MaxVal: Integer);
var
  i: Integer;
begin
  if BoundaryCount > MaxVal + 1 then BoundaryCount := MaxVal + 1;
  SetLength(Indexes, BoundaryCount);
  if BoundaryCount = 1
    then Indexes[0] := 0
    else for i := 0 to BoundaryCount - 1 do Indexes[i] := i * MaxVal div (BoundaryCount - 1);
end;

{ TBorderTraceThread }

procedure TBorderTraceThread.TraceBorder(const StartX, StartY, Index: integer);
var
  k: Integer;
  Values: TAdditionalIndexesArray;
  m, r: integer;
  X0, Y0: integer;
  Coords: array [0..7] of TAdditionIndexes;
  IsUndef: array [0..7] of Boolean;
  DiffersFrom: array [-1..8] of Boolean;
begin
  Values := nil;
  if FContainerArray[StartX, StartY] <> 0 then Exit;
  Values := FValuesBuffer[Index];
  CalculateValue(StartX, StartY);
  Values[0].I := StartX;
  Values[0].J := StartY;
  m:=0;
  repeat
    X0 := Values[m].I;
    Y0 := Values[m].J;
    r := m;
    FillChar(IsUndef, SizeOf(IsUndef), 0);
    FillChar(DiffersFrom, SizeOf(DiffersFrom), 0);
    for k := 0 to 7 do
      with Coords[k] do
        begin
          I := X0 + _idx[k].I;
          J := Y0 + _idx[k].J;
          if FContainerArray[I, J] = 0
            then IsUndef[k] := True
            else DiffersFrom[k] := FContainerArray[I, J] <> FContainerArray[X0, Y0];
        end;
    DiffersFrom[-1] := DiffersFrom[7]; DiffersFrom[8] := DiffersFrom[0];
    for k:= 0 to 7 do
      if IsUndef[k] and (DiffersFrom[k-1] or DiffersFrom[k+1]) then
        begin
          Inc(m);
          Values[m] := Coords[k];
          CalculateValue(Values[m].I, Values[m].J);
        end;
    if r = m then Dec(m);
  until (m < 0) or Terminated;
end;

procedure TBorderTraceThread.EvaluateFrame;
begin
  FSegmentBoundaryCount := FSubThreadsMaxCount + 1;
  FLandscapeDivision := FColumnCount > FRowCount;
  if FLandscapeDivision
    then GetBoundariesIndexes(FBoundariesIndexes, FSegmentBoundaryCount, FColumnCount - 1)
    else GetBoundariesIndexes(FBoundariesIndexes, FSegmentBoundaryCount, FRowCount - 1);
  CalculateGrid;
  CalculateAreas;
end;

procedure TBorderTraceThread.Execute;
var
  i, j: integer;
begin
  for i:= 0 to FColumnCount - 1 do
    for j:= 0 to FRowCount - 1 do
      FContainerArray[i, j] := 0;
  FGlobalThreadLock := TCriticalSection.Create;
  EvaluateFrame;
  FGlobalThreadLock.Free;
  if FAutoFillIntermediateValues and not Terminated
    then InterpolateIterations;
end;

procedure TBorderTraceThread.InterpolateIterations;
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

procedure TBorderTraceThread.SetContainerArray(const Value: TContainerArray);
begin
  FContainerArray := Value;
  FColumnCount := Length(FContainerArray);
  FRowCount := Length(FContainerArray[0]);
end;

constructor TBorderTraceThread.Create(CreateSuspended: Boolean);
var
  SysInfo: _SYSTEM_INFO;
begin
  inherited Create(CreateSuspended);
  FContainerArray := nil;
  FIndexedProcedure := nil;
  FColumnCount := 0;
  FRowCount := 0;
  FAutoFillIntermediateValues := False;
  FZeroOrdinateNegativeValueIndex := -1;
  GetSystemInfo(SysInfo);
  FSubThreadsMaxCount := SysInfo.dwNumberOfProcessors;
  FreeOnTerminate := True;
  FSyncEvent := TEvent.Create(nil, False, False, '');
end;

procedure TBorderTraceThread.CalculateValue(const X, Y: Integer);
begin
  FContainerArray[X, Y] := GetLeaveIteration(X, Y);
end;

destructor TBorderTraceThread.Destroy;
begin
  Self.Terminate;
  inherited Destroy;
end;

procedure TBorderTraceThread.CalculateBoundary(const Index: Integer);
var
  i: Integer;
begin
  if FLandscapeDivision
    then for i := 0 to RowCount - 1 do CalculateValue(FBoundariesIndexes[Index], i)
    else for i := 0 to ColumnCount - 1 do CalculateValue(i, FBoundariesIndexes[Index]);
end;

procedure TBorderTraceThread.CalculateStaple(const Index: Integer);
var
  i, j: Integer;
begin
  CalculateBoundary(Index);
  if FLandscapeDivision
    then
      begin
        for j := 0 to 1 do
          if (FZeroOrdinateNegativeValueIndex + j > 0) and (FZeroOrdinateNegativeValueIndex + j < RowCount - 1)
            then for i := FBoundariesIndexes[Index] + 1 to FBoundariesIndexes[Index + 1] - 1 do
              CalculateValue(i, FZeroOrdinateNegativeValueIndex + j);
        for j := 0 to 1 do
          for i := FBoundariesIndexes[Index] + 1 to FBoundariesIndexes[Index + 1] - 1 do
            CalculateValue(i, j * (RowCount - 1));
      end
    else
      for j := 0 to 1 do
        begin
          if (FZeroOrdinateNegativeValueIndex + j > FBoundariesIndexes[Index]) and
             (FZeroOrdinateNegativeValueIndex + j < FBoundariesIndexes[Index + 1])
            then for i := 1 to ColumnCount - 1 do
              CalculateValue(i, FZeroOrdinateNegativeValueIndex + j);
          for i := FBoundariesIndexes[Index] + 1 to FBoundariesIndexes[Index + 1] - 1 do
            CalculateValue(j * (ColumnCount - 1), i);
        end;
end;

procedure TBorderTraceThread.OnBoundariesCalculationThreadTerminate(
  Sender: TObject);
begin
  FGlobalThreadLock.Acquire;
  try
    Dec(FRunningThreadCount);
  finally
    if FRunningThreadCount = 0 then FSyncEvent.SetEvent;
    FGlobalThreadLock.Release;
  end;
end;

procedure TBorderTraceThread.CalculateGrid;
var
  i: Integer;
  FThread: TCalculationSubThread;
begin
  FRunningThreadCount := FSegmentBoundaryCount - 1;
  FIndexedProcedure := CalculateStaple;
  for i := 0 to FSegmentBoundaryCount - 2 do
    begin
      FThread := TCalculationSubThread.Create(True);
      with FThread do
        begin
          OnTerminate := OnBoundariesCalculationThreadTerminate;
          FParentThread := Self;
          FIndex := i;
          Resume;
        end;
     end;
    if FSegmentBoundaryCount = 1 then CalculateBoundary(0);
    if FSegmentBoundaryCount > 1
      then
        begin
          CalculateBoundary(FSegmentBoundaryCount - 1);
          FSyncEvent.WaitFor(INFINITE);
        end;
end;

procedure TBorderTraceThread.CalculateAreas;
var
  i: Integer;
  FThread: TCalculationSubThread;
begin
  FRunningThreadCount := FSegmentBoundaryCount - 1;
  FIndexedProcedure := CalculateSingleArea;
  SetLength(FValuesBuffer, FSegmentBoundaryCount - 1);
  for i := 0 to FSegmentBoundaryCount - 2 do
    begin
      FThread := TCalculationSubThread.Create(True);
      SetLength(FValuesBuffer[i], FColumnCount * FRowCount div (FSegmentBoundaryCount - 1));
      with FThread do
        begin
          OnTerminate := OnBoundariesCalculationThreadTerminate;
          FParentThread := Self;
          FIndex := i;
          Resume;
        end;
     end;
    if FSegmentBoundaryCount > 1 then FSyncEvent.WaitFor(INFINITE);
    for i := 0 to FSegmentBoundaryCount - 2 do SetLength(FValuesBuffer[i], 0);
    SetLength(FValuesBuffer, 0);
end;

procedure TBorderTraceThread.CalculateFramedArea(const X1, Y1, X2, Y2, Index: Integer);
var
  i, j, k, m: Integer;
begin
  for k :=0 to 1 do
    begin
      j := Y1 + k * (Y2 - Y1);
      m := j + 1 - 2 * k;
      for i := X1 to X2 - 1 do
        if FContainerArray[i, j] <> FContainerArray[i + 1, j] then
          begin
            TraceBorder(i, m, Index);
            TraceBorder(i + 1, m, Index);
          end;
      i := X1 + k * (X2 - X1);
      m := i + 1 - 2 * k;
      for j := Y1 to Y2 - 1 do
       if FContainerArray[i, j] <> FContainerArray[i, j + 1] then
        begin
          TraceBorder(m, j, Index);
          TraceBorder(m, j + 1, Index);
       end;
    end;
end;

procedure TBorderTraceThread.CalculateSingleArea(const Index: Integer);
begin
  if FLandscapeDivision
    then
      begin
        if FZeroOrdinateNegativeValueIndex > 0
          then CalculateFramedArea(FBoundariesIndexes[Index], 0,
                 FBoundariesIndexes[Index + 1], FZeroOrdinateNegativeValueIndex, Index);
        if (FZeroOrdinateNegativeValueIndex + 1 > 0) and
           (FZeroOrdinateNegativeValueIndex + 1 < RowCount - 1)
          then CalculateFramedArea(FBoundariesIndexes[Index], FZeroOrdinateNegativeValueIndex + 1,
                 FBoundariesIndexes[Index + 1], RowCount - 1, Index);
        if FZeroOrdinateNegativeValueIndex = -1
          then CalculateFramedArea(FBoundariesIndexes[Index], 0,
                 FBoundariesIndexes[Index + 1], RowCount - 1, Index);
      end
    else
      begin
        if (FZeroOrdinateNegativeValueIndex > FBoundariesIndexes[Index]) and
           (FZeroOrdinateNegativeValueIndex < FBoundariesIndexes[Index + 1])
          then CalculateFramedArea(0, FBoundariesIndexes[Index],
                 ColumnCount - 1, FZeroOrdinateNegativeValueIndex, Index);
        if (FZeroOrdinateNegativeValueIndex + 1 > FBoundariesIndexes[Index]) and
           (FZeroOrdinateNegativeValueIndex + 1 < FBoundariesIndexes[Index + 1])
          then CalculateFramedArea(0, FZeroOrdinateNegativeValueIndex + 1,
                 ColumnCount - 1, FBoundariesIndexes[Index + 1], Index);
        if (FZeroOrdinateNegativeValueIndex + 1 <= FBoundariesIndexes[Index]) or
           (FZeroOrdinateNegativeValueIndex >= FBoundariesIndexes[Index + 1])
          then CalculateFramedArea(0, FBoundariesIndexes[Index],
                 ColumnCount - 1, FBoundariesIndexes[Index + 1], Index);
      end;
end;

{ TCalculationSubThread }

constructor TCalculationSubThread.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  FreeOnTerminate := True;
end;

procedure TCalculationSubThread.Execute;
begin
  FParentThread.FIndexedProcedure(FIndex);
end;

initialization

  CreateIndexArray;

finalization

  { Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure TBorderTraceThread.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }
end.
