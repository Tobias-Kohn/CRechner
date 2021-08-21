{ ************************************************************************** }
{  Den String, den der Anwender eingegeben hat analysieren und in eine Liste }
{ umwandeln.                                                                 }
{ ************************************************************************** }
{  Convert a string to a list of numbers.                                    }
{ ************************************************************************** }
{                                                                            }
{                       (c) 1999/2000, Tobias Kohn                           }
{                                Version 2.0                                 }
{                                                                            }
{ ************************************************************************** }
{$G+}             { 286-Codes }
UNIT NInPut;
{ ************************************************************************** }
INTERFACE
 USES Lists, CRTypes, Errors, CRComplx, AuxStr, NBasics;
{ ************************************************************************** }

   { ************************************************** }
   {  StrToChain Wandelt einen String ohne Klammern in  }
   {              eine Kette um.                        }
   { ************************************************** }
   function StrToChain(var AStr: string): HChain;

   { ************************************************** }
   {  ReplaceFunctions   Ersetzt alle mehrzeichigen     }
   {              Funktionsbezeichner durch ein einzel- }
   {              nes Zeichen mit dem Wert (kd_x + $80).}
   { ************************************************** }
   procedure ReplaceFunctions(var AStr: string);

{ ************************************************************************** }
IMPLEMENTATION
{ ************************************************************************** }

 { **************************************************** }
 {  Die Analyse eines Strings gliedert sich in 2 Teile: }
 { 1.) Zersplittern des Strings in Nummern und Opera-   }
 {      tionszeichen.                                   }
 { 2.) Umwandeln aller Teile in Nummern und erneutes    }
 {      zusammenfuegen dieser Teile.                    }
 { **************************************************** }
 function StrToChain(var AStr: string): HChain;
 var
   AStrList: LStrList;
   i,j,cor : byte;
   knd,k   : Byte;
   s1,s2,s3: string;

   ATree: LTree;
   p,q,r: HChain;

 begin
   if GlobalError.IsError then begin
     StrToChain := nil;
     exit;
   end;
   if (AStr = '') or (AStr = '()') then AStr := '0';

   if (AStr[1] = '#') then begin                { Bei vorangehendem # handelt es sich }
     if (AStr[2] = '(') then begin              { bei dem String um eine einzige Klammer. }
       knd := kd_Clip;
       AStr := Copy(AStr, 3, 255);
     end else begin
       knd := ord(AStr[2]) - $80;
       AStr := Copy(AStr, 4, 255);
     end;
     dec(Byte(AStr[0]));
   end else knd := kd_Clip;

   if CharIsLetter(AStr[1]) then AStr := '1'+AStr;       { Beginnt der string mit einer Variable, }
                                                         { muss eine 1 davorgeschoben werden. }
   if (FindNextSepar(Copy(AStr, 2, 255)) = 0)
         and (FindOpenClip(AStr) = 0) then begin         { Um eine einzelne Nummer }
     p := HChain(StrToNumber(AStr));                     { zu analysieren, existiert }
     if not (knd = kd_Clip)                              { eine eigene Routine. }
      then p := NewChain(knd, p, nil);                   { Trotzdem muss aber unter }
     StrToChain := p;                                    { Umstaneden eine Funktion }
     exit;                                               { dazugesetzt werden. }
   end;

   { ************************ TEIL 1 ************************ }
   AStrList.Init;
                                        { In dieser Schleife wird der String }
   repeat                               { in einzelne Nummern und Operations- }
     i := FindNextSepar(AStr);          { zeichen aufgespalten. }
     if (i = 1)                         { +-x als +(-x) beruecksichtigen. }
      then i := FindNextSepar(Copy(AStr, 2, 255))+1;
     if (i = 0) or (i = 1) then break;

     k := FindOpenClip(AStr);                { Klammer nicht auseinander }
     if not (k = 0) and (i > k) then begin   { nehmen, sondern als ganzes }
       i := FindCloseClip(AStr);             { Weiterverarbeiten. }
       s1 := Copy(AStr, 1, i);
       AStr := '_' + Copy(AStr, i+1, 255);
       AStrList.Add('#'+s1);
       Continue;
     end;

     s1 := Copy(AStr, 1, i-1);
     s2 := AStr[i];
     AStr := Copy(AStr, i+1, 255);

     AStrList.Add(s1);
     if not (AStr = '') then AStrList.Add(s2);
   until False;

   if not (AStr = '') then begin        { Die Liste soll nicht mit einem }
     if CharInString('(', AStr)         { Operationszeichen enden und in AStr }
      then AStr := '#'+AStr;            { wird dasjenige Operationszeichen }
     AStrList.Add(AStr);                { zurueckgegeben, dass fuer eine nach- }
     AStr := '*';                       { folgende Klammer relevant waere. }
   end else AStr := s2;

   s1 := AStrList.GetString(0);
   if (s1 = '-') or (s1 = '+') then begin
     AStrList.SetString(1, s1+AStrList.GetString(1));
     AStrList.DeleteItem(0);
   end;

   for i := (AStrList.Count-1) downto 0
    do if (AStrList.GetString(i) = '_') then AStrList.DeleteItem(i);

   { ************************ TEIL 2 ************************ }
   ATree.Init;

   cor := 255;
   for i := 0 to (AStrList.Count-1) do begin    { Alle Strings, die keine }
     s1 := AStrList.GetString(i);               { Operanden sind in Ketten }
     if (pos(s1, '+-*/^') = 0) then begin       { umwandeln. }
       p := StrToChain(s1);
       ATree.AddItem(HTreeItem(p));
       if (cor = 255) then cor := i+1;
     end;
   end;

   for i := (AStrList.Count-2) downto 0 do
    if (AStrList.GetString(i) = '^') then begin
      j := (i-cor) div 2;
      q := HChain(ATree.CopyItem(j + 1)); { Basis und Exponent werden nach p und q }
      ATree.DeleteItem(j + 1);            { kopiert und aus der Liste entfernt. }
      p := HChain(ATree.CopyItem(j));     { Basis und Exponent werden in einer }
      ATree.DeleteItem(j);                { neuen Kette als Potenz-Funktion mit- }
                                          { einander verknuepft und dieses Produkt }
      p^.Next := q;                       { wird wieder in die Liste eingefuegt. }
      p := NewChain(kd_Pot, p, nil);
      ATree.InsertItem(HTreeItem(p), j);

      AStrList.DeleteItem(i);
      AStrList.DeleteItem(i);
    end;

   for i := (AStrList.Count-2) downto 0 do begin
     s1 := AStrList.GetString(i);
     if (s1 = '*') or (s1 = '/') then begin
       j := (i-cor) div 2;
       q := HChain(ATree.CopyItem(j + 1)); { Die beiden Faktoren werden aus der Liste }
       ATree.DeleteItem(j + 1);            { ausgeschnitten, miteinander verknuepft }
       p := HChain(ATree.CopyItem(j));     { und das Produkt wird wieder eingefuegt. }
       ATree.DeleteItem(j);

       if (s1 = '*') then begin                 { Wenn eines der beiden Elemente }
         if (p^.Kind = kd_Mul)                  { bereits eine Multiplikations- }
          then ConcatChains(HChain(p^.Sub), q)  { Kette ist, muss das andere Element }
          else if (q^.Kind = kd_Mul)            { nur gerade in diese erstere }
          then begin                            { eingefuegt werden. }
            ConcatChains(HChain(q^.Sub), p);
            p := q;
          end else begin
            p^.Next := q;
            p := NewChain(kd_Mul, p, nil);
          end;
       end else begin
         p^.Next := q;
         p := NewChain(kd_Div, p, nil);
       end;
       ATree.InsertItem(HTreeItem(p), j);

       AStrList.DeleteItem(i);
       AStrList.DeleteItem(i);
     end;
   end;

   for i := 0 to (AStrList.Count-2) do
    if (AStrList.GetString(i) = '-') then begin
      j := (i-cor) div 2 + 1;
      p := HChain(ATree.GetItem(j));
      if (p^.Kind = kd_Number) then begin
        CNeg(HNumber(p)^.Value);
      end else begin
        p := HChain(ATree.CopyItem(j));
        ATree.DeleteItem(j);
        p := NewChain(kd_Neg, p, nil);
        ATree.InsertItem(HTreeItem(p), j);
      end;
        AStrList.SetString(i, '+');
    end;

   p := NewChain(knd, HChain(ATree.FirstItem), nil);
   ATree.ReleaseDone;                   { Speicher wieder freigeben und }
   AStrList.Done;                       { Rueckgabewert weitergeben. }
   StrToChain := p;
 end;
 { ****************************************************** }

 procedure ReplaceFunctions(var AStr: string);
 var
   i: Byte;
 begin
   ReplaceStrings(AStr, '[', '(');      { Der Anwender darf die drei Arten von }
   ReplaceStrings(AStr, ']', ')');      { Klammer frei gebrauchen. Intern wird }
   ReplaceStrings(AStr, '{', '(');      { nur 1 Format benoetigt. }
   ReplaceStrings(AStr, '}', ')');

   ReplaceStrings(AStr, str_arcsin+'(', chr(kd_arcsin + $80)+'(');
   ReplaceStrings(AStr, str_arccos+'(', chr(kd_arccos + $80)+'(');
   ReplaceStrings(AStr, str_arctan+'(', chr(kd_arctan + $80)+'(');
   ReplaceStrings(AStr, str_sin+'(', chr(kd_sin + $80)+'(');
   ReplaceStrings(AStr, str_cos+'(', chr(kd_cos + $80)+'(');
   ReplaceStrings(AStr, str_tan+'(', chr(kd_tan + $80)+'(');

   ReplaceStrings(AStr, str_ln+'(', chr(kd_ln + $80)+'(');
   ReplaceStrings(AStr, str_lg+'(', chr(kd_lg + $80)+'(');
   ReplaceStrings(AStr, str_lb+'(', chr(kd_lb + $80)+'(');

   ReplaceStrings(AStr, str_exp1+'(', chr(kd_exp + $80)+'(');
   ReplaceStrings(AStr, str_exp2+'(', chr(kd_exp + $80)+'(');

   ReplaceStrings(AStr, str_sqrt+'(', chr(kd_sqrt + $80)+'(');
   ReplaceStrings(AStr, str_kbrt+'(', chr(kd_kbrt + $80)+'(');
   ReplaceStrings(AStr, str_sqr+'(',  chr(kd_sqr + $80)+'(');
   ReplaceStrings(AStr, str_kb+'(',   chr(kd_kb + $80)+'(');

   ReplaceStrings(AStr, str_inv+'(', chr(kd_inv + $80)+'(');
   ReplaceStrings(AStr, str_abs+'(', chr(kd_abs + $80)+'(');

   ReplaceStrings(AStr, 'ans', '"');                        { ans -> " }
   ReplaceStrings(AStr, 'cis', '<');                        { cis -> < }
   ReplaceStrings(AStr, ':=', '=');                         { :=  -> = }
   ReplaceStrings(AStr, ',', '.');                          { ,   -> . }
   ReplaceStrings(AStr, 'pi', str_Pi);                      { pi  -> ´Pi´ }
   ReplaceStrings(AStr, '-(', '(-1)*(');                    { -(  -> (-1)*( }

   repeat
     i := posOfNegat(AStr);
     if (i = 0) then break;
     Delete(AStr, i, 1);
     Insert('(-1)*', AStr, i);
   until false;

   for i := length(AStr) downto 2 do                        { Unter Umstaenden ist vor einer Klammer }
    if (AStr[i] = '(') then begin                           { ein Muliplikationszeichen noetig, das }
      if (ord(AStr[i-1]) > $80) and (i > 2) then dec(i);    { aber nicht immer geschrieben wird. }
      case AStr[i-1] of                                     { z.B.     3(1+2a)    -> 3*(1+2a)    }
       '0'..'9',')':        Insert('*', AStr, i);           {          (x-4)(x-3) -> (x-4)*(x-3) }
       'a'..'z', 'A'..'Z':  Insert('*', AStr, i);
      end;
    end;
 end;
 { ****************************************************** }

{ ************************************************************************** }
END.
{ ************************************************************************** }