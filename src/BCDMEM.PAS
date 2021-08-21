{ ************************************************************************** }
{  Diese Unit hier erweitert die Unit Memory um einige Routinen fuer BCD-    }
{ Zahlen. Der Zweck dieser Routinen ist die Ausgabe von Real-Zahlen.         }
{ ************************************************************************** }
{  This Unit contains procedures for calculating with BCD-Numbers.           }
{ ************************************************************************** }
{                                                                            }
{                          (c) 1999, Tobias Kohn                             }
{                                Version 2.0                                 }
{                                                                            }
{ ************************************************************************** }
{$G+}             { 286-Codes }
UNIT BCDMem;
{ ************************************************************************** }
INTERFACE
 USES Errors, Basics, Memory;
{ ************************************************************************** }

 CONST
   proc_Ld1     = $41;          { LbcdMem.Ld_1x }
   proc_BcdAdd  = $42;          { LBcdMem.Add }
   proc_Mul2    = $43;          { LBcdMem.Mul2 }
   proc_Div2    = $44;          { LBcdMem.Div2 }

 TYPE
   { ************************************************** }
   {  Dieses Objekt verwaltet den Spicher, der fuer die }
   { BCD-Berechnungen benoetigt wird.                   }
   { ************************************************** }
   {  Ld_1f      Schreibt in das erste Feld eine 1.     }
   {  Ld_1l      Schreibt in das letzte Feld eine 1.    }
   {  Add        Addiert zwei BCD-Zahlen miteinander.   }
   {              Der Rueckgabewert gibt den Uebertrag  }
   {              an.                                   }
   {  Mul2       Multipliziert den ganzen Speicherbe-   }
   {              reich mit 2.                          }
   {  Div2       Dividiert die Zahl durch 2.            }
   { ************************************************** }
   HBcdMem = ^LBcdMem;
   LBcdMem = object(LMem)
     procedure Ld_1f;
     procedure Ld_1l;
     function Add(var AMem): Byte;
     function Mul2: Byte;
     function Div2: Byte;
   end;

{ ************************************************************************** }
IMPLEMENTATION
{ ************************************************************************** }

 procedure LbcdMem.Ld_1f; assembler;
 asm
       les      di,self
       mov      cx,es:[di].LBcdMem.Size
       jcxz     @@2
       les      di,es:[di].LbcdMem.Address

       cld
       mov      ax,0001h
       stosw
       shr      cx,01
       dec      cx
       xor      ax,ax
       rep      stosw

       jmp      @@3
 @@2:  push     er_NotInit
       push     proc_Ld1
       push     es
       push     di
       call     SetError
 @@3:
 end;

 procedure LbcdMem.Ld_1l; assembler;
 asm
       les      di,self
       mov      cx,es:[di].LBcdMem.Size
       jcxz     @@2
       les      di,es:[di].LbcdMem.Address

       shr      cx,01
       dec      cx
       xor      ax,ax
       cld
       rep      stosw
       mov      ax,0100h
       stosw

       jmp      @@3
 @@2:  push     er_NotInit
       push     proc_Ld1
       push     es
       push     di
       call     SetError
 @@3:
 end;

 function LBcdMem.Add(var AMem): byte; assembler;
 asm
       push     ds
       les      di,self                 { Parameter laden. }
       mov      cx,es:[di].LBcdMem.Size
       jcxz     @@2
       les      di,es:[di].LBcdMem.Address
       lds      si,AMem

       std                              { Mit der Addition von hinten }
       add      di,cx                   { her beginnen. }
       add      si,cx
       dec      di
       dec      si
       xor      dh,dh                   { dh speichert den Uebertrag. }

 @@1:  lodsb
       xor      ah,ah
       mov      dl,es:[di]
       add      dl,dh
       add      al,dl
       aaa
       mov      dh,ah
       stosb
       loop     @@1

       mov      al,dh
       jmp      @@3
 @@2:  les      di,self                 { Fehler ausloesen }
       push     er_NotInit
       push     proc_BcdAdd
       push     es
       push     di
       call     SetError
       xor      al,al

 @@3:  pop      ds
 end;

 function LBcdMem.Mul2: Byte; assembler;
 asm
       les      di,self
       mov      cx,es:[di].LBcdMem.Size
       jcxz     @@2
       les      di,es:[di].LBcdMem.Address

       std
       add      di,cx
       dec      di
       xor      dx,dx
 @@1:  xor      ah,ah
       mov      al,es:[di]
       shl      ax,01
       aam

       add      al,dh                   { Uebertrag beruecksichtigen. }
       mov      dh,ah
       xor      ah,ah
       aaa
       add      dh,ah

       stosb
       loop     @@1

       mov      al,dh
       jmp      @@3
 @@2:  push     er_NotInit              { Fehler ausloesen. }
       push     proc_Ld1
       push     es
       push     di
       call     SetError
       xor      al,al
 @@3:
 end;

 function LBcdMem.Div2: Byte; assembler;
 asm
       les      di,self
       mov      cx,es:[di].LBcdMem.Size
       jcxz     @@2
       les      di,es:[di].LBcdMem.Address

       cld
       xor      dx,dx

 @@1:  xor      al,al
       mov      ah,es:[di]

       aad
       shr      ax,01
       aam
       add      ah,dl                           { Den Uebertrag nicht vergessen. }

       mov      dl,al
       mov      es:[di],ah
       inc      di
       loop     @@1

       mov      al,dl
       jmp      @@3
 @@2:  push     er_NotInit                      { Fehler ausloesen. }
       push     proc_Ld1
       push     es
       push     di
       call     SetError
       xor      al,al
 @@3:
 end;

{ ************************************************************************** }
END.
{ ************************************************************************** }