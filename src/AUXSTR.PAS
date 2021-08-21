{ ************************************************************************** }
{  In dieser Unit findet sich Hilfs-Routinen, um Pascal-Strings zu bearbeiten}
{ Diese sind vor allem fuer die Ein- und Ausgabe von Termen interessant.     }
{  Ebenfalls hier zu finden, sind die Bezeichner der Mathematischen Funktio- }
{ nen (sin, arccos, ln,...).                                                 }
{ ************************************************************************** }
{  Auxiliary procedures to edit Pascal-strings.                              }
{ ************************************************************************** }
{                                                                            }
{                          (c) 2000, Tobias Kohn                             }
{                                Version 1.0                                 }
{                                                                            }
{ ************************************************************************** }
{$G+}             { 286-Codes }
UNIT AuxStr;
{ ************************************************************************** }
INTERFACE
{ ************************************************************************** }

 CONST
   { ************************************************** }
   {  NumberChars   Gibt die Zeichen an, die fuer eine  }
   {                 reine Zahl gueltig sind. Dieser    }
   {                 Wert wird von der Funktion         }
   {                 StrIsNumber verwendet. Zusaetzlich }
   {                 zu diesen zeichen ist noch ein     }
   {                 einmaliges Auftreten von 'E' als   }
   {                 Exponent oder der Zeichen + und -  }
   {                 erlaubt.                           }
   {  str_Pi        Definiert das Zeichen Pi. Unter DOS }
   {                 stellt dieses Zeichen wirklich das }
   {                 Pi dar, nicht jedoch unter Windows.}
   {                 Die Variablen koennen aber auch    }
   {                 unter Windows nur durch einen Buch-}
   {                 staben vertreten werden, so dass   }
   {                 ein Zeichen als Pi definiert werden}
   {                 muss.                              }
   { ************************************************** }
   NumberChars: string[15] = '0123456789.';

   str_Pi  = #227;
   str_Pi2 : string[3] = 'Pi';

   { ************************************************** }
   {  Diese Bezeichner werden fuer das Erkennen von     }
   { funktionen und deren Ausgabe verwendet.            }
   {  Die folgenden Bezeichner werden wohl kaum geaen-  }
   { dert werden, aber falls dies jemals notwendig wer- }
   { den sollte, so wird mit der Definition hier eine   }
   { einfache Moeglichkeit dazu geboten. Jedoch sollte  }
   { keine Funktion laenger sein als 7 Zeichen.         }
   { ************************************************** }
   str_sin    = 'sin';
   str_cos    = 'cos';
   str_tan    = 'tan';
   str_arcsin = 'arcsin';       str_asin   = str_arcsin;
   str_arccos = 'arccos';       str_acos   = str_arccos;
   str_arctan = 'arctan';       str_atan   = str_arctan;

   str_ln     = 'ln';
   str_lg     = 'lg';
   str_lb     = 'lb';

   str_exp1   = 'e^';
   str_exp2   = 'exp';
   str_exp    = str_exp1;

   str_sqrt   = 'sqrt';
   str_kbrt   = 'kbrt';

   str_sqr    = 'sqr';
   str_kb     = 'kb';

   str_inv    = 'inv';
   str_abs    = 'abs';

   { ************************************************** }
   {  CharInString  Prueft, ob das Zeichen AChar im     }
   {                 angegebenen String vorkommt.       }
   {  CountOfChar   Gibt an, wie oft das Zeichen AChar  }
   {                 in AStr vorkommt.                  }
   {                                                    }
   {  CmplxIinStr   Gibt die Stelle an, wo ein i ohne   }
   {                 nachfolgende Potenz steht, falls   }
   {                 ein solches vorhanden ist. Sind    }
   {                 mehrere solche i vorhanden, wird   }
   {                 nur das erste angezeigt.           }
   {                                                    }
   {  StrSHL1       Schiebt den ganzen String um 1 nach }
   {                 links. Dies kommt dem Loeschen des }
   {                 ersten Zeichens gleich.            }
   {  ReplaceChar   Ersetzt alle Zeichen ACh1 durch das }
   {                 Zeichen ACh2.                      }
   {  DelSpaces     Loescht alle Leerschlaege im String.}
   {  LowerCase     Wandelt alle Grossbuchstaben in     }
   {                 kleine um.                         }
   {  LowerNumber   Wandelt alle Grossbuchstaben ausser }
   {                 dem 'E' (Unterscheidung Exponent / }
   {                 eulersche Zahl) in Kleinbuchstaben }
   {                 um.                                }
   {                                                    }
   {  ReplaceStrings Ersetzt alle s1 in AStr durch s2.  }
   { ************************************************** }
   function CharInString(AChar: Char; AStr: string): Boolean;
   function CountOfChar(AChar: Char; AStr: string): Byte;

   function CmplxIinString(AStr: string): Byte;

   procedure StrSHL1(var AStr: string);
   procedure ReplaceChar(var AStr: string; ACh1, ACh2: Char);
   procedure DelSpaces(var AStr: string);
   procedure LowerCase(var AStr: string);
   procedure LowerNumber(var AStr: string);

   procedure ReplaceStrings(var AStr: string; s1, s2: string);

   { ************************************************** }
   {  StrIsNumber   Prueft, ob sich im String wirklich  }
   {                 nur fuer eine Zahl gueltige Zei-   }
   {                 chen befinden. Siehe NumberChars.  }
   {  StrIsNumberI  Ist mit der vroangehenden Funktion  }
   {                 identisch, akzeptiert aber auch    }
   {                 das 'i' (komplexe Zahlen).         }
   {  CharIsLetter  Prueft, ob es sich bei dem angege-  }
   {                 nen Zeichen um einen Buchstaben    }
   {                 handelt. Umlaute werden nicht als  }
   {                 Buchstaben anerkannt.              }
   {  CharIsSepar   Prueft, ob das Zeichen ein Operator }
   {                 +-*/^ ist.                         }
   { ************************************************** }
   function StrIsNumber(AStr: string): Boolean;
   function StrIsNumberI(AStr: string): Boolean;
   function CharIsLetter(AChar: char): Boolean;
   function CharIsSepar(AChar: char): Boolean;

   { ************************************************** }
   {  FindNextLetter   Sucht nach dem naechsten Zeichen,}
   {                 bei dem es sich um einen Buchstaben}
   {                 handelt.                           }
   {  FindNextSepar Sucht nach dem naechsten Operations-}
   {                 Zeichen +-*/^. Steht das ^ gleich  }
   {                 nach einem Buchstaben, wird es ig- }
   {                 noriert, genauso bei einem + oder  }
   {                 - hinter einem E.                  }
   {  FindLastSepar Sucht nach dem letzen Operations-   }
   {                 Zeichen. Benutzt die gleichen      }
   {                 Optionen wie FindNextSepar.        }
   {  FindOpenClip  Sucht nach der naechsten oeffnenden }
   {                 Klammer (.                         }
   {  FindCloseClip Sucht nach derjenigen schliessenden }
   {                 Klammer ), die zur naechsten oeff- }
   {                 nenden gehoert.                    }
   {  PosOfNegat    Sucht nach einem Minuszeichen - mit }
   {                 darauffolgender Funktion.          }
   { ************************************************** }
   function FindNextLetter(AStr: string): byte;
   function FindNextSepar(AStr: string): byte;
   function FindLastSepar(AStr: string): byte;
   function FindOpenClip(AStr: string): byte;
   function FindCloseClip(AStr: string): byte;

   function PosOfNegat(AStr: string): byte;

{ ************************************************************************** }
IMPLEMENTATION
{ ************************************************************************** }

 function CharInString(AChar: Char; AStr: string): Boolean; assembler;
 asm
       les      di,AStr         { Parameter laden: }
       cld                      { ES:[DI] -> String-Adresse }
       mov      cl,es:[di]      { CX      -> String-Groesse }
       xor      ch,ch           { AL      -> gesuchtes Zeichen }
       mov      al,AChar
       inc      di

       repne    scasb           { Zeichen suchen. }
       je       @@1
       mov      al,false
       jmp      @@2
 @@1:  mov      al,true
 @@2:
 end;

 function CountOfChar(AChar: Char; AStr: string): Byte; assembler;
 asm
       push     ds
       lds      si,AStr         { Parameter laden:                }
       cld                      { DS:[SI] -> Adresse des Strings. }
       lodsb                    { CX      -> String-Groesse.      }
       mov      cl,al           { AH      -> Gesuchtes Zeichen.   }
       xor      ch,ch           { DX      -> Anzahl (Rueckgabewert) }
       mov      ah,AChar
       xor      dx,dx

 @@1:  lodsb                    { Anzahl der Zeichen ermitteln. }
       cmp      al,ah
       jne      @@2
       inc      dl
 @@2:  loop     @@1
       pop      ds
       mov      al,dl
 end;

 function CmplxIinString(AStr: string): Byte; assembler;
 asm
       les      di,AStr         { Parameter laden: }
       cld                      { ES:[DI] -> String-Adresse }
       mov      cl,es:[di]      { CX      -> String-Groesse }
       xor      ch,ch
       mov      dx,cx
       inc      di

 @@1:  mov      al,'i'
       jcxz     @@2             { String fertig ? }
       repne    scasb           { i suchen. }
       jne      @@2             { nichts gefunden. }
       mov      al,'^'          { Ist naechstes Zeichen ein ^ ? }
       dec      cx
       scasb
       je       @@1
       mov      ax,dx           { i gefunden: Position in AX ermitteln. }
       sub      ax,cx
       dec      ax
       jmp      @@3

 @@2:  xor      al,al           { nichts gefunden: Position 0 }
 @@3:
 end;

 procedure StrSHL1(var AStr: string); assembler;
 asm
       push     ds
       les      di,AStr         { Parameter laden:                }
       lds      si,AStr         { DS:[SI] -> Adresse des Strings. }
       cld                      { ES:[DI] -> Adresse des Strings. }
       lodsb                    { CX      -> String-Groesse.      }
       dec      al
       mov      cl,al
       xor      ch,ch
       jcxz     @@Q             { Leeren String nicht bearbeiten. }
       mov      es:[di],al      { String wird um 1 kleiner. }

       inc      si              { Source-Index soll gegenueber dem }
       inc      di              { Dest.-Index einen Vorsprung um 1 haben. }
       rep      movsb           { Bytes verschieben. }

 @@Q:  pop      ds
 end;

 procedure ReplaceChar(var AStr: string; ACh1, ACh2: Char); assembler;
 asm
       les      di,AStr         { Parameter laden:                }
       cld                      { ES:[DI] -> Adresse des Strings. }
       mov      cl,es:[di]      { CX      -> String-Groesse.      }
       xor      ch,ch
       inc      di
       mov      ah,ACh1
       mov      dl,ACh2

 @@1:  mov      al,es:[di]      { Jedes Zeichen pruefen, ob es ein }
       cmp      al,ah           { ACh1 ist. Wenn ja, dann durch ein }
       jne      @@2             { ACh2 ersetzen. }
       mov      al,dl
 @@2:  stosb
       loop     @@1
 end;

 procedure DelSpaces(var AStr: string);
 var
   i: Byte;
 begin
   repeat                       { Nach Leerzeichen suchen, bis keine mehr }
     i := Pos(' ', AStr);       { vorhanden sind und alle leerzeichen }
     if (i = 0) then break;     { loeschen. }
     Delete(AStr, i, 1);
   until False;
 end;

 procedure LowerCase(var AStr: string); assembler;
 asm
       les      di,AStr         { Parameter laden:                }
       cld                      { ES:[DI] -> Adresse des Strings. }
       mov      cl,es:[di]      { CX      -> String-Groesse.      }
       xor      ch,ch
       inc      di

 @@1:  mov      al,es:[di]      { Bei jedem Zeichen pruefen, ob es }
       cmp      al,'A'          { sich um einen grossen Buchstaben }
       jb       @@2             { handelt. Wenn ja, wird dieser in }
       cmp      al,'Z'          { einen Kleinbuchstaben umgewandelt. }
       ja       @@2
       add      al,'a'-'A'
 @@2:  stosb
       loop     @@1
 end;

 procedure LowerNumber(var AStr: string); assembler;
 asm
       les      di,AStr         { Parameter laden:                }
       cld                      { ES:[DI] -> Adresse des Strings. }
       mov      cl,es:[di]      { CX      -> String-Groesse.      }
       xor      ch,ch
       inc      di

 @@1:  mov      al,es:[di]      { Bei jedem Zeichen pruefen, ob es }
       cmp      al,'E'          { sich um einen grossen Buchstaben }
       je       @@2             { handelt. Wenn ja, wird dieser in }
       cmp      al,'A'          { einen Kleinbuchstaben umgewandelt. }
       jb       @@2             { Das 'E' wird aber nicht in einen }
       cmp      al,'Z'          { Kleinbuchstaben umgewandelt. }
       ja       @@2
       add      al,'a'-'A'
 @@2:  stosb
       loop     @@1
 end;

 procedure ReplaceStrings(var AStr: string; s1, s2: string);
 var
   i: Byte;
 begin
   repeat
     i := pos(s1, AStr);
     if (i = 0) then break;

     Delete(AStr, i, length(s1));
     Insert(s2, AStr, i);
   until False;
 end;
 { ****************************************************** }

 function StrIsNumber(AStr: string): Boolean;
 var
   i: Byte;
   Buffer: Boolean;
 begin                                                    { Jedes Zeichen des Strings }
   Buffer := true;                                        { wird einzeln geprueft, ob }
   for i := 1 to ord(AStr[0]) do                          { es in NumberChars enthalten }
    if not CharInString(AStr[i], NumberChars) then begin  { ist. }
      buffer := false;
      break;
    end;
   StrIsNumber := Buffer;
 end;

 function StrIsNumberI(AStr: string): Boolean;
 var
   Buffer: Boolean;
 begin
   NumberChars := NumberChars + 'i';
   Buffer := StrIsNumber(AStr);
   dec(Byte(NumberChars[0]));
   StrIsNumberI := Buffer;
 end;

 { ! Hinweis: die folgenden zwei Funktionen duerfen nur das AX-Register }
 { frei verwednen. Alle anderen Register muessten zuerst auf den Stack }
 { gelegt werden und am Ende wieder restauriert ! }
 function CharIsLetter(AChar: char): Boolean; assembler;
 asm
       mov      ah,false
       mov      al,AChar         { Diese Routine arbeitet vor allem, um die }
       cmp      al,227           { Variablen aus einem String heruaszulesen }
       je       @@1              { (Projekt CRechner). Da aber E keine Var- }
       cmp      al,'E'           { iable sein kann, sondern den Exponenten  }
       je       @@2              { angiebt, soll E nicht als Buchstabe be-  }
       cmp      al,'A'           { handelt werden.                          }
       jb       @@2              { Fuer andere Programme sind die zwei Zeilen }
       cmp      al,'z'           { entsprechend abzuaendern.                  }
       ja       @@2
       cmp      al,'Z'
       jna      @@1
       cmp      al,'a'
       jb       @@2
 @@1:  mov      ah,true
 @@2:  mov      al,ah
 end;

 { Achtung: Siehe Hinweis zu CharIsLetter ! }
 function CharIsSepar(AChar: char): Boolean; assembler;
 asm
       mov      ah,true
       mov      al,AChar
       cmp      al,'+'
       je       @@1
       cmp      al,'-'
       je       @@1
       cmp      al,'*'
       je       @@1
       cmp      al,'/'
       je       @@1
       cmp      al,'^'
       je       @@1
       mov      ah,false
 @@1:  mov      al,ah
 end;
 { ****************************************************** }

 function FindNextLetter(AStr: string): byte; assembler;
 asm
       les      di,AStr         { Parameter laden:                }
       cld                      { ES:[DI] -> Adresse des Strings. }
       mov      cl,es:[di]      { CX      -> String-Groesse.      }
       xor      ch,ch
       xor      dx,dx

 @@1:  inc      di
       mov      al,es:[di]      { Alle Zeichen des Strings }
       inc      dl              { pruefen, bis ein Buchstabe }
       push     ax              { gefunden wurde. }
       call     CharIsLetter
       cmp      al,true
       je       @@2
       loop     @@1

 @@2:  cmp      al,true         { Wurde kein Buchstabe gefunden, nicht die }
       je       @@3             { Laenge des Strings, sondern Null zurueck- }
       xor      dl,dl           { geben. }
 @@3:  mov      al,dl
 end;

 function FindNextSepar(AStr: string): byte; assembler;
 asm
       les      di,AStr         { Parameter laden:                }
       cld                      { ES:[DI] -> Adresse des Strings. }
       mov      cl,es:[di]      { CX      -> String-Groesse.      }
       xor      ch,ch           { DX      -> Zaehler. }
       xor      dx,dx
       jcxz     @@4

 @@1:  inc      di
       mov      al,es:[di]      { Alle Zeichen des Strings }
       inc      dl              { pruefen, bis ein Operator }
       push     ax              { gefunden wurde. }
       call     CharIsSepar
       cmp      al,false
       je       @@3

       mov      ax,es:[di-1]
       xchg     al,ah           { Bei "E+" oder "E-" wurde kein }
       cmp      ax,452Bh        { wirklicher Operator gefunden. }
       je       @@3
       cmp      ax,452Dh
       je       @@3

       cmp      al,'^'          { Bei "^" zuerst pruefen, ob vorher ein }
       jne      @@2             { Buchstabe steht. Wenn ja, handelt es }
       mov      al,ah           { sich ebenfalls nicht um einen Operator, }
       push     ax              { sondern um die Potenzbezeichnung einer }
       call     CharIsLetter    { Variable oder Konstante. }
       cmp      al,false
       je       @@4
       jmp      @@3

 @@2:  cmp      ax,'^+'         { Nach einem Potenzzeichen sind + und - }
       je       @@3             { keine Operatoren, sondern Vorzeichen. }
       cmp      ax,'^-'
       jne      @@4

 @@3:  loop     @@1
                                { Wurde kein Operator gefunden, nicht die }
       xor      dl,dl           { Laenge des Strings, sondern Null zurueck- }
 @@4:  mov      al,dl           { geben. }
 end;

 function FindLastSepar(AStr: string): byte; assembler;
 asm
       les      di,AStr         { Parameter laden:                }
       cld                      { ES:[DI] -> Adresse des Strings. }
       mov      cl,es:[di]      { CX      -> String-Groesse.      }
       xor      ch,ch
       add      di,cx
       jcxz     @@3

 @@1:  mov      al,es:[di]      { Alle Zeichen des Strings }
       dec      di              { pruefen, bis ein Operator }
       push     ax              { gefunden wurde. }
       call     CharIsSepar
       cmp      al,false
       je       @@2

       mov      ax,es:[di]
       xchg     al,ah           { Bei "E+" oder "E-" wurde kein }
       cmp      ax,452Bh        { wirklicher Operator gefunden. }
       je       @@2
       cmp      ax,452Dh
       je       @@2

       cmp      al,'^'          { Bei "^" zuerst pruefen, ob vorher ein }
       jne      @@3             { Buchstabe steht. Wenn ja, handelt es }
       mov      al,ah           { sich ebenfalls nicht um einen Operator, }
       push     ax              { sondern um die Potenzbezeichnung einer }
       call     CharIsLetter    { Variable oder Konstante. }
       cmp      al,false
       je       @@3

 @@2:  loop     @@1             { Wurde kein Operator gefunden, nicht die }
                                { Laenge des Strings, sondern Null zurueck- }
 @@3:  mov      al,cl           { geben. }
 end;

 function FindOpenClip(AStr: string): byte; assembler;
 asm
       cld                      { Zuerst die Werte laden. }
       les      di,AStr
       mov      cl,es:[di]
       xor      ch,ch
       inc      di              {  Da der rep-Befehl rueckwaerts zaehlt, }
       mov      dl,cl           { und ein Zeichen gefunden wird, ist cx }
       mov      al,'('          { nicht der Index des Zeichens, sondern }
       repne    scasb           { Stringlaenge (ist in DX) minus CX. }
       je       @@1
       mov      cl,dl
 @@1:  mov      al,dl
       sub      al,cl
 end;

 function FindCloseClip(AStr: string): byte; assembler;
 asm
       xor      bx,bx           {  Damit nicht das erste )-Zeichen bereits }
       les      di,AStr         { als schliessende Klammer angesehen wird, }
       cld                      { muessen die oeffnenden Klammern mitge- }
       mov      cl,es:[di]      { zaehlt werden: jede offene Klammer }
       xor      ch,ch           { muss zuerst wieder durch eine schliessende }
       mov      dl,'('          { ausgeglichen werden. }
       mov      dh,')'          {  Leider kann man dazu auch nicht einfach }
 @@1:  inc      di              { von hinten her zaehlen, da ja mehrere }
       inc      bh              { gleichwertiuge Klammern nebeneinander }
       mov      al,es:[di]      { stehen koennen. }
       cmp      al,dl           {  Beispiele: Welche Klammer wird "gefunden"? }
       jne      @@2             { 1.   (abc(df)ge)+(ac)       }
       inc      bl              {                ^            }
 @@2:  cmp      al,dh           { 2.   (abc)                  }
       jne      @@3             {          ^                  }
       dec      bl              { 3.   (a(bc)+(de)-b)+(dfg)   }
       je       @@4             {                   ^         }
 @@3:  loop     @@1             { 4.   ab(c)de                }
 @@4:  mov      al,bh           {          ^                  }
 end;

 function PosOfNegat(AStr: string): byte; assembler;
 asm
       les      di,AStr
       mov      cl,es:[di]
       inc      di
       xor      ch,ch
       xor      dx,dx

 @@1:  mov      ax,es:[di]
       inc      dl
       cmp      al,'-'
       jne      @@2
       cmp      ah,80h
       jae      @@3

 @@2:  inc      di
       loop     @@1

 @@3:  xor      al,al
       or       cx,cx
       jz       @@4
       mov      al,dl
 @@4:
 end;
{ ************************************************************************** }
END.
{ ************************************************************************** }