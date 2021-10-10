unit CustomRoutinesUnit;

interface
uses
  SysUtils,
  CustomTypesUnit, LongNumbers, LongNumberConversion;

  function Coordinate(XValue, YValue:TStorageUnit): TCoordinate;
  function GetScale(XValue, YValue:TStorageUnit): TScale;

  procedure ModifyCenterOnLocalFractionalZoom(var Center: TCoordinate;
    OldScale: TScale; const p, q, Factor: Extended);
  procedure ModifyCenterOnCenteredFractionalZoom(var Center: TCoordinate;
    OldScale: TScale; const p, q: Extended);

  procedure ModifyScale(var Scale: TScale; const Factor: Extended);
  procedure ModifyScaleToKeepRatio(var Scale: TScale; const ColumnCount, RowCount: Integer);
  
  procedure ReadLineFromString(var Buf: String; out Line: String);


implementation

procedure ReadLineFromString(var Buf: String; out Line: String);
var
  i,j: Integer;
begin
  i := 1;
  while (i <= Length(Buf)) and ((Buf[i] = #13) or (Buf[i] = #10) or (Buf[i] = ' ')) do inc(i);
  j:=i;
  while (j <= Length(Buf)) and ((Buf[j] <> #13) and (Buf[j] <> #10) and (Buf[j] <> ' ')) do inc(j);
  Line := Copy(Buf, i, j - i);
  Buf := Copy(Buf, j, Length(Buf) - j + 1);
end;

function Coordinate(XValue, YValue:TStorageUnit): TCoordinate;
begin
  with Result do
    begin
      ExtendedToLongNumber(XValue, X);
      ExtendedToLongNumber(YValue, Y);
    end;
end;

function GetScale(XValue, YValue:TStorageUnit): TScale;
begin
  with Result do
    begin
      ExtendedToLongNumber(XValue, X);
      ExtendedToLongNumber(YValue, Y);
    end;
end;

// X := OldCenter.X + r * OldScale.X;
// Y := OldCenter.Y + t * OldScale.Y;
procedure ModifyScale(var Scale: TScale; const Factor: Extended);
var
  t: TLongNumber;
  r: Extended;
begin
  r := 1. / Factor;
  ExtendedToLongNumber(r, t);
  with Scale do
    begin
      MultiplyNumbers(X, t, X);
      MultiplyNumbers(Y, t, Y);
    end;
end;

procedure ModifyCenterOnLocalFractionalZoom(var Center: TCoordinate; OldScale: TScale;
  const p, q, Factor: Extended);
var
  r, t: Extended;
  u: TLongNumber;
begin
  t := (1 - 1 / Factor);
  r := t * (p - 0.5);
  t := t * (q - 0.5);
  
  ExtendedToLongNumber(r, u);
  MultiplyNumbers(u, OldScale.X, u);
  AddNumber(Center.X, u);

  ExtendedToLongNumber(t, u);
  MultiplyNumbers(u, OldScale.Y, u);
  AddNumber(Center.Y, u);
end;

//  X := OldCenter.X + r * OldScale.X;
//  Y := OldCenter.Y + t * OldScale.Y;
procedure ModifyCenterOnCenteredFractionalZoom(var Center: TCoordinate;
  OldScale: TScale; const p, q: Extended);
var
  r, t: TStorageUnit;
  u: TLongNumber;
  FScale: TScale;
begin
  FScale := OldScale;

  r := p - 0.5;
  t := q - 0.5;

  ExtendedToLongNumber(r, u);
  MultiplyNumbers(u, FScale.X, u);
  AddNumber(Center.X, u);

  ExtendedToLongNumber(t, u);
  MultiplyNumbers(u, FScale.Y, u);
  AddNumber(Center.Y, u);
end;

  (*
  if  Y / FBitmap.Height < X / FBitmap.Width
  then Y := X * FBitmap.Height / FBitmap.Width
  else X := Y * FBitmap.Width / FBitmap.Height;
  *)

procedure ModifyScaleToKeepRatio(var Scale: TScale; const ColumnCount, RowCount: Integer);
var
  u, v: TLongNumber;
begin
  with Scale do
    begin
      u := X;
      v := Y;
      //DivideByInteger(u, u, ColumnCount);
      //DivideByInteger(v, v, RowCount);
      MultiplyByInteger(v, v, ColumnCount);
      MultiplyByInteger(u, u, RowCount);
      if ByModuloSecondIsGreater(v, u)
        then
          begin
            MultiplyByInteger(X, Y, RowCount);
            DivideByInteger(Y, Y, ColumnCount);
          end
        else
          begin
            MultiplyByInteger(Y, X, ColumnCount);
            DivideByInteger(X, X, RowCount);
          end;
    end;
end;

{
function GetNewCenterOnLocalZoom(OldCenter, ZoomPoint: TCoordinate; const Factor: Double): TCoordinate;
var
  t: TStorageUnit;
  u: TLongNumber;
begin
  with Result do
    begin
      t := (1 - 1 / Factor);
      //X := OldCenter.X / Factor + t * ZoomPoint.X;
      //Y := OldCenter.Y / Factor + t * ZoomPoint.Y;

      ExtendedToLongNumber(t, u);              // u := t
      MultiplyNumbers(u, ZoomPoint.X, X);      // XP := u * ZoomPoint.XP
      MultiplyNumbers(u, ZoomPoint.Y, Y);

      t := 1. / Factor;

      ExtendedToLongNumber(t, u);              // u := 1. / Factor
      MultiplyNumbers(u, OldCenter.X, u);      // u := u * OldCenter.XP
      AddNumber(X, u);                         // XP := XP + u

      ExtendedToLongNumber(t, u);
      MultiplyNumbers(u, OldCenter.Y, u);
      AddNumber(Y, u);
    end;
end;
}

{procedure ZoomInLocal(var Boundaries:TBoundaries;
      const Coordinate:TCoordinate; const Factor: Double);
begin
  with Boundaries do
    begin
      with Center do
        begin
          X := X / Factor + (1 - 1 / Factor) * Coordinate.X;
          Y := Y / Factor + (1 - 1 / Factor) * Coordinate.Y;
        end;
      with Scale do
        begin
          X := X / Factor;
          Y := Y / Factor;
        end;
    end;
end;

procedure ZoomInFractionLocal(var Boundaries:TBoundaries; const p, q, Factor: double);
begin
  with Boundaries do
    begin
      with Center do
        begin
          X := X + (1 - 1 / Factor) * Scale.X * (p - 0.5);
          Y := Y + (1 - 1 / Factor) * Scale.Y * (q - 0.5);
        end;
      with Scale do
        begin
          X := X / Factor;
          Y := Y / Factor;
        end;
    end;
end;

procedure ZoomInCentered(var Boundaries:TBoundaries;
      const Coordinate:TCoordinate; const Factor: Double);
begin
  with Boundaries do
    begin
      Center := Coordinate;
      with Scale do
        begin
          X := X / Factor;
          Y := Y / Factor;
        end;
    end;
end;

procedure ZoomInFractionCentered(var Boundaries:TBoundaries; const p, q, Factor: double);
begin
    with Boundaries do
    begin
      with Center do
        begin
          X := X + Scale.X * (p - 0.5);
          Y := Y + Scale.Y * (q - 0.5);
        end;
      with Scale do
        begin
          X := X / Factor;
          Y := Y / Factor;
        end;
    end;
end; }

{
procedure ZoomInLocal(var Boundaries:TBoundaries;
      const Coordinate:TCoordinate; const Factor: Double);
begin
  with Boundaries, Coordinate do
    begin
      Left := X - (X - Left) / Factor;
      Right := (Right - X) / Factor + X;
      Bottom:= Y - (Y - Bottom) / Factor;
      Top:= (Top - Y) / Factor + Y;
    end;
end;

procedure ZoomInFractionLocal(var Boundaries:TBoundaries; const p, q, Factor: double);
begin
  with Boundaries do
    ZoomInLocal(Boundaries, Coordinate(Left + (Right - Left) * p, Bottom + (Top - Bottom) * q), Factor);
end;

procedure ZoomInCentered(var Boundaries:TBoundaries;
      const Coordinate:TCoordinate; const Factor: Double);
var
  dx, dy: double;
begin
  with Boundaries, Coordinate do
    begin
      dx:= (Right - Left) / Factor;
      dy:= (Top - Bottom) / Factor;
      Top:= Y + dy / 2.;
      Bottom:= Y - dy / 2.;
      Left:= X - dx / 2.;
      Right:= X + dx / 2.;
    end;
end;

procedure ZoomInFractionCentered(var Boundaries:TBoundaries; const p, q, Factor: double);
begin
  with Boundaries do
    ZoomInCentered(Boundaries, Coordinate(Left + (Right - Left) * p, Bottom + (Top - Bottom) * q), Factor);
end;

}

end.
