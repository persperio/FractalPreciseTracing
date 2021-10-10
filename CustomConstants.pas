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

  const ccsDone = 'Готово.';
  const ccsRepainting = 'Идёт перерисовка.';
  const ccsCalculationsStarted = 'Идёт вычисление.';
  const ccsParametersDialogName = 'Параметры';
  const ccsDialogError: PChar = 'Ошибка при указании параметров';
  const ccsDialogErrorCaption: PChar = 'Ошибка';
  const ccsCenterCoordinates = 'Координаты центра';
  const ccsScaleValues = 'Размеры области';
  const ccsTouchWindowFromInside = 'Умещать в окно, не растягивая';
  const ccsCopyButtonHint = 'Копировать параметры в буфер';
  const ccsPasteButtonHint = 'Вставить параметры из буфера';
  const ccsOK = 'OK';
  const ccsCancel = 'Отмена';
{$ENDIF}


implementation

end.
