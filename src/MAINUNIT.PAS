unit Mainunit;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, Buttons, Menus, NInPut, NBasics, NCalcs,
  AuxStr, CRM_Ext, CRTypes, NVars, AboutU, Lists, NSolve;

type
  TMainForm = class(TForm)
    SolutionMemo: TMemo;
    CalcButton: TBitBtn;
    InputField: TEdit;
    QuitButton: TBitBtn;
    MainMenu: TMainMenu;
    Menu_File: TMenuItem;
    File_Opt: TMenuItem;
    File_Calc: TMenuItem;
    N1: TMenuItem;
    File_Quit: TMenuItem;
    Menu_Edit: TMenuItem;
    Edit_Save: TMenuItem;
    N2: TMenuItem;
    Edit_Clr: TMenuItem;
    Edit_Font: TMenuItem;
    Edit_Copy: TMenuItem;
    FontDialog: TFontDialog;
    SaveDialog: TSaveDialog;
    Edit_Paste: TMenuItem;
    N4: TMenuItem;
    File_Info: TMenuItem;
    procedure ResizeForm(Sender: TObject);
    procedure QuitClick(Sender: TObject);
    procedure Edit_SaveClick(Sender: TObject);
    procedure Edit_FontClick(Sender: TObject);
    procedure Edit_ClrClick(Sender: TObject);
    procedure Edit_CopyClick(Sender: TObject);
    procedure Edit_PasteClick(Sender: TObject);
    procedure File_InfoClick(Sender: TObject);
    procedure File_OptClick(Sender: TObject);
    procedure InputFieldKeyPress(Sender: TObject; var Key: Char);
    procedure FormCreate(Sender: TObject);
    procedure CalcClick(Sender: TObject);
  public
    procedure Calculate(Sender: TObject; AStr: string);
    function CheckCommand(Sender: TObject; AStr: string): Boolean;
    function CheckSyntax(Sender: TObject; AStr: string): Boolean;
    procedure LoadIniFile;
    procedure SaveIniFile;
    procedure LoadScript(AFile: string);
    procedure LoadLabels;
  end;

var
  MainForm: TMainForm;

  LastChain: HChain;
  LastText : string;

const
  IniFileName   = '\CRECHNER.INI';
  LabelFileName = '\LABELS2.';

  ProgramPath : string = 'C:\MATHE';
  IniPath     : string = '';

  Language    : string[3] = 'ENG';

{ **************************************************************************** }
implementation
 uses OptUnit;
{ **************************************************************************** }

{$R *.DFM}

{ Das Fenster darf nicht zu klein gemacht werden. }
procedure TMainForm.ResizeForm(Sender: TObject);
var
  i: Integer;
begin
  if (Height < 250) then Height := 250;
  if (Width  < 300) then Width  := 300;

  i := Width div 2;
  CalcButton.Left := i-8-CalcButton.Width;
  QuitButton.Left := i+8;

  SolutionMemo.Width := ClientWidth - 8;
  InputField.Width    := ClientWidth - 8;

  SolutionMemo.Height := ClientHeight - 80;
  InputField.Top := ClientHeight - 70;
  CalcButton.Top := ClientHeight - 40;
  QuitButton.Top := ClientHeight - 40;
end;

procedure TMainForm.QuitClick(Sender: TObject);
begin
  SaveIniFile;
  Application.Terminate;
end;

procedure TMainForm.Edit_SaveClick(Sender: TObject);
begin
  if SaveDialog.Execute
   then SolutionMemo.Lines.SaveToFile(SaveDialog.FileName);
end;

procedure TMainForm.Edit_FontClick(Sender: TObject);
begin
  FontDialog.Font := SolutionMemo.Font;
  if FontDialog.Execute
   then SolutionMemo.Font := FontDialog.Font;
end;

procedure TMainForm.Edit_ClrClick(Sender: TObject);
begin
  SolutionMemo.Lines.Clear;
end;

procedure TMainForm.Edit_CopyClick(Sender: TObject);
begin
  if SolutionMemo.Focused
   then SolutionMemo.CopyToClipboard;
  if InputField.Focused
   then InputField.CopyToClipboard;
end;

procedure TMainForm.Edit_PasteClick(Sender: TObject);
begin
  if SolutionMemo.Focused
   then SolutionMemo.PasteFromClipboard;
  if InputField.Focused
   then InputField.PasteFromClipboard;
end;

procedure TMainForm.File_InfoClick(Sender: TObject);
begin
  AboutBox.Left := MainForm.Left + 30;
  AboutBox.Top  := MainForm.Top  + 30;
  AboutBox.ShowModal;
end;

procedure TMainForm.File_OptClick(Sender: TObject);
var
  s1: string[3];
begin
  s1 := Language;
  OptForm.LoadLabels;
  OptForm.Left := MainForm.Left + 30;
  OptForm.Top  := MainForm.Top  + 30;
  OptForm.ShowModal;
  if (OptForm.ModalResult = mrOK) then SaveIniFile;
  if not (s1 = Language) then LoadLabels;
end;

procedure TMainForm.InputFieldKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #27) then begin
    InputField.Text := '';
    Key := #00;
  end;
  if CharInString(Key, '+*/^') and
      ((length(InputField.Text) = 0) or (InputField.SelLength > 0)) then begin
    InputField.Text := '"';
    InputField.SelStart := 1;
  end;
  if ((InputField.Text+Key) = 'entry') then begin
    InputField.Text := LastText;
    InputField.SelStart := 0;
    InputField.SelLength := length(InputField.Text);
    Key := #00;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  LoadIniFile;
end;

{ **************************************************************************** }
{ **************************************************************************** }

procedure TMainForm.CalcClick(Sender: TObject);
var
  s: string;
  l: byte absolute s;
  i,j: Byte;
begin
  s := InputField.Text;
  LastText := s;
  if not (s[l] = ';') then s := s + ';';

  i := CountOfChar(';', s);
  if (i > 0) then begin
    for i := 1 to i do begin
      j := pos(';', s);
      Calculate(Sender, Copy(s, 1, j-1));
      s := Copy(s, j+1, 255);
    end;
  end;
  InputField.SelStart := 0;
  InputField.SelLength := length(InputField.Text);
  InputField.SetFocus;
end;

procedure TMainForm.Calculate(Sender: TObject; AStr: string);
var
  Buffer, p, q: HChain;
  s2    : string[5];
  name1 : char;
  eqflag: boolean;
  i,j   : Integer;
begin
  GlobalError.ClearError;
  name1 := #00;
  DelSpaces(AStr);
  if CheckCommand(Sender, AStr) then exit;

  if not CaseSens then LowerNumber(AStr);
  if not CheckSyntax(Sender, AStr) then begin
    GlobalError.SetError(er_Syntax, $00);
    exit;
  end;
  SolutionMemo.Lines.Add(AStr);
  ReplaceFunctions(AStr);

  if (AStr[2] = '=') then begin     { x=... -> Konstante setzen oder loeschen. }
    name1 := AStr[1];
    AStr  := Copy(AStr, 3, 255);
    if (AStr = '()') then begin     { Bei leerer Klammer soll die Konstante }
      AddConstTolist(name1, nil);   { geloescht werden. }
      SolutionMemo.Lines.Add(#9+name1+'={}');
      exit;
    end;
    if (name1 = 'E') then begin              { "E" darf nicht als Konstante }
      GlobalError.SetError(er_DefE, $00);    { verwendet werden. }
      exit;
    end;
  end;
  if CharInString('=', AStr) then begin      { Bei einem anderen Gleichheits- }
    ReplaceStrings(AStr, '=0', '');          { zeichen handelt es sich um eine }
    ReplaceStrings(AStr, '=', ')-(');        { Gleichung. }
    AStr := '(' + AStr + ')';
    eqflag := true;
    if CharInString('=', AStr) then begin
      GlobalError.SetError(er_Syntax, $00);
      exit;
    end;
  end else eqflag := false;

  Buffer := StrToChain(AStr);                { String in Term umwandeln. }

  ReplaceChain(Buffer, str_Pi, const_Pi);    { Term zusammenfassen und alle }
  ReplaceChain(Buffer, '"', LastChain);      { bekannten Konstanten durch }
  UniteChains(Buffer);                       { Werte ersetzen. }
  UniteChains(Buffer);
  if eqflag then AddConstToList('x', nil);
  ReplaceAllConsts(Buffer);
  UniteChains(Buffer);

  AddConstToList(name1, Buffer);             { bei x=... die neue Konstante }
                                             { hinzufuegen. }
  if eqflag then begin                       { Eingabe ist Gleichung: Versuchen }
    InitSolver;                              { diese zu loesen. }
    SplitUpChain(Buffer);
    i := GetEquatLevel(Buffer)-1;
    if (i > 0) then for i := 1 to i do begin
      p := CopyChain(Buffer);
      SolveEquat(p, i);
      UniteChains(p);
      UniteChains(p);
      if GlobalError.IsError then break;
      AStr := ChainToStr(p);
      SecInfos.Add(#9+'x'+IntToStr(i)+'= '+AStr);
    end;
    SolveEquat(Buffer, i+1);
    UniteChains(Buffer);
    UniteChains(Buffer);
    if (SecInfos.Count > 0) then for j := 0 to (SecInfos.Count-1)
     do SolutionMemo.Lines.Add(SecInfos[j]);
    DoneSolver;
  end;

  if GlobalError.IsError
   then SolutionMemo.Lines.Add(#9+'Error')
   else begin
     AStr := ChainToStr(Buffer);             { Term (Resultat) wieder ausgeben. }

     if (AStr[1] = '(') and (AStr[length(AStr)] = ')')
      then AStr := Copy(AStr, 2, length(AStr)-2);
     if not (name1 = #00) then AStr := name1 + '=' + AStr;
     if eqflag then AStr := 'x'+IntToStr(i+1)+'= '+AStr;

     SolutionMemo.Lines.Add(#9+AStr);
   end;

  DisposeTreeItem(HTreeItem(LastChain));     { LastChain soll immer das letzte }
  LastChain := Buffer;                       { Resultat enthalten. }
end;

function TMainForm.CheckCommand(Sender: TObject; AStr: string): boolean;
var
  i: Integer;
  p: HConst;
begin
  LowerCase(AStr);
  ReplaceStrings(AStr, ':=', '=');

  if (AStr = 'exit') or (AStr = 'quit') or (AStr = 'ende')
   then Application.Terminate;
  if (AStr = 'about') or (AStr = 'info') then begin       { Infobox }
    File_InfoClick(Sender);
    CheckCommand := true; exit;
  end;
  if (AStr = 'save') then begin          { Speichern }
    Edit_SaveClick(Sender);
    CheckCommand := true; exit;
  end;
  if (AStr = 'options') then begin       { Optionen }
    File_OptClick(Sender);
    CheckCommand := true; exit;
  end;
  if (AStr = 'clr') or (AStr = 'clear') or (AStr = 'new') or (AStr = 'cls')
   then begin
    Edit_ClrClick(Sender);
    CheckCommand := true; exit;
  end;
  if (AStr = 'const') or (AStr = 'consts') then begin
    if (ConstList.Count > 0) then
     for i := 0 to (ConstList.Count-1) do begin
       p := HConst(ConstList.GetItem(i));
       SolutionMemo.Lines.Add(#9+p^.Name+': '+ChainToStr(p^.Term));
     end;
    CheckCommand := true; exit;
  end;

  if (Copy(AStr, 1, 7) = 'digits=') then begin      { Anzahl Stellen }
    i := StrToInt(Copy(AStr,8,5));
    if (i > 3) and (i < 103) then Digits := i;
  end;
  if (Copy(AStr, 1, 6) = 'digits') then begin
    SolutionMemo.Lines.Add(#9+' Digits: '+IntToStr(Digits));
    CheckCommand := true; exit;
  end;
  if (Copy(AStr, 1, 6) = 'angle=') then begin
    if (Copy(AStr, 7, 3) = 'rad') then AngleType := at_rad;
    if (Copy(AStr, 7, 3) = 'deg') then AngleType := at_deg;
  end;
  if (Copy(AStr, 1, 5) = 'angle') then begin
    if (AngleType = at_Rad) then SolutionMemo.Lines.Add(#9+' Angle: rad');
    if (AngleType = at_Deg) then SolutionMemo.Lines.Add(#9+' Angle: deg');
    CheckCommand := true; exit;
  end;
  if (Copy(AStr, 1, 5) = 'cplx=') then begin
    if (Copy(AStr, 6, 4) = 'rect') then CmplxType := ct_Rect;
    if (Copy(AStr, 6, 5) = 'polar') then CmplxType := ct_Polar;
  end;
  if (Copy(AStr, 1, 4) = 'cplx') then begin
    if (CmplxType = ct_rect) then SolutionMemo.Lines.Add(#9+' Complex: rect');
    if (CmplxType = ct_polar) then SolutionMemo.Lines.Add(#9+' Complex: polar');
    CheckCommand := true; exit;
  end;
  if (Copy(AStr, 1, 5) = 'case=') then begin
    if (Copy(AStr, 6, 4) = 'true') or (AStr[6] = '1') then CaseSens := true;
    if (Copy(AStr, 6, 5) = 'false') or (AStr[6] = '0') then CaseSens := false;
  end;
  if (Copy(AStr, 1, 4) = 'case') then begin
    if CaseSens
     then SolutionMemo.Lines.Add(#9+' Case sensitive: true')
     else SolutionMemo.Lines.Add(#9+' Case sensitive: false');
    CheckCommand := true; exit;
  end;

  if (Copy(AStr, 1, 5) = 'path=') then begin    { Programmpfad setzen. }
    ProgramPath := Copy(AStr, 6, 255);
    CheckCommand := true; exit;
  end;
  if (Copy(AStr, 1, 4) = 'ini=') then begin     { Pfad fuer die INI-Datei setzen. }
    IniPath := Copy(AStr, 5, 255);
    CheckCommand := true; exit;
  end;
  if (Copy(AStr, 1, 5) = 'load=') or
       (Copy(AStr, 1, 5) = 'open=') then begin  { Eine Datei laden und abarbeiten, }
    LoadScript(Copy(AStr,6, 255));              { als waeren die Eingabe vom }
    CheckCommand := true; exit;                 { Anwender. }
  end;
  if (Copy(AStr, 1, 4) = 'pos.') and (AStr[6] = '=') then begin { Position des }
    if (AStr[5] = 'x') then Left := StrToInt(Copy(AStr, 7, 6)); { Hauptfensters }
    if (AStr[5] = 'y') then Top := StrToInt(Copy(AStr, 7, 6));  { festlegen. }
    CheckCommand := true; exit;
  end;
  if (Copy(AStr, 1, 5) = 'size.') and (AStr[7] = '=') then begin { Groesse des }
    if (AStr[6] = 'x') then Width := StrToInt(Copy(AStr, 8, 6)); { Hauptfensters }
    if (AStr[6] = 'y') then Height := StrToInt(Copy(AStr, 8, 6));{ festlegen. }
    CheckCommand := true; exit;
  end;
  if (AStr = 'deutsch') or (AStr = 'lang=ger') then begin    { Sprache wechseln. }
    Language := 'GER';
    CheckCommand := true; exit;
  end;
  if (AStr = 'english') or (AStr = 'lang=eng') then begin
    Language := 'ENG';
    CheckCommand := true; exit;
  end;
  if (AStr = 'sprache') or (AStr = 'language') then begin
    SolutionMemo.Lines.Add(#9+' '+Language);
    CheckCommand := true; exit;
  end;

  CheckCommand := false;
end;

function TMainForm.CheckSyntax(Sender: TObject; AStr: string): Boolean;
var
  i: Byte;
  Buffer: boolean;
begin
  buffer := true;

  i := CountOfChar('(', AStr);         { Alle oeffnenden Klammern muessen auch }
  if not (i = CountOfChar(')', AStr))  { wieder geschlossen werden. }
   then buffer := false;

  if (CountOfChar('=', AStr) > 1) then buffer := false;
  if (AStr[length(AStr)] = '=') then buffer := false;

  CheckSyntax := buffer;
end;

 function GetWinDir: string;           { Ermittelt das Windows-Verzeichniss. }
 var
   Buffer: array[0..255] of char;
   l,i   : byte;
   AStr  : string absolute Buffer;
 begin
   l := GetWindowsDirectory(buffer, 250);
   for i := (l+1) downto 1 do Buffer[i] := Buffer[i-1];
   Buffer[0] := chr(l);
   GetWinDir := AStr;
 end;

procedure TMainForm.LoadIniFile;
var
  f: TextFile;
  s: string;
  i: Word;
begin
  if (ParamCount > 0) and (ParamStr(1) = '-') then exit;

  if (IniPath = '') then IniPath := GetWinDir;
  if (IniPath[length(IniPath)] = '\')      { Pfad darf nicht mit "\" enden. }
   then dec(byte(IniPath[0]));

  AssignFile(f, IniPath+IniFileName);      { Daten aus einer Ini-Datei laden. }
  {$I-}
    ReSet(f);
    if not (IOResult = 0) then exit;
  {$I+}
  while not eof(f) do begin
    readLn(f, s);
    if CharInString(';', s)
     then s := Copy(s, 1, pos(';', s)-1);
    if CharInString('=', s) and (length(s) > 0) then CheckCommand(nil, s);
  end;
  CloseFile(f);
  LoadLabels;
  CheckCommand(nil, 'clr');

  if (ParamCount = 0) then exit;           { Daten aus der Kommandozeile laden. }
  for i := 1 to ParamCount do begin
    s := ParamStr(i);
    if CharInString(';', s)
     then s := Copy(s, 1, pos(';', s)-1);
    if CharInString('=', s) and (length(s) > 0) then CheckCommand(nil, s);
  end;

  CheckCommand(nil, 'clr');
end;

procedure TMainForm.SaveIniFile;
var
  f: TextFile;
  s: string;
begin
  if (ParamStr(1) = '-') then exit;

  AssignFile(f, IniPath+IniFileName);
  ReWrite(f);
  s := '[C-Rechner-Version 2.0]'; writeLn(f, s);
  s := 'PATH='+ProgramPath;       writeLn(f, s);
  s := 'LANG='+Language;          writeLn(f, s);
  s := 'DIGITS='+IntToStr(Digits);writeLn(f, s);
  if (AngleType = at_Deg)
   then s := 'ANGLE=DEG'
   else s := 'ANGLE=RAD';         writeLn(f, s);
  if (CmplxType = ct_Polar)
   then s := 'CPLX=POLAR'
   else s := 'CPLX=RECT';         writeLn(f, s);

  s := 'POS.X='+IntToStr(Left);   writeLn(f, s);
  s := 'POS.Y='+IntToStr(Top);    writeLn(f, s);
  s := 'SIZE.X='+IntToStr(Width); writeLn(f, s);
  s := 'SIZE.Y='+IntToStr(Height);writeLn(f, s);

  CloseFile(f);
end;

procedure TMainForm.LoadScript(AFile: string);
var
  f: TextFile;
  s: string;
begin
  AssignFile(f, AFile);
  ReSet(f);
  while not eof(f) do begin
    readLn(f, s);
    if (s[length(s)] = ';') then dec(Byte(s[0]));                         
    Calculate(nil, s);
  end;
  CloseFile(f);
end;

procedure TMainForm.LoadLabels;
var
  f: TextFile;
  s: string;
begin
  { Menü-Einträge laden. }
  AssignFile(f, ProgramPath+LabelFileName+Language);
  ReSet(f);
  while not eof(f) do begin
    readLn(f, s);
    if (s = '[MENU]') then break;
  end;
  repeat readLn(f,s) until (s = '/File') or EOF(f);
  readLn(f, s); Menu_File.Caption := s;
  readLn(f, s); File_Calc.Caption := s;
  readLn(f, s); File_Opt.Caption  := s;
  readLn(f, s); File_Info.Caption := s;
  readLn(f, s); File_Quit.Caption := s;

  repeat readLn(f,s) until (s = '/Edit') or EOF(f);
  readLn(f, s); Menu_Edit.Caption := s;
  readLn(f, s); Edit_Copy.Caption := s;
  readLn(f, s); Edit_Paste.Caption:= s;
  readLn(f, s); Edit_Save.Caption := s;
  readLn(f, s); Edit_Clr.Caption  := s;
  readLn(f, s); Edit_Font.Caption := s;
  CloseFile(f);

  { Button-Beschriftungen laden. }
  AssignFile(f, ProgramPath+LabelFileName+Language);
  ReSet(f);
  while not eof(f) do begin
    readLn(f, s);
    if (s = '[BUTTONS]') then break;
  end;
  readLn(f, s); CalcButton.Caption := s;
  readLn(f, s); QuitButton.Caption := s;
  readLn(f, s); CalcButton.Hint    := s;
  readLn(f, s); QuitButton.Hint    := s;
  CloseFile(f);
end;

 procedure NewErrorHandler; far;
 var
   s: string;
 begin
   case GlobalError.GetError of
     er_Syntax : s := 'Syntax-Error.';
     er_DivZero: s := 'Cannot divide by zero.';
     er_LnZero : s := 'ln(0) is not defined.';
     er_Equat  : s := 'Cannot solve equation.';
     er_DefE   : s := 'Use E only for Exponent!';
   else
     s := 'Error: ' + IntToStr(GlobalError.GetError);
   end;
   if not (GlobalError.ProcNr = $00)
    then s := '['+IntToStr(GlobalError.ProcNr)+'] '+s;

   MessageDlg(s, mtError, [mbOk], 0);
 end;

var
  s: string[7];
  p: HChain;
begin
  CalcConsts1;
  CalcNumPi;
  LastChain := nil;
  LastText  := '';

  s := chr(kd_exp+$80)+'(1)';          { Eulersche Zahl als erste Konstante }
  p := StrToChain(s);                  { hinzufuegen. }
  UniteChains(p);
  AddConstToList('e', p);

  GlobalError.ErrorHandler := NewErrorHandler;
end.
{ **************************************************************************** }
