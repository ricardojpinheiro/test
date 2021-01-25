(*
 * quick editor
 *
 * This is a simple and fast editor to use when you want to quickly
 * change a file.  It is not meant to be used as a programming editor
 * Adapted for MSX by Ricardo Jurczyk Pinheiro - 2020.
 *)

program QEDMSX;

const
    CONTROLA    = 1;
    CONTROLB    = 2;
    CONTROLC    = 3;
    CONTROLE    = 5;
    CONTROLF    = 6;
    CONTROLJ    = 10;
    CONTROLK    = 11;
    CONTROLL    = 12;
    CONTROLN    = 14;
    CONTROLP    = 16;
    CONTROLQ    = 17;
    CONTROLV    = 22;
    CONTROLY    = 25;
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
    anystr      = string [255];
    linestring  = string [128];
    lineptr     = ^linestring;

{$i d:fastwrit.inc}
{$i d:readvram.inc}
{$i d:fillvram.inc}
{$i d:txtwin.inc}
{$i d:blink.inc}

const
    maxlines    = 50;
    maxwidth    = 78;
    maxlength   = 22;

var
    currentline,
    column,
    highestline,
    screenline:         integer;
    linebuffer:         array [1.. maxlines] of lineptr;
    emptyline:          lineptr;
    tabset:             array [1..maxwidth] of boolean;
    textfile:           text;
    searchstring,
    replacement:        linestring;
    insertmode:         boolean;
   
    EditWindowPtr,
    StatusWindowPtr    : Pointer;
   
    FORCLR : Byte Absolute    $F3E9; { Foreground color                        }
    BAKCLR : Byte Absolute    $F3EA; { Background color                        }
    BDRCLR : Byte Absolute    $F3EB; { Border color                            }

function Readkey : char;
var
    bt: integer;
    qqc: byte absolute $FCA9;
 
begin
    readkey := chr(0);
    qqc := 1;
    Inline($f3/$fd/$2a/$c0/$fc/$DD/$21/$9F/00/$CD/$1c/00/$32/bt/$fb);
    readkey := chr(bt);
    qqc := 0;
end;

Procedure CursorOn;
Begin
    BlinkChar(column + 1, screenline + 1);
End;

Procedure CursorOff;
Begin
    ClearBlinkChar(column + 1, screenline + 1);
End;

(**************************************************************************
  Return true if a key waiting, and the key.
 **************************************************************************)
procedure getkey (var key: integer; var iscommand: boolean);
var
    inkey : char;
begin
    iscommand := false;
    inkey := readkey;
    key := ord(inkey);
    case key of
        1..31, 127: iscommand := true;
    end;
end;

procedure WaitForKey;
var
    key         : integer;
   iscommand    : boolean;
begin
    getkey(key, iscommand);
end;

procedure init_msgline;
begin
    GotoXY(1, 24);
end;

procedure edit_win;
begin
(*
    EraseWindow(EditWindowPtr);
    EditWindowPtr := MakeWindow(0, 1, 80, 22, 'Quick Editor for MSX');
*)
end;

procedure full_screen;
begin
(*
    EraseWindow(MainWindowPtr);
    MainWindowPtr := MakeWindow(1, 1, 80, 25, '');
*)
end;

procedure quick_display(x,y: integer; s: linestring);
begin
    GotoWindowXY(EditWindowPtr, x, y);
    WriteWindow(EditWindowPtr, s);
    ClrEolWindow(EditWindowPtr);
end;

 procedure displaykeys;
 begin
   init_msgline;
   Write('1Help 2Locate 3Search 4Replace 5SaveQuit 6InsLine 7DelLine 0QuitNosave');
(*
   BlinkChar(1, 24); 
   BlinkChar(7, 24); 
   BlinkChar(15, 24); 
   BlinkChar(23, 24); 
   BlinkChar(32, 24); 
   BlinkChar(42, 24); 
   BlinkChar(51, 24); 
   BlinkChar(60, 24); 
*)
   edit_win;
 end;

procedure ShowMessage(message : anystr);
begin
    GotoXY(1, 24);
    ClrEol;
    write(message);
    WaitForKey;
    displaykeys;
end;

procedure drawscreen;
var
   i:  integer;
begin
    ClrWindow(EditWindowPtr);
    for i := 1 to (maxlength - 1) do
        quick_display(1 , i, linebuffer [currentline - screenline + i]^);
end;

 procedure newbuffer(var buf: lineptr);
 begin
    new(buf);
 end;

 procedure loadfile (name: linestring);
 var
   i: integer;
   temp, tempint: linestring;
 begin
    edit_win;
    assign(textfile, name);
    {$i-}
    reset(textfile);
    {$i+}

    if (ioresult <> 0) then
    begin
        fillchar(temp, sizeof(temp), ' ' ); 
        temp := concat('File not found: ', name);
        i := length(temp);
        StatusWindowPtr := MakeWindow (((80 - i) div 2), 12, i + 2, 3, 'ERROR!');
        GotoWindowXY (StatusWindowPtr, 1, 1);
        WriteWindow(StatusWindowPtr, temp);
        delay(1000);
        EraseWindow(EditWindowPtr);
        EraseWindow(StatusWindowPtr);
        clrscr;
        halt;
    end;
    
    fillchar(temp, sizeof(temp), ' ' ); 
    temp := concat('Reading file ', name);
    i := length(temp);
    StatusWindowPtr := MakeWindow (((80 - i) div 2), 12, i + 2, 3, 'Reading...');
    gotoWindowXY (StatusWindowPtr, 1, 1);
    WriteWindow(StatusWindowPtr, temp);

    for i := 1 to maxlines do
        if (linebuffer[i] <> emptyline) then
            linebuffer[i]^ := emptyline^;

    currentline := 1;

    while not eof (textfile) do
    begin
        if (currentline mod 100) = 0 then
            write(#13,currentline);

        if linebuffer[currentline] = emptyline then
            newbuffer(linebuffer[currentline]);

        readln(textfile, linebuffer [currentline]^);

        currentline := currentline + 1;
        if (currentline > maxlines) then
        begin
            fillchar(temp, sizeof(temp), ' ' );
            fillchar(tempint, sizeof(tempint), ' ' );
            str(maxlines, tempint);
            temp := concat('File is too long for QED. Maximum of ', tempint, ' lines.');
            i := length(temp);
            StatusWindowPtr := MakeWindow (((80 - i) div 2), 12, i + 2, 3, 'ERROR!');
            gotoWindowXY (StatusWindowPtr, 1, 1);
            WriteWindow (StatusWindowPtr, temp);
            delay(1000);
            EraseWindow (EditWindowPtr);
            EraseWindow (StatusWindowPtr);
            clrscr;
            halt;
        end;
   end;

    EraseWindow(StatusWindowPtr);
    close(textfile);

    highestline := currentline;
    currentline := 1;
    column := 1;
    screenline := 1;
    drawscreen;
 end;

procedure initialize;
var
    i: integer;
    temp: linestring;
begin
    clrscr;
    ClearAllBlinks;
    SetBlinkColors(BAKCLR, FORCLR);
    SetBlinkRate(3, 3);
    
    fillchar(temp, sizeof(temp), ' ');
    temp := concat('Quick Editor for MSX', ' - File: ', paramstr(1));
    EditWindowPtr := MakeWindow(0, 1, 80, 23, temp);
(*   
    SetBlinkColors(BAKCLR, FORCLR);
    SetBlinkRate(3, 0);
*)    
    displaykeys;
(*
* Some variables.
*)   
    currentline := 1;
    column := 1;
    screenline := 1;
    highestline := 1;
    newbuffer(emptyline);
    emptyline^ := '';
    searchstring := '';
    replacement := '';
    insertmode := false;

    for i := 1 to maxwidth do
        tabset[i]:=(i mod 8)= 1;

    for i := 1 to maxlines do
        linebuffer[i] := emptyline;
end;

procedure help;
var
    c: char;
begin
    StatusWindowPtr := MakeWindow(10, 2, 60, 20, 'Help');
    WritelnWindow(StatusWindowPtr, 'Commands:');
    WritelnWindow(StatusWindowPtr, '<BS>, <TAB>, <ENTER>, <INSERT>, <DELETE>, <arrow keys>');
    WritelnWindow(StatusWindowPtr, '<ESC>           - Terminate the program.');
    WritelnWindow(StatusWindowPtr, '<INSERT>        - Toggle insert/overwrite mode.');
    WritelnWindow(StatusWindowPtr, '<CONTROL><L>    - Search for a string.');
    WritelnWindow(StatusWindowPtr, '<SELECT>        - Search and replace.');
    WritelnWindow(StatusWindowPtr, '<CONTROL><Y>    - Delete line.');
    WritelnWindow(StatusWindowPtr, '<CONTROL><A>    - Next word.');
    WritelnWindow(StatusWindowPtr, '<CONTROL><F>    - Previous word.');
    WritelnWindow(StatusWindowPtr, '<CONTROL><Q>    - Beginning of file.');
    WritelnWindow(StatusWindowPtr, '<CONTROL><C>    - End of file.');
    WritelnWindow(StatusWindowPtr, '<CONTROL><J>    - Help.');
    c := readkey;
    EraseWindow(StatusWindowPtr);
end;

 procedure printrow;
 begin
   full_screen;
   gotoxy(60, 1);
   write('line ', currentline:4,' col ', column:2);
   edit_win;
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
            newbuffer(linebuffer[currentline]);
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

        if column = 70 then
            delay(10);
    end;
    CursorOn;
end;

procedure beginfile;
begin
    currentline := 1;
    column := 1;
    screenline := 1;
    drawscreen;
end;

procedure endfile;
begin
    currentline := highestline;
    screenline := maxlength;
    column := 1;
    drawscreen;
end;

procedure beginline;
begin
    currentline := WhereYWindow(EditWindowPtr);
    column := 1;
    screenline := WhereYWindow(EditWindowPtr);
    drawscreen;
end;


procedure funcend;
begin
    column := length (linebuffer [currentline]^) + 1;
    if column > 78 then
        column := 78;
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

    gotoxy (1, 24); clreol; write ('Currentline: ', currentline, ' Highestline: ', highestline, ' Screenline: ', screenline);

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

    gotoxy (1, 24); clreol; write ('Currentline: ', currentline, ' Highestline: ', highestline, ' Screenline: ', screenline);

end;

procedure insertline;
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

procedure return;
begin
    CursorDown;
    column := 1;
    GotoWindowXY(EditWindowPtr, column, screenline);

    if insertmode then
        insertline;
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
        funcend;
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

    full_screen;

    GotoXY(79, 1);
    if insertmode then
        write('I')
    else
        write('O');
    edit_win;
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
        newbuffer(linebuffer[currentline]);
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
        funcend;
    end;
    del;
end;

procedure terminate;
var
    i, j: integer;
    temp, number: linestring;
    c: char;
    
begin
    fillchar(temp, sizeof(temp), ' ' ); 
    temp := '(Y)es or (N)o?';
    i := length(temp);
    StatusWindowPtr := MakeWindow (((80 - i) div 2), 12, i + 2, 3, 'Write to file?');
    GotoWindowXY (StatusWindowPtr, 1, 1);
    WriteWindow(StatusWindowPtr, temp);
    c := readkey;
    EraseWindow(StatusWindowPtr);
    if upcase(c) = 'Y' then
    begin
        fillchar(temp, sizeof(temp), ' ' ); 
        temp := concat('Writing file ', paramstr (1), '...');
        i := length(temp);
        StatusWindowPtr := MakeWindow (((80 - i) div 2), 12, i + 2, 3, 'Writing...');
        GotoWindowXY (StatusWindowPtr, 1, 1);
        WriteWindow(StatusWindowPtr, temp);
        rewrite(textfile);
        for i := 1 to highestline + 1 do
        begin
            if (i mod 100) = 0 then
                write(#13, i);

            writeln(textfile, linebuffer [i]^);
        end;
        EraseWindow(StatusWindowPtr);
        fillchar(temp, sizeof(temp), ' ' ); 
        str(i, number);
        temp := concat('Lines written to file ', paramstr (1), ': ', number, '.');
        i := length(temp);
        StatusWindowPtr := MakeWindow (((80 - i) div 2), 12, i + 2, 3, 'Lines');
        GotoWindowXY (StatusWindowPtr, 1, 1);
        WriteWindow(StatusWindowPtr, temp);

        writeln(textfile,^Z);
        close(textfile);
        delay(1000);

        EraseWindow(StatusWindowPtr);
    end;
    EraseWindow(EditWindowPtr);
    clrscr;
    halt;
end;

 procedure quitnosave;
 begin
   full_screen;
   gotoxy(1, 25);
   clreol;
   gotoxy(1, 24);
   clreol;
   halt;
 end;

 procedure funcpgup;
 begin
   currentline := currentline - 20;
   if currentline <= screenline then
      beginfile
   else
      drawscreen;
 end;

 procedure funcpgdn;
 begin
   currentline := currentline + 20;
   if currentline + 12 >= highestline then
      endfile
   else
      drawscreen;
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

 procedure nextword;
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
   if column > 1 then begin
      repeat
         column := column - 1;
      until (tabset [column]= true) or (column = 1);
   end;
 end;

 procedure escape;
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

 procedure locate;
 var
   temp:               linestring;
   i,
   pointer,
   position,
   len:                integer;
 begin
   init_msgline;
   write('Locate:     Enter string: <',searchstring,'> ');
   temp := '';
   readln(temp);
   if temp <> '' then
      searchstring := temp;
   len := length (searchstring);

   if len = 0 then begin
      displaykeys;
      beginfile;
      exit;
   end;

   clrscr;
   write('Searching...  Press <ESC> to exit, <HOLD> to pause');
   edit_win;
   clrscr;

   for i := 1 to highestline do begin
   (* look for matches on this line *)
      pointer := pos (searchstring, linebuffer [i]^);

    (* if there was a match then get ready to print it *)
      if (pointer > 0) then begin
         temp := linebuffer [i]^;
         position := pointer;
         gotoxy(1, wherey);
         lowvideo;
         write(copy(temp,1,79));
         highvideo;

         (* print all of the matches on this line *)
         while pointer > 0 do begin
            gotoxy(position, wherey);
            write(copy (temp, pointer, len));
            temp := copy (temp, pointer + len + 1, 128);
            pointer := pos (searchstring, temp);
            position := position + pointer + len;
         end;

         (* go to next line and keep searching *)
         writeln;
      end;
   end;

   ShowMessage('End of locate.  Press any key to exit...');

   beginfile;
end;
 
Function WhereXOverWindow (WindowPtr: Pointer; col: byte): byte;
var
    pt              : Pointer;
    at              : integer absolute pt;

begin

    pt := WindowPtr;
    WhereXOverWindow := Mem[at] + col + 1;

end;    { WhereXOverWindow }

Function WhereYOverWindow (WindowPtr: Pointer; row: byte): byte;
var
    pt              : Pointer;
    at              : integer absolute pt;

begin

    pt := WindowPtr;
    WhereYWindow := Mem[at + 1] + row;

end;    { WhereYOverWindow }

 

procedure search;
var
    c                   : char;
    temp                : linestring;
    tempnumber          : string [5];
    i, j, pointer, len  : integer;

begin
    SetBlinkRate (5, 0);
    temp := 'String to be searched: ';
    j := length (temp);
    StatusWindowPtr := MakeWindow (1, 12, 79, 3, 'Search');
    GotoWindowXY (StatusWindowPtr, 1, 1);
    WriteWindow(StatusWindowPtr, temp);
    GotoWindowXY (StatusWindowPtr, j + 1, 1);
    temp := '';
    readln(temp);
    EraseWindow(StatusWindowPtr);

    if temp <> '' then
        searchstring := temp;
    len := length (searchstring);

    if len = 0 then
    begin
        beginfile;
        exit;
    end;

    temp := 'Searching... ';
    j := length (temp);
    GotoXY (1, 24);
    ClrEol;
    Write(temp);

    for i := currentline + 1 to highestline do
    begin
    (* look for matches on this line *)

        pointer := pos (searchstring, linebuffer [i]^);

    (* if there was a match then get ready to print it *)
        
        if (pointer > 0) then
        begin
            currentline := i;
            if currentline >= maxlength then
                screenline := maxlength
            else
                screenline := currentline;
         
            column := pointer;

            Blink(column + 1, screenline + 1, len);
            c := readkey;
            ClearBlink(column + 1, screenline + 1, len);

            exit;
        end;
    end;
    temp := 'Search string not found. Press any key to exit.';
    GotoXY (1, 24);
    ClrEol;
    Write (temp);
    c := readkey;
    ClearAllBlinks;
    SetBlinkRate (3, 3);
end;

procedure replace;
var
    temp                     : linestring;
    tempnumber               : string [5];
    i, j, position, line, replacementlength,
    searchlength             : integer;
    choice                   : char;
   
begin
    SetBlinkRate (5, 0);
    
    temp := 'Search for: ';
    j := length (temp);
    StatusWindowPtr := MakeWindow (1, 12, 79, 3, 'Replace');
    GotoWindowXY (StatusWindowPtr, 1, 1);
    WriteWindow(StatusWindowPtr, temp);
    GotoWindowXY (StatusWindowPtr, j + 1, 1);
    temp := '';
    readln(temp);
    ClrWindow(StatusWindowPtr);

    if temp <> '' then
        searchstring := temp;

    searchlength := length (searchstring);
    if searchlength = 0 then
    begin
        EraseWindow(StatusWindowPtr);
        exit;
    end;

    temp := 'Replace with: ';
    j := length (temp);
    GotoWindowXY (StatusWindowPtr, 1, 1);
    WriteWindow(StatusWindowPtr, temp);
    GotoWindowXY (StatusWindowPtr, j + 1, 1);
    temp := '';
    readln(temp);
    EraseWindow(StatusWindowPtr);

    if temp <> '' then
        replacement := temp;
    replacementlength := length (replacement);

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

            drawscreen;
            column := position;
            Blink(column + 1, screenline + 1, searchlength);

            GotoXY(1, 24);
            write('Replace (Y/N/ESC)? ');
            choice := readkey;
            ClearBlink(column + 1, screenline + 1, searchlength);

            GotoXY(1, 24);
            
            if ord (choice) = 27 then
            begin
                ClrEol;
                displaykeys;
                beginfile;
                exit;
            end;

            temp := 'Searching... Line ';
            j := length (temp);
            GotoXY (1, 24);
            ClrEol;
            Write(temp);

            if choice in ['y','Y'] then
            begin
                linebuffer[line]^ := copy (linebuffer [line]^, 1, position - 1) +
                                        replacement + copy (linebuffer [line]^, position +
                                        length (searchstring), 128);

                position := pos (searchstring, copy (linebuffer[line]^,
                            position + replacementlength + 1,128)) +  position + replacementlength;
            end
            else
                position := pos (searchstring, copy (linebuffer[line]^,
                                position + length(searchstring) + 1,128)) +
                                position + length(searchstring);

            GotoWindowXY(EditWindowPtr, 1, screenline);
            ClrEolWindow(EditWindowPtr);
            write(copy(linebuffer[currentline]^,1,79));
        end;
end;
    temp := 'End of replace.  Press any key to exit.';
    ShowMessage(temp);
    SetBlinkRate(3, 3);
 end;

procedure handlefunc(keynum: integer);
begin
    case keynum of
        BS          :   backspace;
        TAB         :   tabulate;
        ENTER       :   return;
{        27:  escape;
}
        ESC         :   terminate;
        HOME        :   beginline;
        UpArrow     :   CursorUp;
        LeftArrow   :   CursorLeft;
        RightArrow  :   CursorRight;
        DownArrow   :   CursorDown;
        INSERT      :   ins;
        DELETE      :   del;
        CONTROLL    :   search;
        SELECT      :   replace;
        CONTROLY    :   deleteline;
        CONTROLA    :   nextword;
        CONTROLF    :   prevword;
        CONTROLQ    :   beginfile;
        CONTROLC    :   endfile;
        CONTROLJ    :   help;
(*
        CONTROLK    :   begin  
                            getkey (key, iscommand);
                            if iscommand then
                                case key of
                                end;
                        end;
*)
(*
        271:  backtab;
        316:  locate;
        318:  replace;
        319:  terminate;
        320:  insertline;
        324:  quitnosave;
        327:  column := 1;
        329:  funcpgup;
        335:  funcend;
        337:  funcpgdn;
        374:  endfile;
*)

        else    delay(300);
    end;
end;

(* main *)

 var
  key : integer;
  iscommand : boolean;

 begin
    if (paramcount <> 1) then
    begin
        writeln('Usage: qedmsx FILENAME');
        halt;
    end;

    initialize;
    loadfile(paramstr (1));
    printrow;

(* main loop - get a key and process it *)

    repeat
        GotoWindowXY(EditWindowPtr, column, screenline);
        CursorOn;
        getkey (key, iscommand);
        CursorOff;
        if iscommand then
            handlefunc(key)
        else
            character(chr(key));

        printrow;

   until true = false;
 end.
