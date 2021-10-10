{$DEFINE LANG_RU}

unit CustomConstants;

interface

{$IFDEF LANG_EN}

  const ccsDone = 'Done.';
  const ccsRepainting = 'Repainting.';
  const ccsCalculationsStarted = 'Calculations started';
  const ccsParametersDialogName = 'Parameters';
  const ccsDialogError = 'Parameters entered incorrectly';
  const ccsLeft = '';
  const ccsRight = '';
  const ccsTop = '';
  const ccsBottom = '';
  const ccsBoundaries = 'Boundaries';
  const ccsOK = 'OK';
  const ccsCancel = 'Cancel';

{$ENDIF}

{$IFDEF LANG_RU}

  const ccsDone = '������.';
  const ccsRepainting = '��� �����������.';
  const ccsCalculationsStarted = '��� ����������.';
  const ccsParametersDialogName = '���������';
  const ccsDialogError: PChar = '������ ��� �������� ����������';
  const ccsDialogErrorCaption: PChar = '������';
  const ccsCenterCoordinates = '���������� ������';
  const ccsScaleValues = '������� �������';
  const ccsTouchWindowFromInside = '������� � ����, �� ����������';
  const ccsCopyButtonHint = '���������� ��������� � �����';
  const ccsPasteButtonHint = '�������� ��������� �� ������';
  const ccsOK = 'OK';
  const ccsCancel = '������';
{$ENDIF}


implementation

end.
