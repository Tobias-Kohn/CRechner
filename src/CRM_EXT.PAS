{ ************************************************************************** }
{  Diese Unit enthaelt die Routinen, um "hoehere" Funktionen der Mathematik  }
{ zu berechnen. Darunter befinden sich die Trigonometrischen Funktionen, der }
{ Logairtmus und aehnliches.                                                 }
{ ************************************************************************** }
{  Hinweise: die meisten Routinen pruefen zuerst, ob bereits ein Fehler vor- }
{ liegt und brechen gleich wieder ab, wenn dem so ist.                       }
{  Praktisch alle Routinen arbeiten mit Potenz-/MacLaurin-Reihen. Wie genau  }
{ die Routinen arbeiten sollen, kann in der Unit CRTypes eingestellt werden. }
{ Da bei der Potenzreihen-Berechnung meistens vereinfachte Formen der Multi- }
{ plikation und der Division genuegen, sind entsprechende vereinfachte       }
{ Routinen vorhanden, die (vor allem die Division) einiges schneller arbeiten}
{ als die "Vollversionen".                                                   }
{  Die Potenzreihenentwicklung wurde nicht ueberall speziell hingeschrieben. }
{ Unter anderem deshalb, weil die Formeln hier im Kommentar nur schwer lesbar}
{ sind. Die Reihen sollten jedoch in praktisch jeder Mathematik-Formelsamm-  }
{ lung vorhanden sein. Sie sind ebenfalls im Anhang der zu diesem Programm   }
{ gehoerenden Arbeit aufgefuehrt.                                            }
{ ************************************************************************** }
{  This unit contains the further mathematic-procedures like log, sin...     }
{ ************************************************************************** }
{                                                                            }
{                          (c) 1999, Tobias Kohn                             }
{                                Version 2.0                                 }
{                                                                            }
{ ************************************************************************** }
{$G+}             { 286-Codes }
UNIT CRM_Ext;
{ ************************************************************************** }
INTERFACE
 USES Memory, Errors, CRTypes, Basics, CRMathe;
{ ************************************************************************** }

   { ************************************************** }
   {  Fuer den internen Debugger ist es noetig, jeder   }
   { Routine eine Nummer zuzuweisen.                    }
   { ************************************************** }
 CONST
   proc_WMul = $31;     { WMul }
   proc_WDiv = $32;     { WDiv }
   proc_IDiv = $33;     { IDiv }
   proc_RExp = $34;     { RExp }
   proc_RLn  = $35;     { RLn  }
   proc_RAng = $36;     { RStdAngle }
   proc_RSin = $37;     { RSin }
   proc_RCos = $38;     { RCos }
   proc_RTan = $39;     { RTan }
   proc_RASn = $3A;     { RAcrSin }
   proc_RACs = $3B;     { RArcCos }
   proc_RATn = $3C;     { RArcTan }
   proc_RPi  = $3D;     { CalcPi }
   proc_Pot  = $3E;     { RPotenzZ / RPotenz }
   proc_Pi   = $3F;     { CalcPi }
   proc_Exp2Z= $40;     { RExp2Z }

   er_DivRange = $1101; { Dieser Fehler tritt auf, wenn bei der Routine IDiv }
                        { a/b groesser ist als 2047. }
   er_PotReihe = $1102; { Ein Fehler bei einer Potenzreihen-Entwicklung. }
   er_Const    = $1103; { Ein fataler Fehler: Eine wichtige Konstante konnte }
                        { nicht berechnet werden (z.B. Pi). Das Programm muss }
                        { beendet werden, damit es sich nicht aufhaengt! }

   { ************************************************** }
   {  WMul       Multipliziert einen SReal mit einem    }
   {              Word-Wert.                            }
   {  WDiv       Dividiert AReal durch AValue.          }
   {  IDiv       Fuehrt eine Ganzzahl-Division zweier   }
   {              Real-Zahlen durch. Der rest wird in   }
   {              AReal zurueckgegeben.                 }
   {  LMul       Multipliziert einen SReal mit einem    }
   {              LongInt-Wert.                         }
   { ************************************************** }
   procedure WMul(var AReal: SReal; AValue: Word);
   procedure WDiv(var AReal: SReal; AValue: Word);

   function IDiv(var AReal: SReal; BReal: SReal): Integer;
   procedure LMul(var AReal: SReal; AValue: LongInt);

   { ************************************************** }
   {  RExp       Berechnet die Eulersche Zahl hoch das  }
   {              Argument (e^x).                       }
   {  RAuxLn     Eine Hilfsroutine fuer RLn.            }
   {  RLn        Berechnet den natuerlichen Logaritmus  }
   {              des Argumentes.                       }
   {  RLog       Berechnet den 10-Logaritmus.           }
   {  RLb        Berechnet den 2-Logaritmus.            }
   {  RExp10     10^x.                                  }
   {  RExp2Z     Quadriert die Zahl AReal AValue mal.   }
   {              x = x^(2^y)                           }
   { ************************************************** }
   procedure RExp(var AReal: SReal);
   procedure RAuxLn(var AReal: SReal);
   procedure RLn(var AReal: SReal);

   procedure RLog(var AReal: SReal);
   procedure RLb(var AReal: SReal);

   procedure RExp10(var AReal: SReal);

   procedure RExp2Z(var AReal: SReal; AValue: LongInt);

   { ************************************************** }
   {  RStdAngle  Rechnet AReal je nach Einstellung des  }
   {              allgemeinen Flags AngleType zuerst vom}
   {              Grad- ins Bogenmass um und sorgt dann }
   {              dafuer, dass AReal zwischen 0 und 2Pi }
   {              liegt.                                }
   {  RResultAngle    Je nach der Einstellung des Flags }
   {              AngleType wird die Zahl vom Bogen ins }
   {              Gradmass umgerechnet.                 }
   { ************************************************** }
   procedure RStdAngle(var AReal: SReal);
   procedure RResultAngle(var AReal: SReal);

   { ************************************************** }
   {  RSin       Berechnet den Sinus des Arguments.     }
   {  RCos       Berechnet den Cosinus des Arguments.   }
   {  RTan       Berechnet den Tangens des Arguments.   }
   {                                                    }
   {  RSinCos    Berechnet gleichzeitig den Sinus und   }
   {              den Cosinus von AReal. AReal = sin,   }
   {              BReal = cos. Diese Routine ist        }
   {              schneller als das getrennte Berechnen.}
   { ************************************************** }
   procedure RSin(var AReal: SReal);
   procedure RCos(var AReal: SReal);
   procedure RTan(var AReal: SReal);

   procedure RSinCos(var AReal, BReal: SReal);
   { ************************************************** }
   {  RArcSin    Der ArcusSinus.                        }
   {  RArcCos    Der ArcusCosinus.                      }
   {  RArcTan    Der Arcustangens.                      }
   { ************************************************** }
   procedure RArcSin(var AReal: SReal);
   procedure RArcCos(var AReal: SReal);
   procedure RArcTan(var AReal: SReal);

   { ************************************************** }
   {  Berechnen beide a^b. RPotenzZ laesst als Exponent }
   { nur ganzzahlige Werte zu, ist aber schneller.      }
   { ************************************************** }
   procedure RPotenzZ(var AReal: SReal; AValue: LongInt);
   procedure RPotenz(var AReal: SReal; BReal: SReal);

   { ************************************************** }
   {  Berechnet die AValue-te Wurzel von AReal.         }
   { ************************************************** }
   procedure RRootZ(var AReal: SReal; AValue: Word);

   { ************************************************** }
   {  CalcPi     Berechnet Pi.                          }
   {  CalcConsts Berechnet die Konstanten Pi,e,ln2,ln10.}
   { ************************************************** }
   procedure CalcPi;
   procedure CalcConsts1;

 VAR
   QReal: ^SReal;

{ ************************************************************************** }
IMPLEMENTATION
{ ************************************************************************** }

 { ****************************************************** }
 procedure WMul(var AReal: SReal; AValue: Word);
 var
   v: Boolean;
   i, j: Word;
   AMem: LIntMem;
 begin
   if GlobalError.IsError then exit;            { Fehler ueberpruefen. }
   if not TestValid(AReal) then exit;

   if (AValue = 0) then begin                   { x * 0 = 0 }
     RLd_0(AReal);
     exit;
   end;
   if RZero(AReal) then exit;
   GlobalError.EnterProc(proc_WMul);

   v := SReal_Neg_Abs(AReal);                   { Vorzeichen des Resulattes ermitteln. }

   AMem.Init;
   AMem.AssignMem(Addr(AReal.Mant), MantSize);
   if GlobalError.IsError then begin
     GlobalError.LeaveProc; exit;
   end;

   AMem.ShiftR(16);                             { Multiplikation durchfuehren. }
   AMem.MulMem(AValue);

   ValidSReal(AReal);
   AddExpon(AReal, 16);
   if v then SReal_XCHG_Sign(AReal);            { Vorzeichen setzen. }

   AMem.ClearMe;
   AMem.Done;

   GlobalError.LeaveProc;                       { Verlassen der Routine mitteilen. }
 end;

 procedure WDiv(var AReal: SReal; AValue: Word);
 var
   v: Boolean;
   AMem: LIntMem;
 begin
   if GlobalError.IsError or not TestValid(AReal) then exit;
   GlobalError.EnterProc(proc_WDiv);            { Fehler ueberpruefen. }

   v := SReal_Neg_Abs(AReal);                   { Vorzeichen ausfiltern. }
   AMem.Init;                                   { Speicherbehandlung initialisieren. }
   AMem.AssignMem(Addr(AReal.Mant), MantSize);

   AMem.DivMem(AValue);                         { Division durchfuehren. }
   if GlobalError.IsError then begin            { Auf Fehler ueberpruefen. }
     GlobalError.LeaveProc; Exit;
   end;

   ValidSReal(AReal);                           { Zahl gueltig machen. }

   AMem.ClearMe;                                { Objekt freigeben. }
   AMem.Done;
   if v then SReal_XCHG_Sign(AReal);            { Vorzeichen setzen. }

   GlobalError.LeaveProc;
 end;

 function IDiv(var AReal: SReal; BReal: SReal): Integer;
 var
   Buffer: Integer;
   i: Word;
   CReal: SReal;
   v1, v2: Boolean;
 begin
   if GlobalError.IsError then exit;
   if not TestValid(AReal) or not TestValid(BReal) then exit;
   GlobalError.EnterProc(proc_IDiv);

   if RZero(BReal) then begin           { Division durch Null abfangen. }
     GlobalError.SError(er_DivZero);
     GlobalError.LeaveProc;
     RLd_0(AReal); IDiv := 0;
     exit;
   end;
   if RZero(AReal) then begin           { 0 / x = 0 }
     IDiv := 0;
     exit;
   end;

   v1 := SReal_Neg_Abs(AReal);          { Vorzeichen aus den Zahlen ausfiltern. }
   v2 := SReal_Neg_Abs(BReal);
   v1 := v1 xor v2;

   if (abs(AReal.Expon - BReal.Expon) > 10) then begin
     GlobalError.SError(er_DivRange);   { Diese Bedingung muss erfuellt sein, }
     GlobalError.LeaveProc;             { damit die Schlaufe nicht unendlich }
     RLd_0(AReal); IDiv := 0;           { weitergeht. }
     exit;
   end;

   for Buffer := 0 to 2048 do begin     { Den Quotienten bilden. }
     if GlobalError.IsError then break;
     i := abs(Buffer);
     CReal := BReal;
     WMul(CReal, i);
     RCmp(CReal, AReal);
     if (Cmp_Result = cmp_Equal) then break;
     if (Cmp_Result = cmp_Above) then begin
       dec(Buffer);
       break;
     end;
   end;

   CReal := BReal;                      { Den Rest ermitteln. }
   i := Buffer;
   WMul(CReal, i);
   RSub(AReal, CReal);

   GlobalError.LeaveProc;
   if v1 then Buffer := -Buffer;
   if v2 then SReal_XCHG_Sign(AReal);
   IDiv := Buffer;
 end;

 procedure LMul(var AReal: SReal; AValue: LongInt);
 var
   v: Boolean;
   i: Word;
   Buffer: SReal;
   Words: array[0..1] of Word absolute AValue;
 begin
   if GlobalError.IsError or not TestValid(AReal) then exit;

   if (AValue = 0) then RLd_0(AReal);           { x * 0 = 0 }
   if RZero(AReal) then exit;

   v := (AValue < 0);                           { Vorzeichen ausfiltern. }
   if v then AValue := abs(AValue);
   v := v xor SReal_Neg_Abs(AReal);

   i := Words[1];                       { c*(a + b) = c*a + c*b }
   Buffer := AReal;
   AddExpon(Buffer, 16);
   WMul(Buffer, i);

   i := Words[0];
   WMul(AReal, i);
   RAdd(AReal, Buffer);
 end;

 { ****************************************************** }
 procedure RAuxExp(var AReal: SReal);           { Hilfsroutine fuer RExp. }
 var
   v: Boolean;
   BReal, CReal: SReal;
   i,j: Word;
   k: LongInt;
 begin
   if GlobalError.IsError or not TestValid(AReal) then exit;
   GlobalError.EnterProc(proc_RExp);

   if RZero(AReal) then begin                   { e^0 = 1 }
     RLd_1(AReal);
     GlobalError.LeaveProc;
     exit;
   end;
   v := SReal_Neg_Abs(AReal);                   { Vorzeichen ausfiltern. }
   k := AReal.Expon;                            { Buffer zuruecksetzen. }
   i := 0; j := 0;
   RLd_1(BReal); RLd_1(CReal);

   repeat
     if GlobalError.IsError then break;                 { Fehler abfangen. }
     inc(i); j := i;
     if (BReal.Expon > k) then k := BReal.Expon;        { Die Berechnung wird }
     if ((k - Exact_Exp) > BReal.Expon) then break;     { mit einer Potenzreihe }
     RMul(BReal, AReal);                        { durchgefuehrt. Fuer weitere }
     WDiv(BReal, j);                            { Informationen sehen sie bitte }
     RAdd(CReal, BReal);                        { in der Beilage nach. }
     ShowBusy;
   until False;

   AReal := CReal;
   if v then RInv(AReal);                       { e^-x = 1/e^x }
   GlobalError.LeaveProc;
 end;

 procedure RExp(var AReal: SReal);      { Da Die Potenzreihenentwicklung fuer }
 var                                    { e^x bei grossen x sehr langsam ist, }
   Buffer: LongInt;                     { werden hier grosse Zahlen umgangen. }
 begin
   Buffer := AReal.Expon;               { e^x berechnet hier keine Zahlen mehr, }
   if (Buffer > 2)                      { die groesser als 7.999 sind.          }
    then AReal.Expon := 0
    else Buffer := 0;
   RAuxExp(AReal);
   RExp2Z(AReal, Buffer);
 end;

 procedure RAuxLn(var AReal: SReal);    { Dies ist eine Hilfsroutine fuer RLn. }
 var
   v: Boolean;
   BReal, CReal: SReal;
   AuxTerm: SReal;
   i,j: Word;
   k: LongInt;
 begin
   if GlobalError.IsError or not TestValid(AReal) then exit;

   BReal := AReal;
   RRound(BReal);
   v := (RCmp_1(BReal) = cmp_Below);
   RLd_0(BReal);
   RLd_0(CReal);

   BReal := AReal;
   RDec(AReal);                 { AuxTerm = ((x-1)/(x+1))^2 }
   RInc(BReal);
   RDiv(AReal, BReal);
   RAbs(AReal);
   AuxTerm := AReal;
   RSqr(AuxTerm);

   CReal := AReal;
   RLd_0(AReal);                { Zwischenresultate in AReal. }

   i := 0; j := 0; k := 0;
   repeat
     if GlobalError.IsError then break;         { Fehler abfangen. }

     if (BReal.Expon > k) then k := BReal.Expon;{ Bis gewuenschte Genauigkeit erreicht ist. }
     if ((k - Exact_Ln) > BReal.Expon) then break;
     BReal := CReal;                            { Berechnung durch eine Potenzreihenentwicklung. }
     j := (i * 2) + 1;                          { Fuer genauere Informationen sehen sie bitte }
     WDiv(BReal, j);                            { in der Beilage nach. }
     RAdd(AReal, BReal);
     RMul(CReal, AuxTerm);
     inc(i);
     ShowBusy;
   until (i > 32000);

   AddExpon(AReal, 1);
   if v then RNeg(AReal);
 end;

 procedure RLn(var AReal: SReal);
 var
   v: Boolean;
   DReal: SReal;
   j: LongInt;
 begin
   if GlobalError.IsError or not TestValid(AReal) then exit;
   GlobalError.EnterProc(proc_RLn);

   DReal := AReal;
   RRound(DReal);
   if RZero(DReal) or SReal_Neg_Abs(DReal) then begin
     GlobalError.SError(er_LnNotPos);   { In den reellen Zahlen kann nur }
     GlobalError.LeaveProc;             { der Logaritmus einer positiven }
     exit;                              { Zahl gezogen werden. }
   end;
   if ROne(DReal) then begin
     RLd_0(AReal);
     exit;
   end;
   j := AReal.Expon;
   v := (j < -6);
   if v then RInv(AReal);
   if (abs(j) > 6) then begin     { Falls die Zahl zu gross, konvergiert }
     AReal.Expon := 1;            { die Routine zu langsam. Dann wird mit }
     dec(j);                      { folgender Formel ausgeholfen: }
     DReal := rm_ln2;             {   ln (a*2^b) = (ln a) + (b*ln(2)) }
     if RZero(DReal) then begin   { Wenn ln(2) noch nicht berechnet wurde, }
       RLd_1(DReal);              { so muss dies nun geschehen. }
       AddExpon(DReal, 1);
       RAuxLn(DReal);
       rm_ln2 := DReal;
     end;
     LMul(DReal, j);
   end else RLd_0(DReal);

   RAuxLn(AReal);

   RAdd(AReal, DReal);
   if v then RNeg(AReal);         { ln(1/a) = -ln(a) }

   GlobalError.LeaveProc;
 end;

 procedure RLog(var AReal: SReal);
 begin
   RLn(AReal);                          { log(x) = ln(x)/ln(10) }
   if RZero(rm_ln10) then begin         { Wenn ln(10) noch nicht berechnet }
     RLd_0(rm_ln10);                    { ist, so muss das nun kurz getan }
     rm_ln10.Expon := 3;                { werden. }
     rm_ln10.Mant[MantLast] := $50;
     RLn(rm_ln10);
   end;
   RDiv(AReal, rm_ln10);
 end;

 procedure RLb(var AReal: SReal);
 begin
   RLn(AReal);                          { lb(x) = ln(x)/ln(2) }
   if RZero(rm_ln2) then begin          { Wenn ln(2) noch nicht berechnet }
     RLd_1(rm_ln2);                     { ist, so muss das nun kurz getan }
     rm_ln2.Expon := 1;                 { werden. }
     RLn(rm_ln2);
   end;
   RDiv(AReal, rm_ln2);
 end;

 procedure RExp10(var AReal: SReal);
 begin
   if GlobalError.IsError or not TestValid(AReal) then exit;

   if RZero(rm_ln10) then begin              { Falls der Zehnerlogaritmus }
     rm_ln10.Mant[MantLast] := $50;          { noch nicht berechnet ist,  }
     rm_ln10.Expon := 3;                     { dann muss das nun getan werden. }
     RLn(rm_ln10);
     if GlobalError.IsError then exit;
   end;

   RMul(AReal, rm_Ln10);        { 10^x = e^(x*ln(10)) }
   RExp(AReal);
 end;

 procedure RExp2Z(var AReal: SReal; AValue: LongInt);   { x = x^(2^y) }
 var
   i: LongInt;
 begin
   if GlobalError.IsError or not TestValid(AReal) then exit;
   GlobalError.EnterProc(proc_Exp2Z);

   if (AValue < 0) then begin           { Ein Minuszeichen vor dem "y" }
     for i := 1 to abs(AValue)          { bedeutet, dass das 2 zu 0.5 wird, }
      do RSqrt(AReal);                  { also die Wurzel gezogen wird, und }
   end else begin                       { nicht quadriert. }
     for i := 1 to AValue
      do RSqr(AReal);
   end;
   GlobalError.LeaveProc;
 end;
 { ****************************************************** }

 procedure RStdAngle(var AReal: SReal);
 var
   Buffer: SReal;
 begin
   if GlobalError.IsError or not TestValid(AReal) then exit;
   GlobalError.EnterProc(proc_RAng);

   Buffer := rm_Pi;
   if RZero(Buffer) then begin          { Buffer := 2 * Pi }
     CalcPi;
     Buffer := rm_Pi;
   end;
   AddExpon(Buffer, 1);

   if (AngleType = at_Deg) then begin   { Die Zahl sollte im Bogenmass sein. }
     WDiv(AReal, 180);
     RMul(AReal, rm_Pi);
   end;

   while SReal_Neg(AReal) do begin         { Zahl ist noch negativ. }
     RAdd(AReal, Buffer);
     if GlobalError.IsError then break;
     ShowBusy;
   end;
   while (RCmp(AReal, Buffer) = cmp_Above) { Zahl ist noch groesser als }
   do begin                                { 2*Pi. }
     RSub(AReal, Buffer);
     if GlobalError.IsError then break;
     ShowBusy;
   end;

   GlobalError.LeaveProc;
 end;

 procedure RResultAngle(var AReal: SReal);
 begin
   if not TestValid(AReal) or GlobalError.IsError then exit;

   if (AngleType = at_Deg) then begin { Vom Boden- ins Gradmass umrechnen. }
     if RZero(rm_Pi) then CalcPi;       { Pi berechnen, falls dies noch nicht getan ist. }
     WMul(AReal, 180);
     RDiv(AReal, rm_Pi);
   end;
 end;

 { ****************************************************** }

 procedure RSin(var AReal: SReal);
 var
   BReal, CReal: SReal;
   i: Word;
   j: LongInt;
 begin
   if GlobalError.IsError or not TestValid(AReal) then exit;
   GlobalError.EnterProc(proc_RSin);
   RStdAngle(AReal);

   if RZero(AReal) then begin           { sin(0) = 0 }
     GlobalError.LeaveProc; exit;
   end;

   BReal := AReal;
   CReal := AReal;
   RSqr(BReal);

   i := 0; j := AReal.Expon;
   repeat
     if GlobalError.IsError then break;              { Fehler abfangen. }
     inc(i);
     if (CReal.Expon > j) then j := CReal.Expon;     { Bis gewuenschte Genauigkeit }
     if ((j - exact_sin) > CReal.Expon) then break;  { erreicht ist. }

     RMul(CReal, BReal);                { Die Berechnung erfolgt ueber eine }
     WDiv(CReal, (2*i)*((2*i)+1));      { Potenzreihe. }

     if TestBit(i, 0)
      then RSub(AReal, CReal)
      else RAdd(AReal, CReal);
     ShowBusy;
   until (i > 128);

   GlobalError.LeaveProc;
 end;

 procedure RCos(var AReal: SReal);
 var
   BReal, CReal: SReal;
   i: Word;
   j: LongInt;
 begin
   if GlobalError.IsError or not TestValid(AReal) then exit;
   GlobalError.EnterProc(proc_RCos);
   RStdAngle(AReal);

   if RZero(AReal) then begin           { cos(0) = 1 }
     RLd_1(AReal);
     GlobalError.LeaveProc; exit;
   end;

   BReal := AReal;
   RLd_1(AReal);
   RLd_1(CReal);
   RSqr(BReal);

   i := 0; j := AReal.Expon;
   repeat
     if GlobalError.IsError then break;              { Fehler abfangen. }
     inc(i);
     if (CReal.Expon > j) then j := CReal.Expon;     { Bis gewuenschte Genauigkeit }
     if ((j - exact_cos) > CReal.Expon) then break;  { erreicht ist. }

     RMul(CReal, BReal);                { Die Berechnung erfolgt ueber eine }
     WDiv(CReal, (2*i)*((2*i)-1));      { Potenzreihe. }

     if TestBit(i, 0)
      then RSub(AReal, CReal)
      else RAdd(AReal, CReal);
     ShowBusy;
   until (i > 128);

   GlobalError.LeaveProc;
 end;

 procedure RTan(var AReal: SReal);
 begin
   if GlobalError.IsError or not TestValid(AReal) then exit;
   GlobalError.EnterProc(proc_RTan);

   if RZero(AReal) then begin           { tan(0) = 0 }
     GlobalError.LeaveProc; exit;
   end;

   RCos(AReal);                         { Der Tangens wird nach folgender Formel }
   RSqr(AReal);                         { berechnet: }
   RInv(AReal);                         {    a = cos(x) }
   if GlobalError.IsError then exit;    {    sin(x) = sqrt(1-a^2)  }
                                        {    tan(x) = sin(x) / cos(x) }
   RDec(AReal);                         {    tan(x) = sqrt((1/a^2)-1) }
   RSqrt(AReal);

   GlobalError.LeaveProc;
 end;

 procedure RSinCos(var AReal, BReal: SReal);
 begin
   if GlobalError.IsError then exit;
   if not TestValid(AReal) or not TestValid(AReal) then exit;

   BReal := AReal;
   RCos(BReal);               { B := cos(A) }

   if GlobalError.IsError then exit;
   AReal := BReal;            { A := sqrt(1-B^2) = sin(A) }
   RSqr(AReal);
   RNeg(AReal);
   RInc(AReal);
   RSqrt(AReal);
 end;

 { ****************************************************** }
 procedure RArcSin(var AReal: SReal);
 var
   v: Boolean;
   i: Byte;
   BReal: SReal;
 begin
   if not TestValid(AReal) or GlobalError.IsError then exit;
   GlobalError.EnterProc(proc_RASn);

   v := SReal_Neg_Abs(AReal);

   i := RCmp_1(AReal);
   if (i = cmp_Above) then begin        { Der ArcSin einer Zahl groeser als 1 }
     GlobalError.SError(er_ArcRange);   { ist keine reelle Zahl mehr. }
     GlobalError.LeaveProc; exit;
   end;
   if (i = cmp_Equal) then begin
     if RZero(rm_Pi) then CalcPi;       { arcsin(1) = Pi/2 }
     AReal := rm_Pi;
     AddExpon(AReal, -1);
     RResultAngle(AReal);
     GlobalError.LeaveProc; exit;
   end;

   BReal := AReal;              { arcsin(x) = arctan(x/sqrt(1-x^2)) }
   RSqr(BReal);
   RNeg(BReal);
   RInc(BReal);
   RSqrt(BReal);
   RDiv(AReal, BReal);
   RArcTan(AReal);

   if v then RNeg(AReal);       { arcsin(-x) = -arcsin(x) }
   RResultAngle(AReal);
   GlobalError.LeaveProc;
 end;

 procedure RArcCos(var AReal: SReal);
 var
   v: Boolean;
   i: Byte;
   BReal: SReal;
 begin
   if not TestValid(AReal) or GlobalError.IsError then exit;
   GlobalError.EnterProc(proc_RACs);

   v := SReal_Neg_Abs(AReal);

   i := RCmp_1(AReal);

   if (i = cmp_Above) then begin        { Der ArcCos einer Zahl groesser als 1 }
     GlobalError.SError(er_ArcRange);   { ist keine reelle Zahl mehr. }
     GlobalError.LeaveProc; exit;
   end;
   if (i = cmp_Equal) then begin        { arccos(1) = 0 }
     RLd_0(AReal);
     GlobalError.LeaveProc; exit;
   end;

   BReal := AReal;              { arccos(x) = arctan(sqrt(1-x^2)/x) }
   RSqr(BReal);
   RNeg(BReal);
   RInc(BReal);
   RSqrt(BReal);
   RDiv(BReal, AReal);
   AReal := BReal;
   RArcTan(AReal);

   if v then begin                  { arccos(-x) = Pi-arcsin(x) }
     if RZero(rm_Pi) then CalcPi;
     RSub(AReal, rm_Pi);
     RNeg(AReal);
   end;

   RResultAngle(AReal);
   GlobalError.LeaveProc;
 end;

 procedure RAuxATan1(var AReal: SReal);
 var
   v: Boolean;
   BReal, CReal, DReal: SReal;
   i: Word;
   j: LongInt;
 begin
   if not TestValid(AReal) or GlobalError.IsError then exit;

   if RZero(AReal) then exit;                     { arctan(0) = 0 }
   v := SReal_Neg_Abs(AReal);

   if not (RCmp_1(AReal) = cmp_Below) then begin  { Diese Routine funktioniert }
     GlobalError.SError(er_PotReihe);             { nur fuer x < 1 }
     exit;
   end;

   BReal := AReal;
   CReal := AReal;
   DReal := AReal;
   RSqr(BReal);
   RAbs(CReal);
   QReal := Addr(CReal);

   i := 0; j := AReal.Expon;
   repeat
     if GlobalError.IsError then break;              { Fehler abfangen. }
     inc(i);
     if (DReal.Expon > j) then j := DReal.Expon;     { Bis gewuenschte Genauigkeit }
     if ((j - Exact_ATan) > DReal.Expon) then break; { erreicht ist. }

     RMul(CReal, BReal);
     DReal := CReal;
     WDiv(DReal, (2*i)+1);
     if TestBit(i, 0)
      then RSub(AReal, DReal)
      else RAdd(AReal, DReal);
     ShowBusy;
   until (i > 32000);

   if v then RNeg(AReal);
 end;

 procedure RAuxATan2(var AReal: SReal);
 var
   v: Boolean;
   BReal, CReal, DReal: SReal;
   i: Word;
   j: LongInt;
 begin
   if not TestValid(AReal) or GlobalError.IsError then exit;

   if RZero(AReal) then exit;                     { arctan(0) = 0 }
   v := SReal_Neg_Abs(AReal);

   if not (RCmp_1(AReal) = cmp_Above) then begin  { Diese Routine funktioniert }
     GlobalError.SError(er_PotReihe);             { nur fuer x > 1 }
     exit;
   end;

   RInv(AReal);
   BReal := AReal;
   CReal := AReal;
   DReal := AReal;

   RNeg(AReal);
   RSqr(BReal);

   i := 0; j := AReal.Expon;
   repeat
     if GlobalError.IsError then break;              { Fehler abfangen. }
     inc(i);
     if (DReal.Expon > j) then j := DReal.Expon;     { Bis gewuenschte Genauigkeit }
     if ((j - Exact_ATan) > DReal.Expon) then break; { erreicht ist. }

     RMul(CReal, BReal);
     DReal := CReal;
     WDiv(DReal, (2*i)+1);
     if TestBit(i, 0)
      then RAdd(AReal, DReal)
      else RSub(AReal, DReal);
     ShowBusy;
   until (i > 32000);

   if RZero(rm_Pi) then CalcPi;
   BReal := rm_Pi;
   AddExpon(BReal, -1);
   RAdd(AReal, BReal);

   if v then RNeg(AReal);
 end;

 procedure RArcTan(var AReal: SReal);
 var
   v: Boolean;
 begin
   if not TestValid(AReal) or GlobalError.IsError then exit;
   GlobalError.EnterProc(proc_RAtn);

   v := SReal_Neg_Abs(AReal);

   RRound(AReal);
   case RCmp_1(AReal) of
     cmp_Below: RAuxATan1(AReal);
     cmp_Above: RAuxATan2(AReal);
     cmp_Equal: begin                   { arctan(1) = Pi/4 }
       if RZero(rm_Pi) then CalcPi;
       AReal := rm_Pi;
       AddExpon(AReal, -2);
     end;
   end;

   if v then RNeg(AReal);
   RResultAngle(AReal);
   GlobalError.LeaveProc;
 end;
 { ****************************************************** }

 procedure RPotenzZ(var AReal: SReal; AValue: LongInt);
 var
   v: Boolean;
   i: LongInt;
   Buffer: SReal;
 begin
   if GlobalError.IsError or not TestValid(AReal) then exit;
   GlobalError.EnterProc(proc_Pot);

   v := (AValue < 0);
   if v then AValue := Abs(AValue);

   RLd_1(Buffer);
   for i := 1 to AValue do begin
     RMul(Buffer, AReal);
     ShowBusy;
   end;


   AReal := Buffer;
   if v then RInv(AReal);
   GlobalError.LeaveProc;
 end;

 procedure RPotenz(var AReal: SReal; BReal: SReal);
 begin
   if GlobalError.IsError then exit;
   if not TestValid(AReal) or not TestValid(BReal) then exit;
   GlobalError.EnterProc(proc_Pot);

   if SReal_Neg_Abs(BReal) then          { a^(-b) = 1/a^b }
     if RZero(AReal) then begin
       GlobalError.SError(er_DivZero);
       GlobalError.LeaveProc; exit;
     end else RInv(AReal);

   if RZero(BReal) then begin       { a^0 = 1 }
     RLd_1(AReal);
     GlobalError.LeaveProc; exit;
   end;

   if ROne(BReal) then exit;        { a^1 = a }

   RLn(AReal);                      { a^b = e^(b*ln(a)) }
   RMul(AReal, BReal);
   RExp(AReal);

   GlobalError.LeaveProc;
 end;

 procedure RRootZ(var AReal: SReal; AValue: Word);
 begin
   if GlobalError.IsError then exit;
   if not TestValid(AReal) or (AValue = 1) then exit;
   if (AValue = 0) then begin
     GlobalError.SetError(er_DivZero, proc_Pot); exit;
   end;
   if (AValue = 2) then begin
     RSqrt(AReal); exit;
   end;

   GlobalError.EnterProc(proc_Pot);

   RLn(AReal);                      { a^(1/b) = e^(ln(a)/b) }
   WDiv(AReal, AValue);
   RExp(AReal);

   GlobalError.LeaveProc;
 end;
 { ****************************************************** }

 procedure CalcPi;
 var
   Buffer: SReal;
 begin
   if GlobalError.IsError then exit;

   RLd_0(Buffer);                   { Buffer = 3 }
   Buffer.Mant[MantLast] := $60;
   Buffer.Expon := 1;

   RSqrt(Buffer);                   { Pi := 6 * arctan(1/sqrt(3)) }
   RInv(Buffer);
   RAuxATan1(Buffer);
   WMul(Buffer, 6);

   rm_Pi := Buffer;
   if RZero(Buffer) then begin
     GlobalError.SetError(er_Const, proc_Pi);
     halt;
   end;
 end;

 procedure CalcConsts1;
 var
   Buffer: SReal;
 begin
   CalcPi;                         { Pi }

   RLd_1(Buffer);                  { e }
   RExp(Buffer);
   rm_e := Buffer;

   RLd_1(Buffer);                  { ln(2) }
   AddExpon(Buffer, 1);
   RLn(Buffer);
   rm_ln2 := Buffer;

   RLd_0(Buffer);                  { ln(10) }
   Buffer.Mant[MantLast] := $50;
   Buffer.Expon := 3;
   RLn(Buffer);
   rm_ln10 := Buffer;
 end;
 { ****************************************************** }

{ ************************************************************************** }
END.
{ ************************************************************************** }