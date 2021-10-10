unit CustomTypesUnit;

interface

uses
  SysUtils,
  LongNumbers;

type

  TContainerArray = array of array of Integer;

  TIntegerArray = array of Integer;

  TStorageUnit = Extended;

  TCoordinate = record
    X, Y: TLongNumber;
  end;

  TDelta = record
    P, Q: TLongNumber;
  end;

  TScale = record
    X, Y: TLongNumber;
  end;

  TFastCoordinate = record
    X, Y: TStorageUnit;
  end;

  TFastDelta = record
    P, Q: TStorageUnit;
  end;

  TFastScale = record
    X, Y: TStorageUnit;
  end;

  TCalculationParameters = record
    AutoFillIntermediateValues: Boolean;
    Center: TCoordinate;
    Scale: TScale;
    MaxIterations: Integer;
    MaxRadius: Integer;
    UseExtendedPrecision: Boolean;
    KeepAspectRatio: Boolean;
  end;

implementation

end.
