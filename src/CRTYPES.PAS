{ ************************************************************************** }
{                              CRECHNER 2.0                                  }
{ ************************************************************************** }
{  Diese Unit enthaelt die globalen Definitionen und Konstanten fuer das     }
{ ganze Programm.                                                            }
{  Zu SReal: Um gewisse Fehler schon moeglichst frueh abzufangen, nehmen die }
{ Routinen diesen Typ nur an, wenn er entweder Null ist, oder das zweithoe-  }
{ chste Bit gesetzt ist. Ansonsten werden die Routinen mit einem Fehler (NaN)}
{ abgebrochen.                                                               }
{ ************************************************************************** }
{                                                                            }
{                       (c) 1999/2000, Tobias Kohn                           }
{                                Version 2.0                                 }
{                                                                            }
{ ************************************************************************** }
{$G+}             { 286-Codes }
UNIT CRTypes;
{ ************************************************************************** }
INTERFACE
 USES Errors;
{ ************************************************************************** }

 CONST
   { ************************************************** }
   {  Mathematische Fehler:                             }
   { ************************************************** }
   {  Manche Konstanten haben hier mehrere Namen. Das   }
   { hat den Vorteil, das man bei den Bezeichnungen im  }
   { Quelltext freier ist.                              }
   { ************************************************** }
   er_DivisionByZero = $0101;      { Division durch Null. }
   er_DivideByZero   = $0101;
   er_DivZero        = $0101;
   er_Overflow       = $0102;      { Ueberlauf. }
   er_NotANumber     = $0103;      { Die Nummer ist ungueltig. }
   er_NaN            = $0103;
   er_NegRoot        = $0104;      { Wurzel einer negativen Zahl. }
   er_LnNotPos       = $0105;      { Logaritmus einer negativen Zahl }
   er_LnZero         = $0105;      { oder Null. }
   er_NegLn          = $0105;
   er_ArcRange       = $0106;      { ArcSin oder ArcCos eines Wertes ueber 1. }
   er_MathError      = $01FF;      { Unbekannter Mathematischer Fehler. }

   er_Syntax         = $0201;      { Fehler in der Eingabe-Syntax. }
   er_EquatError     = $0202;      { Fehler im Ausloesen der Gleichung. }
   er_Equat          = $0202;
   er_DefE           = $0203;      { E darf nur als Exponent Verwendung finden. }

   { ************************************************** }
   {  "Fuer die Verwendung der folgenden Konstanten ist }
   { jeweils die Beschreibung der angegebenen Variable  }
   { zu konsultieren."                                  }
   { ************************************************** }
   at_Rad  = $01;       { AngleType }
   at_Deg  = $02;

   io_Bin  = $01;       { InOutType }
   io_Oct  = $02;
   io_Dez  = $03;
   io_Hex  = $04;

   ct_Rect = $01;       { CmplxType }
   ct_Polar= $02;

   { ************************************************** }
   {  Die folgenden Konstanten koennen waerend der      }
   { Laufzeit abgeaendert werden.                       }
   { ************************************************** }
   {  Digits     Die Anzahl Stellen, die ausgegeben     }
   {              werden sollen.                        }
   {  AngleType  Das Winkelmass, das hauptsaechlich ver-}
   {              wendet werden soll.                   }
   {  InOutType  Legt fest, in welchem Zahlensystem die }
   {              Zahlen ein-bzw. ausgegeben werden.    }
   {  CmplxType  Die Art, wie die komplexen Zahlen aus- }
   {              gegeben werden. Dieser Wert bezieht   }
   {              sich wirklich nur auf die Art der     }
   {              Ausgabe und nicht auf die Art, wie die}
   {              Routinen der Unit CRCmplx ihre Para-  }
   {              meter interpretieren.                 }
   { ************************************************** }
   Digits   : Byte = 50;
   AngleType: Byte = at_Rad;
   InOutType: Byte = io_Dez;
   CmplxType: Byte = ct_Rect;

   { ************************************************** }
   {  Folgende Definitionen dienen fuer das Vergleichen }
   { zweier Zahlen.                                     }
   { ************************************************** }
    cmp_Below   = $01;
    cmp_Less    = $01;
    cmp_Equal   = $02;
    cmp_Greater = $03;
    cmp_Above   = $03;

    Cmp_Result: Byte = $00;

   { ************************************************** }
   {  Diese Konstanten geben an, mit welcher Genauig-   }
   { die entsprechenden Routinen rechnen sollen.        }
   {  Exact_Sqrt gibt an, wie viele Durchgaenge durchge-}
   { fuehrt werden, alle anderen geben die Genauigkeit  }
   { in Binaerstellen an (sind daher abhaengig von Mant-}
   { Size).                                             }
   { ************************************************** }
   exact_Sqrt : Word =  12;
   exact_Exp  : Word = 520;
   exact_Ln   : Word = 520;
   exact_Sin  : Word = 520;
   exact_Cos  : Word = 520;
   exact_ATan : Word = 520;

   { ************************************************** }
   {  Geben die Groesse von SReal bzw. den Bestandteilen}
   { von SReal an.                                      }
   {  Alle diese Groesen sollten gerade Zahlen sein, da }
   { einige Routinen nur Gerade Speicher-Groessen verar-}
   { beiten koennen.                                    }
   {  ExpoSize kann nicht so ohne weiteres geaendert    }
   { werden, die die meisten Routinen fest mit dem Long-}
   { Int-Typ rechnen.                                   }
   { ************************************************** }
   {  MantSize   Die Groesse der Mantisse. Diese Groesse}
   {              der Mantisse reicht fuer 150 Dezimal- }
   {              stellen.                              }
   {  ExpoSize   Die Groesse des Exponenten.            }
   {  CmpMSize   Die Anzahl der Bytes, die bei Verglei- }
   {              chen beruecksichtigt werden.          }
   {  OutMSize   Die Anzahl Stellen, die bei der Ausgabe}
   {              beruecksichtigt werden.               }
   {  MantLast   Gibt das Letzte Element des Array of   }
   {              Byte an.                              }
   { ************************************************** }
   MantSize = $42;        { 66 }
   ExpoSize = $04;        {  4 }

   CmpMSize : Word = $38; { 56 }
   OutMSize = $40;        { 58 }

   MantLast = MantSize-1;

 TYPE
   { ************************************************** }
   {  Dies hier ist nun der zentrale Typ fuer die Bere- }
   { chnungen: der "neue" Real-Typ.                     }
   { ************************************************** }
   {  Die Mantisse ist im Intel-Format abgelegt, das    }
   { heisst, das die Bytes eigentlich genau "verkehrt"  }
   { herum angeordnet sind.                             }
   {  Da es bei solchen Computer-Berechnungen immer eine}
   { gewisse Ungenauigkeit gibt, werden fuer die Aus-   }
   { gabe und die Vergleiche nicht alle Stellen berueck-}
   { sichtigt.                                          }
   {  Um die Operationen ein bisschen einfacher zu ges- }
   { talten, wurde fuer den Exponenten ein TP-Interner  }
   { Typ benutzt.                                       }
   { ************************************************** }
   HReal = ^SReal;
   SReal = record
     Expon: LongInt;                        { Exponent. }
     Mant : array[0..MantLast] of Byte;     { Mantisse. }
   end;

   { ************************************************** }
   {  Hier die Definitionen der komplexen Zahlen.       }
   { ************************************************** }
   HComplex = ^Complex;
   Complex = record
     Real: SReal;               { Real-Teil }
     Imag: SReal;               { Imaginaer-Teil }
   end;

 VAR
   { ************************************************** }
   {  Die hier definierten mathematischen Konstanten    }
   { besitzen nicht von Beginn her ihre Werte, sie      }
   { muessen also zuerst noch berechnet werden.         }
   { ************************************************** }
   rm_e : SReal;        { Eulersche Zahl }
   rm_Pi: SReal;        { Kreiszahl Pi }

   rm_ln2 : SReal;      { ln(2) }
   rm_ln10: SReal;      { ln(10) }

   rm_0   : SReal;      { Null }

   { ************************************************** }
   {  ValidSReal Bringt die positive (!) Zahl AReal in  }
   {              ein gueltiges Format.                 }
   {  TestValid  Ueberprueft, ob AReal eine hueltige    }
   {              Zahl ist und loest, wenn nicht einen  }
   {              Fehler aus.                           }
   {                                                    }
   {  SReal_Neg  Gibt an, ob das Argument eine negative }
   {              Zahl ist (true).                      }
   {  SReal_Neg_Abs  Das Resultat ist True, wenn AReal  }
   {              eine negative Zahl ist. In jedem Fall }
   {              wird AReal positiv gemacht.           }
   {  SReal_XCHG_Sign  Vertasucht das Vorzeichen der    }
   {              Zahl.                                 }
   {                                                    }
   {  SwapReals  Vertauscht die zwei SReal-Zahlen.      }
   {  AddExpon   Erhoeht den Exponent der Zahl um den   }
   {              Wert AValue (AValue darf auch Negativ }
   {              sein (Subtraktion)).                  }
   {  AddExpon2  => AddExpon. Diese Funktion prueft im  }
   {              Gegensatz zu AddExpon nicht, ob die   }
   {              Zahl gueltig ist und so weiter.       }
   { ************************************************** }
   procedure ValidSReal(var AReal: SReal);
   function TestValid(AReal: SReal): Boolean;

   function SReal_Neg(var AReal: SReal): Boolean;
   function SReal_Neg_Abs(var AReal: SReal): Boolean;
   procedure SReal_XCHG_Sign(var AReal: SReal);

   procedure SwapReals(var AReal, BReal: SReal);
   procedure AddExpon(var AReal: SReal; AValue: LongInt);
   procedure AddExpon2(var AReal: SReal; AValue: LongInt);

   { ************************************************** }
   {  Diese Funktionen laden die Zahlen mit entsprechen-}
   { den einfachen Konstanten.                          }
   { ************************************************** }
   procedure RLd_0(var AReal: SReal);
   procedure RLd_1(var AReal: SReal);

   procedure CLd_0(var ACplx: Complex);
   procedure CLd_1(var ACplx: Complex);
   procedure CLd_i(var ACplx: Complex);

 VAR
   GlobalError: LErrorObj;

   { ************************************************** }
   {  ShowBusy   Diese Zeiger zeigt auf eine Prozedur,  }
   {              die von den Routinen aufgerufen wird, }
   {              die laengere Berechnungen durchfueh-  }
   {              ren. Dieser Zeiger muss immer auf eine}
   {              gueltige Funktion zeigen, sie duerfen }
   {              ihn jedoch auf ihre eigene Routine    }
   {              umbiegen, um z.B. eine Sanduhr zu be- }
   {              wegen, um dem Anwender mitzuteilen,   }
   {              dass der Computer beschaeftigt ist.   }
   { ************************************************** }
   ShowBusy : procedure;

{ ************************************************************************** }
IMPLEMENTATION
 USES Basics, Memory;
{ ************************************************************************** }

 { ****************************************************** }
 procedure ValidSReal(var AReal: SReal);
 var
   AMem: HIntMem;
   i   : LongInt;                       { Der Zaehler soll verhindern, dass die Routine bei }
 begin                                  { Null einfach bis ins unendliche weitermacht. }
   AMem := New(HIntMem, Init);              { Zuerst das Memory-Objekt initialisieren }
   if (AMem = nil) then exit;               { und ihm die Mantisse uebertragen. }
   AMem^.AssignMem(Addr(AReal.Mant), MantSize);

   for i := 0 to (CmpMSize+1) do            { Das erste Byte suchen, das nicht Null ist. }
    if not (AReal.Mant[MantLast-i] = $00)
     then break;

   if (i > (CmpMSize-4)) then begin         { Wenn die Genauigkeit Ueberschritten wurde, }
     RLd_0(AReal);                          { ist die Zahl gleich Null. }
     AMem^.ClearMe;
     AMem^.Free;
     exit;
   end;
   if (i > 0) then begin
     AMem^.ShiftL(8*i);
     AddExpon2(AReal, (-8 * i));
   end;

   if not (AReal.Mant[MantLast] = $00) then begin
     if TestBit(AReal.Mant[MantLast], 7) then begin     { Ein Bit zu weit links, }
       AMem^.ShiftR(1);                                 { danach ist das Ziel erreicht. }
       AddExpon2(AReal, 1);
     end else begin
       i := HighestBit(AReal.Mant[MantLast]);
       AMem^.ShiftL(7-i);
       AddExpon2(AReal, i-7);
     end;
   end else begin
     AMem^.Fill(0);
     AReal.Expon := 0;
   end;

   AMem^.ClearMe;
   AMem^.Free;
 end;

 function TestValid(AReal: SReal): boolean;
 begin
   if ((AReal.Mant[MantLast] = $00) and (AReal.Expon = $00))
      or TestBit(AReal.Mant[MantLast], 6)
    then begin
      TestValid := true;
      exit;
    end;
   GlobalError.SError(er_NaN);
   TestValid := false;
 end;

 function SReal_Neg(var AReal: SReal): Boolean; assembler;
 asm
       les      di,AReal
       add      di,ExpoSize+MantLast
       mov      al,es:[di]
       and      al,80h
       jz       @@1
       mov      al,true
 @@1:
 end;

 function SReal_Neg_Abs(var AReal: SReal): Boolean; assembler;
 asm
       les      di,AReal
       add      di,ExpoSize+MantLast
       mov      al,es:[di]
       mov      ah,al
       and      ah,7Fh
       mov      es:[di],ah
       and      al,80h
       jz       @@1
       mov      al,true
       jmp      @@2
 @@1:  mov      al,false
 @@2:
 end;

 procedure SReal_XCHG_Sign(var AReal: SReal); assembler;
 asm
       les      di,AReal                { Bei der Zahl Null wird das Vorzeichen }
       mov      bx,ExpoSize+MantLast    { nicht gewechselt. }
       mov      al,es:[di+bx]
       or       al,al
       jz       @@1
       xor      al,80h
       mov      es:[di+bx],al
 @@1:
 end;

 procedure SwapReals(var AReal, BReal: SReal); assembler;
 asm
       push     ds
       les      di,AReal
       lds      si,BReal
       mov      cx,ExpoSize+MantSize
       shr      cx,01
       cld

 @@1:  mov      ax,es:[di]
       xchg     ax,ds:[si]
       add      si,02
       stosw
       loop     @@1

       pop      ds
 end;

 procedure AddExpon(var AReal: SReal; AValue: LongInt);
 begin
   if not (AReal.Mant[MantLast] = $00) and TestValid(AReal)  { Diese Operation nur durchfuehern, wenn }
    then AReal.Expon := AReal.Expon + AValue;                { die Zahl nicht Null und gueltig ist. }
 end;

 procedure AddExpon2(var AReal: SReal; AValue: LongInt);
 begin
   AReal.Expon := AReal.Expon + AValue;
 end;
 { ****************************************************** }

 procedure RLd_0(var AReal: SReal); assembler;
 asm
       les      di,AReal
       mov      cx,ExpoSize+MantSize
       xor      ax,ax
       cld
       shr      cx,01
       rep      stosw
 end;

 procedure RLd_1(var AReal: SReal); assembler;
 asm
       les      di,AReal
       mov      cx,ExpoSize+MantSize-2
       xor      ax,ax
       cld
       shr      cx,01
       rep      stosw
       mov      ax,4000h
       stosw
 end;

 procedure CLd_0(var ACplx: Complex);
 begin
   RLd_0(ACplx.Real);
   RLd_0(ACplx.Imag);
 end;

 procedure CLd_1(var ACplx: Complex);
 begin
   RLd_1(ACplx.Real);
   RLd_0(ACplx.Imag);
 end;

 procedure CLd_i(var ACplx: Complex);
 begin
   RLd_0(ACplx.Real);
   RLd_1(ACplx.Imag);
 end;
 { ****************************************************** }

 procedure ShowBusyDummy; far;
 begin end;

{ ************************************************************************** }
BEGIN
  ShowBusy := ShowBusyDummy;
  GlobalError.Init;
  RLd_0(rm_e);                  { Alle diese Konstanten werden am Anfang }
  RLd_0(rm_Pi);                 { auf Null gesetzt, damit spaeter ueber- }
  RLd_0(rm_ln2);                { prueft werden kann, ob sie bereits }
  RLd_0(rm_ln10);               { berechnet wurden. }
  RLd_0(rm_0);                  { Diese Hier stimmt bereits. }
END.
{ ************************************************************************** }