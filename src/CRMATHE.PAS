{ ************************************************************************** }
{  Diese Unit enthaelt die fuer das Rechnen mit Reelen Zahlen grundlegenden  }
{ Routinen, wie Addition, Subtraktion oder Vergleiche.                       }
{ ************************************************************************** }
{  Hinweise: die meisten Routinen pruefen zuerst, ob bereits ein Fehler vor- }
{ liegt und brechen gleich wieder ab, wenn dem so ist.                       }
{ ************************************************************************** }
{  This unit contains the basical mathematic-procedures.                     }
{ ************************************************************************** }
{                                                                            }
{                       (c) 1999/2000, Tobias Kohn                           }
{                                Version 2.0                                 }
{                                                                            }
{ ************************************************************************** }
{$G+}             { 286-Codes }
UNIT CRMathe;
{ ************************************************************************** }
INTERFACE
 USES Memory, Errors, CRTypes, Basics;
{ ************************************************************************** }

   { ************************************************** }
   {  Fuer den internen Debugger ist es noetig, jeder   }
   { Routine eine Nummer zuzuweisen.                    }
   { ************************************************** }
 CONST
   proc_RAdd  = $21;    { RAdd / RSub }
   proc_RMul  = $22;    { RMul / RDiv }
   proc_RInv  = $23;    { RInv / RDiv }
   proc_RCmp  = $24;    { RCmp(s) / RCmp_1 }
   proc_Sqrt  = $25;    { RSqrt }

   { ************************************************** }
   {  RAdd       Addiert zwei SReal-Zahlen.             }
   {  RSub       Subtrahiert BReal von AReal.           }
   {  RMul       Multipliziert zwei SReal miteinander.  }
   {  RDiv       Dividiert AReal durch BReal.           }
   {                                                    }
   {  RInv       Berechnet 1/x. Diese Routine zusammen  }
   {              mit Mul ergibt dann die Division.     }
   {                                                    }
   {  RInc       Erhoeht die Zahl um 1.                 }
   {  RDec       Erniedrigt die Zahl um 1.              }
   { ************************************************** }
   procedure RAdd(var AReal: SReal; BReal: SReal);
   procedure RSub(var AReal: SReal; BReal: SReal);
   procedure RMul(var AReal: SReal; BReal: SReal);
   procedure RDiv(var AReal: SReal; BReal: SReal);

   procedure RInv(var AReal: SReal);

   procedure RInc(var AReal: SReal);
   procedure RDec(var AReal: SReal);

   { ************************************************** }
   {  RSqr       Berechnet das Quadrat des Arguments.   }
   {  RSqrt      Berechnet die Quadratwurzel von AReal. }
   {                                                    }
   {  RAbs       Bildet den Absolutbetrag der Zahl.     }
   {  RNeg       Vertauscht das Vorzeichen der Zahl.    }
   {  RRound     Rundet die Zahl auf CmpMSize stellen.  }
   { ************************************************** }
   procedure RSqr(var AReal: SReal);
   procedure RSqrt(var AReal: SReal);

   procedure RAbs(var AReal: SReal);
   procedure RNeg(var AReal: SReal);
   procedure RRound(var AReal: SReal);

   { ************************************************** }
   {  Beide der folgenden Routinen vergleichen zwei     }
   { SReal-Zahlen. RCmp beruecksichtigt im Unterschied  }
   { zu RCmpS die Vorzeichen jedoch nicht.              }
   {  Der Rueckgabewert wird durch die cmp_XXX Konstan- }
   { ten festgelegt, wobei beide Routinen auch die      }
   { allgemeine Variable Cmp_Result setzen.             }
   { ************************************************** }
   function RCmp(AReal, BReal: SReal): Byte;
   function RCmpS(AReal, BReal: SReal): Byte;

   { ************************************************** }
   {  RZero      Ueberprueft, ob AReal Null ist.        }
   {  ROne       Ueberprueft, ob AReal = 1 ist.         }
   {  Cmp_1      Vergleicht die Zahl mit 1 und gibt das }
   {              Resultat als cmp_XXX zurueck. Cmp_Res-}
   {              ult wird jedoch nicht verandert.      }
   { ************************************************** }
   function RZero(AReal: SReal): Boolean;
   function ROne(AReal: SReal): Boolean;

   function RCmp_1(AReal: SReal): Byte;

   { ************************************************** }
   {  Dies sind Hilfsroutinen fuer die Programmierung   }
   { in Assembler.                                      }
   { ************************************************** }
   procedure AEnterProc(ANr: Word);
   procedure ALeaveProc;

{ ************************************************************************** }
IMPLEMENTATION
{ ************************************************************************** }

 { ****************************************************** }
 procedure RAdd(var AReal: SReal; BReal: SReal);
 var
   v1,v2,v3: Boolean;
   j : LongInt;
   AMem: HIntMem;
 begin
   if GlobalError.IsError then exit;            { Fehler ueberpruefen. }
   if not TestValid(AReal) or not TestValid(BReal) then exit;

   if RZero(AReal) then SwapReals(AReal, BReal);   { x + 0 = x }
   if RZero(BReal) then exit;
   GlobalError.EnterProc(proc_Add);

   v1 := SReal_Neg_Abs(AReal);
   v2 := SReal_Neg_Abs(BReal);
   if (RCmp(BReal, AReal) = cmp_Above) then begin
     SwapReals(AReal, BReal);                   { B darf nicht groeser sein als A. }
     v3 := v2;                                  { Das heisst, unter Umstaenden die }
     v2 := v1;                                  { Zahlen vertauschen. }
     v1 := v3;
   end;
   if (Cmp_Result = cmp_Equal) then begin
     if (v1 = v2)
      then begin                                { x + x = 2*x }
        AddExpon(AReal, 1);
        if v1 then RNeg(AReal);
      end else RLd_0(AReal);                    { x - x = 0 }
     GlobalError.LeaveProc;
     exit;
   end;

   j := abs(AReal.Expon - BReal.Expon);         { Differenz der beiden Exponenten. }
   if (j < (MantSize * 8)) then begin           { Nur Durchfuehren, wenn die Zahlen genug }
                                                  { nahe beieinander liegen. }
     AMem := New(HIntMem, Init);                { SPeicher-Objekt erstellen. }
     if (AMem = nil) then begin                 { Fehler abfangen. }
       GlobalError.SError(er_Heap);
       GlobalError.LeaveProc;
       exit;
     end;
     AMem^.AssignMem(Addr(BReal.Mant), MantSize); { Zuerst B in die richtige Position schieben. }
     AMem^.ShiftR(j);
     if GlobalError.IsError then begin          { Falls inzwischen ein Fehler auftrat, diese }
       GlobalError.LeaveProc; exit;             { Prozedur beenden. }
     end;
     AMem^.ClearMe;
     AMem^.AssignMem(Addr(AReal.Mant), MantSize);
     if (v1 xor v2)                             { Wenn die Vorzeichen verschieden sind, eine Subtraktion }
      then AMem^.SubMem(BReal.Mant)             { durchfuehren, ansonsten eine Addition. }
      else AMem^.AddMem(BReal.Mant);

     AMem^.ClearMe;                             { Speicherobjekt freigeben. }
     AMem^.Free;

   end;
   ValidSReal(AReal);                           { Zahl gueltig machen. }
   if v1 then SReal_XCHG_Sign(AReal);           { Vorzeichen setzen. }
   GlobalError.LeaveProc;
 end;

 procedure RSub(var AReal: SReal; BReal: SReal);
 begin
   SReal_XCHG_Sign(BReal);
   RAdd(AReal, BReal);
 end;

 procedure RMul(var AReal: SReal; BReal: SReal);
 var
   v: Boolean;
   i, j: Word;
   AMem, BMem, CMem: HIntMem;
 begin
   if GlobalError.IsError then exit;            { Fehler ueberpruefen. }
   if not TestValid(AReal) or not TestValid(BReal) then exit;

   if RZero(BReal) then SwapReals(AReal, BReal);{ x * 0 = 0 }
   if RZero(AReal) then exit;
   GlobalError.EnterProc(proc_Mul);

   v := SReal_Neg_Abs(AReal) xor SReal_Neg_Abs(BReal); { Vorzeichen des Resulattes }
                                                { ermitteln und aus A und B loeschen. }
   AMem := New(HIntMem, InitMem(MantSize));
   BMem := New(HIntMem, InitMem(MantSize));     { Speicher-Objekte erstellen und }
   CMem := New(HIntMem, Init);                  { Fehler abfangen. }
   if (AMem = nil) or (BMem = nil) or (CMem = nil)
    then GlobalError.SError(er_Heap);
   if GlobalError.IsError then begin
     GlobalError.LeaveProc; exit;
   end;
   CMem^.AssignMem(Addr(BReal.Mant), MantSize);

   AddExpon(AReal, BReal.Expon);                { Die Exponenten addieren. }
   AddExpon(AReal, 2);
   j := 0;
   for i := 0 to ((MantSize div 2)-2) do begin
     inc(j, 16);                                { Die zweite zahl nacheinander }
     if (CMem^.GetWord(i) = 0) then Continue;   { mit allen Words der Mantisse der }
     AMem^.CopyFrom(AReal.Mant);                { zweiten Zahl mulitplizieren. }
     AMem^.ShiftR(j);                           { (Ausser ein Word ist gleich Null). }
     AMem^.MulMem(CMem^.GetWord(i));
     BMem^.AddMem(AMem^.Address^);
     ShowBusy;
   end;

   BMem^.CopyTo(AReal.Mant);                    { Vom Speicherblock in die Zahl uebertragen }
   ValidSReal(AReal);                           { und Zahl gueltig machen. }
   if v then SReal_XCHG_Sign(AReal);            { Vorzeichen setzen. }

   CMem^.ClearMe;                               { Speicher wieder freigeben. }
   CMem^.Free;
   BMem^.Free;
   AMem^.Free;

   GlobalError.LeaveProc;                       { Verlassen der Routine mitteilen. }
 end;

 procedure RDiv(var AReal: SReal; BReal: SReal);
 begin
   if RZero(AReal) and TestValid(AReal)
    and not RZero(BReal) then exit;             { 0 / x = 0 }
   RInv(BReal);
   if not GlobalError.IsError
    then RMul(AReal, BReal);
 end;

 procedure RInv(var AReal: SReal);
 var
   v: Boolean;          { Vorzeichen }
   i,j,k: Word;         { Zahler }
   Buffer: LongInt;
   BReal, CReal, DReal: SReal; { Buffer }
 begin
   if not TestValid(AReal) or GlobalError.IsError then exit;
   if RZero(AReal) then begin           { Eine Division durch Null ist nicht erlaubt ! }
     GlobalError.SError(er_DivZero);
     exit;
   end;
   GlobalError.EnterProc(proc_RInv);
   k := CmpMSize;                       { Diese Routine soll genauer arbeiten als }
   CmpMSize := MantSize-1;              { die Vergleiche sonst. }

   v := SReal_Neg_Abs(AReal);           { Vorzeichen separieren. }

   Buffer := AReal.Expon;               { Der Exponent wird in etwa umgekehrt, }
   AReal.Expon := 0;                    { aber wenn die Mantisse alleine = 1 ist }
   if ROne(AReal) then begin            { kann der Rest der Routine (der lange Teil) }
     AddExpon(AReal, -Buffer);          { gespart werden. }
     if v then SReal_Neg_Abs(AReal);
     exit;
   end;
   Buffer := -(Buffer+1);               { Expon := -Expon-1 }

   RLd_0(BReal);                        { Buffer loeschen. }
   RLd_0(CReal);
   RLd_0(DReal);

   for j := MantLast downto 0 do begin
     for i := 7 downto 0 do begin
       if (i = 7) and (j = MantLast) then Continue;     { Vorzeichen-Bit ueberspringen. }

       AddExpon(AReal, -1);
       CReal := BReal;                  { "Sicherungs"-Kopier erstellen. }
       RAdd(BReal, AReal);              { Probehalber dazuaddieren. }
       case RCmp_1(BReal) of            { Darf 1 nicht ueberschreiten ! }
         cmp_Above: BReal := CReal;     { Addition war zuviel. Ein Schritt zurueck. }
         cmp_Below: SetBitB(DReal.Mant[j], i);  { Addition war richtig: Bit setzen. }
         cmp_Equal: begin               { Gewuenschte Zahl ist bereits erreicht. }
           SetBitB(DReal.Mant[j], i);
           i := 8; break;
         end;
       end;
       ShowBusy;

     end;
     if GlobalError.IsError or (i = 8) then break;
   end;

   AReal := DReal;                      { Resultat uebertragen. }
   AReal.Expon := Buffer;

   ValidSReal(AReal);                   { Zahl muss gueltig sein. }
   if v then SReal_Neg_Abs(AReal);      { Vorzeichen setzen. }

   CmpMSize := k;
   GlobalError.LeaveProc;
 end;

 procedure RInc(var AReal: SReal);
 var
   Buffer: SReal;
 begin
   RLd_1(Buffer);
   RAdd(AReal, Buffer);
 end;

 procedure RDec(var AReal: SReal);
 var
   Buffer: SReal;
 begin
   RLd_1(Buffer);
   RSub(AReal, Buffer);
 end;

 procedure RSqr(var AReal: SReal);
 begin
   RMul(AReal, AReal);
 end;

 procedure RSqrt(var AReal: SReal);
 var
   i: Byte;
   BReal, CReal: SReal;
 begin
   if not TestValid(AReal) or GlobalError.IsError then exit;
   if TestBit(AReal.Mant[MantLast], 7) then begin      { Nicht die Wurzel einer }
     GlobalError.SetError(er_NegRoot, proc_Sqrt);      { negativen Zahl ziehen. }
     exit;
   end;
   if RZero(AReal) or ROne(AReal) then exit;           { Wurzel aus 0 od. 1 gibt 0 bzw. 1 }
   RLd_1(BReal);
   RLd_0(CReal);
   BReal.Expon := AReal.Expon div 2;
   for i := 1 to exact_sqrt do begin                   { Berechnung mit Hilfe der Formel }
     CReal := AReal;                                   { von Heron. }
     RDiv(CReal, BReal);
     RAdd(BReal, CReal);
     AddExpon(BReal, -1);
     ShowBusy;
   end;
   AReal := BReal;
 end;

 procedure RAbs(var AReal: SReal); assembler;
 asm
       les      di,AReal
       add      di,ExpoSize+MantLast
       mov      al,07Fh
       and      es:[di],al
 end;

 procedure RNeg(var AReal: SReal);
 begin
   SReal_XCHG_Sign(AReal);
 end;

 procedure RRound(var AReal: SReal);
 var
   v: Boolean;
   i: Word;
   Buffer: SReal;
 begin
   if GlobalError.IsError or not TestValid(AReal) then exit;
   v := SReal_Neg_Abs(AReal);

   if (AReal.Mant[MantSize-CmpMSize] > $7F) then begin  { Aufrunden ? }
     RLd_1(Buffer);
     Buffer.Expon := (-8 * CmpMSize) + 2 + AReal.Expon;
     RAdd(AReal, Buffer);
   end;

   for i := 0 to (MantSize-CmpMSize)    { Alle zusaetzlichen Stellen loeschen. }
    do AReal.Mant[i] := $00;

   if v then RNeg(AReal);
 end;

 { ****************************************************** }
 function RCmp(AReal, BReal: SReal): Byte; assembler;
 asm
       push     proc_RCmp               { Als erstes Mitteilen, dass diese }
       call     AEnterProc              { Routine aufgerufen wurde. }

       push     ds
       les      di,AReal
       lds      si,BReal

       mov      bx,ExpoSize+MantLast    { Zuerst die Vorzeichen der beiden }
       mov      al,7Fh                  { Zahlen Auf Null setzen. Die Vorzeichen }
       and      es:[di+bx],al           { sind jeweils in den hoechsten Bits der }
       and      ds:[si+bx],al           { "letzten" Bytes der Mantisse abgelegt. }

       mov      ax,es:[di+02]           { Als naechstes sind die Exponenten zu }
       mov      dx,ds:[si+02]           { ueberpruefen. Zuesrt die vorderen Stellen, }
       cmp      ax,dx                   { danach die hinteren. }
       jg       @@A
       jl       @@B
       mov      ax,es:[di]
       mov      dx,ds:[si]
       cmp      ax,dx
       ja       @@A
       jb       @@B

       add      di,ExpoSize+MantSize-2  { Zuletzt werden die beiden Mantissen }
       add      si,ExpoSize+MantSize-2  { miteinenader verglichen. }
       mov      cx,CmpMSize             { CmpMSize gibt an, wie viele Byte zu preufen sind. }
       std
       shr      cx,01
 @@1:  cmpsw
       jb       @@A
       ja       @@B
       loop     @@1

       jmp      @@E                     { Falls keine Unterschiede gefunden wurden, }
                                        { muessen die beiden Zahlen gleich sein. }
 @@A:  mov      al,cmp_Above
       jmp      @@Q
 @@B:  mov      al,cmp_Below
       jmp      @@Q
 @@E:  mov      al,cmp_Equal
 @@Q:  pop      ds
       mov      cmp_Result,al
       push     ax

       call     ALeaveProc              { Verlassen der Routine mitteilen. }
       pop      ax
 end;

 function RCmpS(AReal, BReal: SReal): Byte; assembler;
 asm
       push     proc_RCmp               { Als erstes Mitteilen, dass diese }
       call     AEnterProc              { Routine aufgerufen wurde. }

       push     ds
       les      di,AReal
       lds      si,BReal

       mov      bx,MantLast+ExpoSize    { Zuerst die Vorzeichen der beiden }
       mov      al,es:[di+bx]           { Zahlen ueberpruefen. Die Vorzeichen }
       mov      ah,ds:[si+bx]           { sind jeweils in den hoechsten Bits }
       and      ax,8080h                { der "letzten" Bytes der Mantisse abge- }
       cmp      al,ah                   { legt. }
       ja       @@B
       jb       @@A

       mov      ax,es:[di+02]           { Als naechstes sind die Exponenten zu }
       mov      dx,ds:[si+02]           { ueberpruefen. Zuesrt die vorderen Stellen, }
       cmp      ax,dx                   { danach die hinteren. }
       jg       @@A
       jl       @@B
       mov      ax,es:[di]
       mov      dx,ds:[si]
       cmp      ax,dx
       ja       @@A
       jb       @@B

       add      di,ExpoSize+MantSize-2  { Zuletzt werden die beiden Mantissen }
       add      si,ExpoSize+MantSize-2  { miteinenader verglichen. }
       mov      cx,CmpMSize             { CmpMSize gibt an, wie viele Byte zu preufen sind. }
       std
       shr      cx,01
 @@1:  cmpsw
       ja       @@B
       jb       @@A
       loop     @@1

       jmp      @@E                     { Falls keine Unterschiede gefunden wurden, }
                                        { muessen die beiden Zahlen gleich sein. }
 @@A:  mov      al,cmp_Greater
       jmp      @@Q
 @@B:  mov      al,cmp_Less
       jmp      @@Q
 @@E:  mov      al,cmp_Equal
 @@Q:  pop      ds
       mov      cmp_Result,al
       push     ax

       call     ALeaveProc              { Verlassen der Routine mitteilen. }
       pop      ax
 end;

 function RZero(AReal: SReal): Boolean; assembler;
 asm
       les      di,AReal                { Damit die ganze Zahl Null ist, muessen }
       xor      ax,ax                   { der Exponent und das erste Byte der Mantisse }
                                        { Null sein. }
       cld                              { Zuerst den Exponenten ueberpruefen. }
       mov      cx,ExpoSize
       shr      cx,01
       repz     scasw
       jnz      @@1

       add      di,MantLast             { Nun das erste Byte der Mantisse }
       cmp      al,es:[di]
       jnz      @@1

       mov      al,true
 @@1:
 end;

 function ROne(AReal: SReal): Boolean; assembler;
 asm
       les      di,AReal                { Damit eine Zahl = 1 ist, muss das erste Byte }
       mov      bx,ExpoSize+MantLast-01 { den Wert 40h enthalten, alls anderen Bytes }
                                        { muessen Null sein. }
       mov      dx,es:[di+bx]           { Das erste Byte ueberpruefen. }
       cmp      dx,4000h
       mov      al,false
       jne      @@1

       xor      ax,ax
       cld                              { Zuerst den Exponenten ueberpruefen. }
       mov      cx,ExpoSize
       shr      cx,01
       repz     scasw
       jnz      @@1

       mov      cx,CmpMSize             { Danach auch die Mantisse ueberpruefen. }
       shr      cx,01                   { (Das oberste Word braucht nicht mehr }
       dec      cx                      { mitberuecksichtigt zu werden). }
       std
       add      di,MantLast-02
       repz     scasw
       jnz      @@1

       mov      al,true
 @@1:
 end;

 function RCmp_1(AReal: SReal): Byte;
 begin
   GlobalError.EnterProc(proc_RCmp);
   if TestBit(AReal.Mant[MantLast], 7) then begin  { Negative Zahlen sind }
     RCmp_1 := cmp_Less;                           { immer kleiner als 1 ! }
     GlobalError.LeaveProc; exit;
   end;
   if ROne(AReal) then begin    { Zahl = 1 ? }
     RCmp_1 := cmp_Equal;
     GlobalError.LeaveProc; exit;
   end;
   if (AReal.Expon < 0)         { Im Binaersystem genuegt es nun, den }
    then RCmp_1 := cmp_Below    { Exponenten zu betrachten. }
    else RCmp_1 := cmp_Above;
   GlobalError.LeaveProc;
 end;
 { ****************************************************** }

 procedure AEnterProc(ANr: Word);
 begin
   GlobalError.EnterProc(ANr);
 end;

 procedure ALeaveProc;
 begin
   GlobalError.LeaveProc;
 end;
 { ****************************************************** }

{ ************************************************************************** }
END.
{ ************************************************************************** }