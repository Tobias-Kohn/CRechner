unit Optunit;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, Buttons, CRTypes, Spin, NSolve;

type
  TOptForm = class(TForm)
    OKButton: TBitBtn;
    CancButton: TBitBtn;
    Label1: TLabel;
    Label2: TLabel;
    AngleBox: TComboBox;
    cplxoputBox: TComboBox;
    Label3: TLabel;
    DigitEdit: TSpinEdit;
    Case_Box: TCheckBox;
    SecInfoBox: TCheckBox;
    Lang_Box: TComboBox;
    Label4: TLabel;
    procedure FormActivate(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
  public
    procedure LoadLabels;
  end;

var
  OptForm: TOptForm;

const
  CaseSens: boolean = false;

implementation
 uses MainUnit;

{$R *.DFM}

procedure TOptForm.FormActivate(Sender: TObject);
begin
  AngleBox.ItemIndex := AngleType - $01;
  cplxoputBox.ItemIndex := CmplxType - $01;
  DigitEdit.Value := Digits;
  Case_Box.Checked := CaseSens;
  SecInfoBox.Checked := SecInfoFlag;
  if (Language = 'ENG') then Lang_Box.ItemIndex := $00;
  if (Language = 'GER') then Lang_Box.ItemIndex := $01;
end;

procedure TOptForm.OKButtonClick(Sender: TObject);
begin
  AngleType := AngleBox.ItemIndex + $01;
  CmplxType := cplxoputBox.ItemIndex + $01;
  Digits := DigitEdit.Value;
  CaseSens := Case_Box.Checked;
  SecInfoFlag := SecInfoBox.Checked;
  if (Lang_Box.ItemIndex = $00) then Language := 'ENG';
  if (Lang_Box.ItemIndex = $01) then Language := 'GER';
end;

procedure TOptForm.LoadLabels;
var
  f: TextFile;
  s: string;
begin
  AssignFile(f, ProgramPath+LabelFileName+Language);
  ReSet(f);
  while not eof(f) do begin
    readLn(f, s);
    if (s = '[OPTIONS]') then break;
  end;
  readLn(f, s); Label1.Caption     := s;
  readLn(f, s); Label2.Caption     := s;
  readLn(f, s); Label4.Caption     := s;
  readLn(f, s); Case_Box.Caption   := s;
  readLn(f, s); SecInfoBox.Caption := s;
  readLn(f, s); Label3.Caption     := s;
  CloseFile(f);
end;

end.
