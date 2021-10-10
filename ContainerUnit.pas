unit ContainerUnit;

interface

uses
  SysUtils, Classes,
  CalculationsUnit, CustomTypesUnit, CustomRoutinesUnit;

type

  TIterationContainer = class (TObject)
  private
    FContainerArray: TContainerArray;
    FCalculationThread: TCalculationThread;
    FThreadIsRunning: Boolean;
    FOnCalculationsComplete: TNotifyEvent;
    FCalculationTime: TDateTime;
    procedure WhenThreadTerminates(Sender: TObject);
    function GetCalculationTime: TDateTime;
   protected
    FCalculationParameters: TCalculationParameters;
    property CalculationParameters: TCalculationParameters read FCalculationParameters write FCalculationParameters;
    property ContainerArray: TContainerArray read FContainerArray;
    property OnCalculationsComplete: TNotifyEvent read FOnCalculationsComplete write FOnCalculationsComplete;
    property ThreadIsRunning: Boolean read FThreadIsRunning;
    procedure StartCalculation(const ColumnCount, RowCount: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    property LastCalculationTime: TDateTime read GetCalculationTime;
  end;

implementation

{ TIterationContainer }

constructor TIterationContainer.Create;
begin
  inherited Create;
  FCalculationThread := nil;
  FOnCalculationsComplete := nil;
  with FCalculationParameters do
    begin
      AutoFillIntermediateValues := False;
      Scale := GetScale(0.0, 0.0);
      Center := Coordinate(0.0, 0.0);
      MaxIterations := 256;
      MaxRadius := 2;
      UseExtendedPrecision := False;
      KeepAspectRatio := True;
    end;
  FCalculationTime := 0.0;
  FThreadIsRunning := False;
end;

destructor TIterationContainer.Destroy;
begin
  FCalculationThread.Free;
  SetLength(FContainerArray, 0);
  inherited Destroy;
end;

function TIterationContainer.GetCalculationTime: TDateTime;
begin
  if FThreadIsRunning
    then Result := 0.0
    else Result := FCalculationTime;
end;

procedure TIterationContainer.StartCalculation(const ColumnCount, RowCount: Integer);
var
  TempParams: TThreadParameters;
begin
  if FThreadIsRunning then Exit;
  FThreadIsRunning := True;
  SetLength(FContainerArray, ColumnCount, RowCount);
  if FCalculationParameters.UseExtendedPrecision
    then FCalculationThread := TPreciseCalculationThread.Create(True)
    else FCalculationThread := TFastCalculationThread.Create(True);
  with TempParams do
    begin
      ContainerArray := FContainerArray;
      CalculationParameters := FCalculationParameters;
    end;
  FCalculationTime := Date + Time;
  with FCalculationThread do
    begin
      SetThreadParameters(TempParams);
      OnTerminate := WhenThreadTerminates;
      Resume;
    end;
end;

procedure TIterationContainer.WhenThreadTerminates(Sender: TObject);
begin
  FThreadIsRunning := False;
  FCalculationTime := Date + Time - FCalculationTime;
  if Assigned(FOnCalculationsComplete) then FOnCalculationsComplete(Self);
end;


end.
 