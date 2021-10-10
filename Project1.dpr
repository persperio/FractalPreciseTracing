program Project1;

uses
  Forms,
  MainFormUnit in 'MainFormUnit.pas' {MainForm},
  ContainerUnit in 'ContainerUnit.pas',
  CalculationsUnit in 'CalculationsUnit.pas',
  RecoloringUnit in 'RecoloringUnit.pas',
  LongArithmetics in 'LongArithmetics.pas',
  BorderTraceUnit in 'BorderTraceUnit.pas',
  CustomTypesUnit in 'CustomTypesUnit.pas',
  CustomRoutinesUnit in 'CustomRoutinesUnit.pas',
  CustomConstants in 'CustomConstants.pas',
  ParametersDialogUnit in 'ParametersDialogUnit.pas' {ParametersDialog},
  LongNumbers in 'LongNumbers\LongNumbers.pas',
  LongData in 'LongNumbers\LongData.pas',
  LongNumberConversion in 'LongNumbers\LongNumberConversion.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Mandelbrot';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TParametersDialog, ParametersDialog);
  Application.Run;
end.
