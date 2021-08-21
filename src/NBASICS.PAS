{ ************************************************************************** }
{  Dies ist die Erste Unit, die im Programm CRechner zur Syntax-Analyse be-  }
{ nutzt wird. Sie enthaelt die grundlegenden Routinen und Strukturen, um die }
{ Listen mit den Zahlen, Funktionen und Variablen zu verwalten.              }
{  Zur Routine "StrToNumber" moechte ich bemerken, dass sie ein einzeln, das }
{ heisst ohne nachfolgende Potenz (durch ^ gekennzeichnet), vorkommendes i   }
{ als imaginaere Einheit interpretiert, ein i mit Potenz jedoch als Variable.}
{ ************************************************************************** }
{  Managing the lists of numbers, functions and variables.                   }
{ ************************************************************************** }
{                                                                            }
{                       (c) 1999/2000, Tobias Kohn                           }
{                                Version 2.0                                 }
{                                                                            }
{ ************************************************************************** }
{$G+}             { 286-Codes }
UNIT NBasics;
{ ************************************************************************** }
INTERFACE
 USES Lists, CRTypes, Errors, CRComplx, AuxStr, CRMathe;
{ ************************************************************************** }

   { ************************************************** }
   {  Folgende Konstanten geben jeweils den Typ eines   }
   { Listen-Elementes an. Sie sind nicht durchgehend    }
   { nummeriert, sondern in moeglichst sinnvolle        }
   { Gruppen unterteilt.                                }
   {  Alle Funktionen, die der Anwender auch direkt     }
   { eingeben kann, muessen zur Syntaxanalyse im        }
   { Bereich zwischen 01h und 5Fh liegen.               }
   {  Falls diese Werte geaendert werden, achten sie    }
   { bitte darauf, dass sie entweder nur neue Werte hin-}
   { zufuegen oder aber alle Funktionen (v.a. in der    }
   { Unit NCalcsN) ueberarbeiten, damit diese weiterhin }
   { korrekt arbeiten.                                  }
   { ************************************************** }
 CONST
   { x Unterelemente: }
   kd_Number    = $01;                          { Nummer: Zahl mit Variablen }
   kd_Clip      = $02;     kd_Add       = $02;  { Klammer: Zusammenfassen anderer Listen. }
   kd_Mul       = $03;                          { Multiplikation verschiedener Listen. }

   { 1 Unterelement: }
   kd_Neg       = $08;                          { Negiert das Unterelement. }
   kd_Inv       = $09;                          { Invertiert das Unterelement. }
   kd_Sqr       = $0A;                          { Quadriert das UE. }
   kd_Sqrt      = $0B;                          { Die Quadratwurzel aus dem UE. }
   kd_Kb        = $0C;                          { UE hoch 3. }
   kd_Kbrt      = $0D;                          { Die dritte Wurzel des UE. }
   kd_Fakul     = $0E;                          { Die Fakultaet. }
   kd_Abs       = $0F;                          { Der Absolutbetrag. }

   { 2 Unterelemente: }
   kd_Div       = $10;     kd_Frac      = $10;  { Bruch, Division }
   kd_Potenz    = $11;     kd_Pot       = $11;  { Potenz: x^y }

   { 1 Unterelement: }
   kd_Ln        = $20;                          { Natuerlicher Logaritmus. }
   kd_Lg        = $21;                          { Zehner-Logaritmus. }
   kd_Lb        = $22;                          { Binaerer Logaritmus }
   kd_Exp       = $23;                          { e^x }

   kd_sin       = $30;                          { sinus }
   kd_cos       = $31;                          { cosinus }
   kd_tan       = $32;                          { tangens }
   kd_arcsin    = $38;     kd_asin      = $38;  { arcussinus }
   kd_arccos    = $39;     kd_acos      = $39;  { arcuscosinus }
   kd_arctan    = $3A;     kd_atan      = $3A;  { arcustangens }

   { x Unterelemente: }
   kd_NoX       = $60;                          { Diese Typen werden fuer das Loesen }
   kd_x1        = $61;                          { von Gleichungen 1-4 Grades gebraucht. }
   kd_x2        = $62;                          { Die Gleichungen werden in 5 Terme zerlegt, }
   kd_x3        = $63;                          { wobei jeder Term den Koeffizienten vor }
   kd_x4        = $64;                          { einem x^z darstellt. }
                                                { Hinweis: da der Anwender keinen aktiven Zugriff }
                                                { auf diese Funktionen erhaelt, liegen sie im }
                                                { Bereich ueber 5Fh. (siehe oben) }
   { ************************************************** }
   proc_New     = $51;                   { NewVar, NewNumber, NewChain }
   proc_NrStr   = $52;                   { NumberToStr }
   proc_ChStr   = $53;                   { ChainToStr }
   proc_StrNr   = $54;                   { StrToNumber }
   proc_StrCh   = $55;                   { StrToChain }

   { ************************************************** }
   {  Die Listenelemente. Diese Elemente sind so defi-  }
   { niert, dass sie mit den Objektes aus der Unit Lists}
   { verwaltet werden koennen.                          }
   { ************************************************** }
   {  LVar       Nimmt eine Variable auf.               }
   {  LNumber    Enthaelt eine Nummer: eine komplexe    }
   {              Zahl mit Variablen.                   }
   {  LChain     Ein beliebiges Element: eine Funktion, }
   {              eine Klammer oder eine Nummer.        }
   { ************************************************** }
   {  Next       Zeigt jeweils auf das naechste Element }
   {              in der Liste.                         }
   {  Size       Gibt die Groesse an.                   }
   {  Sub        Das erste Untergeordnete Element.      }
   {                                                    }
   {  Name       Ein Buchstabe zur identifizierung der  }
   {              Variable.                             }
   {  Potenz     Die Potenz, in der die Variable steht. }
   {                                                    }
   {  Kind       Gibt den Typ des Elementes an (kd_XX). }
   {  Value      Die komplexe Zahl.                     }
   { ************************************************** }
 TYPE
   HVar = ^LVar;
   LVar = record
     Next: HVar;
     Size: Word;
     Sub : Pointer;
     Name: Char;
     Potenz: Integer;
   end;

   HNumber = ^LNumber;
   LNumber = record
     Next: HNumber;
     Size: Word;
     Sub : HVar;
     Kind: Byte;
     Value: Complex;
   end;

   HChain = ^LChain;
   LChain = record
     Next: HChain;
     Size: Word;
     Sub : Pointer;
     Kind: Byte;
   end;

   { ************************************************** }
   {  Die folgenden Funktionen erstellen neue Listen-   }
   { Elemente im Heap mit den angegebenen Eigenschaften.}
   { Mit Hilfe des Feldes Next eignen sich diese        }
   { Routinen auch dazu, ganze Listen zu erstellen.     }
   { ************************************************** }
   {  NewVar     Erstellt eine neue Variable.           }
   {  NewNumber  Erstellt eine neue Nummer.             }
   {  NewNumber  Erstellt eine neue Nummer, setzt aber  }
   {              den Imaginaerteil der Zahl auf 0.     }
   {  NewChain   Erstellt ein neues Kettenelement.      }
   {                                                    }
   {  GetNumZero Gibt eine Nummer ohne Variablen mit dem}
   {              Wert Null zurueck.                    }
   { ************************************************** }
   function NewVar(AName: Char; APotenz: Integer; ANext: HVar): HVar;
   function NewNumber(AValue: Complex; AVar: HVar; ANext: HNumber): HNumber;
   function NewNumberRe(AValue: SReal; AVar: HVar; ANext: HNumber): HNumber;
   function NewChain(AKind: Byte; AFirst: Pointer; ANext: Pointer): HChain;

   function GetNumZero: HNumber;

   { ************************************************** }
   {  Die folgenden Routinen wandeln einzelne Elemente  }
   { einer Liste in Strings um, damit diese ausgegeben  }
   { werden koennen.                                    }
   { ************************************************** }
   {  VarToStr   Gibt einen String zurueck, der den     }
   {              Namen der Variablen und die Potenz    }
   {              enthaelt, falls diese nicht 1 ist.    }
   {  NumberToStr   Wandelt eine Nummer in einen String }
   {              um.                                   }
   {  ChainToStr Eine Kette umwandeln.                  }
   { ************************************************** }
   function VarToStr(AVar: HVar): string;
   function NumberToStr(ANumber: HNumber): string;
   function ChainToStr(AChain: HChain): string;

   { ************************************************** }
   {  GetFuncStr Gibt einen String zurueck, der die     }
   {              angegebene Funktion repraesentiert.   }
   {              Dient vor allem auch der Ausgabe.     }
   { ************************************************** }
   function GetFuncStr(ACode: Byte): string;

   { ************************************************** }
   {  StrToNumber   Wandelt einen String in eine Nummer }
   {              um. Die variablen und ihre Potenzen   }
   {              werden dabei auch herausgelesen.      }
   { ************************************************** }
   function StrToNumber(AStr: string): HNumber;

   { ************************************************** }
   {  SortVars   Sortiert die Variablen der Nummer      }
   {              alphabetisch.                         }
   {  UniteVars  Fasst Variablen mit gleichen Namen zu  }
   {              einer Variablen zusammen.             }
   {                                                    }
   {  VarEquals  Ueberprueft, ob die Variablen in den   }
   {              beiden Nummern alle gleich sind und   }
   {              fasst auf jeden Fall alle Variablen   }
   {              zusammen.                             }
   {  GetVarPotenz Ermittelt die Potenz einer Variablen }
   {              in einer Nummer. Diese Routine funk-  }
   {              tioniert auch, wenn die Variablen     }
   {              nicht sortiert sind.                  }
   {                                                    }
   {  DeleteVar  Loescht die Variable mit dem Namen     }
   {              AName vollstaendig aus der Nummer.    }
   { ************************************************** }
   procedure SortVars(var ANumber: HNumber);
   procedure UniteVars(var ANumber: HNumber);

   function VarEquals(var ANum1, ANum2: HNumber): boolean;
   function GetVarPotenz(ANumber: HNumber; AName: Char): Integer;

   procedure DeleteVar(ANum: HNumber; AName: char);

   { ************************************************** }
   {  ConcatChains  Fuegt ACh2 an das Ende von ACh1 an. }
   {  CopyChains Kopiert die angegebene Kette.          }
   { ************************************************** }
   procedure ConcatChains(var ACh1, ACh2: HChain);
   function CopyChain(AChain: HChain): HChain;

{ ************************************************************************** }
IMPLEMENTATION
 USES CRConv;
{ ************************************************************************** }

 function NewVar(AName: Char; APotenz: Integer; ANext: HVar): HVar;
 var
   Buffer: HVar;
 begin
   if GlobalError.IsError then begin
     NewVar := nil;
     exit;
   end;
   GetMem(Buffer, SizeOf(LVar));        { Speicher reservieren. }
   if (Buffer = nil) then begin         { Fehler anfangen. }
     GlobalError.SetError(er_Heap, proc_New);
     NewVar := nil;
     exit;
   end;

   Buffer^.Next := ANext;
   Buffer^.Size := 3;                   { Werte zuweisen. }
   Buffer^.Sub  := nil;
   Buffer^.Name := AName;
   Buffer^.Potenz := APotenz;

   NewVar := Buffer;
 end;

 function NewNumber(AValue: Complex; AVar: HVar; ANext: HNumber): HNumber;
 var
   Buffer: HNumber;
 begin
   if GlobalError.IsError then begin
     NewNumber := nil;
     exit;
   end;
   GetMem(Buffer, SizeOf(LNumber));     { Speicher reservieren. }
   if (Buffer = nil) then begin         { Fehler anfangen. }
     GlobalError.SetError(er_Heap, proc_New);
     NewNumber := nil;
     exit;
   end;

   Buffer^.Next  := ANext;              { Werte zuweisen. }
   Buffer^.Size  := SizeOf(Buffer^.Value)+SizeOf(Buffer^.Kind);
   Buffer^.Sub   := AVar;
   Buffer^.Kind  := kd_Number;
   Buffer^.Value := AValue;

   NewNumber := Buffer;
 end;

 function NewNumberRe(AValue: SReal; AVar: HVar; ANext: HNumber): HNumber;
 var
   Buffer: HNumber;
 begin
   if GlobalError.IsError then begin
     NewNumberRe := nil;
     exit;
   end;
   GetMem(Buffer, SizeOf(LNumber));     { Speicher reservieren. }
   if (Buffer = nil) then begin         { Fehler anfangen. }
     GlobalError.SetError(er_Heap, proc_New);
     NewNumberRe := nil;
     exit;
   end;

   Buffer^.Next  := ANext;              { Werte zuweisen. }
   Buffer^.Size  := SizeOf(Buffer^.Value)+SizeOf(Buffer^.Kind);
   Buffer^.Sub   := AVar;
   Buffer^.Kind  := kd_Number;
   Buffer^.Value.Real := AValue;
   RLd_0(Buffer^.Value.Imag);

   NewNumberRe := Buffer;
 end;

 function NewChain(AKind: Byte; AFirst: Pointer; ANext: Pointer): HChain;
 var
   Buffer: HChain;
 begin
   if GlobalError.IsError then begin
     NewChain := nil;
     exit;
   end;
   if (AKind = kd_Number)               { Speicher reservieren. }
    then GetMem(Buffer, SizeOf(LNumber))
    else GetMem(Buffer, SizeOf(LChain));
   if (Buffer = nil) then begin         { Fehler anfangen. }
     GlobalError.SetError(er_Heap, proc_New);
     NewChain := nil;
     exit;
   end;

   Buffer^.Next := ANext;               { Werte zuweisen. }
   Buffer^.Size := 1;
   if (AKind = kd_Number)
    then Buffer^.Size := Buffer^.Size + SizeOf(Complex);
   Buffer^.Sub  := AFirst;
   Buffer^.Kind := AKind;

   NewChain := Buffer;
 end;

 function GetNumZero: HNumber;
 var
   AValue: Complex;
 begin
   CLd_0(AValue);
   GetNumZero := NewNumber(AValue, nil, nil);
 end;
 { ****************************************************** }

 function VarToStr(AVar: HVar): string;
 var
   Buffer: string;
 begin
   if (AVar = nil) or GlobalError.IsError then exit;

   Buffer := '';
   if not (AVar^.Potenz = 1) then begin           { Die Potenz nur anfuegen, wenn }
     str(AVar^.Potenz, Buffer);                   { sie nicht 1 ist. }
     Buffer := '^' + Buffer;
   end;
   if (AVar^.Name = str_pi)                       { Den Namen der Variablen anfuegen. }
    then Buffer := str_Pi2 + Buffer
    else Buffer := AVar^.Name + Buffer;
   if (AVar^.Potenz = 0) then Buffer := '';       { x^0 = 1: also die Variable ignorieren. }

   VarToStr := Buffer;
 end;

 { Dies ist eine Hilfsroutine fuer NumberToStr.                 }
 { Sie fuegt dem ersten String den zweiten an. Dabei wird noch  }
 { ein Multiplikationszeichen '*' eingefuegt.                   }
 procedure NumberAddVar(var AStr1: string; AStr2: string);
 begin
   if (AStr2 = '') or (AStr2 = '1') then exit;
   AStr1 := AStr1 + '*' + AStr2;
 end;

 function NumberToStr(ANumber: HNumber): string;
 var
   Buffer: string;
   SecBuffer: string[15];
   ACmplx: Complex;
   ACpxPl: ComplexPolar absolute ACmplx;
   p     : HVar;
 begin
   if (ANumber = nil) or GlobalError.IsError then exit;
   GlobalError.EnterProc(proc_NrStr);

   if CZero(ANumber^.Value) then begin       { Wenn der Wert der Zahl 0 ist, fallen }
     NumberToStr := '0';                     { die Variablen sowieso weg. }
     GlobalError.LeaveProc;
     exit;
   end;
   Buffer := '';

   if (CmplxType = ct_Polar) then begin      { Denn Wert der Funktion in einen String }
     ACmplx := ANumber^.Value;               { umwandeln. Zu Beruecksichtigen: ob die }
     RectToPolar(ACmplx);                    { Zahlen in Normal- oder Polarform ausge- }
     Buffer := CPolarToStr(ACpxPl);          { geben werden sollen. }
   end else begin
     Buffer := CComplexToStr(ANumber^.Value);
   end;

   p := ANumber^.Sub;                        { Variablen anfuegen. }
   while not (p = nil) do begin              { Die ganze Liste durchgehen. }
     SecBuffer := VarToStr(p);
     if not (SecBuffer = '') or (GlobalError.IsError)
      then NumberAddVar(Buffer, SecBuffer);
     p := p^.Next;
   end;

   if (Copy(Buffer, 1, 2) = '1*')            { Wenn vor den Variablen nur eine }
    then Buffer := Copy(Buffer, 3, 255);     { 1 steht, ist diese ueberfluessig. }
   if (Copy(Buffer, 1, 3) = '-1*')
    then Buffer := '-'+Copy(Buffer, 4, 255); 

   GlobalError.LeaveProc;
   NumberToStr := Buffer;
 end;

 function ChainToStr(AChain: HChain): string;
 var
   ANumber: HNumber absolute AChain;
   Buffer : string;
   l      : Byte absolute Buffer;
   p      : HChain;
 begin
   if GlobalError.IsError or (AChain = nil) then begin
     ChainToStr := '';
     exit;
   end;
   GlobalError.EnterProc(proc_ChStr);

   if (AChain^.Kind = kd_Number) then begin           { Wenn es sich um eine Nummer }
     ChainToStr := NumberToStr(ANumber);              { handelt, die Aufgabe weiter- }
     GlobalError.LeaveProc;                           { geben. }
     exit;
   end;
   Buffer := '';

   Buffer := GetFuncStr(AChain^.Kind);          { Die Funktion ermitteln. }

   p := AChain^.Sub;                            { Nun alle Unterelemente anfuegen. }
   while not (p = nil) do begin
     if (l > 0) and not (Buffer[l] = '(')
      then case AChain^.Kind of                 { Die Opertaionszeichen einfuegen. }
        kd_Pot : Buffer := Buffer + ' ^ ';
        kd_Mul : Buffer := Buffer + ' * ';
        kd_Div : Buffer := Buffer + ' / ';
      else
        Buffer := Buffer + ' + ';
      end;
     Buffer := Buffer + ChainToStr(p);
     p := p^.Next;
   end;
                                                      { Funktionen brauchen eine schliessende }
   if not (AChain^.Kind = kd_Abs)                     { Klammer. }
    then Buffer := Buffer + ')'
    else Buffer := Buffer + '|';

   case AChain^.Kind of
     kd_Fakul: Buffer := Buffer + '!';
     kd_sqr  : Buffer := Buffer + '^2';
     kd_kb   : Buffer := Buffer + '^3';
   end;
   ReplaceStrings(Buffer, '|(', '|');
   ReplaceStrings(Buffer, '+ -', '- ');

   GlobalError.LeaveProc;
   ChainToStr := Buffer;
 end;
 { ****************************************************** }

 function GetFuncStr(ACode: Byte): string;
 var
   Buffer: string;
 begin
   Buffer := '';
   if (ACode = kd_Number) then begin
     GetFuncStr := '';
     exit;
   end;

   case ACode of
     kd_ln  : Buffer := str_ln;
     kd_lg  : Buffer := str_lg;
     kd_lb  : Buffer := str_lb;

     kd_exp : Buffer := str_exp;

     kd_sqrt: Buffer := str_sqrt;
     kd_kbrt: Buffer := str_kbrt;

     kd_sin : Buffer := str_sin;
     kd_cos : Buffer := str_cos;
     kd_tan : Buffer := str_tan;
     kd_asin: Buffer := str_asin;
     kd_acos: Buffer := str_acos;
     kd_atan: Buffer := str_atan;
     kd_neg : Buffer := '-';
     kd_inv : Buffer := '1/';
     kd_abs : Buffer := '|';
     kd_x1  : Buffer := 'x*';
     kd_x2  : Buffer := 'x^2*';
     kd_x3  : Buffer := 'x^3*';
     kd_x4  : Buffer := 'x^4*';
   else
     Buffer := '';
   end;

   GetFuncStr := Buffer + '('
 end;
 { ****************************************************** }

 {  Hilfsrouitne fuer StrToNumber. Liest alle Variablen aus }
 { dem String aus und wandelt sie in interne Variblen um.   }
 function StrToVars(var AStr: string): HVar;
 var
   Buffer, p: HVar;
   i,j      : Byte;
   AChar    : Char;
   APotenz  : Integer;
 begin
   if GlobalError.IsError or (AStr = '') then exit;

   Buffer := nil; p := nil;
   AStr := AStr + '_';

   i := pos('"', AStr);
   if (i > 0) then begin
     Buffer := NewVar('"', 1, nil);
     Delete(AStr, i, 1);
   end;
   if CharInString('"', AStr) then begin
     GlobalError.SetError(er_Syntax, $00);
     exit;
   end;

   repeat
     i := FindNextLetter(AStr);         { Naechsten Buchstaben suchen. }
     if (i = 0) then break;             { Keiner gefunden? - Abbrechen. }

     AChar := AStr[i];                  { Buchstaben in einer neuen Variable }
     Delete(AStr, i, 1);                { speichern und aus String loeschen. }

     if (AStr[i] = '^') then begin      { Bei nachfolgendem ^ folgt noch die Angabe }

       if not CharInString(AStr[i+1], '0123456789+-') then begin  { Das erste Zeichen   }
         GlobalError.SError(er_Syntax); { nach dem Potenzzeichen darf auch ein "-" oder }
       end;                             { "+" beinhalten, die anderen nicht. }

       for j := (i+2) to length(AStr)   { Ganze Potenz heraussuchen. }
        do if not CharInString(AStr[j], '0123456789') then break;

       APotenz := StrToInt(Copy(AStr, i+1, (j - (i+1) )));
       Delete(AStr, i, (j - i));
     end else APotenz := 1;

     p := NewVar(AChar, APotenz, nil);  { Variable erzeugen und an die Liste haengen. }
     ConcatLists(HListItem(Buffer), HListItem(p));
   until false;
   dec(byte(AStr[0]));                  { "_" am schluss wieder loeschen. }

   StrToVars := Buffer;
 end;

 function StrToNumber(AStr: string): HNumber;
 var
   Buffer: HNumber;
   p     : HVar;
   AValue: Complex;
   flagI : Boolean;
   i     : Byte;
 begin
   if GlobalError.IsError or (AStr = '') then begin
     StrToNumber := nil;
     exit;
   end;
   GlobalError.EnterProc(proc_StrNr);

   CLd_0(AValue);

   i := cmplxIinString(AStr);                   { i (als imaginaere Einheit) suchen }
   flagI := not (i = 0);                        { und wenn vorhanden loeschen, aber }
   if flagI then Delete(AStr, i, 1);            { flag setzen. }

   p := StrToVars(AStr);                        { Variablen herauslesen. }

   if (AStr = '') then AStr := '1';             { Wenn nur Variablen vorhanden waren, }
                                                { ist der Wert 1. }
   if CharInString('<', AStr) then begin        { "<" dient als Winkelzeichen }
     i := Pos('<', AStr);                       { bei komplexen Zahlen. }
     StrToSReal(AValue.Real, Copy(AStr, 1, i-1));
     StrToSReal(AValue.Imag, Copy(AStr, i+1, 255));
     PolarToRect(AValue);
   end else if not flagI                        { Restliches in komplexe Zahl }
    then StrToSReal(AValue.Real, AStr)          { umwandeln. }
    else StrToSReal(AValue.Imag, AStr);

   Buffer := NewNumber(AValue, p, nil);         { Nummer erzeugen. }

   StrToNumber := Buffer;
   GlobalError.LeaveProc;
 end;
 { ****************************************************** }

 procedure SortVars(var ANumber: HNumber);
 var
   ATree: LTree;
 begin
   if GlobalError.IsError or (ANumber = nil) then exit;
   if not (ANumber^.Kind = kd_Number) then exit;

   ATree.Init;
   ATree.AssignTreeItem(HTreeItem(ANumber));
   ATree.SortItems(0,1,true);
   ANumber^.Sub := HVar(ATree.FirstItem);
   ATree.Release;
   ATree.Done;
 end;

 procedure UniteVars(var ANumber: HNumber);
 var
   p,q: HVar;
 begin
   if GlobalError.IsError or (ANumber = nil) then exit;
   if not (ANumber^.Kind = kd_Number) then exit;

   SortVars(ANumber);                  { Zuerst alle Variablen sortieren. }
   if GlobalError.IsError then exit;

   p := ANumber^.Sub;
   while not ((p = nil) or (p^.Next = nil)) do
    if (p^.Name = p^.Next^.Name) then begin     { Wenn zwei Variablen den selben  }
      p^.Potenz := p^.Potenz + p^.Next^.Potenz; { Namen tragen, koennen sie zu    }
      q := p^.Next;                             { einer Variablen zusammengefasst }
      p^.Next := q^.Next;                       { werden. }
      Dispose(q);
    end else p := p^.Next;
 end;

 function VarEquals(var ANum1, ANum2: HNumber): boolean;
 var
   p,q: HVar;
 begin
   if GlobalError.IsError then begin
     VarEquals := false; exit;
   end;
   if (ANum1 = nil) or (ANum2 = nil) or         { Beides muessen sicher Nummern sein. }
     not ((ANum1^.Kind = kd_Number) and (ANum2^.Kind = kd_Number)) then begin
     VarEquals := false; exit;
   end;

   UniteVars(ANum1);            { Variablen beider Nummern zusammenfassen. }
   UniteVars(ANum2);
   if GlobalError.IsError then begin    { Fehler abfangen. }
     VarEquals := false; exit;
   end;

   p := ANum1^.Sub;
   q := ANum2^.Sub;
   while not ((p = nil) or (q = nil)) do begin  { Alle Variablen durchgehen und }
     if not (p^.Name = q^.Name) then break;     { immer deren Namen und Potenzen }
     if not (p^.Potenz = q^.Potenz) then break; { vergleichen. }

     p := p^.Next;
     q := q^.Next;
   end;
                                                { Falls die Schleife nicht zu ende }
   if not (p = nil) or not (q = nil)            { gefuehrt wurde oder in den beiden }
    then VarEquals := false                     { Nummern nicht gleich viele Variablen }
    else VarEquals := true;                     { sind, sind die Variablen nicht gleich. }
 end;

 function GetVarPotenz(ANumber: HNumber; AName: Char): Integer;
 var
   p: HVar;
   Buffer: Integer;
 begin
   if GlobalError.IsError or (ANumber = nil) then begin
     GetVarPotenz := 0; exit;
   end;

   Buffer := 0;
   p := ANumber^.Sub;
   while not (p = nil) do begin
     if (p^.Name = AName)
      then Buffer := Buffer + p^.Potenz;

     p := p^.Next;
   end;

   GetVarPotenz := Buffer;
 end;

 procedure DeleteVar(ANum: HNumber; AName: char);
 var
   AList: LList;
   i    : Word;
 begin
   if (ANum = nil) then exit;
   if (ANum^.Sub = nil) then exit;

   AList.Init;
   AList.AddList(HListItem(ANum^.Sub));
   for i := (AList.Count-1) downto 0
    do if (HVar(AList.GetItem(i))^.Name = AName)
     then AList.DeleteItem(i);
   ANum^.Sub := HVar(AList.FirstItem);
   AList.ReleaseDone;
 end;
 { ****************************************************** }

 procedure ConcatChains(var ACh1, ACh2: HChain);
 begin
   ConcatLists(HListItem(ACh1), HListItem(ACh2));
 end;

 function CopyChain(AChain: HChain): HChain;
 var
   ATree: LTree;
   Buffer: HChain;
 begin
   if GlobalError.IsError or (AChain = nil) then begin
     CopyChain := nil; exit;
   end;

   ATree.Init;
   ATree.AddTree(HTreeItem(AChain));
   Buffer := HChain(ATree.CopyItem(0));
   ATree.ReleaseDone;
   CopyChain := Buffer;
 end;
 { ****************************************************** }

{ ************************************************************************** }
END.
{ ************************************************************************** }