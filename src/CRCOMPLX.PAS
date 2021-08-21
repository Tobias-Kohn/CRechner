{ ************************************************************************** }
{  Diese Unit enthaelt Routinen und Definitionen vor allem zum Rechnen mit   }
{ Komplexen Zahlen.                                                          }
{ ************************************************************************** }
{  Routines for calculations with complex numbers.                           }
{ ************************************************************************** }
{                                                                            }
{                       (c) 1998/2000, Tobias Kohn                           }
{                             VERSION 3.0                                    }
{                                                                            }
{ ************************************************************************** }
{$N+,E-}             { Koprozessor benutzen }
{$G+}                { Code fuer 286 erzeugen }
UNIT CRComplx;
{ ************************************************************************** }
INTERFACE
 USES CRTypes, CRMathe, CRM_Ext, CRConv;

 const
   RootNumber : Word = 0;               { Bei Komplexen Wurzeln existieren }
                                        { jeweils n Loesungen. Diese Zahl hier }
                                        { gibt an, die wievielte CRootZ    }
                                        { berechnen soll.                  }
   WriteZero  : Boolean = False;        { Gibt an, ob die Funktion CComplex- }
                                        { toStr auch Zahlen ausgeben soll, die }
                                        { Null sind. }
   c_cis = ' cis ';                     { Gibt an, was bei der Umwandlung }
                                        { einer Polar-komplexen Zahl zwischen }
                                        { Radius und Winkel stehen soll. }

   { ***** Fehlerbehandlung: ***** }
   ErrorVar : Integer = 0;              { Der momentan aufgetretene Fehler }

   er_NoError       = $00;              { Kein Fehler }
   er_AnyError      = $FF;              { Unbekannter Fehler }
   er_DivisionZero  = $FE;              { Division durch Null }
   er_Overflow      = $FD;              { Ueberlauf: Zu grosse Zahl }
   er_RootNegative  = $FC;              { Wurzel einer Negativen Zahl }

   { Fuer die Funktion "ExtToStr" }
   nt_Std   = $01;                      { ts_Std / ts_Float    Standart-Ausgabe, wobei     }
   nt_Float = $01;                      {                       Zahlen in einem gewissen   }
   nt_Sci   = $02;                      {                       Bereich ohne Exponent      }
   nt_Eng   = $03;                      {                       dargestellt werden.        }
                                        {                       Bsp: 1E3 => 1000           }
   Num_Type: Byte = nt_Std;             { ts_Sci               Wissenschaftliche Ausgabe.  }
                                        {                       Praktisch so wie bei einer }
   Num_Clip: Boolean = True;            {                       normalen Verwendung von    }
                                        {                       Str.                       }
                                        { ts_Eng               Der Exponent wird auf eine  }
                                        {                       3er-Zahl gebracht.         }
                                        {                       Bsp: 1E4 => 10E3           }
                                        { True:  Nachkomma-Nullen werden abge-     }
                                        {         schnitten. (0.0100 => 0.01)      }
                                        { False: Nachkomma-Nullen bleiben.         }

 type
   ComplexPolar = record                { Eine Komplexe Zahl in Polar- }
     Radius: SReal;                     { koordinaten. }
     Angle : SReal;
   end;
        { Ausser bei Umrechnungsfunktionen wird ueberall als Argument die }
        { Kartesische Form verlangt und auch zurueckgegeben. Diese Form    }
        { hier dient hauptsaechlich zur Verbesserung der Lesequalitaet    }
        { eines Quelltextes.                                              }

 var
   c_i : Complex;                       { Die imaginaere Einheit als }
                                        { komplexe Zahl definieren.  }

{ ************************************************************************** }

 { Umrechnen von Grad- ins Bogenmass und umgekehrt. }
 procedure DegToRad(var x: SReal);                       { Deg -> Rad }
 procedure RadToDeg(var x: SReal);                       { Rad -> Deg }

 { Liefern den Exponenten von aZahl zur 2er Basis zurÅck. }
 function GetExp2(aZahl: SReal): LongInt;

{ ************************************************************************** }
 { *** Komplexe Zahlen: *** }

 procedure CLd_0(var c: Complex);               { Laden c mit 0 bzw. 1 }
 procedure CLd_1(var c: Complex);

 function CComplexToStr(z1: Complex): String;          { Wandelt eine Komplexe Zahl }
 function CPolarToStr(z1: ComplexPolar): String;       { in einen String um. }

 { Grundfunktionen: }
 procedure CAdd(var z1: Complex; z2: Complex);         { z1 = z1 + z2 }
 procedure CSub(var z1: Complex; z2: Complex);         { z1 = z1 - z2 }
 procedure CMul(var z1: Complex; z2: Complex);         { z1 = z1 * z2 }
 procedure CDiv(var z1: Complex; z2: Complex);         { z1 = z1 / z2 }
 procedure CSqr(var z1: Complex);                      { z1 = z1˝ }
 procedure CSqrt(var z1: Complex);                     { z1 = ˚z1 }

 { Vergleichen zweier Komplexer Zahlen od. einer Zahl mit Null. }
 function CZero(z1: Complex): Boolean;                 { z1 = 0 ? }
 function CEqual(z1, z2: Complex): Boolean;            { z1 = z2 ? }

 procedure CNeg(var z1: Complex);                      { z1 = -z1 }
 procedure CAbs(var z1: Complex);                      { CAbs = |z1| }

 { Setzt eine Komplexe Zahl mit den angegebenen Werten. }
 procedure CSet(var z1: Complex; z2, z3: SReal);       { z1 = z2 + z3 * i }
 procedure CSetZero(var z1: Complex);                  { z1 = 0 }

 procedure CInv(var z1: Complex);                      { z1 = 1 / z1 }

 { Umrechnen zwischen Polar- und Kartesicher Form. }
 procedure RectToPolar(var z1: Complex);               { Kartes. -> Polar }
 procedure PolarToRect(var z1: Complex);               { Polar -> Kartes. }

 { Potenzfunktionen: }
 procedure CExpZ(var z1: Complex; z2: Integer);        { z1 = z1 ^ z2; z2 Ó Z }
 procedure CExpR(var z1: Complex; z2: SReal);          { z1 = z1 ^ z2; z2 Ó R }
 procedure CExpC(var z1: Complex; z2: Complex);        { z1 = z1 ^ z2; z2 Ó C }
 procedure CRootZ(var z1: Complex; z2: Word);          { z1 = z1 ^ (1/z2) }

 procedure CLn(var z1: Complex);                       { z1 = ln z1 }
 procedure CExp(var z1: Complex);                      { z1 = e^z1 }

 procedure CLog(var z1: Complex);                      { z1 = log z1 }
 procedure CLb(var z1: Complex);                       { z1 = lb z1 }

 { Trigonometrische Funktionen: }
 procedure CSin(var z1: Complex);                      { z1 = sin z1 }
 procedure CCos(var z1: Complex);                      { z1 = cos z1 }
 procedure CTan(var z1: Complex);                      { z1 = tan z1 }

 procedure CArcSin(var z1: Complex);                   { z1 = arcsin z1 }
 procedure CArcCos(var z1: Complex);                   { z1 = arccos z1 }
 procedure CArcTan(var z1: Complex);                   { z1 = arctan z1 }

 { Versucht, die komplexe Zahl in einen LongInt zu konvertieren. }
 { Dazu muss der Imagaerteil 0 sein und der Realteil im Bereich  }
 { eines LongInt liegen.                                         }
 function CmplxToInt(z: Complex): LongInt;

{ ************************************************************************** }
IMPLEMENTATION
 USES Basics;
{ ************************************************************************** }

 { *************************************************** }
 procedure CLd_0(var c: Complex);
 begin
   RLd_0(c.Real);
   RLd_0(c.Imag);
 end;

 procedure CLd_1(var c: Complex);
 begin
   RLd_1(c.Real);
   RLd_0(c.Imag);
 end;

 { *************************************************** }
 {  Liefert den Exponenten von aZahl als Zweierexpo-   }
 { nent (2^x ˜ y).                                     }
 { *************************************************** }
 function GetExp2(aZahl: SReal): LongInt;
 begin
   GetExp2 := aZahl.Expon;
 end;
 { *************************************************** }

 { *************************************************** }
 {  Rechnet vom Grad- ins Bogenmass um.                }
 { *************************************************** }
 procedure DegToRad(var x: SReal);
 begin
   if RZero(rm_Pi) then CalcPi;
   RMul(x, rm_Pi);
   WDiv(x, 180);
 end;
 { *************************************************** }

 { *************************************************** }
 {  Rechnet vom Bogen- ins Gradmass um.                }
 { *************************************************** }
 procedure RadToDeg(var x: SReal);
 begin
   if RZero(rm_Pi) then CalcPi;
   WMul(x, 180);
   RDiv(x, rm_Pi);
 end;
 { *************************************************** }

{ ************************************************************************** }

 { *************************************************** }
 {  Wandelt die komplexe Zahl (in Normalform) in einen }
 { String um.                                          }
 { *************************************************** }
 function CComplexToStr(z1: Complex): String;
 var
   Buffer,s: String;
   v       : Boolean;
 begin
   if GlobalError.IsError then exit;

   Buffer := SRealToStr(z1.Real);
   if RZero(z1.Real) and not WriteZero
    then Buffer := '';

   v := SReal_Neg_Abs(z1.Imag);
   s := SRealToStr(z1.Imag);
   if v
    then s := '-' + s + 'i'
    else begin
      s := s + 'i';
      if not (Buffer = '') then s := '+' + s;
    end;
   if RZero(z1.Imag) and not WriteZero
    then s := '';
   Buffer := Buffer + s;
   if (Buffer = '')
    then CComplexToStr := '0'
    else CComplexToStr := Buffer;
 end;
 { *************************************************** }

 { *************************************************** }
 {  Wandelt die Komplexe Zahl (in Polarform) in einen  }
 { String um.                                          }
 { *************************************************** }
 function CPolarToStr(z1: ComplexPolar): string;
 var
   Buffer,s: String;
 begin
   if GlobalError.IsError then exit;
   Buffer := SRealToStr(z1.Radius);
   if (AngleType = at_Deg) then RadToDeg(z1.Angle);
   s := SRealToStr(z1.Angle);
   CPolarToStr := Buffer + c_cis + s;
 end;
 { *************************************************** }

 { *************************************************** }
 {  Addiert zwei Komplexe Zahlen.                      }
 { *************************************************** }
 procedure CAdd(var z1: Complex; z2: Complex);
 begin
   RAdd(z1.Real, z2.Real);
   RAdd(z1.Imag, z2.Imag);
 end;
 { *************************************************** }

 { *************************************************** }
 {  Subtrahiert zwei Komplexe Zahlen.                  }
 { *************************************************** }
 procedure CSub(var z1: Complex; z2: Complex);
 begin
   RSub(z1.Real, z2.Real);
   RSub(z1.Imag, z2.Imag);
 end;
 { *************************************************** }

 { *************************************************** }
 {  Multipliziert zwei Komplexe Zahlen.                }
 { *************************************************** }
 procedure CMul(var z1: Complex; z2: Complex);
 var
   Buffer: Complex;
   b1,b2 : SReal;
 begin
   if GlobalError.IsError then exit;
   b1 := z1.Real;
   RMul(b1, z2.Real);
   b2 := z1.Imag;
   RMul(b2, z2.Imag);
   RSub(b1, b2);
   Buffer.Real := b1;

   b1 := z1.Real;
   RMul(b1, z2.Imag);
   b2 := z1.Imag;
   RMul(b2, z2.Real);
   RAdd(b1, b2);
   Buffer.Imag := b1;

   z1 := Buffer;
 end;
 { *************************************************** }

 { *************************************************** }
 {  Dividiert zwei Komplexe Zahlen.                    }
 { *************************************************** }
 procedure CDiv(var z1: Complex; z2: Complex);
 var
   Buffer : Complex;
   a,b1,b2: SReal;
 begin
   if GlobalError.IsError then exit;
   a := z2.Real;       b2 := z2.Imag;
   RSqr(a);            RSqr(b2);
   RAdd(a, b2);

   Buffer := z2;
   RNeg(Buffer.Imag);
   CMul(Buffer, z1);

   RDiv(Buffer.Real, a);
   RDiv(Buffer.Imag, a);
   z1 := Buffer;
 end;
 { *************************************************** }

 { *************************************************** }
 {  Quadriert eine Komplexe Zahl.                      }
 { *************************************************** }
 procedure CSqr(var z1: Complex);
 var
   Buffer: Complex;
   b1, b2: SReal;
 begin
   if GlobalError.IsError then exit;
   b1 := z1.Real;       b2 := z1.Imag;
   RSqr(b1);            RSqr(b2);
   RSub(b1, b2);
   Buffer.Real := b1;

   b1 := z1.Real;
   AddExpon(b1 ,1);
   RMul(b1, z1.Imag);
   Buffer.Imag := b1;

   z1 := Buffer;
 end;
 { *************************************************** }

 { *************************************************** }
 {  Zieht die Quadratwurzel einer Komplexen Zahl.      }
 { *************************************************** }
 procedure CSqrt(var z1: Complex);
 var
   Buffer : Complex;
   a,b1,b2: SReal;
   v : Boolean;
 begin
   if GlobalError.IsError then exit;

   if RZero(z1.Imag) then begin
     v := SReal_Neg_Abs(z1.Real);
     RSqrt(z1.Real);
     if v then begin
       z1.Imag := z1.Real;
       RLd_0(z1.Real);
     end;
     exit;
   end;

   b1 := z1.Real;       b2 := z1.Imag;
   RSqr(b1);            RSqr(b2);
   RAdd(b1, b2);
   a := b1;
   RSqrt(a);

   b1 := z1.Real;
   RAdd(b1, a);
   AddExpon(b1, -1);
   RSqrt(b1);
   Buffer.Real := b1;

   inc(b1.Expon);
   RInv(b1);
   RMul(b1, z1.Imag);
   Buffer.Imag := b1;

   z1 := Buffer;
 end;
 { *************************************************** }

 { *************************************************** }
 {  Prueft, ob z1 Null ist.                            }
 { *************************************************** }
 function CZero(z1: Complex): Boolean;
 begin
   CZero := RZero(z1.Real) and RZero(z1.Imag);
 end;
 { *************************************************** }

 { *************************************************** }
 {  Prueft, ob beide Zahlen gleich sind.               }
 { *************************************************** }
 function CEqual(z1, z2: Complex): Boolean;
 begin
   CEqual := (RCmpS(z1.Real, z2.Real) = cmp_Equal)
               and (RCmps(z1.Imag, z2.Imag) = cmp_Equal)
 end;
 { *************************************************** }

 { *************************************************** }
 {  Multipliziert die Komplexe Zahl mit -1.            }
 { *************************************************** }
 procedure CNeg(var z1: Complex);
 begin
   RNeg(z1.Real);
   RNeg(z1.Imag);
 end;
 { *************************************************** }

 { *************************************************** }
 {  Berechnet den Betrag der komplexen Zahl.           }
 { *************************************************** }
 procedure CAbs(var z1: Complex);
 begin
   RSqr(z1.Real);
   RSqr(z1.Imag);
   RAdd(z1.Real, z1.Imag);
   RSqrt(z1. Real);
   RLd_0(z1.Imag);
 end;
 { *************************************************** }

 { *************************************************** }
 {  Setzt eine Komplexe Zahl mit den beiden Kompo-     }
 { nenten.                                             }
 { *************************************************** }
 procedure CSet(var z1: Complex; z2, z3: SReal);     { z1 = z2 + z3 * i }
 begin
   z1.Real := z2;
   z1.Imag := z3;
 end;
 { *************************************************** }

 { *************************************************** }
 {  Setzt eine komplexe Zahl mit Null.                 }
 { *************************************************** }
 procedure CSetZero(var z1: Complex);
 begin
   RLd_0(z1.Real);
   RLd_0(z1.Imag);
 end;
 { *************************************************** }

 { *************************************************** }
 {  Bildet den Kehrwert der Zahl.                      }
 { *************************************************** }
 procedure CInv(var z1: Complex);
 var
   a, b1, b2 : SReal;
 begin
   if GlobalError.IsError then exit;
   if CZero(z1) then begin
     GlobalError.SetError(er_DivZero, 0);
     exit;
   end;
   b1 := z1.Real;       b2 := z1.Imag;
   RSqr(b1);            RSqr(b2);
   a := b1;
   RAdd(a, b2);

   RDiv(z1.Real, a);
   RDiv(z1.Imag, a);
   RNeg(z1.Imag);
 end;
 { *************************************************** }

 { *************************************************** }
 {  Rechnet eine Komplexe Zahl in Kartesichen Koordi-  }
 { naten in eine Zahl mit Polarkoordinaten um.         }
 { *************************************************** }
 procedure RectToPolar(var z1: Complex);
 var
   Buffer1: ComplexPolar;
   Buffer2: Complex absolute Buffer1;   { Zur einfacheren Uebertragung auf z1 }
 begin
   if GlobalError.IsError then exit;

   if RZero(z1.Real) then begin                { Division durch Null umgehen }
     if RZero(rm_Pi) then CalcPi;

     Buffer1.Angle := rm_Pi;
     AddExpon(Buffer1.Angle, -1);
     if SReal_Neg_Abs(z1.Imag)
       then WMul(Buffer1.Angle, 3);
   end else begin
     Buffer1.Angle := z1.Imag;
     RDiv(Buffer1.Angle, z1.Real);
     RArcTan(Buffer1.Angle);                     { "normale" Berechnung }
   end;
   if SReal_Neg_Abs(z1.Real)
    then RAdd(Buffer1.Angle, rm_Pi);
   CAbs(z1);
   Buffer1.Radius := z1.Real;
   z1 := Buffer2;
 end;
 { *************************************************** }

 { *************************************************** }
 {  Rechnet eine Komplexe Zahl in Polarkoordinaten in  }
 { eine Zahl mit Kartesischen Koordinaten um.          }
 { *************************************************** }
 procedure PolarToRect(var z1: Complex);
 var
   Buffer1: Complex;
   Buffer2: ComplexPolar absolute z1;
   b1, b2 : SReal;
 begin
   if GlobalError.IsError then exit;

   b1 := Buffer2.Angle;         b2 := Buffer2.Angle;
   RCos(b1);                    RSin(b2);

   Buffer1.Real := Buffer2.Radius;
   RMul(Buffer1.Real, b1);
   Buffer1.Imag := Buffer2.Radius;
   RMul(Buffer1.Imag, b2);

   z1 := Buffer1;
 end;
 { *************************************************** }

 { *************************************************** }
 {  Berechnet z1 hoch z2 (x^y).                        }
 { *************************************************** }
 procedure CExpZ(var z1: Complex; z2: Integer);
 var
   Buffer: Complex;
 begin
   if GlobalError.IsError then exit;

   if (z2 < 0) then begin               { Wenn der Exponent negativ ist, }
     if CZero(z1) then begin            { Es waere eine Division durch Null }
       GlobalError.SetError(er_DivZero, $00);  { aufgetreten. }
       Exit;                            { Prozedur abbrechen. }
     end;
     CInv(z1);                          { den Exponent positiv machen und }
     z2 := abs(z2);                     { die Basis hoch -1 rechnen. }
   end;
   RLd_1(Buffer.Real);                  { Anfangswert fuer Buffer laden. }
   RLd_0(Buffer.Imag);
   For z2 := 1 to z2 do                 { Berechnung durchfuehren. }
    CMul(Buffer, z1);
   z1 := Buffer;                        { Rueckgabewert }
 end;
 { *************************************************** }

 { *************************************************** }
 {  Berechnet z1 hoch z2 (x^y), wobei z1 Komplex ist,  }
 { und z2 Reell.                                       }
 { *************************************************** }
 procedure CExpR(var z1: Complex; z2: SReal);
 var
   Buffer: Complex;
   i,j,e : LongInt;
   a     : Complex;
 begin
   if GlobalError.IsError then exit;

   if SReal_Neg_Abs(z2) then               { Kehrwert bilden, wenn der Exponent }
    if CZero(z1) then begin                { negativ ist. }
      GlobalError.SetError(er_DivZero, $00);
      Exit;
    end else CInv(z1);
   e := z2.Expon;               { Zuerst Zahl wieder der Groessenordnung nach }
   Buffer := z1;                { annaehern. Dabei wird aExp auf eine Zahl }
   if (e >= 0) then             { zwischen 0 und 10 gebracht.             }
    For i := 1 to e do
     CSqr(Buffer)
   else
    For i := -1 downto e do
     CSqrt(Buffer);
   a := Buffer;
   for j := 0 to (MantSize-2) do
    if not (z2.Mant[j] = 0) then break;
   For j := (MantLast) downto j do        { Alle Bytes der Reihe nach behandeln }
    For i := 7 downto 0 do begin          { Ein Byte auswerten }
      if (i > 5) and (j = MantLast)
       then Continue;
      CSqrt(a);
      if TestBit(z2.Mant[j], i) then           { Wenn Bit gesetzt, dann }
       CMul(Buffer,a);                         { die Zahl erweitern. }
    end;
   z1 := Buffer;                  { Rueckgabewert Åbergeben. }
 end;
 { *************************************************** }

 { *************************************************** }
 {  Berechnet z1 hoch z2 (x^y), wobei beides komplexe  }
 { Zahlen sind.                                        }
 { *************************************************** }
 procedure CExpC(var z1: Complex; z2: Complex);
 var
   a: ComplexPolar;
   a2: Complex absolute a;
   b,c,d: SReal;
 begin
   if GlobalError.IsError then exit;

   if CZero(z2) then begin
     RLd_1(z1.Real);
     RLd_0(z1.Imag);
     exit;
   end;
   a2 := z1;

   RectToPolar(a2);
   b := a.Radius;

   RPotenz(b, z2.Real);
   c := a.Angle;
   RMul(c, z2.Imag);
   RNeg(c);
   RExp(c);
   RMul(b, c);

   c := a.Radius;
   RLn(c);
   RMul(c, z2.Imag);
   d := z2.Real;
   RMul(d, a.Angle);
   RAdd(c, d);

   d := c;
   RCos(c);             RMul(c, b);
   RSin(d);             RMul(d, b);

   z1.Real := c;
   z1.Imag := d;
 end;
 { *************************************************** }

 { *************************************************** }
 {  Berechnet die n-te Wurzel einer Komplexen Zahl.    }
 { Es existieren jeweils n verschiedene Loesungen. Mit }
 { der Variablen "RootNumber" wird festgelegt, die     }
 { wievielte Wurzel berechnet werden soll.             }
 { *************************************************** }
 procedure CRootZ(var z1: Complex; z2: Word);
 var
   Buffer: ComplexPolar;
   Buffer2: Complex absolute Buffer;
   a: SReal;
 begin
   if GlobalError.IsError then exit;

   if (z2 = 0) then begin
     GlobalError.SetError(er_DivZero, $00);  { Division durch Null verhindern. }
     exit;
   end;
   Buffer2 := z1;
   RectToPolar(Buffer2);                { Umrechnen in Polarform }

   WDiv(Buffer.Angle, z2);

   a := rm_Pi; AddExpon(a, 1);          { phi' := phi / z2 }
   WMul(a, RootNumber);
   WDiv(a, z2);
   RAdd(Buffer.Angle, a);

   RRootZ(Buffer.Radius, z2);           { r' = r^(1/z2) }

   PolarToRect(Buffer2);                { Zurueckrechnen in Kartesische Form }
   z1 := Buffer2;
 end;
 { *************************************************** }

 { *************************************************** }
 {  Berechnet den natuerlichen Logarithmus einer Kom-  }
 { plexen Zahl.                                        }
 { *************************************************** }
 procedure CLn(var z1: Complex);
 var
   Buffer: ComplexPolar;
   Buffer2: Complex absolute Buffer;
 begin
   if GlobalError.IsError then exit;

   if CZero(z1) then begin
     GlobalError.SetError(er_LnZero, $00);{ Ln 0 ist nicht definiert ! }
     exit;
   end;
   Buffer2 := z1;
   RectToPolar(Buffer2);
   z1.Real := Buffer.Radius;
   RLn(z1.Real);
   z1.Imag := Buffer.Angle;
 end;
 { *************************************************** }

 { *************************************************** }
 {  Berechnet e hoch dem Argument im Komplexen. Siehe  }
 { auch Turbo Pascal Hilfe fÅr "Exp".                  }
 { *************************************************** }
 procedure CExp(var z1: Complex);
 begin
   if GlobalError.IsError then exit;
   RExp(z1.Real);
   PolarToRect(z1);
 end;
 { *************************************************** }

 { *************************************************** }
 {  Der Logarithmus zur Basis 10.                      }
 { *************************************************** }
 procedure CLog(var z1: Complex);
 begin
   if GlobalError.IsError then exit;
   if CZero(z1) then begin
     GlobalError.SetError(er_LnZero, $00);
     exit;
   end;

   if RZero(rm_ln10) then CalcConsts1;
   CLn(z1);
   RDiv(z1.Real, rm_ln10);
   RDiv(z1.Imag, rm_ln10);
 end;
 { *************************************************** }

 { *************************************************** }
 {  Der Logarithmus zur Basis 2.                       }
 { *************************************************** }
 procedure CLb(var z1: Complex);
 begin
   if GlobalError.IsError then exit;
   if CZero(z1) then begin
     GlobalError.SetError(er_LnZero, $00);
     exit;
   end;

   if RZero(rm_ln2) then CalcConsts1;
   CLn(z1);
   RDiv(z1.Real, rm_ln2);
   RDiv(z1.Imag, rm_ln2);
 end;
 { *************************************************** }

 { *************************************************** }
 {  Berechnet den Sinus einer komplexen Zahl.          }
 { *************************************************** }
 procedure CSin(var z1: Complex);
 var
   a,b: Complex;
   c,d: SReal;
 begin
   if GlobalError.IsError then exit;

   if RZero(z1.Imag) then begin     { Wenn der Imaginaerteil Null ist, }
     RSin(z1.Real);                 { genuegt eine reelle Berechnung. }
     exit;
   end;
   a := z1;                     { sin a = (e^(-ia)-e^(ia))/(-2i) }
   CDiv(a, c_i);
   CExp(a);
   b := z1;
   CMul(b, c_i);
   CExp(b);
   RRound(a.Real); RRound(a.Imag);
   RRound(b.Real); RRound(b.Imag);
   CSub(a, b);
   RLd_0(c);            { 0 }
   RLd_1(d);            { -2 }
   AddExpon(d,1);
   RNeg(d);
   CSet(b, c, d);
   CDiv(a, b);
   z1 := a;
 end;
 { *************************************************** }

 { *************************************************** }
 {  Berechnet den Cosinus einer Komplexen Zahl.        }
 { *************************************************** }
 procedure CCos(var z1: Complex);
 var
   a,b: Complex;
   c,d: SReal;
 begin
   if GlobalError.IsError then exit;

   if RZero(z1.Imag) then begin     { Wenn der Imaginaerteil Null ist, }
     RCos(z1.Real);                 { genuegt eine reelle Berechnung. }
     exit;
   end;
   a := z1;                     { cos a = (e^(-ia)+e^(ia))/2 }
   CDiv(a, c_i);
   CExp(a);
   b := z1;
   CMul(b, c_i);
   CExp(b);
   RRound(a.Real); RRound(a.Imag);
   RRound(b.Real); RRound(b.Imag);
   CAdd(a, b);
   RLd_1(c); AddExpon(c, 1);   { 2 }
   RLd_0(d);                   { 0 }
   CSet(b, c, d);
   CDiv(a, b);
   z1 := a;
 end;
 { *************************************************** }

 { *************************************************** }
 {  Berechnet den Tangens einer komplexen Zahl.        }
 { *************************************************** }
 procedure CTan(var z1: Complex);
 var
   a,b: Complex;
 begin
   if GlobalError.IsError then exit;

   if RZero(z1.Imag) then begin     { Wenn der Imaginaerteil Null ist, }
     RTan(z1.Real);                 { genuegt eine reelle Berechnung. }
     exit;
   end;
   b := z1;
   CCos(b);
   if CZero(b) then begin
     GlobalError.SetError(er_DivZero, $00);
     exit;
   end;
   a := z1;
   CSin(a);
   CDiv(a,b);
   z1 := a;
 end;
 { *************************************************** }

 { *************************************************** }
 {  Berechnet den ArcusSinus einer komplexen Zahl.     }
 { *************************************************** }
 procedure CArcSin(var z1: Complex);
 var
   c1,c2: Complex;
 begin
   if GlobalError.IsError then exit;

   if RZero(z1.Imag) and not (RCmp_1(z1.Real) = cmp_Above) then begin
     RArcSin(z1.Real);
     exit;
   end;
   c1 := z1;
   CSqr(c1);
   CNeg(c1);
   RInc(c1.Real);
   CSqrt(c1);
   c2 := z1;
   CMul(c2, c_i);
   CAdd(c1, c2);
   CLn(c1);
   CDiv(c1, c_i);
   z1 := c1;
 end;
 { *************************************************** }

 { *************************************************** }
 {  Berechnet den ArcusCosinus einer kompexen Zahl.    }
 { *************************************************** }
 procedure CArcCos(var z1: Complex);
 var
   c1,c2: Complex;
   a,b: SReal;
 begin
   if GlobalError.IsError then exit;

   if RZero(z1.Imag) and not (RCmp_1(z1.Real) = 1) then begin
     RArcCos(z1.Real);
     exit;
   end;
   RLd_1(a);    RLd_0(b);
   CSet(c2, a, b);
   c1 := z1;
   CSqr(c1);
   CSub(c1,c2);
   CSqrt(c1);
   CAdd(c1,z1);
   CLn(c1);
   CDiv(c1,c_i);
   if SReal_Neg(c1.Real) then CNeg(c1);   { cos -a = cos a }
   z1 := c1;
 end;
 { *************************************************** }

 { *************************************************** }
 {  Berechnet den ArcusTangens einer komplexen Zahl.   }
 { *************************************************** }
 procedure CArcTan(var z1: Complex);
 var
   c1,c2: Complex;
 begin
   if GlobalError.IsError then exit;

   c1 := c_i;
   CMul(c1, z1);
   RInc(c1.Real);
   c2 := z1;
   CSqr(c2);
   RInc(c2.Real);
   CSqrt(c2);
   CDiv(c1, c2);
   CLn(c1);
   CDiv(c1, c_i);
   z1 := c1;
 end;
 { *************************************************** }

 function CmplxToInt(z: Complex): LongInt;
 begin
   if GlobalError.IsError or not RZero(z.Imag) then begin
     CmplxToInt := 0;
     exit;
   end;

   CmplxToInt := SRealToInt(z.Real);
 end;
 { *************************************************** }

{ ************************************************************************** }
begin
  RLd_0(c_i.Real);        { i mit dem richtigen Wert belegen. }
  RLd_1(c_i.Imag);
end.
{ ************************************************************************** }
