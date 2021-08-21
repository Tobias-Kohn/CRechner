{ ************************************************************************** }
{  Diese Unit beinhaltet ein einfaches Objekt, welches die Grundlage fuer    }
{ eine Objekthierarchie bilden kann sowie einfache Routinen, um die Bits in  }
{ einem Byte/Word zu manipulieren.                                           }
{  Im Gegensatz zur Standart-Vereinbarung in Turbo Pascal, den Objekten ein  }
{ T und ihren Zeigern ein P voranzustellen, werden hier ein L und ein H      }
{ benutzt. Dies geschieht unter anderem, um Konflikte mit gleichen Namen zu  }
{ vermeiden, wenn diese Hierarchie und die TP-Hierarchie gleichzeitig ver-   }
{ wendet werden.                                                             }
{ ************************************************************************** }
{  This unit contains an object that could be the start-point for a object-  }
{ hierarchy and some routines to manipulate the bits of a byte/word.         }
{ ************************************************************************** }
{                                                                            }
{                          (c) 1999, Tobias Kohn                             }
{                                Version 1.0                                 }
{                                                                            }
{ ************************************************************************** }
{$G+}             { 286-Codes }
UNIT Basics;
{ ************************************************************************** }
INTERFACE
{ ************************************************************************** }

 TYPE
   { ************************************************** }
   {  Das Ur-Object, auf dem alle weiteren Objekte auf- }
   { bauen sollten.                                     }
   { ************************************************** }
   {  Init       Inititalisiert alle virtuellen Metho-  }
   {              den und setzt alle eigenen Variablen  }
   {              auf Null.                             }
   {  Free       Gibt den Heap-Speicher wieder frei,    }
   {              den dieses Objekt besetzt.            }
   { ************************************************** }
   HObject = ^LObject;
   LObject = object
     constructor Init;
     destructor Done; virtual;
     procedure Free; virtual;
   end;

   { ************************************************** }
   {  Bei den nachfolgenden Prozeduren ist zu bemerken, }
   { dass sich die Bits in einem Byte von 0 bis 7       }
   { zaehlen, wobei das Bit 7 an hoechster Stelle steht,}
   { und Bit 0 an der niedrigsten (7 6 5 4 3 2 1 0).    }
   {  Ist das letzte Zeichen des Routinenbezeichners ein}
   { W, so bearbeitet sie Word-Werte bei einem B Byte-  }
   { Werte und steht nichts, so wird beides akzeptiert. }
   { ************************************************** }

   { ************************************************** }
   {  Diese Funktion prueft, ob das Bit ABit gesetzt    }
   { ist.                                               }
   { ************************************************** }
   function TestBit(AWert: Word; ABit: Byte): Boolean;

   { ************************************************** }
   {  Die folgenden Routinen pruefen, ob das Bit ABit   }
   { gesetzt ist und loeschen das betreffende Bit auf   }
   { jeden Fall.                                        }
   { ************************************************** }
   function TestBitZeroB(var AWert: Byte; ABit: Byte): Boolean;
   function TestBitZeroW(var AWert: Word; ABit: Byte): Boolean;

   { ************************************************** }
   {  Setzen das Bit ABit.                              }
   { ************************************************** }
   procedure SetBitB(var AWert: Byte; ABit: Byte);
   procedure SetBitW(var AWert: Word; ABit: Byte);

   { ************************************************** }
   {  Prueft, ob gilt: (AVal1 and AVal2) = AVal2        }
   { ************************************************** }
   function TestValue(AVal1, AVal2: Word): boolean;

   { ************************************************** }
   {  Sucht das hoechste gesetzte Bit und gibt dessen   }
   { Position+1 zurueck (Die niedrigste Stelle waere    }
   { hier also 1 und nicht 0). Ist der Rueckgabewert 0, }
   { so ist auch AValue 0.                              }
   { ************************************************** }
   function HighestBit(AValue: Word): Byte;

{ ************************************************************************** }
IMPLEMENTATION
{ ************************************************************************** }

 { ****************************************************** }
 constructor LObject.Init;
 type
   ARec=record                          { Hier werden alle Variablen }
     a,b: Word;                         { des eigenen Objektes auf Null }
   end;                                 { gesetzt. }
 var
   p: ARec absolute Self;
 begin
   FillChar(p.b, SizeOf(Self)-2, 0);
 end;

 destructor LObject.Done;
 begin end;

 procedure LObject.Free;
 begin
   Dispose(HObject(@Self), Done);
 end;

 { ****************************************************** }
 function TestBit(AWert: Word; ABit: Byte): Boolean; assembler;
 asm
       mov      dx,01
       mov      cl,ABit
       shl      dx,cl
       mov      ax,AWert
       cmp      cl,7
       ja       @@1
       xor      ah,ah
 @@1:  and      ax,dx
       or       ax,ax
       jz       @@2
       mov      al,true
 @@2:
 end;

 function TestBitZeroB(var AWert: Byte; ABit: Byte): Boolean; assembler;
 asm
       mov      dl,01
       mov      cl,ABit
       shl      dl,cl
       les      di,AWert
       mov      al,es:[di]
       and      al,dl
       or       al,al
       jz       @@1
       mov      al,true
 @@1:  push     ax
       mov      al,es:[di]
       not      dl
       and      al,dl
       stosb
 @@2:  pop      ax
 end;

 function TestBitZeroW(var AWert: Word; ABit: Byte): Boolean; assembler;
 asm
       mov      dx,01
       mov      cl,ABit
       shl      dx,cl
       les      di,AWert
       mov      ax,es:[di]
       and      ax,dx
       or       ax,ax
       jz       @@1
       mov      al,true
 @@1:  push     ax
       mov      ax,es:[di]
       not      dx
       and      ax,dx
       stosw
 @@2:  pop      ax
 end;

 procedure SetBitB(var AWert: Byte; ABit: Byte); assembler;
 asm
       mov      dl,01
       mov      cl,ABit
       shl      dl,cl
       les      di,AWert
       mov      al,es:[di]
       or       al,dl
       mov      es:[di],al
 end;

 procedure SetBitW(var AWert: Word; ABit: Byte); assembler;
 asm
       mov      dx,01
       mov      cl,ABit
       shl      dx,cl
       les      di,AWert
       mov      ax,es:[di]
       or       ax,dx
       mov      es:[di],ax
 end;

 function TestValue(AVal1, AVal2: Word): boolean; assembler;
 asm
       mov      ax,AVal1
       mov      dx,AVal2
       and      ax,dx
       cmp      ax,dx
       je       @@1
       mov      al,false
       jmp      @@2
 @@1:  mov      al,true
 @@2:
 end;

 function HighestBit(AValue: Word): Byte; assembler;
 asm
       mov      ax,AValue
       or       ax,ax
       jz       @@3
       xor      cl,cl

 @@1:  inc      cl
       shl      ax,01
       jnc      @@1

 @@2:  mov      al,11h
       sub      al,cl
 @@3:
 end;
 { ****************************************************** }

{ ************************************************************************** }
END.
{ ************************************************************************** }