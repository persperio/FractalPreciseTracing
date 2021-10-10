unit RecoloringUnit;

interface

uses
  Windows, SysUtils, Classes, Graphics, Types,
  ContainerUnit, CustomRoutinesUnit, CustomTypesUnit, LongNumbers, LongNumberConversion;

type
  TColorizator = class(TIterationContainer)
    private
      FAutoUpdateOnZoom: Boolean;
      FAfterBitmapUpdate: TNotifyEvent;
      FBeforeThreadRun: TNotifyEvent;
      FBeforeBitmapUpdate: TNotifyEvent;
      FBitmap: TBitmap;
      procedure OnThreadFinished(Sender: TObject);
    public
      property CalculationParameters;
      property AfterBitmapUpdate: TNotifyEvent read FAfterBitmapUpdate write FAfterBitmapUpdate;
      property AutoUpdateOnZoom: Boolean read FAutoUpdateOnZoom write FAutoUpdateOnZoom;
      property BeforeThreadRun: TNotifyEvent read FBeforeThreadRun write FBeforeThreadRun;
      property BeforeBitmapUpdate: TNotifyEvent read FBeforeBitmapUpdate write FBeforeBitmapUpdate;
      property Bitmap: TBitmap read FBitmap;
      constructor Create;
      destructor Destroy; override;
      procedure Update;
      procedure Zoom(const X, Y: Integer; const Factor: Double; const CenterZoom: Boolean = True);
    end;

implementation

function GetProperColor(Iteration: integer): TColor; forward;

{ TColorizaror }

constructor TColorizator.Create;
begin
  inherited;
  FBeforeBitmapUpdate := nil;
  FAfterBitmapUpdate := nil;
  FBeforeThreadRun := nil;
  FAutoUpdateOnZoom := True;
  FBitmap := TBitmap.Create;
  OnCalculationsComplete := OnThreadFinished;
end;

destructor TColorizator.Destroy;
begin
  FBitmap.Free;
  FBitmap := nil;
  inherited Destroy;
end;

procedure TColorizator.OnThreadFinished(Sender: TObject);
var
  i, j, m, n: integer;
  C, OldBrushColor: TColor;
  ProperColorArray: array of TColor;
begin
  if Assigned(FBeforeBitmapUpdate) then FBeforeBitmapUpdate(Self);
  if Assigned(FBitmap) then
    begin
      SetLength(ProperColorArray, CalculationParameters.MaxIterations);
      for i := 0 to CalculationParameters.MaxIterations - 1 do
        ProperColorArray[i] := GetProperColor(i + 1);
      m := Length(ContainerArray);
      n := Length(ContainerArray[0]);
      with FBitmap do
        begin
          OldBrushColor := Canvas.Brush.Color;
          Canvas.Brush.Color := clBlack;
          Canvas.FillRect(Rect(0, 0, Width, Height));
          if m > Width then m := Width;
          if n > Height then n := Height;
          for i:= 0 to m - 1 do
            for j:= 0 to n - 1 do
              if ContainerArray[i, j] > 0
                then Canvas.Pixels[i, n - 1 - j] := ProperColorArray[ContainerArray[i, j] - 1];
          for i:= 1 to m - 2 do
            for j:= 1 to n - 2 do
              if (ContainerArray[i, j] = 0) and (ContainerArray[i, j - 1] > 0) then
                begin
                  C := Canvas.Pixels[i, n - j];
                  Canvas.Brush.Color := C;
                  Canvas.FloodFill(i, n - 1 - j, C, fsBorder);
                end;
          Canvas.Brush.Color := OldBrushColor;
        end;
    end;
  if Assigned(FAfterBitmapUpdate) then FAfterBitmapUpdate(Self);
end;

procedure TColorizator.Update;
begin
  if ThreadIsRunning then Exit;
  if Assigned(FBeforeThreadRun) then FBeforeThreadRun(Self);
  StartCalculation(FBitmap.Width, FBitmap.Height);
end;

procedure TColorizator.Zoom(const X, Y: Integer;
  const Factor: Double; const CenterZoom: Boolean = True);
var
  p, q: TStorageUnit;
  FScale: TScale;
begin
  if ThreadIsRunning then Exit;
  p := X / (FBitmap.Width - 1);
  q := 1. - Y / (FBitmap.Height - 1);
  with FCalculationParameters do
    begin
      FScale := Scale;
      if KeepAspectRatio then ModifyScaleToKeepRatio(FScale, FBitmap.Width, FBitmap.Height);
      if CenterZoom
        then ModifyCenterOnCenteredFractionalZoom(Center, FScale, p, q )
        else ModifyCenterOnLocalFractionalZoom(Center, FScale, p, q, Factor);
      ModifyScale(Scale, Factor);
    end;
  if FAutoUpdateOnZoom then Update;
end;

function GetPeriodicValue(X, T, MinY, MaxY: Integer): Integer;
begin
  X := X mod T;
  if X < T div 2
    then Result := MinY + 2 * (MaxY - MinY) * X div T
    else Result := 2 * MaxY - MinY - 2 * (MaxY - MinY) * X div T;
end;

function GetProperColor(Iteration: integer): TColor;
begin
  Result :=
    RGB (GetPeriodicValue(Iteration, 128, 0, $7F),
         GetPeriodicValue(Iteration, 32, $7f, $FF),
         GetPeriodicValue(Iteration, 512, $0, $FF));
    //RGB ((Iteration + (Iteration shr 8) * $10) and $FF, (Iteration and $0F) * $10 + $7f, Iteration and $F0);
end;

end.
