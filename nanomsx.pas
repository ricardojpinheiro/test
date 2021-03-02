(*
 * nanomsx
 *
 * This wannabe GNU nano-like text editor is based on Qed-Pascal
 * (http://texteditors.org/cgi-bin/wiki.pl?action=browse&diff=1&id=Qed-Pascal).
 * Our main approach is to have all GNU nano funcionalities. 
 * MSX version by Ricardo Jurczyk Pinheiro - 2020/2021.
 *)

program nanoMSX;

const
    CONTROLA    = 1;
    CONTROLB    = 2;
    CONTROLC    = 3;
    CONTROLD    = 4;
    CONTROLE    = 5;
    CONTROLF    = 6;
    CONTROLG    = 7;
(*    CONTROLH    = 8; *)
(*    CONTROLI    = 9; *)
    CONTROLJ    = 10;
(*    CONTROLK    = 11; *)
(*    CONTROLL    = 12; *)
(*    CONTROLM    = 13; *)
    CONTROLN    = 14;
    CONTROLO    = 15;
    CONTROLP    = 16;
    CONTROLQ    = 17;
(*    CONTROLR    = 18; *)
    CONTROLS    = 19;
    CONTROLT    = 20;
    CONTROLU    = 21;
    CONTROLV    = 22;
    CONTROLW    = 23;
(*    CONTROLX    = 24; *)
    CONTROLY    = 25;
    CONTROLZ    = 26;
    BS          = 8;
    TAB         = 9;
    HOME        = 11;
    CLS         = 12;
    ENTER       = 13;
    INSERT      = 18;
    SELECT      = 24;
    ESC         = 27;
    RightArrow  = 28;
    LeftArrow   = 29;
    UpArrow     = 30;
    DownArrow   = 31;
    Space       = 32;
    DELETE      = 127;

type
    str80               = string [80];
    anystr              = string [255];
    linestring          = string [128];
    lineptr             = ^linestring;
    KeystrokeLines      = (main, search, replace, align);

{$i d:types.inc}
{$i d:dos.inc}
{$i d:dos2err.inc}
{$i d:fastwrit.inc}
{$i d:readvram.inc}
{$i d:fillvram.inc}
{$i d:txtwin.inc}
{$i d:blink.inc}

const
    maxlines    = 230;
    maxwidth    = 78;
    maxlength   = 21;

var
    currentline,
    highestline,
    screenline:         integer;
    column:             byte;
    linebuffer:         array [1.. maxlines] of lineptr;
    emptyline:          lineptr;
    tabset:             array [1..maxwidth] of boolean;
    textfile:           text;
    searchstring,
    replacestring,
    filename, temp:     str80;
    savedfile,
    insertmode:         boolean;
    tempnumber0:        string[5];

    Registers:          TRegs;
   
    EditWindowPtr,
    StatusWindowPtr:    Pointer;
   
    FORCLR : Byte Absolute    $F3E9; { Foreground color                        }
    BAKCLR : Byte Absolute    $F3EA; { Background color                        }
    BDRCLR : Byte Absolute    $F3EB; { Border color                            }

function Readkey: char;
var
    bt: integer;
    qqc: byte absolute $FCA9;
 
begin
    Readkey := chr(0);
    qqc := 1;
    Inline($f3/$fd/$2a/$c0/$fc/$DD/$21/$9F/00/$CD/$1c/00/$32/bt/$fb);
    Readkey := chr(bt);
    qqc := 0;
end;

(* Finds the last occurence of a char into a string. *)

function LastPos(Character: char; Phrase: TString): integer;
var
    i: integer;
    Found: boolean;
begin
    i := length(Phrase);
    Found := false;
    repeat
        if Phrase[i] = Character then
        begin
            LastPos := i + 1;
            Found := true;
        end;
        i := i - 1;
    until (Found = true) or (i = 1);
    if Not Found then LastPos := 0;
end;

(* Finds the first occurence of a char which is different into a string. *)

function DifferentPos(Character: char; Phrase: TString): byte;
var
    i: byte;
    Found: boolean;
begin
    i := 1;
    Found := false;
    repeat
        if Phrase[i] <> Character then
        begin
            DifferentPos := i;
            Found := true;
        end;
        i := i + 1;
    until (Found = true) or (i = length(Phrase));
    if Not Found then DifferentPos := 0;
end;

(* Finds the last occurence of a char which is different into a string. *)

function LastDifferentPos(Character: char; Phrase: TString): integer;
var
    i: integer;
    Found: boolean;
begin
    i := length(Phrase);
    Found := false;
    repeat
        if Phrase[i] <> Character then
        begin
            LastDifferentPos := i + 1;
            Found := true;
        end;
        i := i - 1;
    until (Found = true) or (i = 1);
    if Not Found then LastDifferentPos := 0;
end;

procedure CheatAPPEND (FileName: TFileName);
var
    i, FirstTwoDotsFound, LastBackSlashFound: byte;
    APPEND: string[7];
    Path, Temporary: TFileName;
begin

(* Initializing some variables... *)

    fillchar(Path, sizeof(Path), ' ' );
    fillchar(Temporary, sizeof(Temporary), ' ' );
    APPEND[0] := 'A';   APPEND[1] := 'P';   APPEND[2] := 'P';
    APPEND[3] := 'E';   APPEND[4] := 'N';   APPEND[5] := 'D';
    APPEND[6] := #0;
    
(*  Sees if in the path there is a ':', used with drive letter. *)    
    
    FirstTwoDotsFound := Pos (chr(58), FileName);

(*  If there is a two dots...  *)
    
    if FirstTwoDotsFound <> 0 then
    begin
    
(*  Let me see where is the last backslash character...  *)

        LastBackSlashFound := LastPos (chr(92), FileName);
        Path := copy (FileName, 1, LastBackSlashFound);

(*  Copy the path to the variable. *)
        
        for i := 1 to LastBackSlashFound - 1 do
            Temporary[i - 1] := Path[i];
        Temporary[LastBackSlashFound] := #0;
        Path := Temporary;

(*  Sets the APPEND environment variable. *)
        
        with Registers do
        begin
            B := sizeof (Path);
            C := ctSetEnvironmentItem;
            HL := addr (APPEND);
            DE := addr (Path);
        end;
        MSXBDOS (Registers);
    end;
end;

(* Here we use MSX-DOS 2 to do the error handling. *)

procedure ErrorCode (ExitsOrNot: boolean);
var
    ErrorCodeNumber: byte;
    ErrorMessage: TMSXDOSString;
    
begin
    ErrorCodeNumber := GetLastErrorCode;
    GetErrorMessage (ErrorCodeNumber, ErrorMessage);
    WriteLn (ErrorMessage);
    if ExitsOrNot = true then
        Exit;
end;

Procedure CursorOn;
Begin
    BlinkChar(column + 1, screenline + 1);
End;

Procedure CursorOff;
Begin
    ClearBlinkChar(column + 1, screenline + 1);
End;

(* Return true if a key waiting, and the key. *)

procedure GetKey (var key: byte; var iscommand: boolean);
var
    inkey : char;
begin
    iscommand   := false;
    inkey       := readkey;
    key         := ord(inkey);
    case key of
        1..31, 127: iscommand := true;
    end;
end;

procedure quick_display(x, y: integer; s: linestring);
begin
    GotoWindowXY(EditWindowPtr, x, y);
    WriteWindow (EditWindowPtr, s);
    ClrEolWindow(EditWindowPtr);
end;

procedure StatusLine (message: str80);
var
    i, lengthmessage, position: byte;
    
begin
    ClearBlink(1, maxlength + 1, maxwidth + 2);
    FillChar(temp, maxwidth + 3, #23);
    temp[1] := #26;     temp[maxwidth + 2] := #27;
    WriteVram(0, (maxwidth + 2) * maxlength, Addr(temp[1]), maxwidth + 3);

    message := concat('[ ', message, ' ]');
    lengthmessage := length(message);
    position := (maxwidth - lengthmessage) div 2;

    GotoXY(position, maxlength + 1);
    FastWrite(message);
    Blink(position, maxlength + 1, lengthmessage);
end;

procedure DisplayKeys (whichkey: KeystrokeLines);
var
    BlinkSequence: array [1..6] of byte;
    Line1, Line2: str80;
    i, BlinkLength: byte;
    
begin
    for i := 2 to 3 do
        ClearBlink(1, maxlength + i, maxwidth);

    fillchar(BlinkSequence, sizeof(BlinkSequence), 0);

    case whichkey of
        main:       begin
                        BlinkLength := 2;
                        BlinkSequence[1] := 1;  BlinkSequence[2] := 9;
                        BlinkSequence[3] := 22; BlinkSequence[4] := 34;
                        BlinkSequence[5] := 43; BlinkSequence[6] := 54;
                        Line1 := '^G Help ^O Write Out ^W Where Is ^K Cut   ^T Execute ^C Location  ';
                        Line2 := '^Z Exit ^R Read File ^N Replace  ^U Paste ^J Justify ^_ Go To Line';
                    end;
        search:     begin
                        BlinkLength := 2;
                        BlinkSequence[1] := 1;  BlinkSequence[2] := 11;
                        BlinkSequence[3] := 24; BlinkSequence[4] := 37;
                        BlinkSequence[5] := 46;
                        Line1 := '^G Help   ~C Case Sens ~B Backwards ^P Older ^T Go To Line        ';
                        Line2 := '^C Cancel ~R Reg.Exp.  ^E Replace   ^N Newer ^X Exit              ';
                    end;
        replace:    begin
                        BlinkLength := 2;
                        BlinkSequence[1] := 1;  BlinkSequence[2] := 15;
                        Line1 := ' Y Yes         A All                                              ';
                        Line2 := ' N No         ^C Cancel                                           ';
                    end;
        align:      begin
                        BlinkLength := 2;
                        BlinkSequence[1] := 1;  BlinkSequence[2] := 15;
                        Line1 := ' L Left        C Center                                            ';
                        Line2 := ' R Right       J Justify                                           ';
                    end;
    end;
    WriteVRAM(0, (maxwidth + 2) * (maxlength + 1), Addr(Line1[1]), length(Line1));
    WriteVRAM(0, (maxwidth + 2) * (maxlength + 2), Addr(Line2[1]), length(Line2));

    for i := 1 to sizeof(BlinkSequence) do
    begin
        Blink(BlinkSequence[i], maxlength + 2, BlinkLength);
        Blink(BlinkSequence[i], maxlength + 3, BlinkLength);
    end;
end;

procedure DrawScreen;
var
   i:  integer;
begin
    ClrWindow(EditWindowPtr);
    for i := 1 to (maxlength - 1) do
        quick_display(1 , i, linebuffer [currentline - screenline + i]^);
end;

procedure NewBuffer (var buf: lineptr);
begin
    new(buf);
end;

procedure ReadFile (name: str80);
var
    i: integer;
    maxlinesnotreached: boolean;

begin
    maxlinesnotreached := false;
    
    assign(textfile, name);
    {$i-}
    reset(textfile);
    {$i+}

    if (ioresult <> 0) then
        StatusLine('New file')
    else
    begin
        for i := 1 to maxlines do
            if (linebuffer[i] <> emptyline) then
                linebuffer[i]^ := emptyline^;

        currentline := 1;

        while not eof (textfile) do
        begin

            if (currentline mod 100) = 0 then
                write(#13, currentline);

            if linebuffer[currentline] = emptyline then
                NewBuffer(linebuffer[currentline]);

            readln(textfile, linebuffer [currentline]^);

            currentline := currentline + 1;
            
            if (currentline > maxlines) then
            begin
                maxlinesnotreached := true;
                exit;
            end;
        end;
        
(*  Resolver depois: Se o arquivo for grande demais pro editor, ler 
*   somente a parte que dá pra ler e parar.*)
        
        str(currentline - 1, tempnumber0);

        if maxlinesnotreached then
            temp := concat('File is too long. Read ', tempnumber0, ' lines. ')
        else
            temp := concat('Read ', tempnumber0, ' lines.');

        StatusLine (temp);
    end;

    close(textfile);

    highestline := currentline;
    currentline := 1;
    column      := 1;
    screenline  := 1;

    DrawScreen;
end;

procedure InitTextEditor;
var
    i: integer;

begin
    clrscr;
    ClearAllBlinks;
    SetBlinkColors(BAKCLR, FORCLR);
    SetBlinkRate(5, 0);
    
    fillchar(temp, sizeof(temp), ' ');
    EditWindowPtr := MakeWindow(0, 1, maxwidth + 2, maxlength + 1, filename);

    GotoXY(3, 1);
    FastWrite('nanoMSX 0.1');

    Blink(2, 1, maxwidth);

    DisplayKeys (main);

(*  Some variables. *)   

    currentline     := 1;
    column          := 1;
    screenline      := 1;
    highestline     := 1;
    NewBuffer(emptyline);
    emptyline^      := '';
    searchstring    := '';
    replacestring   := '';
    insertmode      := false;
    savedfile       := false;

    for i := 1 to maxwidth do
        tabset[i] := (i mod 8) = 1;

    for i := 1 to maxlines do
        linebuffer[i] := emptyline;
end;

procedure Help;
var
    c: char;
begin
    ClearBlink(1, maxlength + 1, maxwidth + 2);
    StatusWindowPtr := MakeWindow(0, 1, maxwidth + 2, maxlength + 1, 'Main nanoMSX help text');
    WritelnWindow(StatusWindowPtr, 'Commands:');
    WritelnWindow(StatusWindowPtr, 'TODO Ctrl-S - Save current file.     Ctrl-O - Offer to write file ("Save as").');
    WritelnWindow(StatusWindowPtr, 'TODO Ctrl-R - Read new file.            Ctrl+Z - Close buffer, exit from nano.');
    WritelnWindow(StatusWindowPtr, 'Ctrl+G - Display help text               TODO Ctrl+C - Report cursor position.');
    WritelnWindow(StatusWindowPtr, 'Ctrl+A - To start of line. Ctrl+Y - One page up.   Ctrl+F - One word backward.');
    WritelnWindow(StatusWindowPtr, 'Ctrl+E - To end of line.   Ctrl+V - One page down. Ctrl+D - One word forward.');
    WritelnWindow(StatusWindowPtr, 'TAB - Indent marked region                SELECT+TAB - Unindent marked region.');
    WritelnWindow(StatusWindowPtr, 'Cursor right - One character forward.              Cursor up    - One line up.');
    WritelnWindow(StatusWindowPtr, 'Cursor left  - One character backward            Cursor down  - One line down.');
    WritelnWindow(StatusWindowPtr, 'HOME - To start of file.                        Ctrl+W - Start forward search.');
    WritelnWindow(StatusWindowPtr, 'CLS - To end of file.                     TODO Ctrl+Q - Start backward search.');
    WritelnWindow(StatusWindowPtr, 'TODO Ctrl+J - Align line.                  Ctrl+N - Start a replacing session.');
    WritelnWindow(StatusWindowPtr, 'BS - Delete character before cursor.      DEL - Delete character under cursor.');
    WritelnWindow(StatusWindowPtr, 'SELECT-DEL - Delete current line.');
{
    WritelnWindow(StatusWindowPtr, '');
    WritelnWindow(StatusWindowPtr, '');
    WritelnWindow(StatusWindowPtr, '');
    WritelnWindow(StatusWindowPtr, '');
    WritelnWindow(StatusWindowPtr, '');
    WritelnWindow(StatusWindowPtr, '');
}
    c := readkey;
    EraseWindow(StatusWindowPtr);
end;

procedure character(inkey : char);
begin
    CursorOff;
    if column > maxwidth then
        delay(30)
    else
    begin
        GotoWindowXY(EditWindowPtr, column, screenline);
        WriteWindow(EditWindowPtr, inkey);

        if linebuffer[currentline] = emptyline then
        begin
            NewBuffer(linebuffer[currentline]);
            linebuffer[currentline]^ := '';
        end;

        while length(linebuffer[currentline]^) <= column do
            linebuffer[currentline]^ := linebuffer[currentline]^ + ' ';

        insert(inkey, linebuffer [currentline]^, column);
        column := column + 1;

        if not insertmode then
            delete(linebuffer [currentline]^, column, 1);

(* redraw current line if in insert mode *)
        if insertmode then
            quick_display(1, screenline, linebuffer [currentline]^);

(* ding the bell when close to the end of a line *)

        if column >= 78 then
            delay(10);
    end;
    CursorOn;
end;

procedure BeginFile;
begin
    currentline := 1;
    column      := 1;
    screenline  := 1;
    DrawScreen;
end;

procedure EndFile;
begin
    currentline := highestline;
    screenline  := maxlength;
    column      := 1;
    DrawScreen;
end;

procedure BeginLine;
begin
    currentline := WhereYWindow(EditWindowPtr);
    column      := 1;
    screenline  := WhereYWindow(EditWindowPtr);
    DrawScreen;
end;

procedure EndLine;
begin
    column      := length (linebuffer [currentline]^) + 1;
    if column > maxwidth then
        column := maxwidth;
end;

procedure CursorUp;
begin
    if currentline = 1 then
        exit;

    currentline := currentline - 1;
    if screenline = 1 then
    begin
        gotoWindowXY(EditWindowPtr, 1, 1);
        ScrollWindowDown(EditWindowPtr);
        quick_display(1, 1, linebuffer [currentline]^);
    end
    else
        screenline := screenline - 1;
end;

procedure CursorDown;
begin
    if currentline >= (highestline - 1) then
        exit;
    
    currentline :=  currentline + 1;
    screenline  :=  screenline  + 1;

    if screenline > (maxlength - 1) then
    begin
        GotoWindowXY(EditWindowPtr, 1, 2);
        ScrollWindowUp(EditWindowPtr);
        screenline := maxlength - 1;
        quick_display(1, screenline, linebuffer [currentline]^);
    end;
end;

procedure InsertLine;
var
    i: integer;
begin
    GotoWindowXY(EditWindowPtr, column, screenline + 1);
    InsLineWindow(EditWindowPtr);

    for i := highestline + 1 downto currentline do
        linebuffer[i + 1] := linebuffer[i];

    linebuffer[currentline] := emptyline;
    highestline := highestline + 1;
end;

procedure Return;
begin
    CursorDown;
    column := 1;
    GotoWindowXY(EditWindowPtr, column, screenline);

    if insertmode then
        InsertLine;
end;

procedure deleteline;
var
   i: integer;
begin
    DelLineWindow(EditWindowPtr);

    if highestline > currentline + (maxlength - screenline) then
        quick_display(1, maxlength,linebuffer [currentline + ((maxlength + 1) - screenline)]^);

    if linebuffer[currentline] <> emptyline then
        linebuffer[currentline]^ := emptyline^;

    for i := currentline to highestline + 1 do
        linebuffer[i] := linebuffer [i + 1];

    linebuffer [highestline + 2] := emptyline;
    highestline := highestline - 1;

    if currentline > highestline then
        highestline := currentline;
 end;

procedure CursorLeft;
begin
    column := column - 1;

    if column < 1 then
    begin
        CursorUp;
        EndLine;
    end;
end;

procedure CursorRight;
begin
    column := column + 1;

    if column > 79 then
    begin
        CursorDown;
        column := 1;
    end;
end;

procedure ins;
begin
    if insertmode then
        insertmode := false
    else
        insertmode := true;

    GotoXY(79, 1);
    if insertmode then
        write('I')
    else
        write('O');
end;

procedure del;
begin
    if (column > length(linebuffer[currentline]^)) then
    begin
        if (length(linebuffer[currentline]^) + length(linebuffer[currentline+1]^)) < maxwidth then
        begin
            linebuffer[currentline]^ := linebuffer[currentline]^ + linebuffer[currentline+1]^;
            quick_display(1, screenline, linebuffer [currentline]^);
            CursorDown;
            deleteline;
            CursorUp;
        end;
        exit;
    end;

    if linebuffer[currentline] = emptyline then
    begin
        NewBuffer(linebuffer[currentline]);
        linebuffer[currentline]^ := '';
    end;

    while length(linebuffer[currentline]^) < column do
        linebuffer[currentline]^ := linebuffer[currentline]^ + ' ';

    delete(linebuffer [currentline]^, column, 1);

    GotoWindowXY(EditWindowPtr, 1, screenline);
    ClrEolWindow(EditWindowPtr);
    quick_display(1,screenline,linebuffer [currentline]^);
end;

procedure backspace;
begin
    if column > 1 then
        column := column - 1
    else
    begin
        CursorUp;
        EndLine;
    end;
    del;
end;

procedure WriteOut (AskForName: boolean);
var
    i: integer;
    tempfilename: str80;
    
begin
    if AskForName then
    begin
        GotoXY(1, maxlength + 1);
        ClrEol;
        Blink(1, maxlength + 1, maxwidth + 2);
        if filename <> '' then
            temp := concat('File Name to Write [', filename, ']: ')
        else
            temp := concat('File Name to Write: ');
{    
        tempfilename := filename;
}
        FastWrite(temp);
        read(filename);
    end;
    
    assign(textfile, filename);
    {$i-}
    rewrite(textfile);
    {$i+}
    
    filename := tempfilename;
    
    for i := 1 to highestline + 1 do
    begin
        if (i mod 100) = 0 then
            write(#13, i);

        writeln(textfile, linebuffer [i]^);
    end;
    
    close(textfile);
    
    savedfile := true;
    
    ClearBlink(1, maxlength + 1, maxwidth + 2);
    str(highestline + 1, tempnumber0);
    temp := concat('Wrote ', tempnumber0, ' lines ');
    StatusLine(temp);
end;

procedure ExitToDOS;
begin
    if not savedfile then
        WriteOut(false); 
    EraseWindow(EditWindowPtr);
    ClearAllBlinks;
    clrscr;
    halt;
end;

procedure PageUp;
begin
   currentline := currentline - maxlength - 2;
   if currentline <= screenline then
      BeginFile
   else
      DrawScreen;
 end;

procedure PageDown;
begin
  currentline := currentline + maxlength - 2;
  if currentline + 12 >= highestline then
     EndFile
  else
     DrawScreen;
end;

procedure prevword;
begin
(* if i am in a word then skip to the space *)
    while (not ((linebuffer[currentline]^[column] = ' ') or
               (column >= length(linebuffer[currentline]^) ))) and
         ((currentline <> 1) or
          (column <> 1)) do
      CursorLeft;

(* find end of previous word *)
   while ((linebuffer[currentline]^[column] = ' ') or
          (column >= length(linebuffer[currentline]^) )) and
         ((currentline <> 1) or
          (column <> 1)) do
      CursorLeft;

(* find start of previous word *)
   while (not ((linebuffer[currentline]^[column] = ' ') or
               (column >= length(linebuffer[currentline]^) ))) and
         ((currentline <> 1) or
          (column <> 1)) do
      CursorLeft;

   CursorRight;
end;

procedure NextWord;
begin
(* if i am in a word, then move to the whitespace *)
   while (not ((linebuffer[currentline]^[column] = ' ') or
               (column >= length(linebuffer[currentline]^)))) and
         (currentline < highestline) do
      CursorRight;

(* skip over the space to the other word *)
   while ((linebuffer[currentline]^[column] = ' ') or
          (column >= length(linebuffer[currentline]^))) and
         (currentline < highestline) do
      CursorRight;
end;

procedure tabulate;
begin
   CursorOff;
   if column < 79 then
   begin
       repeat
           column := column + 1;
       until (tabset [column]= true) or (column = 79);
   end;
   CursorOn;
end;

procedure backtab;
begin
    if column > 1 then
    begin
        repeat
            column := column - 1;
        until (tabset [column]= true) or (column = 1);
    end;
end;

procedure RemoveLine;
begin
    CursorOff;
    column := 1;
    GotoWindowXY(EditWindowPtr, column, WhereYWindow(EditWindowPtr));
    ClrEolWindow(EditWindowPtr);

    if (linebuffer[currentline] <> emptyline) then
        linebuffer[currentline]^ := emptyline^;

    linebuffer[currentline] := emptyline;
    CursorOn;
end;
{
procedure locate;
var
    i, j, pointer, position, len    : integer;
    c                               : char;

begin
    SetBlinkRate (5, 0);
    temp := 'String to be located: ';
    j := length (temp);
    StatusWindowPtr := MakeWindow (1, 12, 79, 3, 'Search');
    GotoWindowXY (StatusWindowPtr, 1, 1);
    WriteWindow(StatusWindowPtr, temp);
    GotoWindowXY (StatusWindowPtr, j + 1, 1);
    temp := '';
    readln(temp);

    if temp <> '' then
        searchstring := temp;
    len := length (searchstring);

    if len = 0 then
    begin
        BeginFile;
        exit;
    end;

    temp := 'Searching... ';
    j := length (temp);
    GotoXY (1, maxlength + 2);
    ClrEol;
    Write(temp);

    StatusWindowPtr := MakeWindow (1, 2, 79, 22, 'Located strings:');
    GotoWindowXY (StatusWindowPtr, 1, 1);

    for i := 1 to highestline do
    begin
    (* look for matches on this line *)
        pointer := pos (searchstring, linebuffer [i]^);

   (* if there was a match then get ready to print it *)
        if (pointer > 0) then
        begin
            temp := linebuffer [i]^;
            position := pointer;
            WritelnWindow(StatusWindowPtr, copy(temp, 1, 79));

        (* print all of the matches on this line *)
            while pointer > 0 do
            begin
                temp := copy (temp, pointer + len + 1, 128);
                pointer := pos (searchstring, temp);
                position := position + pointer + len;
            end;

        (* go to next line and keep searching *)
        end;
    end;

    WritelnWindow(StatusWindowPtr, 'End of locate.  Press any key to exit...');
    c := readkey;
    ClrWindow(StatusWindowPtr);
    BeginFile;
end;
}
procedure WhereIs;
var
    c                   : char;
    i, j, pointer, len  : integer;
    tempsearchstring    : str80;
 
begin
    DisplayKeys (search);
    GotoXY(1, maxlength + 1);
    ClrEol;
    Blink(1, maxlength + 1, maxwidth + 2);
    tempsearchstring := searchstring;
    if searchstring <> '' then
        temp := concat('Search [', tempsearchstring, ']: ')
    else
        temp := 'Search: ';
        
    FastWrite (temp);
    read(searchstring);

    if length (searchstring) = 0 then
        if length(tempsearchstring) = 0 then
        begin
            BeginFile;
            exit;
        end
        else
            searchstring := tempsearchstring;
        
    for i := currentline + 1 to highestline do
    begin
    
    (* look for matches on this line *)

        pointer := pos (searchstring, linebuffer [i]^);

    (* if there was a match then get ready to print it *)
        
        if (pointer > 0) then
        begin
            currentline := i;
            if currentline >= maxlength then
            begin
                screenline := maxlength - 1;
                DrawScreen;
            end
            else
                screenline := currentline;
            column := pointer;

    (* Redraw the StatusLine, bottom of the window and display keys *)

            ClearBlink(1, maxlength + 1, maxwidth + 2);
            FillChar(temp, maxwidth + 3, #23);
            temp[1] := #26; temp[maxwidth + 2] := #27;
            WriteVram(0, (maxwidth + 2) * maxlength, Addr(temp[1]), maxwidth + 3);
            DisplayKeys (main);
            exit;
        end;
    end;

    ClearBlink(1, maxlength + 1, maxwidth + 2);
    temp := concat(searchstring, ' not found');
    StatusLine(temp);
    DisplayKeys (main);
end;

procedure SearchAndReplace;
var
    i, j, position, line                : integer;
    searchlength, replacementlength     : byte;
    choice                              : char;
    tempsearchstring                    : str80;
   
begin
    DisplayKeys (search);
    SetBlinkRate (5, 0);
    GotoXY(1, maxlength + 1);
    ClrEol;
    Blink(1, maxlength + 1, maxwidth + 2);

    tempsearchstring := searchstring;
    if searchstring <> '' then
        temp := concat('Search (to replace) [', tempsearchstring, ']: ')
    else
        temp := 'Search (to replace): ';
        
    FastWrite (temp);
    read(searchstring);
    
    searchlength := length(searchstring);

    if searchlength = 0 then
        if length(tempsearchstring) = 0 then
        begin
            BeginFile;
            exit;
        end
        else
            searchstring := tempsearchstring;

    GotoXY(1, maxlength + 1);
    ClrEol;
    DisplayKeys (replace);

    temp := concat('Replace with: ');
    FastWrite (temp);
    read(replacestring);    
    
    replacementlength := length (replacestring);

    choice := ' ';    

    for line := 1 to highestline do
    begin
        position := pos (searchstring, linebuffer [line]^);

        while (position > 0) do
        begin
            currentline := line;
            if currentline >= 12 then
                screenline := 12
            else
                screenline := currentline;

            DrawScreen;
            column := position;
            Blink(column + 1, screenline + 1, searchlength);

            GotoXY(1, maxlength + 1);

            if not (choice in ['a', 'A']) then
            begin
                FastWrite('Replace this instance?');
                choice := readkey;
            end;

            ClearBlink(column + 1, screenline + 1, searchlength);

(*      Problema: Na execução do replace, *)
            
            case ord (choice) of
            CONTROLC:          begin
                                    ClrEol;
                                    StatusLine('Cancelled');
                                    DisplayKeys (main);
                                    BeginFile;
                                    exit;
                                end;
                                
(* a, A, y, Y *)
                                
(* Problema: A rotina que faz a troca precisa fazer nova busca a partir daquela posição
* nova. Este é um problema que vem desde o código original. Outra alteração seria 
* apenas reescrever aquela linha específica, e não toda a janela. Redesenhar toda a 
* janela, somente se trocar de página. *)
                                
            65, 97, 89, 121:    begin
                                    linebuffer[line]^ := copy (linebuffer [line]^, 1, position - 1) +
                                    replacestring + copy (linebuffer [line]^, 
                                    position + length (searchstring), 128);

                                    position := pos (searchstring, copy (linebuffer[line]^,
                                    position + replacementlength + 1, 128)) + 
                                    position + replacementlength;
                                end;
(* n, N *)                                

            78, 110:            position := pos (searchstring, copy (linebuffer[line]^,
                                position + length(searchstring) + 1, 128)) +
                                position + length(searchstring);
            end;

            GotoWindowXY(EditWindowPtr, 1, screenline);
            ClrEolWindow(EditWindowPtr);
            temp := copy(linebuffer[currentline]^, 1, 79);
            WriteWindow(EditWindowPtr, temp);
        end;
    end;
end;

procedure AlignText;
var
    lengthline, blankspaces: byte;
    c: char;
    justifyvector: array [1..80] of byte;

    i, j, k, l: byte;

    procedure RemoveBlankSpaces;
    begin
        delete(linebuffer[currentline]^, 1, DifferentPos(#32, linebuffer[currentline]^) - 1);
        delete(linebuffer[currentline]^, LastDifferentPos(#32, linebuffer[currentline]^), lengthline);
    end;
    
begin
(*  Testar um pouco mais. *)

    lengthline := (LastDifferentPos(#32, linebuffer[currentline]^)) - (DifferentPos(#32, linebuffer[currentline]^) - 1) + 1;
    gotoxy (15, 1); write(lengthline);

    DisplayKeys(align);
    c := readkey;

    case ord(c) of
        76, 108:    begin
(* left *)
                        RemoveBlankSpaces;
                        blankspaces := (maxwidth - lengthline) + 1;
                        for i := 1 to blankspaces do
                            insert(#32, linebuffer[currentline]^ , lengthline);
                        delete(linebuffer[currentline]^, LastDifferentPos(#32, linebuffer[currentline]^), lengthline);
                    end;
        82, 114:    begin
(* right *)        
                        RemoveBlankSpaces;
                        blankspaces := (maxwidth - lengthline);
                        for i := 1 to blankspaces do
                            insert(#32, linebuffer[currentline]^ , 1);
                    end;
        67, 99:     begin
(* center *)
                        RemoveBlankSpaces;
                        blankspaces := (maxwidth - lengthline) div 2;
                        for i := 1 to blankspaces do
                            insert(#32, linebuffer[currentline]^ , 1);                        
                    end;
        74, 106:    begin
(* justify *)
                        temp := linebuffer[currentline]^;
                        j := 1;
                        for i := 1 to (LastDifferentPos(chr(32), temp)) do
                        begin
                            if ord(temp[i]) = 32 then
                            begin
                                justifyvector[j] := i;
                                j := j + 1;
                            end;
                        end;
                        k := (maxwidth - length(temp)) div (j - 1);
                        
                        for i := j downto 1 do
                        begin
                            for l := 1 to k do
                                insert(#32, temp, justifyvector[i]);
                            justifyvector[i] := justifyvector[i] + k;
                        end;
                        linebuffer[currentline]^ := temp;
                    end;
    end;
    DisplayKeys(main);

(*  Fica mais rápido redesenhar somente a linha alterada. *)

    quick_display(1, screenline, linebuffer[currentline]^);
{
    DrawScreen;
}
end;

procedure Location;
var
    tempnumber1, tempnumber2: string[5];
    tempint, tempint2: byte;

begin
    fillchar(temp, sizeof(temp), #32);
    str(currentline, tempnumber0);
    str(highestline, tempnumber1);

(*  Calculating percentage. *)    

    tempint := ((currentline * 100) div highestline);
    str(tempint, tempnumber2);
    temp := concat(' line ',tempnumber0,'/',tempnumber1, ' (', tempnumber2,'%), ');

    tempint2 := length(linebuffer[currentline]^) + 1;
    str(column, tempnumber0);
    str(tempint2, tempnumber1);
    tempint := ((column * 100) div tempint2);
    str(tempint, tempnumber2);
    
    temp := concat(temp, 'col ',tempnumber0,'/',tempnumber1, ' (', tempnumber2,'%)');

    StatusLine(temp);
end;

procedure handlefunc(keynum: byte);
var
    key         : byte;
    iscommand   : boolean;
    
begin
    case keynum of
        BS          :   backspace;
        TAB         :   tabulate;
        ENTER       :   Return;
        UpArrow     :   CursorUp;
        LeftArrow   :   CursorLeft;
        RightArrow  :   CursorRight;
        DownArrow   :   CursorDown;
        INSERT      :   ins;
        DELETE      :   del;
        HOME        :   BeginFile;
        CLS         :   EndFile;
        CONTROLA    :   BeginLine;
        CONTROLB    :   PrevWord;
        CONTROLC    :   Location; 
        CONTROLD    :   del;
        CONTROLE    :   EndLine;    
        CONTROLF    :   NextWord;
        CONTROLG    :   Help;
        CONTROLJ    :   AlignText;
        CONTROLN    :   SearchAndReplace;
        CONTROLO    :   WriteOut(true);
        CONTROLS    :   WriteOut(false);
(*        CONTROLP    : *)
(*        CONTROLQ    : Busca de trás pra frente. Alterar o search pra isso. *)
(*        CONTROLR    : Ler novo arquivo. *)
(*        CONTROLT    : Tá sobrando... *)
(*        CONTROLU    : Colar conteúdo do buffer. Vai demorar... *)
        CONTROLV    :   PageDown;
        CONTROLW    :   WhereIs;
        CONTROLY    :   PageUp;
        CONTROLZ    :   ExitToDOS;
        SELECT      :   begin
                            GetKey (key, iscommand);
                            if iscommand then
                                case key of
                                    DELETE: RemoveLine;
                                    TAB:    backtab;
                                    else    delay(100);
                                end;
                        end;
        else    delay(100);
    end;
end;

(* main *)

var
    key         : byte;
    iscommand   : boolean;

begin

    if (paramcount <> 1) then
    begin
        writeln('Usage: nanomsx FILENAME');
        halt;
    end;

    filename := paramstr(1);
    InitTextEditor;
    ReadFile(filename);

(* main loop - get a key and process it *)

    repeat
        GotoWindowXY(EditWindowPtr, column, screenline);
        CursorOn;
        GetKey (key, iscommand);
        CursorOff;
        if iscommand then
            handlefunc(key)
        else
            character(chr(key));

   until true = false;
   ClearAllBlinks;
 end.
