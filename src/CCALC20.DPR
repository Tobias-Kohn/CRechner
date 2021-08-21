program Ccalc20;

uses
  Forms,
  Mainunit in 'MAINUNIT.PAS' {MainForm},
  AuxStr in 'AUXSTR.PAS',
  Basics in 'BASICS.PAS',
  BCDMem in 'BCDMEM.PAS',
  CRComplx in 'CRCOMPLX.PAS',
  CRConv in 'CRCONV.PAS',
  CRM_Ext in 'CRM_EXT.PAS',
  CRMathe in 'CRMATHE.PAS',
  CRTypes in 'CRTYPES.PAS',
  Errors in 'ERRORS.PAS',
  Lists in 'LISTS.PAS',
  Memory in 'MEMORY.PAS',
  NBasics in 'NBASICS.PAS',
  NInPut in 'NINPUT.PAS',
  NVars in 'NVARS.PAS',
  NCalcs in 'NCALCS.PAS',
  Aboutu in 'ABOUTU.PAS' {AboutBox},
  Optunit in 'OPTUNIT.PAS' {OptForm},
  Nsolve in 'NSOLVE.PAS';

{$R *.RES}

begin
  Application.Title := 'C-Calculator 2.0';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.CreateForm(TOptForm, OptForm);
  Application.Run;
end.
