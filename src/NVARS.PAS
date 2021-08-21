{ ************************************************************************** }
{  In einem Term sollen Variablen durch andere Terme oder Werte ersetzt      }
{ werden koennen. Diese Ersetzungen nehmen folgende Routinen vor.            }
{ ************************************************************************** }
{  Replace variables in terms by a value or other terms.                     }
{ ************************************************************************** }
{                                                                            }
{                       (c) 1999/2000, Tobias Kohn                           }
{                                Version 2.0                                 }
{                                                                            }
{ ************************************************************************** }
{$G+}             { 286-Codes }
UNIT NVars;
{ ************************************************************************** }
INTERFACE
 USES Lists, CRTypes, Errors, CRComplx, AuxStr, NBasics, CRMathe, CRConv;
{ ************************************************************************** }

 TYPE
   HConst = ^LConst;
   LConst = record
     Next: HConst;
     Size: Word;
     Name: Char;
     Term: HChain;
   end;

   { ************************************************** }
   {  NewConst   Erstellt eine neue "Konstante" mit dem }
   {              Namen AName und dem Wert AChain.      }
   {  AddConstToList  Prueft zuerst, ob bereits eine    }
   {              Konstante dieses Namens in der Liste  }
   {              ist und ersetzt den alten Wert oder   }
   {              fuegt den neuen Wert hinten an.       }
   {  ReplaceAllConsts  Ersetzt alle in ConstList aufge-}
   {              fuehren Konstanten in AChain.         }
   { ************************************************** }
   function NewConst(AName: char; AChain: HChain; ANext: HConst): HConst;
   procedure AddConstToList(AName: char; AChain: HChain);
   procedure ReplaceAllConsts(var AChain: HChain);

   { ************************************************** }
   {  ReplaceNum Ersetzt die Variable AName in AChain   }
   {              durch BChain. AChain muss eine Nummer }
   {              sein.                                 }
   {  ReplaceChain Erstetzt die Variable AName in       }
   {              AChain durch BChain. AChain ist eine  }
   {              beliebige Kette.                      }
   {      Bsp: Repl("4x^2+3y","x","7s") -> "4*49s^2+3y" }
   {                                                    }
   {  CalcNumPi  Besetzt das Feld constPi mit einer     }
   {              Nummer ohne Variablen, die den Wert   }
   {              von pi traegt.                        }
   { ************************************************** }
   procedure ReplaceNum(var AChain: HChain; AName: char; BChain: HChain);
   procedure ReplaceChain(var AChain: HChain; AName: char; BChain: HChain);

   procedure CalcNumPi;

   var
     const_Pi: HChain;

     ConstList: LList;

{ ************************************************************************** }
IMPLEMENTATION
{ ************************************************************************** }

 function NewConst(AName: char; AChain: HChain; ANext: HConst): HConst;
 var
   Buffer: HConst;
 begin
   if GlobalError.IsError then begin
     NewConst := nil; exit;
   end;
   Buffer := New(HConst);
   if not (Buffer = nil) then begin
     Buffer^.Next := ANext;
     Buffer^.Name := AName;
     Buffer^.Size := SizeOf(LConst)-6;
     Buffer^.Term := AChain;
   end;

   NewConst := Buffer;
 end;

 procedure AddConstToList(AName: char; AChain: HChain);
 var
   i: Word;
   p: HConst;
 begin
   if GLobalError.IsError or (AName = #00) then exit;

   if not (ConstList.Count = 0) then
    for i := 0 to (ConstList.Count-1) do                { Zuerst nach alten Kon- }
     if (HConst(ConstList.GetItem(i))^.Name = AName) then begin { stanten suchen. }
       if (AChain = nil) then begin
         ConstList.DeleteItem(i);                       { Wenn AChain=nil ist, }
       end else begin                                   { wird die Konstante er- }
         p := HConst(ConstList.GetItem(i));             { setzt, ansonsten ge- }
         DisposeTreeItem(HTreeItem(p^.Term));           { loescht. }
         p^.Term := CopyChain(AChain);
       end;
       exit;
     end;

   p := NewConst(AName, CopyChain(AChain), nil);       { Neue Konstante hinten }
   ConstList.AddItem(HListItem(p));                    { anfuegen. }
 end;

 procedure ReplaceAllConsts(var AChain: HChain);
 var
   i: Word;
   p: HConst;
 begin
   if (ConstList.Count = 0) or (AChain = nil) then exit;
   for i := 0 to (ConstList.Count-1) do begin
     p := HConst(ConstList.GetItem(i));
     ReplaceChain(AChain, p^.Name, p^.Term);
   end;
 end;
 { ****************************************************** }

 procedure ReplaceNum(var AChain: HChain; AName: char; BChain: HChain);
 var
   i: Integer;
   ANum: HNumber;
   AVal: SReal;
 begin
   if GlobalError.IsError or (AChain = nil) or (BChain = nil) then exit;
   if not (AChain^.Kind = kd_Number) then exit;

   i := GetVarPotenz(HNumber(AChain), AName);
   if (i = 0) then exit;
   BChain := CopyChain(BChain);

   DeleteVar(HNumber(AChain), AName);

   if (i < 0) or (i > 3) then begin
     IntToSReal(AVal, i);
     ANum := NewNumberRe(AVal, nil, nil);
     BChain^.Next := HChain(ANum);
     BChain := NewChain(kd_Pot, BChain, nil);
   end;
   if (i = 2) or (i = 3) then begin
     BChain := NewChain(kd_sqr+((i-2)*2), BChain, nil);
   end;

   HChain(ANum) := AChain^.Next;
   AChain^.Next := BChain;
   AChain := NewChain(kd_Mul, AChain, HChain(ANum));
 end;

 procedure ReplaceChain(var AChain: HChain; AName: char; BChain: HChain);
 var
   ATree: LTree;
   i    : Word;
   p    : HChain;
 begin
   if GlobalError.IsError or (AChain = nil) or (BChain = nil) then exit;
   if (AChain^.Kind = kd_Number) then begin
     ReplaceNum(AChain, AName, BChain);
     exit;
   end;

   ATree.Init;
   ATree.AddTree(AChain^.Sub);
   for i := 0 to (ATree.Count-1) do begin
     p := HChain(ATree.CutItem(i));
     ReplaceChain(p, AName, BChain);
     ATree.InsertItem(HTreeItem(p), i);
   end;
   AChain^.Sub := HChain(ATree.FirstItem);
   ATree.ReleaseDone;
 end;
 { ****************************************************** }

 procedure CalcNumPi;
 begin
   const_Pi := HChain(NewNumberRe(rm_pi, nil, nil));
 end;

{ ************************************************************************** }
BEGIN
  const_Pi := nil;
  ConstList.Init;
END.
{ ************************************************************************** }