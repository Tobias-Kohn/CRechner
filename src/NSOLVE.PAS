{ ************************************************************************** }
{  Routinen, die Gleichungen 1.-4. Grades loesen.                            }
{ ************************************************************************** }
{  Solving equations of 1-4 level.                                           }
{ ************************************************************************** }
{                                                                            }
{                       (c) 1999/2000, Tobias Kohn                           }
{                                Version 2.0                                 }
{                                                                            }
{ ************************************************************************** }
{$G+}             { 286-Codes }
unit NSolve;
{ ************************************************************************** }
interface
 uses NBasics, NCalcs, CRTypes, NVars, Errors, Dialogs, SysUtils,
      Classes, WinProcs, CRConv, Lists, CRComplx;
{ ************************************************************************** }


 CONST
   proc_Solver = $71;

   { ************************************************** }
   {  GetXPotenz Versucht, alle x auszuklammern und     }
   {              gibt die Potenz des ausgeklammerten   }
   {              x zurueck.                            }
   {  FindChainVar  Prueft, ob die Variable AName ir-   }
   {              gendwo im Term enthalten ist.         }
   {  SplitUpChain  Erzeugt die Normalform.             }
   {                                                    }
   {  GetEquatLevel Ermittelt den Grad der Gleichung.   }
   { ************************************************** }
   function GetXPotenz(var AChain: HCHain): Integer;
   function FindChainVar(AChain: HChain; AName: char): boolean;
   procedure SplitUpChain(var AChain: HChain);

   function GetEquatLevel(var AChain: HChain): byte;

   { ************************************************** }
   {  SolveEquat Versucht, die Gleichung (AChain=0) zu  }
   {              loesen. AChain muss vorher mit den    }
   {              obigen Hilfsroutinen in die "Normal-  }
   {              Form" gebracht worden sein. ANr gibt  }
   {              die Nummer der Loesung an (1..4).     }
   {  SolveEquat3  Loest Gleichungen dritten Grades.    }
   {              Diese Routine wird von SolveEquat     }
   {              aufgerufen, sie ist nicht fuer den    }
   {              internen Gebrauch gedacht.            }
   {  SolveEquat4  Loest Gleichungen vierten Grades.    }
   { ************************************************** }
   procedure SolveEquat(var AChain: HChain; ANr: byte);

   function SolveEquat3(var ACh2, ACh1, ACh0: HChain; ANr: Byte): HChain;
   function SolveEquat4(var ACh3, ACh2, ACh1, ACh0: HChain; ANr: Byte): HChain;

   { ************************************************** }
   {  Folgendes System dient dazu, wenn gewuenscht,     }
   { weitere Informationen ueber die Gleichungen anzu-  }
   { zeigen (beispielsweise die Determinante).          }
   { ************************************************** }
   {  AddSecInfo Fuegt den String AStr der Liste        }
   {              SecInfos an, sofern das Flag SecInfo- }
   {              flag gesetzt ist.                     }
   { ************************************************** }
   procedure AddSecInfo(const AStr: string);

   const
     SecInfoFlag: boolean = false;

   var
     SecInfos: TStringList;

   { ************************************************** }
   {  Eine Gleichung n-ten Grades besitzt in C genau n  }
   { Loesungen (wobei manche auch zusammenfallen koen-  }
   { nen). Es beansprucht aber jedesmal Rechenzeit, die }
   { ganzen Formeln durchzurechnen, deshalb werden die  }
   { Zwischenergebnisse abgespeichert und spaeter       }
   { weiterbenutzt.                                     }
   { ************************************************** }
   {  InitSolver Setzt die folgenden Felder zurueck.    }
   {  DoneSolver Gibt den Benutzten Speicherplatz       }
   {              wieder frei.                          }
   { ************************************************** }
 TYPE
   TSolveRec = record                                  { Dieser Record nimmt die }
     u,v,D: HChain;                                    { Zwischen-Variablen beim }
     p,q,r: HChain;                                    { Lösen der Gleichungen auf. }
     b2   : HChain;                                    { Dadurch wird das Lösen sehr }
   end;                                                { viel schneller. }

 var
   SolveRec3: TSolveRec;
   SolveRec4: TSolveRec;

   procedure InitSolver;
   procedure DoneSolver;

{ ************************************************************************** }
implementation
{ ************************************************************************** }

 function GetXPotenz(var AChain: HCHain): Integer;
 var
   Buffer: Integer;
   p: HChain;
 begin
   if GlobalError.IsError or (AChain = nil) then begin
     GetXPotenz := 0; exit;
   end;

   Buffer := 0;
   if (AChain^.Kind = kd_Number) then begin
     Buffer := GetVarPotenz(HNumber(AChain), 'x');
     DeleteVar(HNumber(AChain), 'x');
     GetXPotenz := Buffer;
     exit;
   end;

   p := AChain^.Sub;
   if (AChain^.Kind = kd_Add) then begin              { Addition }
     Buffer := GetXPotenz(p);
     p := p^.Next;
     DeleteVar(HNumber(p), 'x');
     while not (p = nil) do begin
       if not (Buffer = GetXPotenz(p)) then begin
         GlobalError.SetError(er_Equat, $01);
         GetXPotenz := 0; exit;
       end;
       DeleteVar(HNumber(p), 'x');
       p := p^.Next;
     end;
   end;

   if (AChain^.Kind = kd_Mul) then                    { Multiplikation }
    while not (p = nil) do begin
      Buffer := Buffer + GetXPotenz(p);
      DeleteVar(HNumber(p), 'x');
      p := p^.Next;
    end;

   if (AChain^.Kind = kd_Div) then begin              { Division }
     Buffer := GetXPotenz(p) - GetXPotenz(p^.Next);
     DeleteVar(HNumber(p^.Next), 'x');
     DeleteVar(HNumber(p), 'x');
   end;

   if (AChain^.Kind = kd_Inv)                         { Inverses }
    then Buffer := -GetXPotenz(HChain(AChain^.Sub));

   GetXPotenz := Buffer;
   exit;
 end;

 function FindChainVar(AChain: HChain; AName: char): boolean;
 var
   p: HChain;
 begin
   if GlobalError.IsError or (AChain = nil) then begin
     FindChainVar := false;
     exit;
   end;

   if (AChain^.Kind = kd_Number) then begin
     FindChainVar := (GetVarPotenz(HNumber(AChain), AName) > 0);
     exit;
   end;

   p := AChain^.Sub;
   while not (p = nil) do begin
     if FindChainVar(p, AName) then begin
       FindChainVar := true;
       exit;
     end;
     p := p^.Next;
   end;
   FindChainVar := false;
 end;

 procedure SplitUpChain(var AChain: HChain);
 var
   xvars: Array[0..4] of HChain;
   i: Byte;
   p,q: HChain;
 begin
   if GlobalError.IsError or (AChain = nil) then exit;

   for i := 0 to 4 do xvars[i] := nil;

   if not (AChain^.Kind = kd_Clip) then begin
     i := GetXPotenz(AChain);
     if (i < 0) or (i > 4) then GlobalError.SetError(er_Equat, $03);
     if GlobalError.IsError then exit;
     p := AChain^.Next;
     AChain^.Next := nil;
     AChain := NewChain(kd_NoX+i, AChain, p);
     exit;
   end;

   if (AChain^.Kind = kd_Clip) then begin        { Ganze Klammer: alle }
     p := AChain^.Sub;                           { Elemente einzeln behandeln. }
     while not (p = nil) do begin
       i := GetXPotenz(p);
       if (i < 0) or (i > 4) then GlobalError.SetError(er_Equat, $03);
       if GlobalError.IsError then exit;
       q := p^.Next;
       p^.Next := nil;
       ConcatChains(xvars[i], p);
       p := q;
     end;
   end;

   for i := 0 to 4 do                            { In den einzelnen Gliedern }
    if FindChainVar(xvars[i], 'x') then begin    { duerfen keine x mehr vor- }
      GlobalError.SetError(er_Equat, $04);       { handen sein. }
      exit;
    end;

   p := AChain^.Next;                            { Nun alle Elemente wieder }
   Dispose(AChain);                              { zu einer Klammer zusammen- }
   AChain := NewChain(kd_Clip, nil, p);          { fuegen. }
   AChain^.Sub := NewChain(kd_NoX, xvars[0], nil);
   p := AChain^.Sub;
   for i := 1 to 4 do begin
     if not (xvars[i] = nil) then begin
       p^.Next := NewChain(kd_NoX+i, xvars[i], nil);
       p := p^.Next;
       if (p = nil) then begin
         GlobalError.SetError(er_Equat, $05);
         exit;
       end;
     end;
   end;

   if (xvars[0] = nil) and not (AChain^.Sub = nil) then begin
     p := AChain^.Sub;
     AChain^.Sub := p^.Next;
     Dispose(p);
   end;
   if (AChain^.Sub = nil) then begin
     Dispose(AChain);
     AChain := nil;
   end;
 end;
 { ****************************************************** }

 function GetEquatLevel(var AChain: HChain): byte;
 var
   i: Byte;
   p: HChain;
 begin
   if GlobalError.IsError or (AChain = nil) or not (AChain^.Kind = kd_Clip)
    then begin
     GetEquatLevel := 0;
     exit;
   end;

   i := 0;
   p := AChain^.Sub;
   while not (p = nil) do begin
     if ((p^.Kind-kd_NoX) > i) then i := (p^.Kind-kd_NoX);
     p := p^.Next;
   end;
   GetEquatLevel := i;
 end;
 { ****************************************************** }

 procedure SolveEquat(var AChain: HChain; ANr: byte);
 var
   xvars: array[0..4] of HChain;

  procedure DelXVars;    { Hilsroutine: entfernt die lokalen }
  var                    { Variablen wieder vom Heap. }
    i: Byte;
  begin
    for i := 0 to 4 do
     if not (xvars[i] = nil) then DisposeTreeItem(HTreeItem(xvars[i]));
    GlobalError.LeaveProc;
  end;

 var
   p,q,r,s: HChain;
   i,j: Byte;
   BiQuad: Boolean;
 begin
   if GlobalError.IsError or (AChain = nil) or (AChain^.Kind = kd_Number) then exit;
   GlobalError.EnterProc(proc_Solver);

   for i := 0 to 4 do xvars[i] := nil;

   p := AChain^.Sub;
   while not (p = nil) do begin
     case p^.Kind of
       kd_NoX..kd_X4: begin
         ConcatChains(xvars[p^.Kind-kd_NoX], HChain(p^.Sub));
       end;
     else
       GlobalError.SError(er_EquatError);
       DelXVars; exit;
     end;
     p := p^.Next;
   end;

   for j := 4 downto 0 do                       { Grad der Gleichung bestimmen. }
    if not (xvars[j] = nil) then break;
   if (j = 0) then begin
     GlobalError.SError(er_EquatError);
     DelXVars; exit;
   end;
   AChain := nil;

   if (j = 4) and (xvars[3] = nil) and (xvars[1] = nil) then begin
     xvars[1] := xvars[2];                      { Eine Biquadratische Gleichung }
     xvars[2] := xvars[4];                      { wie eine Quadratische loesen. }
     xvars[4] := nil;
     j := 2;
     BiQuad := True;
   end else BiQuad := False;

   if (xvars[0] = nil) and (j = 2) then         { Je nach Gleichung ist eine }
    if (ANr = 2) or (xvars[1] = nil) then begin{ Loesung sicher gleich Null. }
      AChain := LdChain(0);
      DelXVars; exit;
    end;

   for i := 0 to (j-1)                          { Fehlende Koeffizienten auf }
    do if (xvars[i] = nil)                      { 0 setzen, und alle Klammern }
     then xvars[i] := LdChain(0)                { als solche Kennzeichnen. }
     else if not (xvars[i]^.Next = nil)
      then xvars[i] := NewChain(kd_Clip, xvars[i], nil);

{   for i := 0 to 4 do
    if not (xvars[i] = nil) then
     MessageDlg(IntToStr(i)+': '+ChainToStr(xvars[i]), mtInformation, [mbOK], 0);}

   { **************** 1. Grades **************** }
   if (j = 1) then begin
     if not (ANr = 1) then begin
       DelXVars; exit;
     end;

     AChain := NewChain(kd_Neg, CopyChain(xvars[0]), nil);
     AChain^.Next := CopyChain(xvars[1]);                 { x = -b/a }
     AChain := NewChain(kd_Div, AChain, nil);
   end;

   { **************** 2. Grades **************** }
   if (j = 2) and not (xvars[1] = nil) then begin
     if ((ANr > 2) or (ANr < 1)) and not BiQuad then begin
       DelXVars; exit;
     end;
     if SecInfoFlag and (ANr = 1)
      then SecInfos.Add(' ================ ');

     r := CopyChain(xvars[0]);                  { q = -4ac }
     q := CopyChain(xvars[2]);
     r^.Next := LdChain(-4);
     q^.Next := r;
     q := NewChain(kd_Mul, q, nil);

     p := NewChain(kd_sqr, CopyChain(xvars[1]), q);
     p := NewChain(kd_Sqrt, p, nil);            { p = sqrt(b^2-4ac) }

     if SecInfoFlag and (ANr = 1) then begin    { Zusatzinformationen }
       q := CopyChain(p);                       { anzeigen... }
       q^.Kind := kd_Clip;
       UniteChains(q);
       UniteChains(q);
       SecInfos.Add(' D = '+ChainToStr(q));
       DisposeTreeItem(HTreeItem(q));
     end;

     if ((ANr = 2) and not BiQuad) or ((ANr > 2) and BiQuad)
      then p := NewChain(kd_Neg, p, nil);
     UniteChains(p);

     if GlobalError.IsError then begin   { Fehler abfangen. }
       DelXVars; exit;
     end;

     q := NewChain(kd_Neg, CopyChain(xvars[1]), p);
     p := NewChain(kd_Clip, q, nil);                  { p = -b+D }
     q := CopyChain(xvars[2]);                        { q = 2a }
     q^.Next := LdChain(2);
     q := NewChain(kd_Mul, q, nil);

     p^.Next := q;                              { AChain = (-b+D)/(2a) }
     AChain := NewChain(kd_Div, p, nil);
     p := nil; q := nil;

     if BiQuad then begin                         { Diese Prozedur soll auch Bi- }
       AChain := NewChain(kd_sqrt, AChain, nil);  { quadratische Gleichungen loesen. }
       if (ANr = 2) or (ANr = 4) then AChain := NewChain(kd_Neg, AChain, nil);
     end;

     if SecInfoFlag and (ANr = 1)
      then SecInfos.Add(' ================ ');
   end;
   { **************** 2. Grades **************** }
   if (j = 2) and (xvars[1] = nil) then begin
     if ((ANr > 2) or (ANr < 1)) and not BiQuad then begin
       DelXVars; exit;
     end;

     p := CopyChain(xvars[0]);
     q := CopyChain(xvars[2]);
     p^.Next := q;
     p := NewChain(kd_Div, p, nil);
     AChain := NewChain(kd_Neg, p, nil);
     AChain := NewChain(kd_sqrt, p, nil);
     p := nil; q := nil;

     if ((ANr = 2) and not BiQuad) or ((ANr > 2) and BiQuad)
      then AChain := NewChain(kd_Neg, AChain, nil);
     if BiQuad then begin
       AChain := NewChain(kd_sqrt, AChain, nil);
       if (ANr = 2) or (ANr = 4) then AChain := NewChain(kd_Neg, AChain, nil);
     end;
   end;

   { **************** 3. Grades **************** }
   if (j = 3) then begin
     if SecInfoFlag and (ANr = 1)
      then SecInfos.Add(' ================ ');
     p := xvars[2];                              { Bei einer Gleichung in }
     p^.Next := CopyChain(xvars[3]);             { Normalform werden alle }
     p := NewChain(kd_Div, p, nil);              { Koeffizienten durch a  }
     r := xvars[1];                              { dividiert, sodass      }
     r^.Next := CopyChain(xvars[3]);             {  x^3+b'x^2+c'xx+d' = 0 }
     r := NewChain(kd_Div, r, nil);              { ensteht.               }
     q := xvars[0];
     q^.Next := CopyChain(xvars[3]);
     q := NewChain(kd_Div, q, nil);
     AChain := SolveEquat3(p, r, q, ANr);
     if SecInfoFlag and (ANr = 1)
      then SecInfos.Add(' ================ ');
   end;

   { **************** 4. Grades **************** }
   if (j = 4) then begin
     if SecInfoFlag and (ANr = 1)
      then SecInfos.Add(' ================ ');
     p := xvars[3];                              { Bei einer Gleichung in }
     p^.Next := CopyChain(xvars[4]);             { Normalform werden alle }
     p := NewChain(kd_Div, p, nil);              { Koeffizienten durch a  }
     r := xvars[2];                              { dividiert, sodass      }
     r^.Next := CopyChain(xvars[4]);             {  x^3+b'x^2+c'xx+d' = 0 }
     r := NewChain(kd_Div, r, nil);              { ensteht.               }
     q := xvars[1];
     q^.Next := CopyChain(xvars[4]);
     q := NewChain(kd_Div, q, nil);
     s := xvars[0];
     s^.Next := CopyChain(xvars[4]);
     s := NewChain(kd_Div, s, nil);
     AChain := SolveEquat4(p, r, q, s, ANr);
     if SecInfoFlag and (ANr = 1)
      then SecInfos.Add(' ================ ');
   end;

   DelXVars;
   if not (AChain = nil) then UniteChains(AChain);
 end;

 function SolveEquat3(var ACh2, ACh1, ACh0: HChain; ANr: Byte): HChain;
 var
   p,q,D: HChain;
   r,s,t: HChain;
   u,v,b2: HChain;
   Buffer: HChain;
   ARN: Word;
   i: byte;
 begin
   if GlobalError.IsError or (ANr > 3) or (ANr < 1) then begin
     SolveEquat3 := nil; exit;
   end;

   p := CopyChain(SolveRec3.p);   u := CopyChain(SolveRec3.u);
   q := CopyChain(SolveRec3.q);   D := CopyChain(SolveRec3.D);
   s := nil; t := nil;
   Buffer := nil;

   if (u = nil) then begin
     b2 := CopyChain(ACh2);               { b2 = (b/3) }
     r := LdChain(3);
     b2^.Next := r;
     b2 := NewChain(kd_Div, b2, nil);
     if (b2 = nil) then begin
       GlobalError.SetError(er_EquatError, $00);
       SolveEquat3 := nil; exit;
     end;

     UniteChains(b2);
     SolveRec3.b2 := CopyChain(b2);

     p := CopyChain(ACh1);                { p = (c/3)-(b/3)^2 }
     p^.Next := LdChain(3);
     p := NewChain(kd_Div, p, nil);
     s := CopyChain(b2);
     s := NewChain(kd_sqr, s, nil);
     s := NewChain(kd_Neg, s, nil);
     p^.Next := s;
     p := NewChain(kd_Clip, p, nil);
     UniteChains(p);
     UniteChains(p);
     r := nil; s := nil;
     if secInfoflag and (ANr = 1) then SecInfos.Add(' p = '+ ChainToStr(p));
     SolveRec3.p := CopyChain(p);

     q := CopyChain(ACh0);                { q = (d/2)+(b/3)^3-(bc/6) }
     q^.Next := LdChain(2);
     q := NewChain(kd_Div, q, nil);

     r := CopyChain(b2);
     r := NewChain(kd_kb, r, nil);
     s := CopyChain(ACh2);
     s^.Next := CopyChain(ACh1);
     s := NewChain(kd_Mul, s, nil);

     s^.Next := LdChain(6);
     s := NewChain(kd_Div, s, nil);
     s := NewChain(kd_Neg, s, nil);

     r^.Next := s;
     q^.Next := r;
     q := NewChain(kd_Clip, q, nil);
     UniteChains(q);
     UniteChains(q);
     r := nil; s := nil; t := nil;
     if secInfoflag and (ANr = 1) then SecInfos.Add(' q = '+ ChainToStr(q));
     SolveRec3.q := CopyChain(q);

     D := CopyChain(q);                 { D = q^2 + p^3 }
     D := NewChain(kd_sqr, D, nil);
     r := CopyChain(p);
     r := NewChain(kd_kb, r, nil);
     D^.Next := r;
     D := NewChain(kd_Clip, D, nil);

     D := NewChain(kd_sqrt, D, nil);    { D = sqrt(D) }
     UniteChains(D);
     UniteChains(D);
     if secInfoflag and (ANr = 1) then SecInfos.Add(' D = '+ ChainToStr(D));
     SolveRec3.D := CopyChain(D);

     u := CopyChain(D);                   { u = -q + D }
     r := CopyChain(q);
     r := NewChain(kd_Neg, r, nil);
     r^.Next := u;
     u := NewChain(kd_Clip, r, nil);

     UniteChains(u);                      { Zf }
     UniteChains(u);
     SolveRec3.u := CopyChain(u);
   end else b2 := CopyChain(SolveRec3.b2);

   ARN := RootNumber;
   RootNumber := ANr - 1;
   u := NewChain(kd_kbrt, u, nil);
   if secInfoflag and (ANr = 1) then SecInfos.Add(' u = '+ ChainToStr(u));

   if not ((u^.Kind = kd_Number) and CZero(HNumber(u)^.Value)) then begin
     v := CopyChain(u);                   { v = -p/u }
     r := CopyChain(p);
     r := NewChain(kd_Neg, r, nil);
     r^.Next := v;
     v := NewChain(kd_Div, r, nil);
     r := nil;
     if secInfoflag and (ANr = 1) then SecInfos.Add(' v = '+ ChainToStr(v));
   end else v := CopyChain(u);

   Buffer := nil;
   r := NewChain(kd_Neg, b2, nil);
   v^.Next := r;
   u^.Next := v;
   Buffer := NewChain(kd_Clip, u, nil);
   UniteChains(Buffer);
   UniteChains(Buffer);

   DisposeTreeItem(HTreeItem(p));
   DisposeTreeItem(HTreeItem(q));
   DisposeTreeItem(HTreeItem(D));

   RootNumber := ARN;
   SolveEquat3 := Buffer;
 end;

 function SolveEquat4(var ACh3, ACh2, ACh1, ACh0: HChain; ANr: Byte): HChain;

  function ZeroChain(AChain: HChain): boolean;
  begin
    if GlobalError.IsError or (AChain = nil) then begin
      ZeroChain := true; exit;
    end;

    if (AChain^.Kind = kd_Number)
     then ZeroChain := CZero(HNumber(AChain)^.Value)
     else ZeroChain := false;
  end;

 var
   p,q,r : HChain;
   D,a1  : HChain;
   a2,a3 : HChain;
   a4    : HChain;
   u,v,w : HChain;
   b2    : HChain;
   ARN   : Word;
   SIBuffer: Boolean;
 begin
   if GlobalError.IsError or (ANr > 4) or (ANr < 1) then begin
     SolveEquat4 := nil; exit;
   end;

   SIBuffer := SecInfoFlag;
   p := CopyChain(SolveRec4.p);    q := CopyChain(SolveRec4.q);
   D := CopyChain(SolveRec4.D);    r := CopyChain(SolveRec4.r);
   u := CopyChain(SolveRec4.u);    v := CopyChain(SolveRec4.v);
   a1 := nil; a2 := nil; a3 := nil; a4 := nil;

   if (u = nil) and (v = nil) then begin
     b2 := CopyChain(ACh3);              { b2 = b/4 }
     b2^.Next := LdChain(4);
     b2 := NewChain(kd_Div, b2, nil);
     if (b2 = nil) then begin
       GlobalError.SetError(er_EquatError, $00);
       SolveEquat4 := nil; exit;
     end;
     SolveRec4.b2 := CopyChain(b2);

     a1 := LdChain(-6);                  { p = (-6*(b/4)^2)+c }
     p := NewChain(kd_Sqr, CopyChain(b2), nil);
     a1^.Next := p;
     p := NewChain(kd_Mul, a1, nil);
     a1 := CopyChain(ACh2);
     a1^.Next := p;
     p := NewChain(kd_Clip, a1, nil);
     UniteChains(p);
     if SecInfoFlag and (ANr = 1)
      then SecInfos.Add(' p = '+ChainToStr(p));
     SolveRec4.p := CopyChain(p);

     q := CopyChain(ACh3);               { q = ((b/2)^3)-(bc/2)+d }
     q^.Next := LdChain(2);
     q := NewChain(kd_Div, q, nil);
     q := NewChain(kd_kb,  q, nil);

     a1 := CopyChain(ACh3);
     a1^.Next := CopyChain(ACh2);
     a2 := LdChain(-1);
     AddExpon(HNumber(a2)^.Value.Real, -1);
     a2^.Next := a1;
     a1 := NewChain(kd_Mul, a2, nil);

     a1^.Next := CopyChain(ACh1);
     q^.Next := a1;
     q := NewChain(kd_Clip, q, nil);

     UniteChains(q);
     if SecInfoFlag and (ANr = 1)
      then SecInfos.Add(' q = '+ChainToStr(q));
     SolveRec4.q := CopyChain(q);

     r := NewChain(kd_sqr, CopyChain(b2), nil);
     r := NewChain(kd_sqr, r, nil);      { r = (-3*(b/4)^4)+((b/4)^2*c)-((b/4)*d)+e }
     r^.Next := LdChain(-3);
     r := NewChain(kd_Mul, r, nil);

     a1 := NewChain(kd_sqr, CopyChain(b2), nil);
     a2 := CopyChain(ACh2);
     a1^.Next := a2;
     a1 := NewChain(kd_Mul, a1, nil);

     a2 := CopyChain(b2);
     a2^.Next := CopyChain(ACh1);
     a2 := NewChain(kd_Mul, a2, nil);
     a2 := NewChain(kd_Neg, a2, nil);
     a1^.Next := a2;
     r^.Next := a1;
     r := NewChain(kd_Clip, r, nil);

     a2^.Next := CopyChain(ACh0);
     UniteChains(r);
     if SecInfoFlag and (ANr = 1)
      then SecInfos.Add(' r = '+ChainToStr(r));
     SolveRec4.r := CopyChain(r);

     if ZeroChain(q) and ZeroChain(r) then begin
       DisposeTreeItem(HTreeItem(p));
       DisposeTreeItem(HTreeItem(q));
       DisposeTreeItem(HTreeItem(r));
       b2 := NewChain(kd_Neg, b2, nil);
       UniteChains(b2);
       SolveEquat4 := b2;
       exit;
     end;

     a1 := CopyChain(p);                     { a1 = 2p }
     a1^.Next := LdChain(2);
     a1 := NewChain(kd_Mul, a1, nil);
     UniteChains(a1);

     a2 := NewChain(kd_sqr, CopyChain(p), nil);{ a2 = p^2-4r }
     a3 := CopyChain(r);
     a3^.Next := LdChain(-4);
     a3 := NewChain(kd_Mul, a3, nil);
     a2^.Next := a3;
     a2 := NewChain(kd_Clip, a2, nil);
     UniteChains(a2);

     if not ZeroChain(q) then begin
       a3 := NewChain(kd_sqr, CopyChain(q), nil);{ a3 = -q^2 }
       a3 := NewChain(kd_neg, a3, nil);
       UniteChains(a3);
     end else a3 := CopyChain(q);

     SecInfoFlag := false;
     u := SolveEquat3(a1, a2, a3, 1);
     v := SolveEquat3(a1, a2, a3, 2);
     SecInfoFlag := SIBuffer;
     DisposeTreeItem(HTreeItem(a1));
     DisposeTreeItem(HTreeItem(a2));
     DisposeTreeItem(HTreeItem(a3));
     if (u = nil) or (v = nil) then begin
       GlobalError.SetError(er_EquatError, $00);
       SolveEquat4 := nil; exit;
     end;

     u := NewChain(kd_sqrt, u, nil);
     v := NewChain(kd_sqrt, v, nil);
     if SecInfoFlag and (ANr = 1)
      then SecInfos.Add(' u1 = '+ChainToStr(u));
     if SecInfoFlag and (ANr = 1)
      then SecInfos.Add(' u2 = '+ChainToStr(v));
     SolveRec4.u := CopyChain(u);
     SolveRec4.v := CopyChain(v);
   end else b2 := CopyChain(SolveRec4.b2);

   if ZeroChain(q) and ZeroChain(r) then begin
     DisposeTreeItem(HTreeItem(p));
     DisposeTreeItem(HTreeItem(q));
     DisposeTreeItem(HTreeItem(r));
     b2 := NewChain(kd_Neg, b2, nil);
     UniteChains(b2);
     SolveEquat4 := b2;
     exit;
   end;
   if ZeroChain(q) then begin
     a3 := NewChain(kd_NoX,CopyChain(r), nil);
     a2 := NewChain(kd_x1, CopyChain(p), a3);
     a1 := NewChain(kd_x2, LdChain(1),   a2);
     a1 := NewChain(kd_Clip, a1, nil);
     if (ANr > 2)
      then SolveEquat(a1, ANr-2)
      else SolveEquat(a1, ANr);
     a1 := NewChain(kd_sqrt, a1, nil);
     if (ANr > 2)
      then a1 := NewChain(kd_Neg, a1, nil);
     a1^.Next := b2;
     a1 := NewChain(kd_Clip, a1, nil);
     SolveEquat4 := NewChain(kd_Neg, a1, nil);
     exit;
   end;

   a1 := LdChain(1);
   AddExpon(HNumber(a1)^.Value.Real, -1);
   if (ANr > 2)
    then CNeg(HNumber(a1)^.Value);

   a2 := CopyChain(u);
   a3 := CopyChain(v);
   a2^.Next := a3;
   a2 := NewChain(kd_Mul, a2, nil);
   a3 := CopyChain(q);
   a3^.Next := a2;
   a2 := NewChain(kd_Div, a3, nil);
   if (ANr = 1) or (ANr = 3)
    then a2 := NewChain(kd_Neg, a2, nil);

   a3 := CopyChain(v);
   if (ANr = 2) or (ANr = 3)
    then a3 := NewChain(kd_Neg, a3, nil);

   a4 := CopyChain(u);
   a3^.Next := a4;
   a3 := NewChain(kd_Clip, a3, nil);
   a4^.Next := a2;

   a1^.Next := a3;
   a1 := NewChain(kd_Mul, a1, nil);
   b2 := NewChain(kd_Neg, b2, nil);
   a1^.Next := b2;
   a1 := NewChain(kd_Clip, a1, nil);
   UniteChains(a1);
   SolveEquat4 := a1;
 end;
 { ****************************************************** }

 procedure AddSecInfo(const AStr: string);
 begin
   if not SecInfoFlag or GlobalError.IsError then exit;
   SecInfos.Add(AStr);
 end;
 { ****************************************************** }

 procedure InitSolver;
 begin
   FillChar(SolveRec3, SizeOf(SolveRec3), 0);
   FillChar(SolveRec4, SizeOf(SolveRec4), 0);

   SecInfos := TStringList.Create;
 end;

 procedure DoneSolver;
 begin
   if not (SolveRec3.u = nil) then DisposeTreeItem(HTreeItem(SolveRec3.u));
   if not (SolveRec3.v = nil) then DisposeTreeItem(HTreeItem(SolveRec3.v));
   if not (SolveRec3.b2 = nil) then DisposeTreeItem(HTreeItem(SolveRec3.b2));
   if not (SolveRec3.p = nil) then DisposeTreeItem(HTreeItem(SolveRec3.p));
   if not (SolveRec3.q = nil) then DisposeTreeItem(HTreeItem(SolveRec3.q));
   if not (SolveRec3.r = nil) then DisposeTreeItem(HTreeItem(SolveRec3.r));

   if not (SolveRec4.u = nil) then DisposeTreeItem(HTreeItem(SolveRec4.u));
   if not (SolveRec4.v = nil) then DisposeTreeItem(HTreeItem(SolveRec4.v));
   if not (SolveRec4.b2 = nil) then DisposeTreeItem(HTreeItem(SolveRec4.b2));
   if not (SolveRec4.p = nil) then DisposeTreeItem(HTreeItem(SolveRec4.p));
   if not (SolveRec4.q = nil) then DisposeTreeItem(HTreeItem(SolveRec4.q));
   if not (SolveRec4.r = nil) then DisposeTreeItem(HTreeItem(SolveRec4.r));

   SecInfos.Destroy;
 end;
 { ****************************************************** }

{ ************************************************************************** }
end.
{ ************************************************************************** }
