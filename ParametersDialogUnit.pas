unit ParametersDialogUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, CustomConstants, Spin, StdCtrls, ExtCtrls, CustomRoutinesUnit, CustomTypesUnit,
  Buttons,
  LongNumbers, LongNumberConversion;

type
  TParametersDialog = class(TForm)
    OKButton: TButton;
    MaxIterationsSpinEdit1: TSpinEdit;
    IterationsEdit: TLabel;
    RadiusLabel: TLabel;
    MaxRadiusSpinEdit: TSpinEdit;
    CancelButton: TButton;
    CenterGroupBox: TGroupBox;
    RightLabel: TLabel;
    LeftLabel: TLabel;
    CenterXEdit: TEdit;
    CenterYEdit: TEdit;
    ScaleGroupBox: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    ScaleXEdit: TEdit;
    ScaleYEdit: TEdit;
    TouchWindowCheckBox: TCheckBox;
    CopyToClipboardButton: TBitBtn;
    PasteFromClipboardButton: TBitBtn;
    UsePreciseCalculationCheckBox: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CopyToClipboardButtonClick(Sender: TObject);
    procedure PasteFromClipboardButtonClick(Sender: TObject);
  private
    FCalculationParameters: TCalculationParameters;
    FValuesChanged: Boolean;
    function GetValuesFromControls: Boolean;
    procedure SetCalculationParameters(const Value: TCalculationParameters);
  public
    property CalculationParameters: TCalculationParameters read FCalculationParameters write SetCalculationParameters;
    property ValuesChanged: Boolean read FValuesChanged;
  end;

var
  ParametersDialog: TParametersDialog;

implementation

uses Clipbrd;

{$R *.dfm}

procedure TParametersDialog.FormCreate(Sender: TObject);
begin
  FValuesChanged := False;
  Caption := ccsParametersDialogName;
  CenterGroupBox.Caption := ccsCenterCoordinates;
  ScaleGroupBox.Caption := ccsScaleValues;
  OKButton.Caption := ccsOK;
  CancelButton.Caption := ccsCancel;
  CopyToClipboardButton.Hint := ccsCopyButtonHint;
  PasteFromClipboardButton.Hint := ccsPasteButtonHint;
  TouchWindowCheckBox.Caption := ccsTouchWindowFromInside;
end;

function TParametersDialog.GetValuesFromControls: Boolean;
var
  FCenter: TCoordinate;
  FScale: TScale;
begin
  Result:=
    TryStringToLongNumber(CenterXEdit.Text, FCenter.X) and
    TryStringToLongNumber(CenterYEdit.Text, FCenter.Y) and
    TryStringToLongNumber(ScaleXEdit.Text, FScale.X) and
    TryStringToLongNumber(ScaleYEdit.Text, FScale.Y);
  if not Result
    then
      begin
        MessageBox(Self.Handle, ccsDialogError, ccsDialogErrorCaption, 16);
        Exit;
      end;
  with FCalculationParameters do
    begin
      Center := FCenter;
      Scale := FScale;
      MaxIterations := MaxIterationsSpinEdit1.Value;
      MaxRadius := MaxRadiusSpinEdit.Value;
      UseExtendedPrecision := UsePreciseCalculationCheckBox.Checked;
      KeepAspectRatio := TouchWindowCheckBox.Checked;
    end;
end;

procedure TParametersDialog.SetCalculationParameters(
  const Value: TCalculationParameters);
begin
  FCalculationParameters := Value;
  with FCalculationParameters do
    begin
      MaxIterationsSpinEdit1.Value := MaxIterations;
      MaxRadiusSpinEdit.Value := MaxRadius;
      UsePreciseCalculationCheckBox.Checked := UseExtendedPrecision;
      TouchWindowCheckBox.Checked := KeepAspectRatio;
      ScaleXEdit.Text := LongNumberToString(Scale.X);
      ScaleYEdit.Text := LongNumberToString(Scale.Y);
      CenterXEdit.Text := LongNumberToString(Center.X);
      CenterYEdit.Text := LongNumberToString(Center.Y);
    end;
end;

procedure TParametersDialog.OKButtonClick(Sender: TObject);
begin
  if GetValuesFromControls then
    begin
      FValuesChanged := True;
      Hide;
    end;
end;

procedure TParametersDialog.CancelButtonClick(Sender: TObject);
begin
  Hide;
end;

procedure TParametersDialog.FormShow(Sender: TObject);
begin
  FValuesChanged := False;
end;

procedure TParametersDialog.CopyToClipboardButtonClick(Sender: TObject);
var
  S: String;
  i: Integer;
  Values: array [1..4] of TLongNumber;
begin
  if not
    (TryStringToLongNumber(CenterXEdit.Text, Values[1]) and
    TryStringToLongNumber(CenterYEdit.Text, Values[2]) and
    TryStringToLongNumber(ScaleXEdit.Text, Values[3]) and
    TryStringToLongNumber(ScaleYEdit.Text, Values[4]))
    then
      begin
        MessageBox(Self.Handle, ccsDialogError, ccsDialogErrorCaption, 16);
        Exit;
      end;
  S := '';
  for i := 1 to 4 do S := S + LongNumberToString(Values[i]) + #13#10;
  Clipboard.AsText := S;
end;

procedure TParametersDialog.PasteFromClipboardButtonClick(Sender: TObject);
var
  S0: String;
  i: Integer;
  S: array [1..4] of String;
  Values: array [1..4] of TLongNumber;
begin
  S0 := Clipboard.AsText;
  for i:=1 to 4 do
    begin
      ReadLineFromString(S0, S[i]);
      if not TryStringToLongNumber(S[i], Values[i]) then Exit;
    end;
  with FCalculationParameters do
    begin
     Center.X := Values[1];
     Center.Y := Values[2];
     Scale.X := Values[3];
     Scale.Y := Values[4];
    end;
  CenterXEdit.Text := S[1];
  CenterYEdit.Text := S[2];
  ScaleXEdit.Text := S[3];
  ScaleYEdit.Text := S[4];
end;

end.
