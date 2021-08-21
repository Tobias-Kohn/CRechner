{ ************************************************************************** }
{  Die Routinen hier sind zustaendig fuer die Konvertierung verschiedener    }
{ Datenformate. Zum Beispiel auch fuer das Umrechnen eines SReal-Typs in     }
{ einen String-Typ, was sicherlich fuer die Ein- und Ausgabe erforderlich    }
{ ist.                                                                       }
{ ************************************************************************** }
{  These procedures convert different data-types (e.g. SReal to String).     }
{ ************************************************************************** }
{                                                                            }
{                          (c) 1999, Tobias Kohn                             }
{                                Version 2.0                                 }
{                                                                            }
{ ************************************************************************** }
{$G+}             { 286-Codes }
UNIT CRConv;
{ ************************************************************************** }
INTERFACE
 USES Memory, Errors, CRMathe, CRM_Ext, CRTypes, BcdMem, Basics;
{ ************************************************************************** }

 CONST
   proc_ReStr = $51;    { SRealToStr }
   proc_StrRe = $52;    { StrToSReal }

   { ************************************************** }
   {  IntToSReal Wandelt einen LogInt-Wert in einen     }
   {              SReal-Wert um.                        }
   {  IntToStr   Umwandeln eines LongInt in einen       }
   {              String.                               }
   {  StrToInt   Interpretiert einen String als eine    }
   {              ganze Zahl.                           }
   {  SRealToInt Versucht, die reelle Zahl in eine ganze}
   {              Zahl im Bereich eines LongInts umzu-  }
   {              wandeln.                              }
   { ************************************************** }
   procedure IntToSReal(var AReal: SReal; AValue: LongInt);
   function IntToStr(AValue: LongInt): string;
   function StrToInt(AStr: string): LongInt;

   function SRealToInt(AReal: SReal): LongInt;

   { ************************************************** }
   {  SRealToStr Wandelt einen SReal-Wert in einen      }
   {              TurboPascal-String um.                }
   {  StrToSReal Wandelt einen String in einen SReal um.}
   { ************************************************** }
   function SRealToStr(AReal: SReal): string;
   procedure StrToSReal(var AReal: SReal; AStr: string);

{ ************************************************************************** }
IMPLEMENTATION
{ ************************************************************************** }

 { ****************************************************** }

 procedure IntToSReal(var AReal: SReal; AValue: LongInt);
 var
   Bytes: array[0..3] of byte absolute AValue;
   i    : Byte;
   v    : Boolean;
 begin
   RLd_0(AReal);

   v := (AValue < 0);                     { Vorzeichen ausfiltern. }
   if v then AValue := abs(AValue);

   for i := 0 to 3 do                     { Werte uebertragen und an }
    AReal.Mant[MantLast-i] := Bytes[3-i]; { die richtige Position }
   ValidSReal(AReal);                     { bringen. }
   AddExpon(AReal, 30);

   if v then RNeg(AReal);
 end;

 function IntToStr(AValue: LongInt): string;
 var
   s: string[15];
 begin
   Str(AValue, s);
   if not (s[1] = '-') then s := '+' + s;
   IntToStr := s;
 end;

 function StrToInt(AStr: string): LongInt;
 var
   Buffer: LongInt;
   Code  : Integer;
 begin
   Val(AStr, Buffer, Code);
   if not (Code = 0) then GlobalError.SError(er_NaN);
   StrToInt := Buffer;
 end;

 function SRealToInt(AReal: SReal): LongInt; assembler;
 var
       v1: Word;
 asm
       push     ds
       cld
       les      di,AReal                { Adresse der Zahl laden. }

       mov      cx,es:[di]              { Den Exponenten laden und }
       mov      ax,es:[di+02]           { ueberpruefen, ob er innerhalb }
       or       ax,ax                   { des geforderten Bereiches liegt. }
       jnz      @@4                     { (Bereich: 0..30) }
       cmp      cx,30
       ja       @@4

       mov      v1,cx                   { Damit es ein gueltiger LongInt-Wert ist, }
       add      di,ExpoSize             { sollen in den 8 hoechsten Bytes der Mantisse }
       add      di,MantSize-4           { nur die vier hoechsten gesetzt sein. }
       db       66h                     { Das Praefix 66h sorgt fuer eine }
       mov      ax,es:[di-04]           { Benutzung der 32-Bit Register. }
       db       66h
       or       ax,ax
       jnz      @@4

       mov      ax,es:[di]              { Den obersten Teil der Mantisse }
       mov      dx,es:[di+02]           { laden und in einen LongInt }
       and      dh,7Fh                  { konvertieren. }
       mov      cx,30
       sub      cx,v1
       jcxz     @@2

 @@1:  shr      dx,01                   { Die Stellen an ihren "richtigen" }
       rcr      ax,01                   { Platz schieben. }
       jc       @@4
       loop     @@1

 @@2:  push     ax                      { Vorzeichen beachten. }
       mov      al,es:[di+03]
       and      al,80h
       jz       @@3
       pop      ax
       not      ax
       not      dx
       inc      ax
       adc      dx,00
       push     ax
 @@3:  pop      ax

       jmp      @@5
 @@4:  xor      ax,ax
       xor      dx,dx
 @@5:  pop      ds
 end;
 { ****************************************************** }

 function CountStr(ANr: Byte; ACh: Char): string; { Diese Routine erzeigt einen }
 var                                              { String der Laenge ANr, der }
   AStr: string;                                  { aus dem Zeichen ACh besteht. }
 begin
   AStr := '';
   for ANr := 1 to ANr do AStr := AStr + ACh;
   CountStr := AStr;
 end;

 function AuxSRealToStr(AReal: SReal; var AValue: LongInt): string;
 var                                           { Dies ist eine Hilfsroutine duer }
   AMem, BMem: LBcdMem;                        { SRealToStr. Eigentlich macht diese }
   CMem: LLogMem;                              { hier die ganze Arbeit, aber die }
   Buffer: string;                             { "Haupt"-Routine sorgt dafuer, dass }
   i: LongInt;                                 { diese hier nicht zu lange rechnen }
   j,j2: byte;                                 { sollte. }
   k: Word;
   AExpon: LongInt;
   v,v2: Boolean;
 begin
   if GlobalError.IsError or not TestValid(AReal) then begin
     AuxSRealToStr := ''; exit;
   end;
   GlobalError.EnterProc(proc_ReStr);

   if (Digits > 200) then Digits := 200; { Durch die Laengenbegrenzung des Pascal-Strings }
                                         { koennen nicht mehr Stellen ausgegeben werden. }
   v := SReal_Neg_Abs(AReal);            { Vorzeichen bestimmen. }
   Buffer := '';                         { Buffer und lokale Variablen }
   AMem.InitMem(Digits+4);               { initialisieren. }
   BMem.InitMem(Digits+4);
   if GlobalError.IsError then begin
     GlobalError.LeaveProc;
     AuxSRealToStr := '';  exit;
   end;
   v2 := (AExpon = 0);

   if (AReal.Expon > 0) then begin          { Eine erste Annaehrung an die }
     AMem.Ld_1l;                            { Zahl: 2^Exponent. }
     AExpon := Digits;
     for i := 1 to AReal.Expon do begin
       if GlobalError.IsError then break;
       j := AMem.Mul2;
       if not (j = 0) then begin
         inc(AExpon);
         AMem.ShiftR(8);
         AMem.SetByte(0, j);
       end;
       ShowBusy;
     end;
     for i := 1 to 3 do
      if (AMem.GetByte(0) = $00)
       then AMem.ShiftL(8)
       else inc(AExpon);
   end else begin
     AMem.Ld_1f;                                { AMem mit 1 laden. }
     AExpon := 0;                               { Den Exponenten setzen. }
     for i := 1 to abs(AReal.Expon) do begin    { Dem Exponenten entsprechenden }
       j := AMem.Div2;                          { durch zwei Teilen, bis die }
       if GlobalError.IsError then break;       { gewuenschte Zahl erreicht ist. }
       if not (j = 0)                           { Wenn die Zahl rechts hinausgeht, }
        and (AMem.GetByte(0) = 0) then begin    { und ganz links noch Nullen stehen, }
         dec(AExpon);                           { so muss die ganze Zahl geschoben }
         AMem.ShiftL(8);                        { werden, damit keine Stellen }
         AMem.SetByte((AMem.Size-1), j);        { verlorengehen. }
       end;
       ShowBusy;
     end;
   end;

   for k := 0 to Digits                               { Vorangehende Nullen abschneiden. }
    do if not (AMem.GetByte(k) = $00) then break;
   if (k > 0) then begin
     dec(k);
     AMem.ShiftL(k*8);
     AExpon := AExpon - k;
   end;

   for k := MantLast downto (MantSize-OutMSize) do      { Nun alle Bits der }
    for j := 7 downto 0 do begin                        { Mantisse beruecksichtigen: }
      if GlobalError.IsError then break;                { Fehler abfangen. }
      if (j = 7) and (k = MantLast) then Continue;      { Vorzeichen-Bit ueberspringen. }
      if TestBit(AReal.Mant[k], j)                      { Wenn das Bit gesetzt ist, }
       then begin                                       { den entsprechenden Betrag zum }
         j2 := BMem.Add(AMem.Address^);                 { Zwischenresultat hinzuaddieren. }
         if not (j2 = 0) then begin
           BMem.ShiftR(8);
           BMem.SetByte(0, j2);
           inc(AExpon);
         end;
       end;
      AMem.Div2;                        { Naechste Binaerstelle. }
    end;

   AMem.Fill(0);                        { Runden. }
   AMem.SetByte(Digits-1, 1);
   if (BMem.GetByte(Digits) > 4)
    then BMem.Add(AMem.Address^);

   CMem.Init;                           { Umwandeln in Ascii-Code. }
   CMem.AssignObj(Addr(BMem));
   CMem.AddByte(48);
   BMem.CopyTo(Buffer[1]);
   Buffer[0] := chr(Digits);

   if (Buffer[1] = '0') then begin              { Null vor dem Komma abschneiden. }
     Buffer := Copy(Buffer,2, 255);
     dec(AExpon);
   end;

   for j := length(Buffer) downto 1             { Nullen nach dem Komma abschneiden. }
    do if not (Buffer[j] = '0') then break;
   Buffer[0] := chr(j);

   case AExpon of                               { Punkt einfuegen. }
     1..3: begin                                { Bei 1- bis 3-stelligen Zahlen  }
       if (length(Buffer) < (AExpon+1))         { ohne Exponent arbeiten, aber dafuer }
        then Buffer := Buffer + CountStr(AExpon+1-length(Buffer), '0');
       Insert('.', Buffer, 2+AExpon);           { die ganze Zahl darstellen. }
       AExpon := 0;
     end;
     -1: begin                                  { Ebenso bei Zahlen im Bereich }
       Buffer := '0.'+Buffer;                   { 0.1 bis 0.999... }
       AExpon := 0;
     end;
   else
     Insert('.', Buffer, 2);
   end;
   if (Buffer[length(Buffer)] = '.')            { Nicht mit einem Punkt enden. }
    then dec(byte(Buffer[0]));

   AValue := AExpon;                            { Exponenten weitergeben. }
   if v then Buffer := '-' + Buffer;            { Vorzeichen setzen. }

   CMem.ClearMe;             { Speicher wieder freigeben. }
   CMem.Done;
   BMem.Done;
   AMem.Done;
   GlobalError.LeaveProc;
   AuxSRealToStr := Buffer;
 end;

 function SRealToStr(AReal: SReal): string;
 var
   AExpon,j: LongInt;
   Buffer: string;
   BReal: SReal;
 begin
   if not TestValid(AReal) or GlobalError.IsError then exit;

   if (abs(AReal.Expon) > $20000000) then begin      { Der Exponent darf nicht zu gross sein. }
     GlobalError.SetError(er_Overflow, proc_ReStr);
     exit;
   end;

   AExpon := AReal.Expon;
   if (abs(AExpon) > 30) then begin             { Wenn der Exponent "sehr" gross ist, }
     j := abs((AExpon div 3) - 1);              { wird die Zahl zuerts durch 10^y geteilt, }
     IntToSReal(BReal, j);                      { um sie auf eine Groesse zu reduzieren, }
     RExp10(BReal);                             { die mit den BCD-Zahlen erreicht werden }
     RDiv(AReal, BReal);                        { kann. (Ansonsten brauchen die BCD-Berech- }
   end else j := 0;                             { nungen fast eine Ewigkeit. }

   AExpon := j;
   Buffer := AuxSRealToStr(AReal, AExpon);
   AExpon := AExpon + j;

   if not (AExpon = 0)                               { Exponenten anhaengen. }
    then Buffer := Buffer + 'E' + IntToStr(AExpon);

   SRealToStr := Buffer;
 end;
 { ****************************************************** }

 procedure StrToSReal(var AReal: SReal; AStr: string);
 var
   AExpon: LongInt;
   BReal : SReal;
   i,j   : Byte;
   BStr  : string[31];
   l1    : Byte absolute AStr;   { Gibt immer die Laenge von AStr an. }
   AMem  : LLogMem;
   v     : Boolean;
 begin
   if GlobalError.IsError then begin
     RLd_0(AReal);
     exit;
   end;
   GlobalError.EnterProc(proc_StrRe);

   RLd_0(AReal);
   AExpon := 0;

   v := (AStr[1] = '-');                 { Das Vorzeichen herausfiltern. }
   if v  then AStr := Copy(AStr, 2, 255);

   i := Pos('E', AStr);                 { Exponenten herausfiltern }
   if not (i = 0) then begin            { und bestimmen. }
     BStr := Copy(AStr, i+1, 255);
     l1 := i-1;
     AExpon := StrToInt(BStr);
   end else AExpon := 0;

   if (AStr[1] = '.') then AStr := '0' + AStr;          { .xxx = 0.xxx }
   for i := 1 to length(AStr) do                        { In der Zahl duerfen }
    if (Pos(AStr[i], '0123456789.') = 0) then begin     { nur gueltige Zeichen }
      GlobalError.SError(er_NaN);                       { vorhanden sein. }
      GlobalError.LeaveProc;
      RLd_0(AReal);
      exit;
    end;

   i := pos('.', AStr);                 { Den Punkt suchen und }
   if (i = 0) then begin                { den Exponenten aufgrund }
     AStr := AStr + '.';                { der Position des Punktes }
     i := l1;                           { anpassen. }
   end;

   AExpon := AExpon + i - 2;
   Delete(AStr, i, 1);                  { Den Punkt loeschen. }

   AMem.Init;                           { Umwandeln in eine BCD-Zahl. }
   AMem.AssignMem(Addr(AStr[1]), l1);
   AMem.SubByte(48);
   AMem.ClearMe;
   AMem.Done;

   IntToSReal(BReal, AExpon);           { BReal := 10^Exponent }
   RExp10(BReal);

   for i := 1 to l1 do begin            { Die BCD-Zahl in eine Real-Zahl }
     j := ord(AStr[i]);                 { umwandeln. }
     for j := 1 to j
      do RAdd(AReal, BReal);
     WDiv(BReal, 10);
     ShowBusy;
   end;

   RRound(AReal);
   if v then RNeg(AReal);

   GlobalError.LeaveProc;
 end;
 { ****************************************************** }

{ ************************************************************************** }
END.
{ ************************************************************************** }