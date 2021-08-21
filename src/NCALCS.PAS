{ ************************************************************************** }
{  Die hier aufgefuehrten Routinen bearbeiten ganze Nummern und nicht nur    }
{ Zahlen.                                                                    }
{ ************************************************************************** }
{  Calculating with numbers and variables.                                   }
{ ************************************************************************** }
{                                                                            }
{                       (c) 1999/2000, Tobias Kohn                           }
{                                Version 2.0                                 }
{                                                                            }
{ ************************************************************************** }
{$G+}             { 286-Codes }
UNIT NCalcs;
{ ************************************************************************** }
INTERFACE
 USES Lists, CRTypes, Errors, CRComplx, AuxStr, NBasics, CRMathe, CRConv,
      WinProcs, Dialogs;
{ ************************************************************************** }

 const
   proc_NumMul  = $61;  { NumMul }
   proc_UnNum   = $62;  { UniteNumbers }

   { ************************************************** }
   {  NumNeg     Negiert die Zahl der Nummer.           }
   {  NumInv     Invertiert die Zahl und negiert die    }
   {              Potenzen aller Variablen.             }
   { ************************************************** }
   procedure NumNeg(var ANum1: HNumber);
   procedure NumInv(var ANum1: HNumber);

   { ************************************************** }
   {  Wenn die Operationen erfolgreich durchgefuehrt    }
   { werden, werden die zweiten Nummern jeweils vom     }
   { Speicher entfernt.                                 }
   { ************************************************** }
   {  NumAdd     Addiert zwei Nummern. Der Rueckgabewert}
   {              zeigt an, ob die Addition erfolgreich }
   {              verlief (=true).                      }
   {  NumMul     Multipliziert zwei Nummern.            }
   {  NumDiv     Dividiert zwei Nummern.                }
   { ************************************************** }
   function NumAdd(var ANum1, ANum2: HNumber): boolean;
   procedure NumMul(var ANum1, ANum2: HNumber);
   procedure NumDiv(var ANum1, ANum2: HNumber);

   { ************************************************** }
   {  NumSqr     Quadriert die Nummer.                  }
   {  NumSqrt    Zieht die 2te Wurzel aus ANum.         }
   {  NumKube    ANum hoch 3.                           }
   {  NumKbrt    Dritte Wurzel aus ANum.                }
   {  NumTrig    Berechnet die trigonometrischen Funk-  }
   {              tionen (sin..arctan). Der Index gibt  }
   {              die genaue Funktion an: 0-2: sin/cos/ }
   {              tan; 8-10: arcsin/arccos/arctan.      }
   {  NumLog     Fasst die Funktionen ln/log/lb/exp zu- }
   {              sammen. Der Index gibt die Funktion   }
   {              in der obigen Reihenfolge an (mit 0   }
   {              beginnend).                           }
   { ************************************************** }
   procedure NumSqr(var ANum: HNumber);
   function NumSqrt(var ANum: HNumber): Boolean;
   function NumKbrt(var ANum: HNumber): Boolean;
   function NumTrig(var ANum: HNumber; AIndex: Byte): Boolean;
   function NumLog(var ANum: HNumber; AIndex: Byte): Boolean;

   { ************************************************** }
   {  ChainNeg   Negiert alle Element einer Liste, von  }
   {              der AChain das erste Element ist.     }
   {  NumIsQuadrat  Prueft, ob alle Variablen gerade    }
   {             Potenzen besitzen.                     }
   {  ChainBinom Versucht, mit Hilfe der binomischen    }
   {              Formeln die Wurzel aus der Klammer zu }
   {              ziehen.                               }
   { ************************************************** }
   procedure ChainNeg(var AChain: HChain);
   function NumIsQuadrat(ANum: HNumber): Boolean;
   function ChainBinom(var AChain: HChain): boolean;

   { ************************************************** }
   {  NumberCount   Zaehlt, wie viele Kettenelemente in }
   {              AChain Nummern sind.                  }
   {  EachIsNumber  Prueft, ob alle Unterelemente von   }
   {              AChain Nummern sind.                  }
   {                                                    }
   {  UniteChains Fasst jeweils alle Unterglieder zusam-}
   {              men und versucht, falls moeglich und  }
   {              vorhanden, auch die Funktion zu       }
   {              berechnen.                            }
   {  UniteNumbers  Verknuepft alle Unterelemente der   }
   {              Kette, die Nummern sind, miteinander  }
   {              zu verknuepfen.                       }
   {  CalcFunction  Prueft, ob die angegebene Kette     }
   {              eine mathematische Funktion reprasen- }
   {              tiert. Wenn die Kette nun nur 1 UE in }
   {              Form einer Nummer enthaelt, wird die  }
   {              Funktion wenn moeglich berechnet.     }
   {  ChainMul   Multipliziert zwei beliebige Ketten    }
   {              miteinander. Handelt es sich um Klam- }
   {              mern, werden alle Elemente der Klammer}
   {              einzeln behandelt. Der Rueckgabewert  }
   {              ist false, wenn die beiden Elemente   }
   {              nicht weiter zusammengefasst werden   }
   {              koennen.                              }
   {  ChainPot   Versucht, die Kette, sofern es sich um }
   {              eine Potenzierung handelt, auszurech- }
   {              nen. Die Potenz muss dafuer aber eine }
   {              ganze Zahl sein.                      }
   { ************************************************** }
   function NumberCount(AChain: HChain): Word;
   function EachIsNumber(AChain: HChain): boolean;

   procedure UniteChains(var AChain: HChain);
   procedure UniteNumbers(var AChain: HChain);
   procedure CalcFunction(var AChain: HChain);

   function ChainMul(var AChain, BChain: HChain): boolean;
   procedure ChainPot(var AChain: HChain);

   { ************************************************** }
   {  LdChain    Erzeugt eine einfache Kette ohne Vari- }
   {              ablen mit dem Nummernwert i.          }
   { ************************************************** }
   function LdChain(i: Integer): HChain;

{ ************************************************************************** }
IMPLEMENTATION
{ ************************************************************************** }

 { ****************************************************** }
 procedure NumNeg(var ANum1: HNumber);
 begin
   if GlobalError.IsError or (ANum1 = nil) then exit;
   CNeg(ANum1^.Value);
 end;

 procedure NumInv(var ANum1: HNumber);
 var
   p: HVar;
 begin
   if GlobalError.IsError or (ANum1 = nil) then exit;

   CInv(ANum1^.Value);              { Zahl invertieren. }
   p := ANum1^.Sub;                 { Die Potenzen aller Variablen }
   while not (p = nil) do begin     { negieren. }
     p^.Potenz := -p^.Potenz;
     p := p^.Next;
   end;
 end;
 { ****************************************************** }

 function NumAdd(var ANum1, ANum2: HNumber): Boolean;
 begin
   if GlobalError.IsError or (ANum1 = nil) or (ANum2 = nil) then begin
     NumAdd := false;
     exit;
   end;

   if VarEquals(ANum1, ANum2) then begin      { Wenn alle Variablen gleich sind,  }
     CAdd(ANum1^.Value, ANum2^.Value);        { werden die beiden Zahlen addiert. }

     DisposeTreeItem(HTreeItem(ANum2));       { Zweite Zahl loeschen. }
     NumAdd := true;
   end else NumAdd := false;
 end;

 procedure NumMul(var ANum1, ANum2: HNumber);
 begin
   if GlobalError.IsError or (ANum1 = nil) or (ANum2 = nil) then exit;
   GlobalError.EnterProc(proc_NumMul);

   CMul(ANum1^.Value, ANum2^.Value);          { Werte multiplizieren. }
   ConcatLists(HListItem(ANum1^.Sub), HListItem(ANum2^.Sub));
   UniteVars(ANum1);                          { Alle Variablen addieren. }

   Dispose(ANum2);                            { Zweite Zahl loeschen. }
   GlobalError.LeaveProc;
 end;

 procedure NumDiv(var ANum1, ANum2: HNumber);
 begin
   if GlobalError.IsError or (ANum1 = nil) or (ANum2 = nil) then exit;

   NumInv(ANum2);            { x/y = x * (1/y) }
   NumMul(ANum1, ANum2);
 end;
 { ****************************************************** }

 procedure NumSqr(var ANum: HNumber);
 var
   p: HVar;
 begin
   if GlobalError.IsError or (ANum = nil) then exit;

   CSqr(ANum^.Value);              { Wert quadrieren. }
   p := ANum^.Sub;                 { Variablen-Potenzen }
   while not (p = nil) do begin    { verdoppeln. }
     p^.Potenz := p^.Potenz * 2;
     p := p^.Next;
   end;
 end;

 function NumSqrt(var ANum: HNumber): Boolean;
 var
   p: HVar;
 begin
   if GlobalError.IsError or (ANum = nil) then exit;

   p := ANum^.Sub;                          { Um von einer Variablen die Wurzel     }
   while not (p = nil) do begin             { zu ziehen, muss der Exponent halbiert }
     if ((p^.Potenz mod 2) = 1) then begin  { werden. Da die Variablen hier aber    }
       NumSqrt := false;                    { nur ganze Zahlen zulassen, muessen alle }
       exit;                                { Potenzen durch 2 teilbar sein. }
     end;
     p := p^.Next;
   end;

   CSqrt(ANum^.Value);                      { Die Wurzel des Wertes. }
   p := ANum^.Sub;                          { Alle Potenzen halbieren. }
   while not (p = nil) do begin
     p^.Potenz := p^.Potenz div 2;
     p := p^.Next;
   end;
   NumSqrt := true;
 end;

 function NumKbrt(var ANum: HNumber): boolean;
 var
   p: HVar;
 begin
   if GlobalError.IsError or (ANum = nil) then exit;

   p := ANum^.Sub;                          { Um von einer Variablen die dritte Wurzel     }
   while not (p = nil) do begin             { zu ziehen, muss der Exponent gedrittelt }
     if not ((p^.Potenz mod 3) = 0) then begin  { werden. Da die Variablen hier aber    }
       NumKbrt := false;                    { nur ganze Zahlen zulassen, muessen alle }
       exit;                                { Potenzen durch 3 teilbar sein. }
     end;
     p := p^.Next;
   end;

   CRootZ(ANum^.Value, 3);
   p := ANum^.Sub;                          { Alle Potenzen dritteln. }
   while not (p = nil) do begin
     p^.Potenz := p^.Potenz div 3;
     p := p^.Next;
   end;
   NumKbrt := true;
 end;

        { Fuer AIndex gelten die Werte: }
        {      00: sin   08: arcsin     }
        {      01: cos   09: arccos     }
        {      02: tan   10: arctan     }
 function NumTrig(var ANum: HNumber; AIndex: Byte): Boolean;
 begin
   if GlobalError.IsError or (ANum = nil) then begin
     NumTrig := false; exit;
   end;
   if not (ANum^.Sub = nil) then begin
     NumTrig := false; exit;
   end;

   case AIndex of
     00: CSin(ANum^.Value);
     01: CCos(ANum^.Value);
     02: CTan(ANum^.Value);
     08: CArcSin(ANum^.Value);
     09: CArcCos(ANum^.Value);
     10: CArcTan(ANum^.Value);
   end;

   NumTrig := true;
 end;

        { Fuer AIndex gelten die Werte: }
        {      00: Ln    02: Lb         }
        {      01: Log   03: Exp        }
 function NumLog(var ANum: HNumber; AIndex: Byte): Boolean;
 begin
   if GlobalError.IsError or (ANum = nil) then begin
     NumLog := false; exit;
   end;
   if not (ANum^.Sub = nil) then begin
     NumLog := false; exit;
   end;

   case AIndex of
     00: CLn(ANum^.Value);
     01: CLog(ANum^.Value);
     02: CLb(ANum^.Value);
     03: CExp(ANum^.Value);
   end;

   NumLog := true;
 end;
 { ****************************************************** }

 procedure ChainNeg(var AChain: HChain);
 var
   ATree: LTree;
   i    : Word;
   p    : HChain;
 begin
   if GlobalError.IsError or (AChain = nil) then exit;

   ATree.Init;
   ATree.AddTree(HTreeItem(AChain));

   if (ATree.Count > 0) then
    for i := 0 to (ATree.Count-1) do begin
      p := HChain(ATree.CutItem(i));
      if (p^.Kind = kd_Neg)
       then p^.Kind := kd_Clip
       else p := NewChain(kd_Neg, p, nil);
      ATree.InsertItem(HTreeItem(p), i);
    end;

   AChain := HChain(ATree.FirstItem);
   ATree.ReleaseDone;
 end;

 function NumIsQuadrat(ANum: HNumber): Boolean;
 var
   p: HVar;
   Buffer: Boolean;
 begin
   if GlobalError.IsError or (ANum = nil) then begin
     NumIsQuadrat := false; exit;
   end;

   p := ANum^.Sub;
   Buffer := true;
   while not (p = nil) do begin
     if not ((p^.Potenz mod 2) = 0) then begin
       Buffer := false;
       break;
     end;
     p := p^.Next;
   end;
   NumIsQuadrat := Buffer;
 end;

 function ChainBinom(var AChain: HChain): boolean;
 var
   p: HNumber;
   q: HVar;
   negflag: Boolean;
   n1,n2,n3,n4: HNumber;

  procedure DelLocals;
  begin
    if not (n1 = nil) then DisposeTreeItem(HTreeItem(n1));
    if not (n2 = nil) then DisposeTreeItem(HTreeItem(n2));
    if not (n3 = nil) then DisposeTreeItem(HTreeItem(n3));
    if not (n4 = nil) then DisposeTreeItem(HTreeItem(n4));
  end;

 begin
   if GlobalError.IsError or (AChain = nil) then begin
     ChainBinom := false; exit;
   end;

   UniteChains(AChain);

   p := AChain^.Sub;
   if (p = nil) or not (AChain^.Kind = kd_Clip) then begin
     ChainBinom := false; exit;
   end;

   n1 := nil; n2 := nil; n3 := nil; n4 := nil;
   negflag := false;

   p := AChain^.Sub;                          { Zuerst muss der Binom in }
   if (p = nil) then exit;                    { ein a^2, ein b^2 und ein }
                                              { 2ab zerlegt werden. }
   while not (p = nil) do begin
     if not (p^.Kind = kd_Number) then begin
       DelLocals;
       ChainBinom := false; exit;
     end;

     if NumIsQuadrat(p)
      then if (n1 = nil)
        then n1 := HNumber(CopyChain(HChain(p)))
        else if (n3 = nil)
         then n3 := HNumber(CopyChain(HChain(p)))
         else begin
           DelLocals;
           ChainBinom := false; exit;
         end
      else if (n2 = nil)
       then n2 := HNumber(CopyChain(HChain(p)))
       else begin
         DelLocals;
         ChainBinom := false; exit;
       end;
     p := p^.Next;
   end;
   if (n1 = nil) or (n2 = nil) or (n3 = nil) then begin
     DelLocals;
     ChainBinom := false; exit;
   end;

   NegFlag := SReal_Neg(n2^.Value.Real);
   n4 := HNumber(CopyChain(HChain(n1)));
   p  := HNumber(CopyChain(HChain(n3)));
   NumMul(n4, p);
   NumSqr(n2);
   AddExpon(n2^.Value.Real, -2);                      { n2 := (n2/2)^2 = (ab)^2 }
   AddExpon(n2^.Value.Imag, -2);

   if not CEqual(n2^.Value, n4^.Value) then begin     { Wenn dies wirklich ein }
     DelLocals;                                       { Binom ist muss gelten: }
     ChainBinom := false; exit;                       { n2 = n4 }
   end;

   if not VarEquals(n4, n2) then begin       { Nun die Variablen ueberpruefen, }
     DelLocals;                              { ob sie gleich sind. }
     ChainBinom := false; exit;
   end;

   if not (AChain = nil) then DisposeTreeItem(HTreeItem(AChain));

   NumSqrt(n1);
   NumSqrt(n3);
   if NegFlag then CNeg(n3^.Value);

   n3^.Next := nil;                              { Nun muss es ein Binom sein, }
   n1^.Next := n3;                               { und die Kette kann neu mit  }
   AChain := NewChain(kd_Clip, n1, nil);         { der Wurzel der Urspruenglichen }
   n1 := nil; n3 := nil;                         { Kette geladen werden. }

   DelLocals;
   ChainBinom := true;
 end;
 { ****************************************************** }

 function NumberCount(AChain: HChain): Word;
 var
   p: HChain;
   i: Word;
 begin
   if (AChain = nil) or GlobalError.IsError then begin
     NumberCount := 0; exit;
   end;
   i := 0;

   p := AChain;                                 { Einfach alle Elemente durchgehen, }
   while not (p = nil) do begin                 { und jedesmal, wenn ein Element eine }
     if (p^.Kind = kd_Number) then inc(i);      { Nummer ist, den Zaehler erhoehen. }
     p := p^.Next;
   end;

   NumberCount := i;
 end;

 function EachIsNumber(AChain: HChain): boolean;
 var
   p: HChain;
 begin
   if (AChain = nil) or GlobalError.IsError then begin
     EachIsNumber := false; exit;
   end;

   p := HChain(AChain^.Sub);
   while not (p = nil) do begin
     if not (p^.Kind = kd_Number) then begin
       EachIsNumber := false; exit;
     end;
     p := p^.Next;
   end;

   EachIsNumber := true;
 end;
 { ****************************************************** }
 { ****************************************************** }

 procedure UniteChains(var AChain: HChain);
 var
   p,q,r: HChain;
   i,j: Word;
   k: byte;

   ATree,BTree: LTree;
 begin
   if GlobalError.IsError or (AChain = nil) then exit;

   if (AChain^.Kind = kd_Number) then begin
     UniteVars(HNumber(AChain));
     exit;
   end;

   ATree.Init;                              { Alle Unterelemente einzeln }
   ATree.AddTree(AChain^.Sub);              { zusammenfassen.            }
   for i := 0 to (ATree.Count-1) do begin
     p := HChain(ATree.CutItem(i));
     if (p = nil) then break;
     UniteChains(p);
     if not (p = nil) then ATree.InsertItem(HTreeItem(p), i);
   end;

   i := 0;
   k := AChain^.Kind;                           { Unnoetige verschachtelungen }
   if (k = kd_Clip) or (k = kd_Mul)             { mit Klammern aufloesen. }
    then while (i < ATree.Count) do begin
      p := HChain(ATree.GetItem(i));
      if (p^.Kind = k) then begin
        p := HChain(ATree.CutItem(i));
        q := p^.Sub;
        Dispose(p);
        j := 0;
        while not (q = nil) do begin
          p := q^.Next;
          ATree.InsertItem(HTreeItem(q), i+j);
          q := p;
          inc(j);
        end;
      end;
      inc(i);
    end;

   AChain^.Sub := ATree.FirstItem;
   ATree.ReleaseDone;

   if (AChain^.Kind = kd_Pot) then begin
     ChainPot(AChain);
     exit;
   end;
   UniteNumbers(AChain);
   CalcFunction(AChain);

   p := AChain^.Sub;
   if (AChain^.Kind = kd_Div) and (p^.Next^.Kind = kd_Number) then begin
     AChain^.Kind := kd_Mul;
     NumInv(HNumber(p^.Next));
   end;

   if ((AChain^.Kind = kd_Clip) or (AChain^.Kind = kd_Mul))
         and (p^.Next = nil) then begin          { Wenn eine Summe oder ein Produkt }
     q := AChain^.Next;                          { nur 1 Element enthaelt, so kann  }
     Dispose(AChain);                            { die aussere Summe, bzw. das aussere }
     AChain := p;                                { Produkt entfernt werden. }
     AChain^.Next := q;                          { Bsp: (+8) -> 8 }
   end;

   if (AChain^.Kind = kd_sqr) then begin         { Quadrat umwandeln in }
     q := AChain^.Next;                          { die Multiplikation: }
     AChain^.Next := nil;                        { x^2 -> x*x }
     AChain^.Kind := kd_Clip;
     p := CopyChain(AChain);
     AChain^.Next := p;
     AChain := NewChain(kd_Mul, AChain, q);

     UniteChains(AChain);
     p := AChain^.Sub;
   end;

   if (AChain^.Kind = kd_kb) then begin          { x^3 -> x*x*x }
     r := AChain^.Next;
     AChain^.Next := nil;
     AChain^.Kind := kd_Clip;

     p := CopyChain(AChain);
     q := CopyChain(AChain);
     p^.Next := q;
     AChain^.Next := p;
     AChain := NewChain(kd_Mul, AChain, r);

     UniteChains(AChain);
     p := AChain^.Sub;
   end;

   if (AChain^.Kind = kd_Mul) then begin        { Multiplikation. }
     ATree.Init;
     BTree.Init;
     ATree.AddTree(HTreeItem(AChain)^.Sub);

     p := HChain(ATree.CutItem(0));             { Das erste Element ausschneiden. }
     p^.Next := nil;                            { Versuchen, alle weiteren Elemente }
     for i := 0 to (ATree.Count-1) do begin     { zum ersten Element hinzuzumultiplizieren. }
       q := HChain(ATree.CutItem(0));           { Alle Elemente, die nicht hinzumul- }
       q^.Next := nil;                          { tipliziert werden koennen, in BTree sammeln. }
       if not ChainMul(p, q) then BTree.InsertItem(HTreeItem(q), 0);
     end;

     BTree.InsertItem(HTreeItem(p), 0);

     p := HChain(BTree.FirstItem);              { BTree zurueck in eine Kette umwandeln. }
     if (p^.Next = nil) then begin
       p^.Next := AChain^.Next;
       Dispose(AChain);
       AChain := p;
     end else begin
       AChain^.Sub := p;
     end;

     BTree.ReleaseDone;
     ATree.Done;
   end;

   if (AChain^.Kind = kd_Neg) and (p^.Kind = kd_Clip) then begin
     ChainNeg(HChain(p^.Sub));
     p^.Next := AChain^.Next;
     Dispose(AChain);
     AChain := p;
   end;

   if (AChain^.Kind = kd_sqrt) then begin       { Wurzel eines Termes: }
     q := CopyChain(AChain);                    { Versuchen, in Binom zu }
     q^.Kind := kd_Clip;                        { zerlegen. }
     if ChainBinom(q) then begin
       DisposeTreeItem(HTreeItem(AChain));
       AChain := q;
     end else DisposeTreeItem(HTreeItem(q));
   end;
 end;

 {  Diese Routine verarbeitet die beiden Operatoren Division und }
 { Multiplikation zwischen zwei Nummern.                         }
 procedure NumDivPot(var AChain: HChain); near;

   {  Diese Unterprozedur rechnet alle Variablen hoch die Potenz AValue.  }
   { Der Rueckgabewert ist true, wenn diese Rechnung durchgefuehrt werden }
   { konnte.                                                              }
   function VarsPotC(ANum: HNumber; AValue: Complex): boolean;
   var
     p: HVar;
     i: LongInt;
   begin
     if GlobalError.IsError or (ANum = nil) then begin
       VarsPotC := false; exit;
     end;
     p := ANum^.Sub;                    { Wenn keine Variablen vorhanden sind,      }
     if (p = nil) then begin            { muessen sie auch nicht potenziert werden. }
       VarsPotC := true; exit;
     end;

     if not RZero(AValue.Imag) then exit;
     if RZero(AValue.Real)              { Da die Potenzen der Variablen ganze }
      then i := 0                       { Zahlen sind, muss die Potenz hier auch }
      else begin                        { eine ganze, reelle Zahl sein. }
        i := CmplxToInt(AValue);
        if (i = 0) then begin
          VarsPotC := false; exit;
        end;
      end;

     while not (p = nil) do begin       { Alle Variablen potenzieren. }
       p^.Potenz := p^.Potenz * i;
       p := p^.Next;
     end;
     VarsPotC := true;
   end;

 var
   n,m: HNumber;
   p  : HChain;
 begin
   if GlobalError.IsError or (AChain = nil) then exit;

   n := AChain^.Sub;
   if (n = nil) then exit;
   m := n^.Next;
   if (m = nil) or not (m^.Next = nil) then exit;
   if not ((n^.Kind = kd_Number) and (m^.Kind = kd_Number)) then exit;

   p := Achain^.Next;
   case AChain^.Kind of
     kd_Div: begin
       NumDiv(n,m);
       Dispose(AChain);
       AChain := HChain(n);
       AChain^.Next := p;
     end;
     kd_Pot: begin
       if not (m^.Sub = nil) then exit;
       if not VarsPotC(n, m^.Value) then exit;
       CExpC(n^.Value, m^.Value);
       DisposeTreeItem(HTreeItem(m));
       Dispose(AChain);
       AChain := HChain(n);
       AChain^.Next := p;
     end;
   end;
 end;

 procedure UniteNumbers(var AChain: HChain);
 var
   ATree, BTree: LTree;
   i,j,k: Word;
   p: HTreeItem;
   q: HChain absolute p;
   n: HNumber absolute p;
   m: HNumber;
   r: HChain;
 begin
   if GlobalError.IsError or (AChain = nil) then exit;
   if (AChain^.Kind = kd_Number) then exit;

   if (AChain^.Kind = kd_Div) or (AChain^.Kind = kd_Pot) then begin
     NumDivPot(AChain);
     exit;
   end;

   k := AChain^.Kind;

   ATree.Init;
   BTree.Init;
   BTree.AddTree(HTreeItem(AChain^.Sub));
   if (BTree.Count = 0) then exit;
                                                { Ausplittung: ATree enthaelt alle }
   for i := (BTree.Count-1) downto 0            { Nummern, BTree alle anderen. }
    do if (HChain(BTree.GetItem(i))^.Kind = kd_Number) then begin
      p := BTree.CutItem(i);
      ATree.InsertItem(p, 0);
    end;

   i := 0;
   if (AChain^.Kind = kd_Mul)                   { Alle Nummern soweit moeglich }
    then begin                                  { zusammenfassen. }
      p := ATree.GetItem(0);                    { Multiplikation: alle Nummern }
      m := n; n:= nil;                          { miteinander multiplizieren. }
      for i := 1 to (ATree.Count-1) do begin
        p := ATree.CutItem(1);
        NumMul(m, n);
      end;
    end else
      while ((i+1) < ATree.Count) do begin              { Addition: addieren, wenn }
        p := ATree.GetItem(i);                          { die Variablen gleich sind. }
        for j := (ATree.Count-1) downto (i+1) do begin
          m := HNumber(ATree.CopyItem(j));
          if NumAdd(n, m)
           then ATree.DeleteItem(j)
           else DisposeTreeItem(HTreeItem(m));
        end;
        inc(i);
      end;

   p := ATree.FirstItem;                        { Beide Listen nun wieder }
   ATree.Release;                               { zusammenfuegen. }
   if not (BTree.Count = 0) then begin
     r := HChain(BTree.FirstItem);
     ConcatChains(q, r);
     BTree.Release;
   end;
   if (p = nil) then q := LdChain(0);

   AChain^.Sub := p;

   BTree.Done;
   ATree.Done;
 end;

 procedure CalcFunction(var AChain: HChain);
 var
   n: HNumber;
   m: HChain absolute n;
   p: HVar;

  procedure DelFunct;           { Wenn die Funktion ausgefuehrt werden }
  begin                         { konnte, wird sie entfernt.           }
    m^.Next := AChain^.Next;    { Bsp: sin(1) -> sin(0.84) -> 0.84     }
    Dispose(AChain);            {                          ^           }
    AChain := m;                {                  Diesen Schritt hier }
  end;                          {              erledigt diese Routine. }

 begin
   if GlobalError.IsError or (AChain = nil) then exit;
   if (AChain^.Sub = nil) then exit;

   n := AChain^.Sub;
   if not ((m^.Kind = kd_Number) and (n^.Next = nil)) then exit;

   case AChain^.Kind of
     kd_Neg: begin      { Negieren }
       NumNeg(n);
       DelFunct;
     end;
     kd_Inv: begin      { Invertieren }
       NumInv(n);
       DelFunct;
     end;
     kd_Sqr: begin      { Quadrieren }
       NumSqr(n);
       DelFunct;
     end;
     kd_abs: begin
       if (n^.Sub = nil) then begin
         CAbs(n^.Value);
         DelFunct;
       end;
     end;
     kd_Sqrt: if NumSqrt(n) then DelFunct;
     kd_Kbrt: if NumKbrt(n) then DelFunct;
     kd_sin..kd_arctan:
              if NumTrig(n, (AChain^.Kind)-kd_sin) then DelFunct;
     kd_ln..kd_exp:
              if NumLog(n, (AChain^.Kind)-kd_ln) then DelFunct;
   end;
 end;
 { ****************************************************** }
 { ****************************************************** }

 function ChainMul(var AChain, BChain: HChain): boolean;
 var
   p,q: HChain;
   i: Word;

   ATree, BTree: LTree;
 begin
   if GlobalError.IsError or (AChain = nil) or (BChain = nil) then begin
     ChainMul := false; exit;
   end;

   if (AChain^.Kind = kd_Number) and (BChain^.Kind = kd_Number) then begin
     NumMul(HNumber(AChain), HNumber(BChain));
     ChainMul := true; exit;
   end;

   if (BChain^.Kind = kd_Clip) and not (AChain^.Kind = kd_Clip) then begin
     p := BChain;
     BChain := AChain;
     AChain := p;

     p := AChain^.Next;
     AChain^.Next := BChain^.Next;
     BChain^.Next := p;
   end;

   if (BChain^.Kind = kd_Number) then begin        { 2 Spezialfaelle: }
     if ROne(HNumber(BChain)^.Value.Real) and RZero(HNumber(BChain)^.Value.Real)
            and (BChain^.Sub = nil) then begin     { 1 * x = x }
       DisposeTreeItem(HTreeItem(BChain));
       ChainMul := true;
       exit;
     end;
     if CZero(HNumber(BChain)^.Value) then begin   { 0 * x = 0 }
       DisposeTreeItem(HTreeItem(AChain));
       AChain := BChain; BChain := nil;
       ChainMul := true;
       exit;
     end;
   end;

   { a * (b+c+d+...) -> ab+ac+ad+... }
   if (AChain^.Kind = kd_Clip) then begin
     ATree.Init;
     BTree.Init;
     ATree.AddTree(HTreeItem(AChain^.Sub));
     BTree.AddTree(HTreeItem(BChain));

     for i := (ATree.Count-1) downto 0 do begin
       q := HChain(BTree.CopyItem(0));
       p := HChain(ATree.CutItem(i));
       if not ChainMul(p, q) then begin
         p^.Next := q;
         p := NewChain(kd_Mul, p, nil);
       end;
       ATree.InsertItem(HTreeItem(p), i);
     end;

     p := AChain^.Next;
     AChain := HChain(ATree.FirstItem);
     if not (AChain^.Next = nil)
      then AChain := NewChain(kd_Clip, AChain, p)
      else AChain^.Next := p;
     BChain := nil;
     BTree.Done;
     ATree.ReleaseDone;
     ChainMul := true;
     exit;
   end;

   { Nun folgen einige Spezialfaelle von Funktionen, }
   { die ebenfalls zusammengefasst werden.           }
   i := AChain^.Kind;
   if (i = BChain^.Kind) and (i = kd_Mul) then begin    { (x*y)*(z*q)=x*y*z*q }
     p := AChain^.Sub;
     ConcatLists(HListItem(p), HListItem(BChain^.Sub));
     Dispose(BChain);
     ChainMul := true; exit;
   end;

   if (i = BChain^.Kind) and (i = kd_exp) then begin
     ConcatLists(HListItem(AChain^.Sub), HListItem(BChain^.Sub));  { (e^x)*(e^y) = e^(x+y) }
     Dispose(BChain);
     ChainMul := true; exit;
   end;

   if (i = BChain^.Kind) and ((i >= kd_Inv) and (i <= kd_Fakul)) then begin
     p := NewChain(kd_Clip, BChain^.Sub, nil);     { Fuer gewisse Funktionen gilt: }
     p := NewChain(kd_Clip, AChain^.Sub, p);       { f(x)*f(y) = f(x*y) }
     p := NewChain(kd_Mul, p, nil);                { Zu diesen Funktion gehoeren: }
     p := NewChain(i, p, AChain^.Next);            { inv, sqr, sqrt, kb, kbrt }
     Dispose(AChain);
     Dispose(BChain);
     AChain := p;
     ChainMul := true; exit;
   end;

   if (i = BChain^.Kind) and (i = kd_Neg) then begin
     p := NewChain(kd_Clip, BChain^.Sub, nil);        { (-x)*(-y) = x*y }
     p := NewChain(kd_Clip, AChain^.Sub, p);
     p := NewChain(kd_Mul, p, AChain^.Next);
     Dispose(AChain);
     Dispose(BChain);
     AChain := p;
     ChainMul := true; exit;
   end;

   if (i = kd_Inv) then begin                         { (1/x)*y = (y/x) }
     p := AChain^.Next;
     BChain^.Next := AChain^.Sub;
     Dispose(AChain);
     AChain := NewChain(kd_Div, BChain, p);
     BChain := nil;
     ChainMul := true; exit;
   end;

   if (BChain^.Kind = kd_Inv) then begin              { x*(1/y) = x/y }
     p := AChain^.Next;
     AChain^.Next := BChain^.Sub;
     AChain := NewChain(kd_Div, AChain, p);
     Dispose(BChain);
     ChainMul := true; exit;
   end;

   ChainMul := false;
 end;

 procedure ChainPot(var AChain: HChain);
 var
   ATree, BTree: LTree;
   p,q: HChain;
   v  : Boolean;
   l  : LongInt;
 begin
   if GlobalError.IsError or (AChain = nil) then exit;

   p := AChain^.Sub;                                            { Eine Klammer kann nur }
   p := p^.Next;                                                { mit einer ganzen Zahl }
   if not ((p^.Kind = kd_Number) and (p^.Next = nil)) then exit;{ potenziert werden. }
   if not (p^.Sub = nil) or not (RZero(HNumber(p)^.Value.Imag)) then exit;
   l := SRealToInt(HNumber(p)^.Value.Real);
   if (l = 0) then begin
     if RZero(HNumber(p)^.Value.Real) then begin
       DisposeTreeItem(HTreeItem(AChain));
       AChain := LdChain(1);
     end;
     exit;
   end;

   v := (l < 0);        { Die Potenz nun in eine Multiplikationskette }
   l := abs(l);         { umwandeln (x^n = x*x*x*...). }

   ATree.Init;
   BTree.Init;
   ATree.AddTree(HTreeItem(AChain^.Sub));

   for l := 1 to l do BTree.AddItem(ATree.CopyItem(0));

   ATree.Done;
   AChain^.Kind := kd_Mul;
   AChain^.Sub := HChain(BTree.FirstItem);
   UniteChains(AChain);

   if v then AChain := NewChain(kd_Inv, AChain, nil);
 end;

 function LdChain(i: Integer): HChain;
 var
   a: SReal;
 begin
   IntToSReal(a, i);
   LdChain := HChain(NewNumberRe(a, nil, nil));
 end;
 { ****************************************************** }

{ ************************************************************************** }
END.
{ ************************************************************************** }