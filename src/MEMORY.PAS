{ ************************************************************************** }
{  Diese Unit soll die Grundlegende Maniplierung des Speichers erlauben, bzw }
{ vereinfachen (und evtl. beschleunigen). Ein Speicherblock wird hier als    }
{ Objekt angesehen.                                                          }
{  Leider verfuegen die hier aufgefuehrten Objekte und Routinen nicht (!)    }
{ ueber die Moeglichkeit, auf den Erweiterten Speicher zuzugreiffen. Diese   }
{ Routinen sind nur in der Lage, kleinere Speicherbloecke (bis 65 KB) im DOS-}
{ RAM zu bearbeiten.                                                         }
{ ************************************************************************** }
{  This unit provides some procedures that allow to manipulate the memory.   }
{ ************************************************************************** }
{                                                                            }
{                          (c) 1999, Tobias Kohn                             }
{                                Version 2.0                                 }
{                                                                            }
{ ************************************************************************** }
{  Hinweis: Alle Speichergroessen innerhalb dieser Unit werden in geraden    }
{ Werten angegeben. Wenn ein Wert ungerade ist, wird er dementsprechend      }
{ aufgerundet. Dies hat den Vorteil, dass verschiedene Routinen im Word-     }
{ Format (auch als Intel-Formaz bezeichnet) arbeiten koennen.                }
{  Fuer Details die Fehlerbehandlung betreffend siehe Unit Errors.           }
{ ************************************************************************** }
{  Benoetigte Units: -Errors: beinhaltet eine einfache Fehlerbehandlung;     }
{ ************************************************************************** }
{$G+}             { 286-Codes }
UNIT Memory;
{ ************************************************************************** }
INTERFACE
 USES Errors, Basics;
{ ************************************************************************** }

 CONST
   { *** Fehlerbehandlung: *** }
   er_NotInit     = $11;  { LMem wurde kein Speicher zugewisen. }
   er_ShiftRange  = $12;  { Es kann nicht weiter geshiftet werden als der }
                          { Speicherbereich gross ist ! }
   er_FileNotFound= $13;  { Der Computer findet die angegebene Datei nicht. }
   er_FileTooLarge= $14;  { Die Datei ist groesser als 1 Segment. }
   er_PntrNil     = $15;  { Ein Zeiger ist nil (der nicht nil sein sollte!) }
   er_MemRange    = $16;  { Ein Versuch, auf einen nicht zugewisenen Speicher zuzugreiffen. }
   er_DivZero     = $0101;{ Division durch Null (LIntMem.DivMem). }

                          { Prozedur: }
   proc_Alloc = $01;      { LMem.AllocMem }
   proc_Copy1 = $02;      { LMem.CopyTo }
   proc_Copy2 = $03;      { LMem.CopyFrom }
   proc_FillM = $04;      { LMem.Fill }
   proc_GtByt = $05;      { LMem.GetByte }
   proc_StByt = $06;      { LMem.SetByte }
   proc_ShftR = $07;      { LMem.ShiftR }
   proc_ShftL = $08;      { LMem.ShiftL }
   proc_SaveF = $09;      { LMem.SaveToFile }
   proc_LoadF = $0A;      { LMem.LoadFromFile }
   proc_Conv  = $0B;      { LIntMem.Convert }
   proc_Add   = $0C;      { LIntMem.Add / LintMem.Sub }
   proc_Mul   = $0D;      { LIntMem.Mul / LIntMem.Div }
   proc_AssObj= $0E;      { LMem.AssignObj }
   proc_LogMat= $0F;      { LLogMem.AddByte oder LLogMem.SubByte }
   proc_Logik = $10;      { LLogMem.OrMem oder AndMem oder XorMem oder NotMem }

   { ************************************************** }
   {  Fuer das Objekt LMem werden hier einige Konstant- }
   { en definiert, die jeweils die Nummer der Methode   }
   { in der VMT angeben.                                }
   { (Fuer genauere Angaben sehen sie bitte im          }
   { Programmierhandbuch zu Turbo Pascal 7.0 nach.)     }
   { ************************************************** }

   mt_Destr = $00;        { Done }
   mt_Free  = $01;        { Free }
   mt_AllcM = $02;        { AllocMem }
   mt_ReleM = $03;        { ReleaseMem }
   mt_AssM  = $04;        { AssignMem }
   mt_AssO  = $05;        { AssignObj }
   mt_ClrMe = $06;        { ClearMe }
   mt_CopyT = $07;        { CopyTo }
   mt_CopyF = $08;        { CopyFrom }
   mt_Fill  = $09;        { Fill }
   mt_Swap  = $0A;        { Swap }
   mt_GtByt = $0B;        { GetByte }
   mt_StByt = $0C;        { SetByte }
   mt_shrByt= $0D;        { shr_Bytes }
   mt_shlByt= $0E;        { shl_Bytes }
   mt_shrBit= $0F;        { shr_Bits }
   mt_shlBit= $10;        { shl_Bits }
   mt_SvFile= $11;        { SaveToFile }
   mt_LdFile= $12;        { LoadFromFile }
   mt_GtWrd = $13;        { GetWord }
   mt_StWrd = $14;        { SetWord }
   mt_Conv  = $15;        { Convert }
   mt_AddMem= $16;        { AddMem }
   mt_SubMem= $17;        { SubMem }
   mt_MulMem= $18;        { MulMem }
   mt_DivMem= $19;        { DivMem }

 TYPE
   { ************************************************** }
   {  Dieses Objekt soll einen Spicherblock im normalen }
   { RAM verwalten. Dies hier ist nur das Grundlagen-   }
   { objekt.                                            }
   { ************************************************** }
   {  Address    Die Adresse des zugewiesenen Speicher- }
   {              bereiches.                            }
   {  Size       Die Grîsse des zugewiesenen Speicher-  }
   {              bereiches.                            }
   { ************************************************** }
   {  InitMem    Initialisierung, wobei ein Speicher-   }
   {              block der Grîsse ASize angefordert    }
   {              wird.                                 }
   {  AllocMem   Anfordern eines Speicherblockes der    }
   {              Grîsse ASize (Bytes).                 }
   {  ReleaseMem Freigeben des Speicherblocks.          }
   {  AssignMem  Weist dem Objekt den durch APntr ange- }
   {              gebenen Speicherplatz der Grîsse      }
   {              ASize zu.                             }
   {  AssignObj  "Dupliziert" ein Objekt: das heisst,   }
   {              ein gewisser Speicherbereich wird nun }
   {              von zwei verschiedenen Objekten       }
   {              gleichzeitig verwaltet.               }
   {  ClearMe    Loescht die internen Felder, ohne zu   }
   {              versuchen, den Speicher wieder frei-  }
   {              zugeben (Gegenstueck zu AssignMem).   }
   {  CopyTo     Kopiert den Speicher in die Variable   }
   {              AMem. AMem sollte genug gross sein!   }
   {  CopyFrom   Kopiert die Variable AMem in den eige- }
   {              nen Speicher. Ist nicht genug Platz   }
   {              vorhanden, oder noch kein Speicher-   }
   {              platz zugewiesen, wird das nachgeholt.}
   {  Fill       Fuellt alle Bytes des zugewisenen Spei-}
   {              chers mit AValue.                     }
   {  Swap       Vertauscht den Inhalt des eigenen      }
   {              Speicherblockes mit dem Inhelt des    }
   {              Speicherblockes, der mit AMem angege- }
   {              ben wird.                             }
   {  GetByte    Interpretiert den Speicher als ein     }
   {              Array of Byte und ermittelt das ANr-  }
   {              te Element.                           }
   {  SetByte    s. GetByte. Diese Methode setzt jedoch }
   {              das ANr-te Element.                   }
   {  ShiftR     Shiftet den ganzen zugewisenen         }
   {              Speicherbereich um AShift Bits nach   }
   {              Rechts.                               }
   {  ShiftL     Shiftet den ganzen zugewisenen         }
   {              Speicherbereich um AShift Bits nach   }
   {              Links.                                }
   {  shr_Bytes..shl_Bits     Sind die Unterroutinen    }
   {              fuer ShiftX. Der Rueckgabewert zeigt  }
   {              an, ob innerhalb der Rouine ein Fehler}
   {              auftrat (false) oder nicht (true).    }
   {  SaveToFile Speichert den ganzen Speicherblock in  }
   {              die Datei AFileName ab. Existiert die }
   {              Datei bereits, wird sie ueber-        }
   {              schrieben.                            }
   {  LoadFrFile Laedt den Inhalt einer Datei in den    }
   {              Speicher.                             }
   { ************************************************** }
   HMem = ^LMem;
   LMem = object(LObject)
     Address: Pointer;
     Size   : Word;
     constructor InitMem(ASize: Word);
     destructor Done; virtual;

     procedure AllocMem(ASize: Word); virtual;
     procedure ReleaseMem; virtual;
     procedure AssignMem(APntr: Pointer; ASize: Word); virtual;
     procedure AssignObj(AMem: HMem); virtual;
     procedure ClearMe; virtual;

     procedure CopyTo(var AMem); virtual;
     procedure CopyFrom(var AMem); virtual;
     procedure Fill(AValue: Byte); virtual;
     procedure Swap(var AMem); virtual;

     function GetByte(ANr: Word): Byte; virtual;
     procedure SetByte(ANr: Word; AByte: Byte); virtual;

     procedure ShiftR(AShift: Word);
     procedure ShiftL(AShift: Word);

     function shr_Bytes(AShift: Word): Boolean; virtual;
     function shl_Bytes(AShift: Word): Boolean; virtual;
     function shr_Bits(AShift: Word): Boolean; virtual;
     function shl_Bits(AShift: Word): Boolean; virtual;

     procedure SaveToFile(AFileName: string); virtual;
     procedure LoadFromFile(AFileName: string); virtual;

     procedure SetError(ANr1, ANr2: Word);
   end;

   { ************************************************** }
   {  Folgendes Objekt erweitert LMem. Im Gegensatz zu  }
   { seinem Vorfahren benutzt dieses hier das Intel-    }
   { Format fuer die Speicherverwaltung. Das heisst, das}
   { die Bytes in "verkehrter" Reihenfolge im Speicher  }
   { angelegt sind.                                     }
   { ************************************************** }
   {  GetByte    Interpretiert den Speicher als ein     }
   {              Array of Byte und ermittelt das ANr-  }
   {              te Element.                           }
   {  SetByte    s. GetByte. Diese Methode setzt jedoch }
   {              das ANr-te Element.                   }
   {  GetWord    Interpretiert den Speicher als ein     }
   {              Array of Word und ermittelt das ANr-  }
   {              te Element.                           }
   {  SetWord    s. GetWord. Diese Methode setzt jedoch }
   {              das ANr-te Element.                   }
   {  ShiftR     Shiftet den ganzen zugewisenen         }
   {              Speicherbereich um AShift Bits nach   }
   {              Rechts.                               }
   {  ShiftL     Shiftet den ganzen zugewisenen         }
   {              Speicherbereich um AShift Bits nach   }
   {              Links.                                }
   {  Convert    Wandelt den Speicherinhalt vom linear- }
   {              ins Intel-Format um oder umgekehrt.   }
   {  AddMem     Addiert zum Speicher einen gleichgros- }
   {              sen Speicherbereich dazu.             }
   {  SubMem     Subtrahiert vom Speicher einen anderen }
   {              Speicherbereich.                      }
   {  MulMem     Multipliziert den ganzen Speicherblock }
   {              mit AWert.                            }
   {  DivMem     Dividiert den ganzen Speicherblock     }
   {              durch AWert.                          }
   { ************************************************** }
   HIntMem = ^LIntMem;
   LIntMem = object(LMem)
     function GetByte(ANr: Word): Byte; virtual;
     procedure SetByte(ANr: Word; AByte: Byte); virtual;
     function GetWord(ANr: Word): Word; virtual;
     procedure SetWord(ANr: Word; AWord: Word); virtual;

     function shr_Bytes(AShift: Word): Boolean; virtual;
     function shl_Bytes(AShift: Word): Boolean; virtual;
     function shr_Bits(AShift: Word): Boolean; virtual;
     function shl_Bits(AShift: Word): Boolean; virtual;

     procedure Convert; virtual;

     procedure AddMem(var AMem); virtual;
     procedure SubMem(var AMem); virtual;
     procedure MulMem(AWert: Word); virtual;
     procedure DivMem(AWert: Word); virtual;
   end;

   { ************************************************** }
   {  Das Objekt LogMem (Logik) beinhaltet in erster    }
   { Linie Routinen, die die einzelnen Bytes logisch    }
   { oder Mathematisch manipulieren.                    }
   { ************************************************** }
   {  AddByte    Addiert zu jedem Byte des Speichers    }
   {              den angegebenen Wert hinzu.           }
   {  SubByte    Subtrahiert von jedem Byte des Spei-   }
   {              chers den angegebenen Wert.           }
   {  OrByte     Setzt in jedem Byte die durch AWert    }
   {              angegebenen Bits.                     }
   {  AndByte    Loescht alle bis auf die in AWert ange-}
   {              gebenen Bits.                         }
   {  XorByte    Laesst nur diejenigen Bits stehen, die }
   {              entweder in AWert oder im Speicherbyte}
   {              vorkommen, aber nicht an beiden Orten.}
   {  NotMem     Invertiert jedes Byte.                 }
   { ************************************************** }
   HLogMem = ^LLogMem;
   LLogMem = object(LMem)
     procedure AddByte(AWert: Byte);
     procedure SubByte(AWert: Byte);
     procedure OrByte(AWert: Byte);
     procedure AndByte(AWert: Byte);
     procedure XorByte(AWert: Byte);
     procedure NotMem;
   end;

   { ************************************************** }
   {  Dieser Typ ermoeglicht es, auf jeden beliebigen   }
   { Speicher (ohne Objekte) wie auf ein array of Byte  }
   { zuzugreiffen. Wegen seiner Groesse sollte er jedoch}
   { nicht als Variable deklariert werden.              }
   { ************************************************** }
   {  Bsp:      var     str1: string;                   }
   {            begin   str1 := 'Hallo Welt';           }
   {                    LByteArray(str1)[3] = ord('e'); }
   {                   => str1 = 'Hello Welt' !!!       }
   { ************************************************** }
   HByteArray = ^LByteArray;
   LByteArray = array[0..65000] of byte;

   { ************************************************** }
   {  SwapMem    Vertauscht die Inhalte der zwei durch  }
   {              AMem angegebenen Speicherbereiche der }
   {              Groesse ASize.                        }
   {  CopyMem    Kopiert AMem2 nach AMem1.              }
   { ************************************************** }
   procedure SwapMem(var AMem1, AMem2; ASize: Word);
   procedure CopyMem(var AMem1, AMem2; ASize: Word);

 VAR
   ErrorObj: ErrorObject;

{ ************************************************************************** }
IMPLEMENTATION
{ ************************************************************************** }

 { ****************************************************** }
 constructor LMem.InitMem(ASize: Word);
 begin
   Inherited Init;
   AllocMem(ASize);             { Speicherbereich belegen. }
 end;

 destructor LMem.Done;
 begin
   if not (Size = 0) then ReleaseMem;   { Allenfalls belegten Platz im Heap }
   inherited Done;                      { noch freigeben.                   }
 end;

 procedure LMem.AllocMem(ASize: Word);
 var
   p: Pointer;
 begin
   ReleaseMem;                  { Allenfalls noch besetzten Speicher freigeben. }
   Size := ASize;
   if ((ASize and $01) = $01)   { Alle Speicher-Grîssen sollen gerade sein. }
    then inc(Size);
   GetMem(p, Size);             { Versuchen, den Speicherplatz anzufordern. }
   if (p = nil) then begin      { Fehlgeschlagen: Fehler auslîsen. }
     ErrorObj.SetError(er_TPIntern, proc_Alloc);
     Size := 0; exit;
   end;
   Address := p;                { Adresse speichern. }
   FillChar(p^, Size, 0);       { Speicherbereich auf Null setzen. }
 end;

 procedure LMem.ReleaseMem;
 begin
   if (Size = 0) then exit;        { Den Speicherbereich nur freigeben, }
                                   { wenn er vorher auf dem Heap reserviert wurde. }
   FreeMem(Address, Size);
   Size := 0; Address := nil;
 end;

 procedure LMem.AssignMem(APntr: Pointer; ASize: Word);
 begin
   ReleaseMem;
   Size := ASize;
   Address := APntr;
 end;

 procedure LMem.AssignObj(AMem: HMem);
 begin
   if (AMem = nil)
    then ErrorObj.SetError(er_PntrNil, proc_AssObj)
    else AssignMem(AMem^.Address, AMem^.Size);
 end;

 procedure LMem.ClearMe;
 begin
   Size := 0;
   Address := nil;
 end;

 procedure LMem.CopyTo(var AMem); assembler;
 asm
       push     ds

       les      di,self                 { Pruefen, ob ueberhaupt eigener Speicher }
       mov      cx,es:[di].LMem.Size    { vorhanden ist, ansonsten abbrechen. }
       jcxz     @@1

       lds      si,es:[di].LMem.Address { Die Speicheradresse des eigenen Speichers }
                                        { laden. }
       les      di,AMem                 { Die Adresse des neuen Speicherbereichs }
       cld                              { laden. }

       shr      cx,01                   { Wordweise kopieren. (Erfordern nur die }
       rep      movsw                   { Haelfte der Schleifen-Durchgaenge). }

       jmp      @@2
 @@1:  les      di,self                 { Kein Speicherbereich zugewiesen: }
       push     er_NotInit              { Fehler ausloesen. }
       push     proc_Copy1
       push     es
       push     di
       call     SetError

 @@2:  pop      ds
 end;

 procedure LMem.CopyFrom(var AMem); assembler;
 asm
       push     ds

       les      di,self                 { Pruefen, ob ueberhaupt eigener Speicher }
       mov      cx,es:[di].LMem.Size    { vorhanden ist, ansonsten abbrechen. }
       jcxz     @@1

       les      di,es:[di].LMem.Address { Die Speicheradresse des eigenen Speichers }
                                        { laden. }
       lds      si,AMem                 { Die Adresse des neuen Speicherbereichs }
       cld                              { laden. }

       shr      cx,01                   { Wordweise kopieren. (Erfordern nur die }
       rep      movsw                   { Haelfte der Schleifen-Durchgaenge). }

       jmp      @@2
 @@1:  les      di,self                 { Kein Speicherbereich zugewiesen: }
       push     er_NotInit              { Fehler ausloesen. }
       push     proc_Copy2
       push     es
       push     di
       call     SetError

 @@2:  pop      ds
 end;

 procedure LMem.Swap(var AMem); assembler;
 asm
       push     ds
       les      di,self                 { Daten wie Groesse und Zeiger laden. }
       mov      cx,es:[di].LMem.Size
       jcxz     @@2
       les      di,es:[di].LMem.Address
       lds      si,AMem

       cld
       shr      cx,01                   { Pro Durchgang ein Word (2 Bytes) }
 @@1:  mov      ax,es:[di]              { verarbeiten: erfordert nur halb so  }
       xchg     ds:[si],ax              { viele Durchgange. }
       stosw
       inc      si
       inc      si
       loop     @@1

       jmp      @@3
 @@2:  les      di,self                 { Kein Speicherbereich zugewiesen: }
       push     er_NotInit              { Fehler ausloesen. }
       push     proc_Copy2
       push     es
       push     di
       call     SetError
 @@3:  pop      ds
 end;

 procedure LMem.Fill(AValue: Byte); assembler;
 asm
       les      di,self
       mov      cx,es:[di].LMem.Size    { Groesse und Adresse des Sepicherbereiches }
       jcxz     @@1                     { laden.  }
       les      di,es:[di].LMem.Address

       cld
       mov      al,AValue               { Pro Durchgang immer gleich 2 Bytes }
       mov      ah,al                   { schreiben. }
       shr      cx,01
       jnc      @@3
       stosb
 @@3:  rep      stosw

       jmp      @@2
 @@1:  les      di,self                 { Einen Fehler ausloesen. }
       push     er_NotInit
       push     proc_FillM
       push     es
       push     di
       call     SetError
 @@2:
 end;

 function LMem.GetByte(ANr: Word): Byte; assembler;
 asm
       les      di,self
       mov      cx,es:[di].LMem.Size    { Pruefen, ob ueberhaupt Speicher }
       jcxz     @@1                     { zugewiesen wurde und ob ANr }
       mov      bx,ANr                  { innerhalb dieses Speichers liegt. }
       cmp      bx,cx
       jae      @@1

       les      di,es:[di].LMem.Address { ANr-tes Element laden. }
       mov      al,es:[di+bx]

       jmp      @@2
 @@1:  push     er_NotInit              { Fehler ausloesen. }
       push     proc_GtByt
       push     es
       push     di
       call     SetError
       xor      al,al
 @@2:
 end;

 procedure LMem.SetByte(ANr: Word; AByte: Byte); assembler;
 asm
       les      di,self
       mov      cx,es:[di].LMem.Size    { Pruefen, ob ueberhaupt Speicher }
       jcxz     @@1                     { zugewiesen wurde und ob ANr }
       mov      bx,ANr                  { innerhalb dieses Speichers liegt. }
       cmp      bx,cx
       jae      @@1

       les      di,es:[di].LMem.Address { ANr-tes Element setzen. }
       mov      al,AByte
       mov      es:[di+bx],al

       jmp      @@2
 @@1:  push     er_NotInit              { Fehler ausloesen. }
       push     proc_StByt
       push     es
       push     di
       call     SetError
 @@2:
 end;

 procedure LMem.ShiftR(AShift: Word); assembler;
 asm
       push     ds
       les      di,self
       mov      cx,es:[di].LMem.Size    { Pruefen, ob der Speicher zugewiesen }
       jcxz     @@2                     { wurde. }

       mov      ax,AShift               { Auftrennen in Bit- und Byte- }
       mov      dx,ax                   { Shiftwerte. }
       and      dx,07h
       shr      ax,03h

       or       ax,ax                   { Prozedur zum Shiften der Bytes }
       jz       @@1                     { aufrufen. }
       push     dx
       push     ax
       push     es                      { (Die Prozeduren nur aufrufen, wenn }
       push     di                      { es auch etwas zum Shiften gibt!) }
       mov      di,es:[di]              { shr_Bytes }
       call     dword ptr [di+08+(mt_shrByt*4)]
       pop      dx
       or       ax,ax                   { Wenn etwas schiefgelaufen ist, Routine }
       jz       @@3                     { ganz abbrechen. }

 @@1:  or       dx,dx                   { Prozedur zum Shiften der Bits }
       jz       @@3                     { aufrufen. }
       les      di,self
       push     dx
       push     es
       push     di
       mov      di,es:[di]              { shr_Bits }
       call     dword ptr [di+08+(mt_shrBit*4)]

       jmp      @@3
 @@2:  push     er_NotInit              { Fehler ausloesen. }
       push     proc_ShftR
       push     es
       push     di
       call     SetError
 @@3:  pop      ds
 end;

 procedure LMem.ShiftL(AShift: Word); assembler;
 asm
       push     ds
       les      di,self
       mov      cx,es:[di].LMem.Size    { Pruefen, ob der Speicher zugewiesen }
       jcxz     @@2                     { wurde. }

       mov      ax,AShift               { Auftrennen in Bit- und Byte- }
       mov      dx,ax                   { Shiftwerte. }
       and      dx,07h
       shr      ax,03h

       or       ax,ax                   { Prozedur zum Shiften der Bytes }
       jz       @@1                     { aufrufen. }
       push     dx
       push     ax
       push     es                      { (Die Prozeduren nur aufrufen, wenn }
       push     di                      { es auch etwas zum Shiften gibt!) }
       mov      di,es:[di]              { shlByt }
       call     dword ptr [di+08+(mt_shlByt*4)]
       pop      dx
       or       ax,ax                   { Wenn etwas schiefgelaufen ist, Routine }
       jz       @@3                     { ganz abbrechen. }

 @@1:  or       dx,dx                   { Prozedur zum Shiften der Bits }
       jz       @@3                     { aufrufen. }
       les      di,self
       push     dx
       push     es
       push     di
       mov      di,es:[di]              { shl_Bits }
       call     dword ptr [di+08+(mt_shlBit*4)]

       jmp      @@3
 @@2:  push     er_NotInit              { Fehler ausloesen. }
       push     proc_ShftL
       push     es
       push     di
       call     SetError
 @@3:  pop      ds
 end;

 function LMem.shr_Bytes(AShift: Word): boolean; assembler;
 asm
       push     ds
       mov      bx,er_NotInit
       les      di,self                 { Die Werte laden: }
       mov      cx,es:[di].LMem.Size    { Groesse, Adresse, Shift-Anzahl }
       jcxz     @@2                     { (Noch auf Fehler pruefen) }
       les      di,es:[di].LMem.Address
       mov      ax,AShift

       mov      bx,er_ShiftRange
       cmp      ax,cx                   { Man kann nicht mehr Shiften, als }
       jae      @@2                     { der Speicherbereich gross ist. }

       push     es                      { Quell- und Ziel-Zeiger ausrichten. }
       pop      ds
       add      di,cx
       dec      di
       mov      si,di
       sub      si,ax

       std                              { Alle Bytes verschieben. }
       sub      cx,ax
       shr      cx,01
       jnc      @@1
       movsb
 @@1:  dec      di
       dec      si
       rep      movsw
       inc      di

       mov      cx,AShift
       xor      al,al                   { Rest mit Nullen auffuellen. }
       rep      stosb

       mov      al,true
       jmp      @@3
 @@2:  les      di,self                 { Fehler ausloesen. }
       push     bx                      { => Fuer die Fehlerbehandlung }
       push     proc_ShftR              { wurden alle SHR-Methoden zusam- }
       push     es                      { mengefasst (proc_shftR)! }
       push     di
       call     SetError
       mov      al,false
 @@3:  pop      ds
 end;

 function LMem.shl_Bytes(AShift: Word): boolean; assembler;
 asm
       push     ds
       mov      bx,er_NotInit
       les      di,self                 { Die Werte laden: }
       mov      cx,es:[di].LMem.Size    { Groesse, Adresse, Shift-Anzahl }
       jcxz     @@2                     { (Noch auf Fehler pruefen) }
       les      di,es:[di].LMem.Address
       mov      ax,AShift

       mov      bx,er_ShiftRange
       cmp      ax,cx                   { Man kann nicht mehr Shiften, als }
       jae      @@2                     { der Speicherbereich gross ist. }

       push     es                      { Quell- und Ziel-Zeiger ausrichten. }
       pop      ds
       mov      si,di
       add      si,ax

       cld                              { Alle Bytes verschieben. }
       sub      cx,AShift
       shr      cx,01
       jnc      @@1
       movsb
 @@1:  rep      movsw

       mov      cx,AShift
       xor      al,al                   { Rest mit Nullen auffuellen. }
       rep      stosb

       mov      al,true
       jmp      @@3
 @@2:  les      di,self                 { Fehler ausloesen. }
       push     bx                      { => Fuer die Fehlerbehandlung }
       push     proc_ShftL              { wurden alle SHL-Methoden zusam- }
       push     es                      { mengefasst (proc_shftL)! }
       push     di
       call     SetError
       mov      al,false
 @@3:  pop      ds
 end;

 function LMem.shr_Bits(AShift: Word): boolean; assembler;
 asm
       push     ds
       les      di,self                 { Die Groesse und die Startadresse }
       mov      cx,es:[di].LMem.Size    { des Speicherblockes laden und }
       mov      bx,er_NotInit           { pruefen, ob der Speicher initialisiert }
       jcxz     @@3                     { ist. }
       les      di,es:[di].LMem.Address

       mov      bx,er_ShiftRange       { AShift darf nicht groesser sein als 7 }
       mov      ax,AShift
       test     ax,0FFF8h
       jnz      @@3

       push     es                      { ds:si := es:di }
       pop      ds
       add      di,cx                   { Von "hinten" her beginnen. }
       dec      di
       mov      si,di
       std
       mov      bx,ax                   { bh wird als Flag benutzt: Im ersten }
       mov      bh,01                   { Durchgang soll kein Uebertrag in den }
                                        { Speicher geschrieben werden. }
 @@1:  push     cx
       mov      cl,bl                   { cl enthaelt die Anzahl der zu }
       xor      ah,ah                   { shiftenden Bits. }
       lodsb                            { al=0 und ah aus dem Speicher laden. }
       xchg     al,ah                   { => Bei der R-Schiebung bleibt der Uebertrag in al. }
       shr      ax,cl                   { Nun schieben. }
       xchg     al,ah
       or       bh,bh
       jnz      @@2

       mov      dl,es:[di+01]           { Uebertrag schreiben. }
       or       ah,dl
       mov      es:[di+01],ah

 @@2:  stosb                            { Naechster Schleifendurchgang. }
       xor      bh,bh
       pop      cx
       loop     @@1

       mov      al,true
       jmp      @@4
 @@3:  les      di,self                 { Fehler ausloesen. }
       push     bx
       push     proc_ShftR
       push     es
       push     di
       call     SetError
       mov      al,false
 @@4:  pop      ds
 end;

 function LMem.shl_Bits(AShift: Word): boolean; assembler;
 asm
       push     ds
       les      di,self                 { Die Groesse und die Startadresse }
       mov      cx,es:[di].LMem.Size    { des Speicherblockes laden und }
       mov      bx,er_NotInit           { pruefen, ob der Speicher initialisiert }
       jcxz     @@3                     { ist. }
       les      di,es:[di].LMem.Address

       mov      bx,er_ShiftRange       { AShift darf nicht groesser sein als 7 }
       mov      ax,AShift
       test     ax,0FFF8h
       jnz      @@3

       push     es                      { ds:si := es:di }
       pop      ds
       mov      si,di
       cld
       mov      bx,ax                   { bh wird als Flag benutzt: Im ersten }
       mov      bh,01                   { Durchgang soll kein Uebertrag in den }
                                        { Speicher geschrieben werden. }
 @@1:  push     cx
       mov      cl,bl                   { cl enthaelt die Anzahl der zu }
       xor      ah,ah                   { shiftenden Bits. }
       lodsb                            { al=0 und ah aus dem Speicher laden. }
                                        { => Bei der R-Schiebung bleibt der Uebertrag in al. }
       shl      ax,cl                   { Nun schieben. }
       or       bh,bh
       jnz      @@2

       mov      dl,es:[di-01]           { Uebertrag schreiben. }
       or       ah,dl
       mov      es:[di-01],ah

 @@2:  stosb                            { Naechster Schleifendurchgang. }
       xor      bh,bh
       pop      cx
       loop     @@1

       mov      al,true
       jmp      @@4
 @@3:  les      di,self                 { Fehler ausloesen. }
       push     bx
       push     proc_ShftL
       push     es
       push     di
       call     SetError
       mov      al,false
 @@4:  pop      ds
 end;

 procedure LMem.SetError(ANr1, ANr2: Word);
 begin
   ErrorObj.SetError(ANr1, ANr2);
 end;

 procedure LMem.SaveToFile(AFileName: string);
 var
   f: file;
 begin
   if (Size = 0) then begin
     ErrorObj.SetError(er_NotInit, proc_SaveF);
   end;
   Assign(f, AFileName);                { Datei neu erstellen und festlegen, dass jeweils  }
   ReWrite(f, Size);                    { "Size" Bytes pro Zyklus geschrieben werden sollen. }
   if not (IOResult = 0) then begin     { Fehler abfangen. }
     ErrorObj.SetError(er_TPIntern, proc_SaveF);
     exit;
   end;
   BlockWrite(f, Address^, 1);          { Speicherinhalt in Datei schreiben. }
   Close(f);
 end;

 procedure LMem.LoadFromFile(AFileName: string);
 var
   f: file;
   sz: LongInt;
   er: Word;
 begin
   ReleaseMem;                          { Vorher besetzten Speicher freigeben. }
   Assign(f, AFileName);
   ReSet(f, 1);
   if not (IOResult = 0) then begin     { Fehler abfangen. }
     if (IOResult = 2)
      then er := er_FileNotFound
      else er := er_TPIntern;
     ErrorObj.SetError(er, proc_LoadF);
     exit;
   end;
   sz := FileSize(f);                   { Zuerst die Groesse der Datei bestimmen! }
   if (sz > 65500) then begin           { Speicher kann Segmentgroesse nicht ueberschreiten. }
     ErrorObj.SetError(er_FileTooLarge, proc_LoadF);
     exit;
   end;
   AllocMem(sz);                        { Speicher reservieren. }
   if (Size = 0) then exit;             { ..Fehlgeschlagen ! (Fehler wird in AllocMem abgefanngen.) }
   Close(f);
   ReSet(f, sz);                        { Datei neu oeffnen und die Daten }
   BlockRead(f, Address^ ,1);           { einlesen. }
   Close(f);
 end;

 { ****************************************************** }
 { ****************************************************** }

 function LIntMem.GetByte(ANr: Word): Byte; assembler;
 asm
       les      di,self
       mov      cx,es:[di].LIntMem.Size
       jcxz     @@1
       les      di,es:[di].LIntMem.Address
       sub      cx,ANr
       add      di,cx
       dec      di
       mov      al,es:[di]

       jmp      @@2
 @@1:  push     er_NotInit
       push     proc_GtByt
       push     es
       push     di
       call     SetError
 @@2:
 end;

 procedure LIntMem.SetByte(ANr: Word; AByte: Byte); assembler;
 asm
       les      di,self
       mov      cx,es:[di].LIntMem.Size
       jcxz     @@1
       les      di,es:[di].LIntMem.Address
       sub      cx,ANr
       add      di,cx
       dec      di
       mov      al,AByte
       mov      es:[di],al

       jmp      @@2
 @@1:  push     er_NotInit
       push     proc_StByt
       push     es
       push     di
       call     SetError
 @@2:
 end;

 function LIntMem.GetWord(ANr: Word): Word; assembler;
 asm
       les      di,self
       mov      bx,er_NotInit
       mov      cx,es:[di].LIntMem.Size
       jcxz     @@1
       les      di,es:[di].LIntMem.Address
       mov      bx,er_MemRange
       mov      ax,ANr
       inc      ax
       shl      ax,01
       sub      cx,ax
       jb       @@1
       add      di,cx
       jnc      @@3
       mov      dx,es
       add      dx,1000h
       mov      es,dx
 @@3:  mov      ax,es:[di]

       jmp      @@2
 @@1:  les      di,self
       push     bx
       push     proc_GtByt
       push     es
       push     di
       call     SetError
       xor      ax,ax
 @@2:
 end;

 procedure LIntMem.SetWord(ANr: Word; AWord: Word); assembler;
 asm
       les      di,self
       mov      cx,es:[di].LIntMem.Size
       jcxz     @@1
       les      di,es:[di].LIntMem.Address
       mov      ax,ANr
       inc      ax
       shl      ax,01
       sub      cx,ax
       add      di,cx
       mov      ax,AWord
       mov      es:[di],ax

       jmp      @@2
 @@1:  les      di,self
       push     er_NotInit
       push     proc_StByt
       push     es
       push     di
       call     SetError
 @@2:
 end;

 function LIntMem.shr_Bytes(AShift: Word): Boolean;
 begin
   shr_Bytes := LMem.shl_Bytes(AShift);
 end;

 function LIntMem.shl_Bytes(AShift: Word): Boolean;
 begin
   shl_Bytes := LMem.shr_Bytes(AShift);
 end;

 function LIntMem.shr_Bits(AShift: Word): Boolean; assembler;
 asm
       les      di,self                 { Speichergroesse und Adresse laden und }
       mov      bx,er_NotInit           { pruefen, ob der Speicher initialisiert }
       mov      cx,es:[di].LIntMem.Size { ist. }
       jcxz     @@2
       les      di,es:[di].LIntMem.Address

       mov      bx,er_ShiftRange        { Diese Routine ist nicht dazu geeignet, }
       mov      ax,AShift               { mehr als 7 Bits pro Durchgang zu schieben. }
       test     ax,0FFF8h               { (8 Bits waeren dann ein Byte.) }
       jnz      @@2

       add      di,cx                   { Von "hinten" beginnen und gegen unten }
       mov      bl,al                   { arbeiten. }
       xor      bh,bh
 @@1:  push     cx
       dec      di

       mov      ah,es:[di]              { Zuerst den Wert aus dem Speicher }
       xor      al,al                   { laden und schieben. }
       mov      cl,bl
       shr      ax,cl

       or       ah,bh                   { Den Uebertrag berÅcksichtigen und }
       mov      bh,al                   { den neuen Wert in den Speicher }
       mov      es:[di],ah              { schreiben. }

       pop      cx
       loop     @@1

       mov      al,true
       jmp      @@3
 @@2:  push     bx                      { Fehlerroutine. }
       push     proc_StByt
       push     es
       push     di
       call     SetError
       mov      al,false
 @@3:
 end;

 function LIntMem.shl_Bits(AShift: Word): Boolean; assembler;
 asm
       les      di,self                 { Speichergroesse und Adresse laden und }
       mov      bx,er_NotInit           { pruefen, ob der Speicher initialisiert }
       mov      cx,es:[di].LIntMem.Size { ist. }
       jcxz     @@2
       les      di,es:[di].LIntMem.Address

       mov      bx,er_ShiftRange        { Diese Routine ist nicht dazu geeignet, }
       mov      ax,AShift               { mehr als 7 Bits pro Durchgang zu schieben. }
       test     ax,0FFF8h               { (8 Bits waeren dann ein Byte.) }
       jnz      @@2

       mov      bl,al
       xor      bh,bh
 @@1:  push     cx

       mov      al,es:[di]              { Werte aus dem Speicher laden und }
       xor      ah,ah                   { schieben. }
       mov      cl,bl
       shl      ax,cl

       or       al,bh                   { Uebertrag beruecksichtigen und }
       mov      bh,ah                   { die neuen Werte speichern. }
       mov      es:[di],al
       inc      di

       pop      cx
       loop     @@1


       mov      al,true
       jmp      @@3
 @@2:  push     bx                      { Fehlerroutine. }
       push     proc_StByt
       push     es
       push     di
       call     SetError
       mov      al,false
 @@3:
 end;

 procedure LIntMem.Convert; assembler;
 asm
       push     ds
       les      di,self                         { Diese Routine "spiegelt" den }
       mov      cx,es:[di].LIntMem.Size         { zugewiesenen Speicher in der }
       jcxz     @@2                             { Mitte. Das erste Element wird }
                                                { mit dem letzten vertauscht, das }
       lds      si,es:[di].LIntMem.Address      { zweite mit dem zweitletzen usf. }
       les      di,es:[di].LIntMem.Address
       add      di,cx

       cld
       shr      cx,01                           { Die Routine arbeitet von aussen }
 @@1:  lodsb                                    { nach innen, nicht von links nach }
       dec      di                              { rechts. Daher muss die Schleife }
       xchg     es:[di],al                      { auch nur (Size/2)-Mal ausgefÅhrt }
       mov      ds:[si-01],al                   { werden. }
       loop     @@1

       jmp      @@3
 @@2:  push     er_NotInit                      { Fehler abfangen. }
       push     proc_StByt
       push     es
       push     di
       call     SetError
 @@3:  pop      ds
 end;

 procedure LIntMem.AddMem(var AMem); assembler;
 asm
       push     ds                              { Felder initialisieren }
       les      di,self
       mov      cx,es:[di].LIntMem.Size
       jcxz     @@3
       lds      si,AMem
       les      di,es:[di].LIntMem.Address

       cld
       xor      bx,bx
       shr      cx,01                           { Bei jedem Durchgang ein Word }
 @@1:  lodsw                                    {     bearbeiten. }
       mov      dx,es:[di]                      { Felder laden. }

       add      dx,bx                           { Uebertrag beruecksichtigen. }
       adc      bh,00
       xor      bl,bl
       xchg     bl,bh

       add      ax,dx                           { Addition durchfuehren. }
       adc      bl,00
       stosw
       loop     @@1

       jmp      @@3
 @@2:  push     er_NotInit                      { Fehler abfangen. }
       push     proc_Add
       push     es
       push     di
       call     SetError
 @@3:  pop      ds
 end;

 procedure LIntMem.SubMem(var AMem); assembler;
 asm
       push     ds                              { Felder initialisieren }
       les      di,self
       mov      cx,es:[di].LIntMem.Size
       jcxz     @@3
       lds      si,AMem
       les      di,es:[di].LIntMem.Address

       cld
       xor      bx,bx
       shr      cx,01                           { Bei jedem Durchgang ein Word }
 @@1:  lodsw                                    {     bearbeiten. }
       mov      dx,es:[di]                      { Felder laden. }

       add      ax,bx                           { Uebertrag beruecksichtigen. }
       adc      bh,00
       xor      bl,bl
       xchg     bl,bh

       sub      dx,ax                           { Subtraktion durchfuehren. }
       adc      bl,00
       xchg     ax,dx
       stosw
       loop     @@1

       jmp      @@3
 @@2:  push     er_NotInit                      { Fehler abfangen. }
       push     proc_Add
       push     es
       push     di
       call     SetError
 @@3:  pop      ds
 end;

 procedure LIntMem.MulMem(AWert: Word); assembler;
 asm
       les      di,self                         { Parameter laden. }
       mov      cx,es:[di].LIntMem.Size
       jcxz     @@2
       les      di,es:[di].LIntMem.Address
       mov      bx,AWert

       cld                              { Pro Durchgang ein Word verarbeiten. }
       shr      cx,01
       xor      si,si                   { SI ist hier das Uebertrag-Word. }
 @@1:  mov      ax,es:[di]

       mul      bx                      { Multplizieren und Uebertrag berueck- }
       add      ax,si                   { sichtigen. }
       adc      dx,00
       mov      si,dx

       stosw
       loop     @@1

       jmp      @@3
 @@2:  push     er_NotInit                      { Fehler abfangen. }
       push     proc_Mul
       push     es
       push     di
       call     SetError
 @@3:
 end;

 procedure LIntMem.DivMem(AWert: Word); assembler;
 asm
       les      di,self                         { Parameter laden. }
       mov      bx,er_NotInit
       mov      cx,es:[di].LIntMem.Size
       jcxz     @@3
       les      di,es:[di].LIntMem.Address
       mov      bx,AWert
       or       bx,bx
       jz       @@2

       std
       add      di,cx                   { Wiederum pro Durchgang ein Word }
       sub      di,02                   { verarbeiten. }
       shr      cx,01
       xor      dx,dx
 @@1:  mov      ax,es:[di]              { Der Uebertrag wird schon automatisch }
       div      bx                      { im DX-Register verwaltet. }
       stosw
       loop     @@1

       jmp      @@4
 @@2:  mov      bx,er_DivZero
 @@3:  push     bx                              { Fehler abfangen. }
       push     proc_Mul
       push     es
       push     di
       call     SetError
 @@4:
 end;

 { ****************************************************** }
 procedure LLogMem.AddByte(AWert: Byte); assembler;
 asm
       les      di,self
       mov      cx,es:[di].LLogMem.Size;        { Werte laden. }
       jcxz     @@2
       les      di,es:[di].LLogMem.Address
       mov      dl,AWert

       cld
 @@1:  mov      al,es:[di]                      { Alle Bytes addieren: }
       add      al,dl                           { Uebertraege werden nicht }
       stosb                                    { beruecksichtigt ! }
       loop     @@1

       jmp      @@3
 @@2:  push     er_NotInit                      { Fehler abfangen. }
       push     proc_LogMat
       push     es
       push     di
       call     SetError
 @@3:
 end;

 procedure LLogMem.SubByte(AWert: Byte); assembler;
 asm
       les      di,self
       mov      cx,es:[di].LLogMem.Size;        { Werte laden. }
       jcxz     @@2
       les      di,es:[di].LLogMem.Address
       mov      dl,AWert

       cld
 @@1:  mov      al,es:[di]                      { Alle Bytes subtrahieren: }
       sub      al,dl                           { Uebertraege werden nicht }
       stosb                                    { beruecksichtigt ! }
       loop     @@1

       jmp      @@3
 @@2:  push     er_NotInit                      { Fehler abfangen. }
       push     proc_LogMat
       push     es
       push     di
       call     SetError
 @@3:
 end;

 procedure LLogMem.OrByte(AWert: Byte); assembler;
 asm
       les      di,self
       mov      cx,es:[di].LLogMem.Size;        { Werte laden. }
       jcxz     @@2
       les      di,es:[di].LLogMem.Address
       mov      dl,AWert
       mov      dh,dl

       cld
       shr      cx,01
 @@1:  mov      ax,es:[di]                      { Alle Bytes (Wordweise) }
       or       ax,dx                           { mit AWert or-verknuepfen. }
       stosw
       loop     @@1

       jmp      @@3
 @@2:  push     er_NotInit                      { Fehler abfangen. }
       push     proc_Logik
       push     es
       push     di
       call     SetError
 @@3:
 end;

 procedure LLogMem.AndByte(AWert: Byte); assembler;
 asm
       les      di,self
       mov      cx,es:[di].LLogMem.Size;        { Werte laden. }
       jcxz     @@2
       les      di,es:[di].LLogMem.Address
       mov      dl,AWert
       mov      dh,dl

       cld
       shr      cx,01
 @@1:  mov      ax,es:[di]                      { Alle Bytes (Wordweise) }
       and      ax,dx                           { mit AWert and-verknuepfen. }
       stosw
       loop     @@1

       jmp      @@3
 @@2:  push     er_NotInit                      { Fehler abfangen. }
       push     proc_Logik
       push     es
       push     di
       call     SetError
 @@3:
 end;

 procedure LLogMem.XorByte(AWert: Byte); assembler;
 asm
       les      di,self
       mov      cx,es:[di].LLogMem.Size;        { Werte laden. }
       jcxz     @@2
       les      di,es:[di].LLogMem.Address
       mov      dl,AWert
       mov      dh,dl

       cld
       shr      cx,01
 @@1:  mov      ax,es:[di]                      { Alle Bytes (Wordweise) }
       xor      ax,dx                           { mit AWert xor-verknuepfen. }
       stosw
       loop     @@1

       jmp      @@3
 @@2:  push     er_NotInit                      { Fehler abfangen. }
       push     proc_Logik
       push     es
       push     di
       call     SetError
 @@3:
 end;

 procedure LLogMem.NotMem; assembler;
 asm
       les      di,self
       mov      cx,es:[di].LLogMem.Size;        { Werte laden. }
       jcxz     @@2
       les      di,es:[di].LLogMem.Address

       cld
       shr      cx,01
 @@1:  mov      ax,es:[di]                      { Alle Bytes (Wordweise) }
       not      ax                              { Ivertieren. }
       stosw
       loop     @@1

       jmp      @@3
 @@2:  push     er_NotInit                      { Fehler abfangen. }
       push     proc_Logik
       push     es
       push     di
       call     SetError
 @@3:
 end;

 { ****************************************************** }
 { ****************************************************** }

 procedure SwapMem(var AMem1, AMem2; ASize: Word); assembler;
 asm
       push     ds
       cld
       les      di,AMem1        { Parameter laden }
       lds      si,AMem2
       mov      cx,ASize

       shr      cx,01           { Pro durchgang ein Word verarbeiten. }
       jnc      @@1             { Falls die Speichergroesse ungerade ist, }
       lodsb                    { das erste Byte noch Separat vertauschen. }
       xchg     al,es:[di]
       mov      ds:[si-01],al
       inc      di

 @@1:  lodsw
       xchg     ax,es:[di]
       mov      ds:[si-02],ax
       add      di,02
       loop     @@1

       pop      ds
 end;

 procedure CopyMem(var AMem1, AMem2; ASize: Word); assembler;
 asm
       push     ds
       cld
       les      di,AMem1
       lds      si,AMem2
       mov      cx,ASize
       jcxz     @@2

       shr      cx,01
       jnc      @@1
       movsb
 @@1:  rep      movsw

 @@2:  pop      ds
 end;

{ ************************************************************************** }
BEGIN
  ErrorObj.Init;        { Fehlerbehandlung initialisieren. }
END.
{ ************************************************************************** }