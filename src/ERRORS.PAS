{ ************************************************************************** }
{  Diese Unit stellt ein einfaches Objekt zur Verfuegung, dass helfen soll,  }
{ eine Fehlerbehandlung zu integrieren.                                      }
{ ************************************************************************** }
{                     (c) 1999, Tobias Kohn                                  }
{ ************************************************************************** }
{$G+}       { 286-Code erzeugen. }
{ ************************************************************************** }
UNIT Errors;
{ ************************************************************************** }
INTERFACE
{ ************************************************************************** }

 CONST
   er_NoError    = $0000;         { Kein Fehler. }
   er_AnyError   = $0001;         { Unbekannter Fehler. }
   er_TPIntern   = $0002;         { Interner Turbo-Pascal-Fehler. }
   er_Heap       = $0003;         { Fehler im Heap-Speicher. }
   er_BreakCalc  = $0004;         { Berechnung abbrechen. }

   er_FatalErrors= $8000;

   proc_NoProc   = $0000;         { Prozedur besitzt keine Nummer. }

 TYPE
   { ************************************************** }
   {  Dies ist ein Zeiger auf eine Routine, die ueber-  }
   { prueft, ob z.B. der Anwender ESC oder so etwas     }
   { drueckte, um die Berechnung zu stoppen.            }
   { ************************************************** }
   ATestBreaker = function: Boolean;

   { ************************************************** }
   {  Dies ist ein einfaches Fehler-Objekt.             }
   { ************************************************** }
   {  SetError   Loest einen Fehler aus.                }
   {  GetError   Gibt den letzten Fehler zurueck.       }
   {  ClearError Setzt den Fehlercode auf Null.         }
   {  IsError    Prueft, ob ein Fehler gesetzt ist.     }
   {  WriteError Schreibt den Fehler auf den Bildschirm.}
   { ************************************************** }
   ErrorObject = object
     ErrorHandler: procedure;
     ProcNr: Word;
     Address: Pointer;
     FatalErrors: Word;
     procedure Init;
     procedure SetError(AErrorCode, AProcNr: Word);
     procedure SetErrorI(AErrorCode, AProcNr: Integer);
     function GetError: Word;
     function GetErrorI: Integer;
     procedure ClearError;
     function IsError: Boolean;
     procedure WriteError;
   private
     ErrorCode: Word;
   end;

   { ************************************************** }
   {  Diese Fehlerbehandlung ist in der Lage, abzuspei- }
   { chern, welche Routine als letztes aufgerufen wurde }
   { (sofern diese Routine die Methode EnterProc auf-   }
   { rief).                                             }
   { ************************************************** }
   {  ProcCalls  Die Liste der aufgerufenen Routinen.   }
   {  ProcCount  Das naechste freie Element in Proc-    }
   {              Calls. Zeigt gleichzeitig auch an,    }
   {              wie viele Routinen gerade laufen.     }
   {  DebufFlag  Zeigt an, ob der Debugger aktiv ist.   }
   {  DebugFile  Die Debuger-Datei.                     }
   { ************************************************** }
   {  EnterProc  Die Routinen sollten diese Methode     }
   {              aufrufen, um mitzuteilen, dass sie    }
   {              die bearbeitung uebernehmen.          }
   {  LeaveProc  Teilt mit, dass die zuletzt aufgerufene}
   {              Routine verlassen wird.               }
   {  SError     Setzt den Fehler mit der zuletztaufge- }
   {              rufenen Prozedur.                     }
   {  InitDebug  Startet den Debuger.                   }
   { ************************************************** }
   HErrorObj = ^LErrorObj;
   LErrorObj = object(ErrorObject)
     ProcCalls: Array[0..127] of Word;
     ProcCount: Byte;
     DebugFlag: Boolean;
     DebugFile: string[127];
     TestBreak: ATestBreaker;
     procedure EnterProc(ANr: Word);
     procedure LeaveProc;
     procedure SError(AError: Word);
     procedure InitDebug(AFileName: string);
     procedure DebugAdd(AStr: string; ANr: Word);
   end;



{ ************************************************************************** }
IMPLEMENTATION
{ ************************************************************************** }

 { ****************************************************** }
 procedure ErrorObject.Init;
 begin
   ErrorCode := $00;               { Alle Felder zurÅcksetzen. }
   ErrorHandler := nil;
   ProcNr := $00;
   FatalErrors := er_FatalErrors;
 end;

 procedure ErrorObject.SetError(AErrorCode, AProcNr: Word);
 var
   pa,pb: Word;
 begin
   asm
         mov       ax,ss:[bp+04]        { Die Addresse der Aufruf-Prozedur }
         mov       pa,ax                { nach pa und pb speichern. }
         mov       ax,ss:[bp+02]
         mov       pb,ax
   end;
   Address := Ptr(pa,pb);
   ErrorCode := AErrorCode;
   ProcNr := AProcNr;
   if not (@ErrorHandler = nil) then ErrorHandler;
   if (AErrorCode and FatalErrors) = FatalErrors then halt;
 end;

 procedure ErrorObject.SetErrorI(AErrorCode, AProcNr: Integer);
 var
   pa,pb: Word;
 begin
   asm
         mov       ax,ss:[bp+04]        { Die Addresse der Aufruf-Prozedur }
         mov       pa,ax                { nach pa und pb speichern. }
         mov       ax,ss:[bp+02]
         mov       pb,ax
   end;
   Address := Ptr(pa,pb);
   ErrorCode := Word(AErrorCode);
   ProcNr := Word(AProcNr);
   if not (@ErrorHandler = nil) then ErrorHandler;
   if (AErrorCode and FatalErrors) = FatalErrors then halt;
 end;

 function ErrorObject.GetError: Word;
 begin
   GetError := ErrorCode;
 end;

 function ErrorObject.GetErrorI: Integer;
 begin
   GetErrorI := Integer(ErrorCode);
 end;

 procedure ErrorObject.ClearError;
 begin
   ErrorCode := 0;
   ProcNr := 0;
   Address := nil;
 end;

 function ErrorObject.IsError: Boolean;
 begin
   IsError := not (ErrorCode = 0);
 end;

 procedure ErrorObject.WriteError;
 begin
   WriteLn('Error ', ErrorCode, ' at ',seg(Address^),':',ofs(Address^),'.');
 end;

 { ****************************************************** }
 procedure LErrorObj.EnterProc(ANr: Word);
 begin
   if (ProcCount < 128)
    then ProcCalls[ProcCount] := ANr;
   if (ProcCount < 128)
    then DebugAdd('enter proc ', ProcCalls[ProcCount])
    else DebugAdd('enter any proc ', 0);
   inc(ProcCount);
   if not (@TestBreak = nil) then TestBreak;
 end;

 procedure LErrorObj.LeaveProc;
 begin
   if (ProcCount < 128)
    then DebugAdd('leave proc ', ProcCalls[ProcCount])
    else DebugAdd('leave any proc ', 0);
   if (ProcCount > 0) then dec(ProcCount);
   if not (@TestBreak = nil) then TestBreak;
 end;

 procedure LErrorObj.SError(AError: Word);
 var
   Buffer: Word;
 begin
   if (ProcCount < 128) then begin
     if (ProcCount = 0) and (ProcCalls[0] = 0)
      then Buffer := $00
      else Buffer := ProcCalls[ProcCount];
   end else Buffer := $FFFF;
   SetError(AError, Buffer);
 end;

 procedure LErrorObj.InitDebug(AFileName: string);
 var
   f: File;
 begin
   {$I+}
   DebugFile := AFileName;
   Assign(f, DebugFile);
   ReWrite(f);
   Close(f);
   DebugFlag := true;
 end;

 procedure LErrorObj.DebugAdd(AStr: string; ANr: Word);
 var
   f: Text;
   s: string[7];
 begin
   if not DebugFlag then exit;
   str(ANr, s);
   Assign(f, DebugFile);
   Append(f);
   writeLn(f, AStr+s);
   Close(f);
 end;
 { ****************************************************** }

{ ************************************************************************** }
END.
{ ************************************************************************** }