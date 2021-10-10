unit MainFormUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, RecoloringUnit, Menus, ComCtrls,
  CustomConstants, ParametersDialogUnit, LongNumberConversion;

type
  TMainForm = class(TForm)
    PaintBox1: TPaintBox;
    MainMenu1: TMainMenu;
    Program1: TMenuItem;
    View1: TMenuItem;
    ShowMenu1: TMenuItem;
    ShowStatusBar1: TMenuItem;
    StatusBar1: TStatusBar;
    Exit1: TMenuItem;
    Options1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ShowMenu1Click(Sender: TObject);
    procedure ShowStatusBar1Click(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure Options1Click(Sender: TObject);
  private
    FColorizator:TColorizator;
    procedure SetStatusBarNotification(const Value: String);
    procedure BeforeColorization(Sender: TObject);
    procedure AfterColorization(Sender: TObject);
    procedure BeforeThreadRun(Sender: TObject);
    procedure OnParametersDialogHide(Sender: TObject);
    property StatusBarNotification: String write SetStatusBarNotification;

  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses CustomTypesUnit;

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
var
  t: TStorageUnit;
  FCalculationParameters: TCalculationParameters;
begin
  FColorizator := TColorizator.Create;
  FCalculationParameters := FColorizator.CalculationParameters;
  with FCalculationParameters.Center do
    begin
      t := -0.75;
      ExtendedToLongNumber(t, X);
      t := 0;
      ExtendedToLongNumber(t, Y);
    end;
  with FCalculationParameters.Scale do
    begin
      t := 4;
      ExtendedToLongNumber(t, X);
      t := 2.5;
      ExtendedToLongNumber(t, Y);
    end;
  FColorizator.CalculationParameters := FCalculationParameters;
  FColorizator.AfterBitmapUpdate := AfterColorization;
  FColorizator.BeforeBitmapUpdate := BeforeColorization;
  FColorizator.BeforeThreadRun := BeforeThreadRun;
end;

procedure TMainForm.PaintBox1Paint(Sender: TObject);
begin
  PaintBox1.Canvas.Draw(0, 0, FColorizator.Bitmap);
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  if Self.Visible then
    begin
      FColorizator.Bitmap.Height := PaintBox1.Height;
      FColorizator.Bitmap.Width := PaintBox1.Width;
      FColorizator.Update;
    end;
end;

procedure TMainForm.PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Factor: TStorageUnit;
begin
  if ssCtrl in Shift then Factor := 10. else Factor := 2.;
  case Button of
    mbLeft: ;                         // Factor is already set
    mbRight: Factor := 1. / Factor;
    else exit;
  end;
  if ssShift in Shift then Factor := Sqr(Factor);
  FColorizator.Zoom(X, Y, Factor);
end;

procedure TMainForm.ShowMenu1Click(Sender: TObject);
begin
  ShowMenu1.Checked := not ShowMenu1.Checked;
  MainMenu1.Items.Clear;
end;

procedure TMainForm.ShowStatusBar1Click(Sender: TObject);
begin
  ShowStatusBar1.Checked:= not ShowStatusBar1.Checked;
  StatusBar1.Visible:= ShowStatusBar1.Checked;
  PaintBox1.Align:=alClient;
end;

procedure TMainForm.Exit1Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TMainForm.AfterColorization(Sender: TObject);
begin
  StatusBarNotification := TimeToStr(TColorizator(Sender).LastCalculationTime) + ' ' +  ccsDone;
  Repaint;
end;

procedure TMainForm.BeforeColorization(Sender: TObject);
begin
  StatusBarNotification := ccsRepainting;
end;

procedure TMainForm.BeforeThreadRun(Sender: TObject);
begin
  StatusBarNotification := ccsCalculationsStarted;
end;

procedure TMainForm.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  P:TPoint;
  Factor: TStorageUnit;
begin
  P:=PaintBox1.ScreenToClient(MousePos);
  with P do if (X < 0) or (X > PaintBox1.Width) or (Y < 0) or (Y > PaintBox1.Height) then Exit;
  if ssCtrl in Shift then Factor := 10. else Factor := 2.;
  if WheelDelta < 0 then Factor := - 120. / Factor / WheelDelta else Factor := Factor * WheelDelta / 120.;
  if ssShift in Shift then Factor := Sqr(Factor);
  FColorizator.Zoom(P.X, P.Y, Factor, False);
end;

procedure TMainForm.Options1Click(Sender: TObject);
begin
  Enabled := False;
  with ParametersDialog do
    begin
      CalculationParameters := FColorizator.CalculationParameters;
      OnHide := OnParametersDialogHide;
      Show;
    end;
end;

procedure TMainForm.OnParametersDialogHide(Sender: TObject);
begin
  Enabled := True;
  if ParametersDialog.ValuesChanged then
    with FColorizator do
      begin
        CalculationParameters := ParametersDialog.CalculationParameters;
        Update;
      end;
end;

procedure TMainForm.SetStatusBarNotification(const Value: String);
begin
  StatusBar1.Panels[0].Text := Value;
end;

end.
