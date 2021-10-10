object MainForm: TMainForm
  Left = 269
  Top = 163
  Width = 1305
  Height = 675
  Caption = 'Mandelbrot'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnMouseWheel = FormMouseWheel
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object PaintBox1: TPaintBox
    Left = 0
    Top = 0
    Width = 1297
    Height = 610
    Align = alClient
    Color = clBtnFace
    ParentColor = False
    OnMouseDown = PaintBox1MouseDown
    OnPaint = PaintBox1Paint
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 610
    Width = 1297
    Height = 19
    Panels = <
      item
        Width = 50
      end>
  end
  object MainMenu1: TMainMenu
    Left = 200
    Top = 168
    object Program1: TMenuItem
      Caption = 'ccsProgram'
      object Exit1: TMenuItem
        Caption = 'ccsExit'
        OnClick = Exit1Click
      end
    end
    object View1: TMenuItem
      Caption = 'ccsView'
      object ShowMenu1: TMenuItem
        Caption = 'ccsShow Main Menu'
        Checked = True
        ShortCut = 121
        OnClick = ShowMenu1Click
      end
      object ShowStatusBar1: TMenuItem
        Caption = 'ccsShow Status Bar'
        Checked = True
        OnClick = ShowStatusBar1Click
      end
    end
    object Options1: TMenuItem
      Caption = 'Options'
      OnClick = Options1Click
    end
  end
end
