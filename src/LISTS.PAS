{ ************************************************************************** }
{  In Dieser Unit finden sich Objekte und Typendefinitionen, dies es erlau-  }
{ ben, verschiedene Listen zu verwalten.                                     }
{  Alle Items werden auf dem Heap erzeugt, es muss deshalb genuegend freier  }
{ Heap vorhanden sein.                                                       }
{ ************************************************************************** }
{  This unit contains simply list-objects.                                   }
{ ************************************************************************** }
{                                                                            }
{                          (c) 1999, Tobias Kohn                             }
{                                Version 1.0                                 }
{                                                                            }
{ ************************************************************************** }
{$G+}             { 286-Codes }
UNIT Lists;
{ ************************************************************************** }
INTERFACE
 USES Basics, Errors, Memory;
{ ************************************************************************** }

 CONST
   { ************************************************** }
   {  Diese Konstanten geben die Groessen verschiedener }
   { Typen an. Sie sollten nicht einfach geaendert wer- }
   { den, da sonst die gesamte Speicherverwaltung zu-   }
   { sammenbrechen koennte.                             }
   {  Die Felder, die jedoch die Groessen der List- bzw }
   { TreeItems angeben, sollten bei veraendern der Item-}
   { deinitionen ebenfalls aktualisiert werden.         }
   { ************************************************** }
   sz_Pntr = $04;               { Pointer }
   sz_Word = $02;               { Word }

   sz_ListItem = $06;           { ListItem ohne Data }
   sz_TreeItem = $0A;           { TreeItem ohne Data }

   { ************************************************** }
   {  Fehlerbehandlung:                                 }
   { ************************************************** }
   er_ListRange = $16;          { Es wurde versucht ein Element anzusprechen, }
                                { das in der Liste nicht vorhanden ist, oder }
                                { bei AddItem: die Liste wuerde zu gross. }

   proc_NewItem = $01;          { NewListItem / NewTreeItem }
                                { Die folgenden Methoden gelten auch fuer LTree. }
   proc_GetItem = $02;          { LList.GetItem }
   proc_AddItem = $03;          { LList.AddItem / LList.AddList }
   proc_DelItem = $04;          { LList.DelItem }
   proc_Sort    = $05;          { LList.SortItems }

 TYPE
   { ************************************************** }
   {  LListItem repraesentiert ein allgemeines Element  }
   { aus einer Liste. Es sollte jedoch nicht direkt mit }
   { New oder Dispose behandelt werden, da LByteArray   }
   { ein Typ mit der Groesse von ca. 64 KB ist. Das     }
   { Feld Data erlaubt es lediglich, auf die Daten des  }
   { Items problemlos zuzugreiffen.                     }
   {  LTreeItem gehoert zu einem "Baum". Im unterschied }
   { zu einer List kann jedes Element eines Baumes      }
   { selbst wieder ein Baum sein.                       }
   {  Die hier definierten Items dienen lediglich dazu, }
   { dass die "Ur-Vorfahren" der Listen auf ihre Ele-   }
   { mente zugreiffen koennen. Nachher werden die Listen}
   { auf einen bestimmten Typ spezialisiert (z.B.       }
   { strings, Zahlen...). Dafuer werden die Items dem-  }
   { entsprechend neu definiert. Vor allem das Feld     }
   { Data wird ueberschrieben werden, die anderen soll- }
   { ten jedoch von der Reihenfolge, der Groesse und der}
   { Funktion erhalten bleiben (sie koennen aber umbe-  }
   { nannt werden).                                     }
   { ************************************************** }
   {  Next       Ist Ein Zeiger auf das naechste Element}
   {              in der Liste. Beim letzten Element    }
   {              ist dieser Zeiger nil.                }
   {  Size       Gibt die Groesse des Feldes Data an.   }
   {  Data       Erlaubt es, auf die Daten des Items    }
   {              zuzugreiffen.                         }
   {  Sub        Ein Zeiger auf die naechstniedrigere   }
   {              Ebene.                                }
   { ************************************************** }
   HListItem = ^LListItem;
   LListItem = record
     Next: HListItem;
     Size: Word;
     Data: LByteArray;
   end;

   HTreeItem = ^LTreeItem;
   LTreeItem = record
     Next: HTreeItem;
     Size: Word;
     Sub : HTreeItem;
     Data: LByteArray;
   end;

   HStrItem = ^LStrItem;
   LStrItem = record
     Next: HStrItem;
     Size: Word;
     Data: string;
   end;

   { ************************************************** }
   {  Dieses Objekt verwaltet eine Liste. Eigentlich    }
   { ist es nicht dazu gedacht, in dieser Form wirklich }
   { verwendet zu werden, vielmehr soll es als Vorfahr  }
   { fuer spezialisierte Listen dienen.                 }
   {  Hinweis: Das erste Element beginnt bei 0. So ist  }
   { das letzte Element nicht Count, sondern Count-1.   }
   { ************************************************** }
   {  FirstItem  Ist ein Zeiger auf das erste Element   }
   {              der Liste.                            }
   {  Count      Haelt die Anzahl Elemente der Liste    }
   {              fest.                                 }
   { ************************************************** }
   {  AddItem    Fuegt ein neues Item an das Ende der   }
   {              Liste hinzu.                          }
   {  AddList    Fuegt eine ganze Kette Items hinzu.    }
   {              Bei AddItem wird das Feld Next des    }
   {              hinzugefuegten Elementes auf nil ge-  }
   {              setzt, hier jedoch nicht.             }
   {  InsertItem Fuegt ein neues Item in die Liste an   }
   {              der Stelle AIndex ein.                }
   {  DeleteItem Loescht das Item an der Stelle AIndex. }
   {  Clear      Loescht alle Items.                    }
   {  Release    Gibt alle Items wieder frei, ohne sie  }
   {              vom Heap zu entfernen.                }
   {  ReleaseDone Ruft zuerst Release, danach Done auf. }
   {  GetItem    Gibt einen Zeiger auf das Item an der  }
   {              Stelle AIndex zurueck.                }
   {  SetItem    Das alte Item an der Stelle AIndex wird}
   {              als ungueltig erklaert (nicht geloe-  }
   {              scht) und durch das neue ersetzt.     }
   {  SwapItemNext  Vertauscht das angegebene Item mit  }
   {              dem naechsten der Liste.              }
   {  SortItems  Sortiert die Items nach Groesse. Das   }
   {              kleinste kommt zuerst, das groesste   }
   {              zuletzt. Diese Routine arbeitet mit   }
   {              ItemDataToStr (ebenfalls in dieser    }
   {              Unit). Was die Parameter bedeuten,    }
   {              schauen sie bitte bei dieser Routine  }
   {              nach. AFlag gibt an, ob die Sortie-   }
   {              rund auf- oder absteigend vorgenommen }
   {              werden soll. (true = aufsteigend)     }
   {  CopyItem   Kopiert das angegebene Item und gibt   }
   {              einen Zeiger auf die Kopie zurueck.   }
   {  CutItem    Kopiert das angegebene Item und ent-   }
   {              fernt es aus der Liste.               }
   { ************************************************** }
   HList = ^LList;
   LList = object(LObject)
     FirstItem: HListItem;
     Count    : Word;
     destructor Done; virtual;
     procedure AddItem(AItem: HListItem); virtual;
     procedure AddList(AItem: HListItem); virtual;
     procedure InsertItem(AItem: HListItem; AIndex: Word); virtual;
     procedure DeleteItem(AIndex: Word); virtual;
     procedure Clear; virtual;
     procedure Release; virtual;
     destructor ReleaseDone; virtual;
     function GetItem(AIndex: Word): HListItem; virtual;
     procedure SetItem(AIndex: Word; AItem: HListItem); virtual;
     procedure SwapItemNext(AIndex: Word); virtual;
     procedure SortItems(AStart: Word; ALength: Byte; AFlag: Boolean); virtual;
     function CopyItem(AIndex: Word): HListItem;
     function CutItem(AIndex: Word): HListItem;
   end;

   { ************************************************** }
   {  Dieses Objekt verwaltet einen Baum. Eigentlich    }
   { ist es nicht dazu gedacht, in dieser Form wirklich }
   { verwendet zu werden, vielmehr soll es als Vorfahr  }
   { fuer spezialisierte Baeume dienen.                 }
   {  Hinweis: Das erste Element beginnt bei 0. So ist  }
   { das letzte Element nicht Count, sondern Count-1.   }
   { ************************************************** }
   {  FirstItem  Ist ein Zeiger auf das erste Element   }
   {              des Baumes.                           }
   {  Count      Haelt die Anzahl Elemente im Baum fest.}
   { ************************************************** }
   {  AddItem    Fuegt ein neues Item an das Ende dem   }
   {              Baum hinzu.                           }
   {  AddTree    Fuegt eine ganze Kette Items hinzu.    }
   {              Bei AddItem wird das Feld Next des    }
   {              hinzugefuegten Elementes auf nil ge-  }
   {              setzt, hier jedoch nicht.             }
   {  InsertItem Fuegt ein neues Item in den Baum an    }
   {              der Stelle AIndex ein.                }
   {  DeleteItem Loescht das Item an der Stelle AIndex. }
   {  Clear      Loescht alle Items.                    }
   {  Release    Gibt alle Items wieder frei, ohne sie  }
   {              vom Heap zu entfernen.                }
   {  ReleaseDone Ruft zuerst Release, danach Done auf. }
   {  GetItem    Gibt einen Zeiger auf das Item an der  }
   {              Stelle AIndex zurueck.                }
   {  SetItem    Das alte Item an der Stelle AIndex wird}
   {              als ungueltig erklaert (nicht geloe-  }
   {              scht) und durch das neue ersetzt.     }
   {  AssignTreeItem  Setzt den Baum so, dass das durch }
   {              Sub referenzierte Element von ATree-  }
   {              Item das erste Element des Baumes     }
   {              bildet. Auf diese Weise kann man sozu-}
   {              sagen "zoomen".                       }
   {  SwapItemNext  Vertauscht das angegebene Item mit  }
   {              dem naechsten der Liste.              }
   {  SortItems  Sortiert die Items nach Groesse. Das   }
   {              kleinste kommt zuerst, das groesste   }
   {              zuletzt. Diese Routine arbeitet mit   }
   {              ItemDataToStr (ebenfalls in dieser    }
   {              Unit). Was die Parameter bedeuten,    }
   {              schauen sie bitte bei dieser Routine  }
   {              nach. AFlag gibt an, ob die Sortie-   }
   {              rund auf- oder absteigend vorgenommen }
   {              werden soll. (true = aufsteigend)     }
   {  CopyItem   Kopiert das angegebene Item und gibt   }
   {              einen Zeiger auf die Kopie zurueck.   }
   {              Dabei werden auch alle untergeordneten}
   {              Elemente kopiert.                     }
   {  CutItem    Kopiert das angegebene Item und ent-   }
   {              fernt es aus der Liste.               }
   { ************************************************** }
   HTree = ^LTree;
   LTree = object(LObject)
     FirstItem: HTreeItem;
     Count    : Word;
     destructor Done; virtual;
     procedure AddItem(AItem: HTreeItem); virtual;
     procedure AddTree(AItem: HTreeItem); virtual;
     procedure InsertItem(AItem: HTreeItem; AIndex: Word); virtual;
     procedure DeleteItem(AIndex: Word); virtual;
     procedure Clear; virtual;
     procedure Release; virtual;
     destructor ReleaseDone; virtual;
     function GetItem(AIndex: Word): HTreeItem; virtual;
     procedure SetItem(AIndex: Word; AITem: HTreeItem); virtual;
     procedure AssignTreeItem(ATreeItem: HTreeItem); virtual;
     procedure SwapItemNext(AIndex: Word); virtual;
     procedure SortItems(AStart: Word; ALength: Byte; AFlag: Boolean); virtual;
     function CopyItem(AIndex: Word): HTreeItem;
     function CutItem(AIndex: Word): HTreeItem;
   end;

   { ************************************************** }
   {  Add        Einen String hinzufuegen.              }
   {  Insert     Einen String einfuegen.                }
   {  GetString  Gibt den String AIndex zurueck.        }
   {  SetString  Setzt den String AIndex.               }
   {  SortStrings   Sortiert alle Strings.              }
   { ************************************************** }
   HStrList = ^LStrList;
   LStrList = object(LList)
     procedure Add(AStr: string);
     procedure Insert(AIndex: Word; AStr: string);
     function GetString(AIndex: Word): string;
     procedure SetString(AIndex: Word; AStr: string);
     procedure SortStrings(AFlag: Boolean);
   end;

   { ************************************************** }
   {  Diese Routinen erstellen neue Items mit einem     }
   { Datenfeld der Groesse ASize.                       }
   { ************************************************** }
   function NewListItem(ASize: Word; ANext: HListItem): HListItem;
   function NewTreeItem(ASize: Word; ASub, ANext: HTreeItem): HTreeItem;

   { ************************************************** }
   {  Diese Routinen entfernen die Items mit ihrem gan- }
   { zen Datenfeld. DisposeTreeItem entfernt zudem auch }
   { alle Untergeordneten Baeume.                       }
   { ************************************************** }
   procedure DisposeListItem(var AItem: HListItem);
   procedure DisposeTreeItem(var AItem: HTreeItem);

   { ************************************************** }
   {  Diese Routine fuegt zwei Listen zusammen: die     }
   { zweite wird einfach an das Ende der ersten ange-   }
   { haengt. Funktioniert auch bei Baeumen.             }
   {  Ist AItem1 nil, so zeigt AItem1 nachher einfach   }
   { auf AItem2.                                        }
   {  AItem2 wird dabei auf nil gesetzt.                }
   { ************************************************** }
   procedure ConcatLists(var AItem1, AItem2: HListItem);

   { ************************************************** }
   {  Folgende Funktion gibt einen Teil der Daten eines }
   { Listenelementes als String zurueck. AItem ist ein  }
   { Zeiger auf das Item, AStart gibt an, wie viele     }
   { Bytes des Feldes Data zuerst uebersprungen werden  }
   { sollen und ALength gibt die Anzahl der zu lesenden }
   { Zeichen an. Ist ALength = 0, so wird das durch     }
   { AStart angegebene Zeichen als Laenge interpretiert.}
   { Dies ist beispielsweise der Fall, wenn ein wirkli- }
   { cher Pascal-String abgespeichert ist.              }
   {  Die untere Funktion tut das selbe wie ItemData.., }
   { bezieht sich aber auf ein Baum-Element.            }
   {  Diese Funktion kann beispielsweise benutzt werden,}
   { um die Felder zu sortieren.                        }
   { ************************************************** }
   function ItemDataToStr(AItem: HListItem; AStart: Word; ALength: Byte): string;
   function TreeDataToStr(AItem: HTreeItem; AStart: Word; ALength: Byte): string;

 VAR
   ErrorObj: ErrorObject;

{ ************************************************************************** }
IMPLEMENTATION
{ ************************************************************************** }

 { ****************************************************** }
 destructor LList.Done;
 begin
   Clear;                       { Alle Felder loeschen. }
   inherited Done;
 end;

 procedure LList.AddItem(AItem: HListItem);
 begin
   if (AItem = nil) then exit;
   AItem^.Next := nil;
   AddList(AItem);
 end;

 procedure LList.AddList(AItem: HListItem);
 var
   Pntr: HListItem;
   i   : LongInt;
 begin
   if (AItem = nil) then exit;
   i := Count + 1;                              { Zaehlen, wie viele neue }
   Pntr := AItem;                               { Elemente sich in der Liste }
   while not (Pntr^.Next = nil) do begin        { befinden. }
     Pntr := Pntr^.Next;
     inc(i);
   end;
   if (i > 65000) then begin                        { Es duerfen nicht mehr als }
     ErrorObj.SetError(proc_AddItem, er_ListRange); { 65000 Elemente in der Liste }
     exit;                                          { sein. }
   end;

   if (Count = 0) then begin            { Die zweite Liste hinzufuegen: }
     FirstItem := AItem;
   end else begin
     Pntr := GetItem(Count-1);
     Pntr^.Next := AItem;
   end;
   Count := i;
 end;

 procedure LList.InsertItem(AItem: HListItem; AIndex: Word);
 var
   AP,AQ: HListItem;
 begin
   if (AIndex > Count) then begin                           { Pruefen, ob die Liste ueberhaupt das }
     ErrorObj.SetError(er_ListRange, proc_AddItem);         { angeforderte Element enthaelt. }
     exit;
   end;

   if (AIndex = 0) then begin
     AP := FirstItem;           { Beim einfuegen eines Elementes muessen die }
     FirstItem := AItem;        { Zeiger so umgeleitet werden, dass die Liste }
     FirstItem^.Next := AP;     { nach dem eingefuegten Element "weitergeht". }
   end else begin
     AP := GetItem(AIndex-1);
     AItem^.Next := AP^.Next;
     AP^.Next := AItem;
   end;
   inc(Count);
 end;

 procedure LList.DeleteItem(AIndex: Word);
 var
   AP,AQ: HListItem;
 begin
   if (FirstItem = nil) or (AIndex > (Count-1)) then begin  { Pruefen, ob die Liste ueberhaupt das }
     ErrorObj.SetError(er_ListRange, proc_DelItem);         { angeforderte Element enthaelt. }
     exit;
   end;

   if (AIndex = 0) then begin
     AP := FirstItem^.Next;             { Beim loeschen muss der Zeiger des }
     DisposeListItem(FirstItem);        { letzten Elementes neu ausgerichtet }
     FirstItem := AP;                   { werden, damit die List "weitergeht". }
   end else begin
     AP := GetItem(AIndex-1);
     AQ := AP^.Next;
     AP^.Next := AQ^.Next;
     DisposeListItem(AQ);
   end;
   dec(Count);
 end;

 procedure LList.Clear;
 var
   AP, AQ: HListItem;
 begin
   AP := FirstItem;
   while not (AP = nil) do begin
     AQ := AP;
     AP := AP^.Next;
     DisposeListItem(AQ);
   end;
   Count := 0;
 end;

 procedure LList.Release;
 begin
   Count := 0;
   FirstItem := nil;
 end;

 destructor LList.ReleaseDone;
 begin
   Release;
   Done;
 end;

 function LList.GetItem(AIndex: Word): HListItem;
 var
   Pntr: HListItem;
   i   : Word;
 begin
   if (FirstItem = nil) or (AIndex > (Count-1)) then begin  { Pruefen, ob die Liste ueberhaupt das }
     ErrorObj.SetError(er_ListRange, proc_GetItem);         { angeforderte Element enthaelt. }
     GetItem := nil; exit;
   end;

   Pntr := FirstItem;                           { Nun Elementweise vortasten, bis das angeforderte }
   for i := 1 to AIndex do begin                { Element gefunden wurde. }
     Pntr := Pntr^.Next;
     if (Pntr = nil) then begin                       { Der Zeiger ist unerwarteterweise }
       ErrorObj.SetError(proc_GetItem, er_PntrNil);   { nil: die Liste wurde nicht sauber }
       Count := i;                                    { verwaltet. Um weitere Fehler moeglichst }
       GetItem := nil; exit;                          { zu minimieren, Listen-Zaehler aktualisieren. }
     end;
   end;
   GetItem := Pntr;
 end;

 procedure LList.SetItem(AIndex: Word; AItem: HListItem);
 var
   Pntr: HListItem;
   i   : Word;
 begin
   if (AIndex > (Count-1)) then exit;

   if (AIndex = 0) then begin
     FirstItem := AItem;
     exit;
   end;

   Pntr := FirstItem;
   for i := 1 to (AIndex-1) do begin
     pntr := pntr^.Next;
     if (Pntr = nil) then begin                       { Der Zeiger ist unerwarteterweise }
       ErrorObj.SetError(proc_GetItem, er_PntrNil);   { nil: der Baum wurde nicht sauber }
       Count := i; exit;                              { verwaltet. Um weitere Fehler moeglichst }
     end;                                             { zu minimieren, Baum-Zaehler aktualisieren. }
   end;

   Pntr^.Next := AItem;                               { AItem einfuegen. }
 end;

 procedure LList.SwapItemNext(AIndex: Word);
 var
   p,q,r: HListItem;
 begin
   if ((AIndex+2) > Count) then exit;

   if (AIndex = 0) then begin        { Wenn das erste mit dem zweiten Element }
     p := FirstItem;                 { ausgetauscht wird, so ist es noetig, }
     q := p^.Next;                   { den Zeiger auf das erste Element neu }
     r := q^.Next;                   { auszurichten. }

     if (p = nil) or (r = nil) or (q = nil) then exit;
     p^.Next := r;
     q^.Next := p;
     FirstItem := q;
   end else begin
     p := GetItem(AIndex-1);
     if (p = nil) then exit;
     q := p^.Next;
     r := q^.Next;

     if (p = nil) or (r = nil) or (q = nil) then exit;
     p^.Next := r;
     q^.Next := r^.Next;
     r^.Next := q;
   end;
 end;

 procedure LList.SortItems(AStart: Word; ALength: Byte; AFlag: Boolean);

  function CmpItems(AIndex:Word): Boolean;              { Unterfunktion: ueberprueft, ob }
  var                                                   { das erste Datenfeld groeser ist }
    APntr: HListItem;                                   { als das zweite. }
  begin
    APntr := GetItem(AIndex);
    if (APntr = nil) or (APntr^.Next = nil) then begin
      CmpItems := false; exit;
    end;
    CmpItems := (ItemDataToStr(APntr, AStart, ALength) <= ItemDataToStr(APntr^.Next, AStart, ALength)) xor AFlag;
  end;

 var
   i,j: Word;
 begin
   if (FirstItem = nil) then begin
     ErrorObj.SetError(er_ListRange, proc_Sort);
     exit;
   end;
   if (Count = 1) then exit;            { 1 Item kann nicht sortiert werden. }

   for j := (Count-2) downto 0 do
    for i := 0 to j
     do if CmpItems(i) then SwapItemNext(i);
 end;

 function LList.CopyItem(AIndex: Word): HListItem;
 var
   OldItem: HListItem;
   Buffer : HListItem;
   ASize,i: Word;
 begin
   OldItem := GetItem(AIndex);
   if (OldItem = nil) then begin
     CopyItem := nil; exit;
   end;

   ASize := OldItem^.Size;
   Buffer := NewListItem(ASize, nil);
   if (Buffer = nil) then begin
     CopyItem := nil; exit;
   end;

   CopyMem(Buffer^.Data, OldItem^.Data, ASize);

   CopyItem := Buffer;
 end;

 function LList.CutItem(AIndex: Word): HListItem;
 var
   p,q: HListItem;
   i: Word;
 begin
   if (Count = 0) or (AIndex > (Count-1)) then begin
     CutItem := nil;
     exit;
   end;

   if (AIndex = 0) then begin
     p := FirstItem;
     FirstItem := p^.Next;
     p^.Next := nil;
   end else begin
     p := FirstItem;
     for i := 2 to (AIndex) do p := p^.Next;
     q := p^.Next;
     p^.Next := q^.Next;
     q^.Next := nil;
     p := q;
   end;
   dec(Count);

   CutItem := p;
 end;
 { ****************************************************** }

 destructor LTree.Done;
 begin
   Clear;                       { Alle Felder loeschen. }
   inherited Done;
 end;

 procedure LTree.AddItem(AItem: HTreeItem);
 begin
   if (AItem = nil) then exit;
   AItem^.Next := nil;
   AddTree(AItem);
 end;

 procedure LTree.AddTree(AItem: HTreeItem);
 var
   Pntr: HTreeItem;
   i   : LongInt;
 begin
   if (AItem = nil) then exit;
   i := Count + 1;                              { Zaehlen, wie viele neue }
   Pntr := AItem;                               { Elemente sich im Baum }
   while not (Pntr^.Next = nil) do begin        { befinden. }
     Pntr := Pntr^.Next;
     inc(i);
   end;
   if (i > 65000) then begin                        { Es duerfen nicht mehr als }
     ErrorObj.SetError(proc_AddItem, er_ListRange); { 65000 Elemente im Baum }
     exit;                                          { sein. }
   end;

   if (Count = 0) then begin            { Den zweiten Baum hinzufuegen: }
     FirstItem := AItem;
   end else begin
     Pntr := GetItem(Count-1);
     Pntr^.Next := AItem;
   end;
   Count := i;
 end;

 procedure LTree.InsertItem(AItem: HTreeItem; AIndex: Word);
 var
   AP,AQ: HTreeItem;
 begin
   if (AIndex > Count) then begin                           { Pruefen, ob der Baum ueberhaupt das }
     ErrorObj.SetError(er_ListRange, proc_AddItem);         { angeforderte Element enthaelt. }
     exit;
   end;

   if (AIndex = 0) then begin
     AP := FirstItem;           { Beim einfuegen eines Elementes muessen die }
     FirstItem := AItem;        { Zeiger so umgeleitet werden, dass der Baum }
     FirstItem^.Next := AP;     { nach dem eingefuegten Element "weitergeht". }
   end else begin
     AP := GetItem(AIndex-1);
     AItem^.Next := AP^.Next;
     AP^.Next := AItem;
   end;
   inc(Count);
 end;

 procedure LTree.DeleteItem(AIndex: Word);
 var
   AP,AQ: HTreeItem;
 begin
   if (FirstItem = nil) or (AIndex > (Count-1)) then begin  { Pruefen, ob der Baum ueberhaupt das }
     ErrorObj.SetError(er_ListRange, proc_DelItem);         { angeforderte Element enthaelt. }
     exit;
   end;

   if (AIndex = 0) then begin
     AP := FirstItem^.Next;             { Beim loeschen muss der Zeiger des }
     DisposeTreeItem(FirstItem);        { letzten Elementes neu ausgerichtet }
     FirstItem := AP;                   { werden, damit der Baum "weitergeht". }
   end else begin
     AP := GetItem(AIndex-1);
     AQ := AP^.Next;
     AP^.Next := AQ^.Next;
     DisposeTreeItem(AQ);
   end;
   dec(Count);
 end;

 procedure LTree.Clear;
 var
   AP, AQ: HTreeItem;
 begin
   if (Count = 0) then exit;
   AP := FirstItem;
   while not (AP = nil) do begin
     AQ := AP;
     AP := AP^.Next;
     DisposeTreeItem(AQ);
   end;
   Count := 0;
 end;

 procedure LTree.Release;
 begin
   Count := 0;
   FirstItem := nil;
 end;

 destructor LTree.ReleaseDone;
 begin
   Release;
   Done;
 end;

 function LTree.GetItem(AIndex: Word): HTreeItem;
 var
   Pntr: HTreeItem;
   i   : Word;
 begin
   if (FirstItem = nil) or (AIndex > (Count-1)) then begin  { Pruefen, ob der Baum ueberhaupt das }
     ErrorObj.SetError(er_ListRange, proc_GetItem);         { angeforderte Element enthaelt. }
     GetItem := nil; exit;
   end;

   Pntr := FirstItem;                           { Nun Elementweise vortasten, bis das angeforderte }
   for i := 1 to AIndex do begin                { Element gefunden wurde. }
     Pntr := Pntr^.Next;
     if (Pntr = nil) then begin                       { Der Zeiger ist unerwarteterweise }
       ErrorObj.SetError(proc_GetItem, er_PntrNil);   { nil: der Baum wurde nicht sauber }
       Count := i;                                    { verwaltet. Um weitere Fehler moeglichst }
       GetItem := nil; exit;                          { zu minimieren, Baum-Zaehler aktualisieren. }
     end;
   end;
   GetItem := Pntr;
 end;

 procedure LTree.SetItem(AIndex: Word; AItem: HTreeItem);
 var
   Pntr: HTreeItem;
   i   : Word;
 begin
   if (AIndex > (Count-1)) then exit;

   if (AIndex = 0) then begin
     FirstItem := AItem;
     exit;
   end;

   Pntr := FirstItem;
   for i := 1 to (AIndex-1) do begin
     pntr := pntr^.Next;
     if (Pntr = nil) then begin                       { Der Zeiger ist unerwarteterweise }
       ErrorObj.SetError(proc_GetItem, er_PntrNil);   { nil: der Baum wurde nicht sauber }
       Count := i; exit;                              { verwaltet. Um weitere Fehler moeglichst }
     end;                                             { zu minimieren, Baum-Zaehler aktualisieren. }
   end;

   Pntr^.Next := AItem;                               { AItem einfuegen. }
 end;

 procedure LTree.AssignTreeItem(ATreeItem: HTreeItem);
 begin
   Clear;                       { Falls noch Elemente im Baum sind, diese zuerst loeschen. }
   AddTree(ATreeItem^.Sub);     { Nun alle Elemente laden. }
 end;

 procedure LTree.SwapItemNext(AIndex: Word);
 var
   p,q,r: HTreeItem;
 begin
   if ((AIndex+2) > Count) then exit;

   if (AIndex = 0) then begin        { Wenn das erste mit dem zweiten Element }
     p := FirstItem;                 { ausgetauscht wird, so ist es noetig, }
     q := p^.Next;                   { den Zeiger auf das erste Element neu }
     r := q^.Next;                   { auszurichten. }

     if (p = nil) or (q = nil) then exit;
     p^.Next := r;
     q^.Next := p;
     FirstItem := q;
   end else begin
     p := GetItem(AIndex-1);
     if (p = nil) then exit;
     q := p^.Next;
     r := q^.Next;

     if (p = nil) or (r = nil) or (q = nil) then exit;
     p^.Next := r;
     q^.Next := r^.Next;
     r^.Next := q;
   end;
 end;

 procedure LTree.SortItems(AStart: Word; ALength: Byte; AFlag: Boolean);

  function CmpItems(AIndex:Word): Boolean;              { Unterfunktion: ueberprueft, ob }
  var                                                   { das erste Datenfeld groeser ist }
    APntr: HTreeItem;                                   { als das zweite. }
  begin
    APntr := GetItem(AIndex);
    if (APntr = nil) or (APntr^.Next = nil) then begin
      CmpItems := false; exit;
    end;
    CmpItems := (TreeDataToStr(APntr, AStart, ALength) <= TreeDataToStr(APntr^.Next, AStart, ALength)) xor AFlag;
  end;

 var
   i,j: Word;
 begin
   if (Count = 0) then exit;
   if (FirstItem = nil) then begin
     ErrorObj.SetError(er_ListRange, proc_Sort);
     exit;
   end;
   if (Count = 1) then exit;            { 1 Item kann nicht sortiert werden. }

   for j := (Count-2) downto 0 do
    for i := 0 to j
     do if CmpItems(i) then SwapItemNext(i);
 end;

 function LTree.CopyItem(AIndex: Word): HTreeItem;

  function AuxCopy(AItem: HTreeItem): HTreeItem;
  var
    Buffer: HTreeItem;
  begin
    if (AItem = nil) then begin
      AuxCopy := nil;
      exit;
    end;

    Buffer := NewTreeItem(AItem^.Size, nil, nil);
    CopyMem(Buffer^.Data, AItem^.Data, AItem^.Size); { Datenfeld kopieren. }

    Buffer^.Next := AuxCopy(AItem^.Next);        { Ganze Liste kopieren. }
    Buffer^.Sub  := AuxCopy(AItem^.Sub);         { Alle Unterelemente kopieren. }

    AuxCopy := Buffer;
  end;

 var
   p,q,r: HTreeItem;
 begin
   p := GetItem(AIndex);
   q := p^.Next;
   p^.Next := nil;
   r := AuxCopy(p);
   p^.Next := q;
   CopyItem := r;
 end;

 function LTree.CutItem(AIndex: Word): HTreeItem;
 var
   p,q: HTreeItem;
   i: Word;
 begin
   if (Count = 0) or (AIndex > (Count-1)) then begin
     CutItem := nil;
     exit;
   end;

   if (AIndex = 0) then begin
     p := FirstItem;
     FirstItem := p^.Next;
     p^.Next := nil;
   end else begin
     p := FirstItem;
     for i := 2 to (AIndex) do p := p^.Next;
     q := p^.Next;
     p^.Next := q^.Next;
     q^.Next := nil;
     p := q;
   end;
   dec(Count);

   CutItem := p;
 end;
 { ****************************************************** }

 procedure LStrList.Add(AStr: string);
 var
   Buffer: HListItem;
 begin
   Buffer := NewListItem(256, nil);
   if (Buffer = nil) then begin
     ErrorObj.SetError(er_Heap, $00);
     exit;
   end;
   HStrItem(Buffer)^.Data := AStr;

   AddItem(Buffer);
 end;

 procedure LStrList.Insert(AIndex: Word; AStr: string);
 var
   Buffer: HListItem;
 begin
   Buffer := NewListItem(256, nil);
   if (Buffer = nil) then begin
     ErrorObj.SetError(er_Heap, $00);
     exit;
   end;
   HStrItem(Buffer)^.Data := AStr;

   InsertItem(Buffer, AIndex);
 end;

 function LStrList.GetString(AIndex: Word): string;
 var
   Buffer: HListItem;
 begin
   Buffer := GetItem(AIndex);
   if (Buffer = nil) then begin
     ErrorObj.SetError(er_Heap, $00);
     GetString := ''; exit;
   end;

   GetString := HStrItem(Buffer)^.Data;
 end;

 procedure LStrList.SetString(AIndex: Word; AStr: string);
 var
   Buffer: HListItem;
 begin
   Buffer := GetItem(AIndex);
   if (Buffer = nil) then begin
     ErrorObj.SetError(er_Heap, $00);
     exit;
   end;

   HStrItem(Buffer)^.Data := AStr;
 end;

 procedure LStrList.SortStrings(AFlag: Boolean);
 begin
   SortItems(0, 0, AFlag);
 end;

 { ****************************************************** }
 { ****************************************************** }

 function NewListItem(ASize: Word; ANext: HListItem): HListItem;
 var
   APntr: Pointer;
 begin
   GetMem(APntr, ASize+sz_ListItem);
   if (APntr = nil) then begin                          { Fehler abfangen. }
     ErrorObj.SetError(er_TpIntern, proc_NewItem);
     NewListItem := nil; exit;
   end;
   FillChar(HListItem(APntr)^.Data, ASize, 0);          { Datenfeld auf Null setzen. }
   HListItem(APntr)^.Next := ANext;                     { Parameter uebertragen. }
   HListItem(APntr)^.Size := ASize;
   NewListItem := APntr;
 end;

 function NewTreeItem(ASize: Word; ASub, ANext: HTreeItem): HTreeItem;
 var
   APntr: Pointer;
 begin
   GetMem(APntr, ASize+sz_TreeItem);
   if (APntr = nil) then begin                          { Fehler abfangen. }
     ErrorObj.SetError(er_TpIntern, proc_NewItem);
     NewTreeItem := nil; exit;
   end;
   FillChar(HTreeItem(APntr)^.Data, ASize, 0);          { Datenfeld auf Null setzen. }
   HTreeItem(APntr)^.Next := ANext;                     { Parameter uebertragen. }
   HTreeItem(APntr)^.Size := ASize;
   HTreeItem(APntr)^.Sub  := ASub;
   NewTreeItem := APntr;
 end;

 procedure DisposeListItem(var AItem: HListItem);
 begin
   if (AItem = nil) then exit;
   FreeMem(AItem, sz_ListItem+AItem^.Size);
   AItem := nil;
 end;

 procedure DisposeTreeItem(var AItem: HTreeItem);
 begin
   if (AItem = nil) then exit;
   DisposeTreeItem(AItem^.Sub);
   FreeMem(AItem, sz_TreeItem+AItem^.Size);
   AItem := nil;
 end;

 { ****************************************************** }
 { ****************************************************** }

 procedure ConcatLists(var AItem1, AItem2: HListItem);
 var
   p: HListItem;
 begin
   if (AItem2 = nil) then exit;         { Es gibt nichts anzufuegen. }
   if (AItem1 = nil) then begin         { Der erste Teil ist nil, also soll er }
     AItem1 := AItem2;                  { direkt auf den zweiten zeigen. }
     exit;
   end;

   p := AItem1;                         { Das letzte Element der ersten }
   while not (p^.Next = nil)            { Liste suchen. }
    do p := p^.Next;
   p^.Next := AItem2;                   { zweite Liste anhaengen. }

   AItem2 := nil;
 end;

 { ****************************************************** }
 { ****************************************************** }

 function ItemDataToStr(AItem: HListItem; AStart: Word; ALength: Byte): string;
 var
   Buffer: string;
   i     : Byte;
 begin
   if (AItem = nil) then begin
     ItemDataToStr := '';
     exit;
   end;

   Buffer := '';
   if (ALength = 0) then begin          { Wenn ALength = 0 ist, so soll die Laenge }
     ALength := AItem^.Data[AStart];    { ebenfalls aus dem Feld Data stammen. Dies }
     inc(AStart);                       { ist z.B. bei einem String der Fall. }
   end;

   if ((AStart + ALength) > AItem^.Size) then begin   { Nur Daten innerhalb des Feldes }
     ItemDataToStr := '';                             { lesen: keine unerlaubten }
     exit;                                            { Speicherzugriffe. }
   end;

   for i := 0 to (ALength-1)
    do Buffer := Buffer + chr(AItem^.Data[AStart+i]);
   ItemDataToStr := Buffer;
 end;

 function TreeDataToStr(AItem: HTreeItem; AStart: Word; ALength: Byte): string;
 var
   Buffer: string;
   i     : Byte;
 begin
   if (AItem = nil) then begin
     TreeDataToStr := '';
     exit;
   end;

   Buffer := '';
   if (ALength = 0) then begin          { Wenn ALength = 0 ist, so soll die Laenge }
     ALength := AItem^.Data[AStart];    { ebenfalls aus dem Feld Data stammen. Dies }
     inc(AStart);                       { ist z.B. bei einem String der Fall. }
   end;

   if ((AStart + ALength) > AItem^.Size) then begin   { Nur Daten innerhalb des Feldes }
     TreeDataToStr := '';                             { lesen: keine unerlaubten }
     exit;                                            { Speicherzugriffe. }
   end;

   for i := 0 to (ALength-1)
    do Buffer := Buffer + chr(AItem^.Data[AStart+i]);
   TreeDataToStr := Buffer;
 end;

{ ************************************************************************** }
BEGIN
  ErrorObj.Init;        { Fehlerbehandlung initialisieren. }
END.
{ ************************************************************************** }