Program TESTVRAM;

Type    Pointer   = ^Byte;

{$i d:fillvram.inc}
{$i d:readvram.inc}
{$i d:wrtvram.inc}

const
    maxlines        = 1568;
    maxcols         = 80;
    startvram       = 5120;
    limitvram       = 65280;

type
    linestring      = string [maxcols];
    RStructure      = record
        VRAMBank:       byte;
        VRAMposition:   integer;
    end;
    
    str8            =   string[8];

var
    max:                integer;
    temp:               linestring;
    filename:           string[12];
    txt:                text;
    counter:            real;
    textlines:          array [1..maxlines] of RStructure;
    emptylines:         array [1..maxlines] of boolean;
    Character:          char;
    
function Readkey: char;
var
    bt: integer;
    qqc: byte absolute $FCA9;
begin
     readkey := chr(0);
     qqc := 1;
     Inline($f3/$fd/$2a/$c0/$fc/$DD/$21/$9F/00     
            /$CD/$1c/00/$32/bt/$fb);
     readkey := chr(bt);
     qqc := 0;
end;

Function WhereX: Byte;
Var
    CSRX:   Byte Absolute $f3dd;
Begin
    WhereX := CSRX;
End;

Function WhereY: Byte;
Var
    CSRY:   Byte Absolute $f3dc;
Begin
    WhereY := CSRY;
End;

function IntegerDivision (a, b: real): integer;
begin
    IntegerDivision := round(int((a - (a - (b * (a / b)))) / b));
end;

function IntegerModulo (a, b: real): integer;
begin
    IntegerModulo := round(int(a - (b * round(int(a / b)))));
end;

Function I2Hex (L: real): str8;
const
    D = 16;
var
    S : str8;
    N : integer;
    R : integer;
begin
    S := '';
    if L < 0 then
        L := (((-1 * (maxint)) + L) * -1) + 1;
    for N := 1 to sizeof(S) - 1 do
    begin
        R := IntegerModulo(L, D); { remainder }
        L := IntegerDivision(L, D); { for next dividing/digit }
        if R <= 9 then
            S := chr (R + 48) + S { 0.. 9 -> '0'..'9' (#48.. #57) }
        else
            S := chr (R + 87) + S; { 10..15 -> 'a'..'f' (#97..#102) }
    end;
    I2Hex := S; { the output in exactly 8 digits }
end; { I2Hex }

procedure InitVRAM(linenumber: integer; var counter: real);
begin
    with textlines[linenumber] do
    begin
        if linenumber = 1 then
        begin
            VRAMposition    := startvram;
            VRAMBank        := 0;
        end
        else
        begin
            VRAMposition    :=  textlines[linenumber - 1].VRAMposition + maxcols;
            VRAMBank        :=  textlines[linenumber - 1].VRAMBank;
        end;

        if counter >= limitvram then
        begin
            VRAMBank        := VRAMBank + 1;
            VRAMposition    := $0000;
            counter         := 0;
        end;
    end;
    emptylines[linenumber] := true;
end;

procedure FromRAMToVRAM(var tempstr: linestring; linenumber: integer);
begin
    with textlines[linenumber] do
        WriteVRAM(VRAMBank, VRAMposition, addr(tempstr), maxcols);
end;

procedure FromVRAMToRAM(var tempstr: linestring; linenumber: integer);
begin
    with textlines[linenumber] do
        ReadVRAM(VRAMBank, VRAMposition, addr(tempstr), maxcols);
end;

procedure initprocess;
var
    i:          integer;
    counter:    real;
begin
    clrscr;
    counter     := startvram;
    
    writeln('Erase VRAM');
    for i := 1 to maxlines do
    begin
        InitVRAM(i, counter); 
        counter := counter + maxcols;
    end;
    fillvram(0, $1400,  0, $EC00);
    fillvram(1, 0,      0, $FFFF);

    writeln('Transfer information from RAM to VRAM.');
    writeln('Starts at ', i2hex(startvram), ' with blocks of ', maxcols, ' bytes.');
end;

procedure CopyBlock(FirstLineBlock, LastLineBlock, FirstLineCopy: integer);
var
    i: integer;

begin
    for i := FirstLineBlock to LastLineBlock do
    begin
        textlines   [FirstLineCopy + i - FirstLineBlock]    := textlines[i];
        emptylines  [FirstLineCopy + i - FirstLineBlock]    := false;
    end;
end;

(*
procedure EraseBlock(FirstLineBlock, LastLineBlock, max: integer);
var
    i: integer;
begin
    i := max - FirstLineBlock;
    Move(textlines[LastLineBlock + 1], textlines[FirstLineBlock],
        sizeof(textlines[FirstLineBlock]) * i);
    for i := (max - (LastLineBlock - FirstLineBlock)) to max do 
        textlines[i].VRAMBank := 255;
end;

procedure MoveBlock(FirstLineBlock, LastLineBlock, FirstLineMove: integer; var max: integer);
begin
    CopyBlock(FirstLineBlock, LastLineBlock, FirstLineMove);
    EraseBlock(FirstLineBlock, LastLineBlock, max);
end;

procedure BlankBlock(FirstLineBlock: integer; var max: integer; TotalLines: integer);
var
    i: integer;
begin
    for i := FirstLineBlock to ((FirstLineBlock + TotalLines) - 1) do 
    begin
        textlines[i].VRAMBank       := textlines[max + TotalLines + (i - FirstLineBlock) + 1].VRAMBank;
        textlines[i].VRAMPosition   := textlines[max + TotalLines + (i - FirstLineBlock) + 1].VRAMPosition;
    end;
    max := max + TotalLines;
end;
*) 

procedure ReadFile;
var
    i, j: integer;
    
begin
    write('Reading file... Which file? Well, you tell me the name: ');
    read(filename);
       
    assign (txt, filename);
    reset(txt);

    i := 1;
    j := WhereY + 1;
    while not eof(txt) do
    begin
        gotoxy(1, j);
        writeln ('Reading line ', i, ' and saving it into VRAM.');
        fillchar(temp, sizeof(temp), chr(32));
        readln(txt, temp);
        FromRAMToVRAM(temp, i);
        emptylines[i] := false;
{
        gotoxy(1, WhereY + 1); writeln('i: ', i, ' - ', emptylines[i]);
}
        i := i + 1;
    end;
    max := i - 1;
    
    close(txt);
end;

procedure PrintText;
var
    i: integer;
begin
    for i := 1 to max do
    begin
        fillchar(temp, sizeof(temp), chr(32));
        FromVRAMToRAM(temp, i);
        writeln(i, ' -> ', temp, ' ', textlines[i].VRAMBank, ' ' , 
                        textlines[i].VRAMposition, ' ', emptylines[i]);
    end;
end;

procedure SeeVariables;
begin
    writeln('The file has ', max, ' lines.');
    writeln(' First used VRAM bank: ' , textlines[1].VRAMBank, 
    ' First used VRAM address: ' , i2hex(textlines[1].VRAMposition));
    writeln(' Last used VRAM bank: ' , textlines[max].VRAMBank, 
    ' Last used VRAM address: ' , i2hex(textlines[max].VRAMposition));
end;

function SearchForBlankBlock(BlankLines: integer): integer;
var
    i, k: integer;
    LastPosition: boolean;
begin
    i := 0;
    k := 0;
    LastPosition := true;
    while (i <= maxlines) and (k < BlankLines) do
    begin
        i := i + 1;
        if emptylines[i] = true then
            k := k + 1
        else
            k := 0;
    end;
    SearchForBlankBlock := i - BlankLines;
    writeln('BlankLines: ', BlankLines, ' BeginBlock: ', i - BlankLines,
            ' EndBlock: ', i);
end;

procedure InsertLinesIntoText(CurrentLine   : integer;
                            var TotalLines  : integer;
                                BlankLines  : integer);
var
    i, NewBeginBlock: integer;
    
begin
(*  Move o bloco de texto, até o fim, BlankLines para baixo. *)

    i := (TotalLines + 1) - CurrentLine;
    Move(textlines[CurrentLine], textlines[CurrentLine + BlankLines],
        sizeof(textlines[BlankLines]) * i);

(*  Bloqueia as linhas novas, de forma que na busca por trechos em
*   branco, elas não sejam consideradas. *)

    for i := (TotalLines + 1) to (TotalLines + BlankLines) do 
        emptylines[i] := false;

(*  Procura por blocos vazios do tamanho exato que precisamos, para 
*   redirecionar o bloco de texto na VRAM. *)

    NewBeginBlock := SearchForBlankBlock(BlankLines);

    for i := (CurrentLine + 1) to (CurrentLine + BlankLines) do 
    begin

(*  Reposiciona, na tabela de alocações, o bloco de texto da VRAM. *)

        textlines[i].VRAMBank       := textlines[NewBeginBlock + 
                                        (i - CurrentLine) + 1].VRAMBank;
        textlines[i].VRAMPosition   := textlines[NewBeginBlock + 
                                    (i - CurrentLine) + 1].VRAMPosition;
    end;

(*  Novo máximo, acrescido de BlankLines. *)

    TotalLines := TotalLines + BlankLines;

(*  Marca no vetor emptylines, que essas linhas estão bloqueadas. *)
    
    for i := (CurrentLine + 1) to TotalLines do
        emptylines[i] := false;
end;

procedure DeleteLinesFromText(CurrentLine: integer; var TotalLines: integer;
                                DeletedLines: integer); 
var
    i, NewBeginBlock: integer;
    
begin
(*  Move o bloco de texto, até o fim, DeletedLines para cima. *)

    i := TotalLines - CurrentLine;
    Move(textlines[CurrentLine + DeletedLines], textlines[CurrentLine],
        sizeof(textlines[DeletedLines]) * i);

(*  Libera as linhas novas no final, de forma que na busca por trechos em
*   branco, elas sejam consideradas. *)

    for i := (TotalLines - DeletedLines) to TotalLines do 
        emptylines[i] := true;

(*  Novo máximo, acrescido de BlankLines. *)

    TotalLines := TotalLines - DeletedLines;
end;

procedure InsertBlankLinesIntoText (var max: integer);
var
    Line, BlankLines: integer;
begin
    writeln('Now you can add some lines into the text.');
    write('Please tell me which line do you want to start: ');
    readln(Line);
    write('And now tell me how many blank lines do you want to add: ');
    readln(BlankLines);
    InsertLinesIntoText (Line, max, BlankLines);
end;

procedure RemoveLinesFromText (var max: integer);
var
    Line, DeletedLines: integer;
begin
    writeln('Here you can remove some lines from the text.');
    write('Please tell me which line do you want to start: ');
    readln(Line);
    write('And now tell me how many lines do you want to remove: ');
    readln(DeletedLines);
    DeleteLinesFromText(Line, max, DeletedLines);
end;

procedure CopyTextBlock (var max: integer);
var
    StartLine, FinishLine, DestLine: integer;
begin
    writeln('Here you can copy a text block to another place of the text.');
    write('Please tell me which line do you want to start: ');
    readln(StartLine);
    write('Now tell me the last line: ');
    readln(FinishLine);
    write('Then, where I will copy this text block (from line ', StartLine, 
            ' to ', FinishLine,'): ');
    readln(DestLine);
    writeln;
    
    InsertLinesIntoText (DestLine - 1, max, (FinishLine - StartLine) + 1);
    CopyBlock(StartLine, FinishLine, DestLine);
end;

procedure MoveTextBlock(var max: integer);
var
    i, StartLine, FinishLine, DestLine: integer;
begin
    i := 0;
    writeln('Here you can move a text block to another place of the text.');
    write('Please tell me which line do you want to start: ');
    readln(StartLine);
    write('Now tell me the last line: ');
    readln(FinishLine);
    write('Then, where I will move this text block (from line ', StartLine, 
            ' to ', FinishLine,'): ');
    readln(DestLine);
    writeln;

    InsertLinesIntoText (DestLine - 1, max, (FinishLine - StartLine) + 1);
    CopyBlock(StartLine, FinishLine, DestLine);
    DeleteLinesFromText(StartLine, max, (FinishLine - StartLine) + 1);
end;

procedure RemoveTextBlock(var max: integer);
var
    Line, DeletedLines: integer;
begin
    writeln('Now you can remove some lines into the text.');
    write('Please tell me which line do you want to start: ');
    readln(Line);
    write('And now tell me how many blank lines do you want to remove: ');
    readln(DeletedLines);
    DeleteLinesFromText(Line, max, DeletedLines);
end;

procedure InsertText;
var
    i, FirstLine, EditLines: integer;
begin
    writeln('Now you can add some words to your text.');
    write('Please tell me which line do you want to start: ');
    readln(FirstLine);
    write('And now tell me how many lines do you want to edit: ');
    readln(EditLines);
    for i := (FirstLine + 1) to (FirstLine + EditLines) do
    begin
        fillchar(temp, sizeof(temp), chr(32));
        write('Line ', i,': ');
        readln(temp);
        FromRAMToVRAM (temp, i);
        emptylines[i] := false;
    end;
end;

Begin
    while (Character  <> 'F') do
    begin
        clrscr;
        writeln(' VRAM text storage demo program:');
        writeln(' Choose your weapon: ');
        writeln(' 0 - Init VRAM and all variables.');
        writeln(' 1 - Read file, sending it to VRAM.');
        writeln(' 2 - Retrieve text from VRAM, and print it in the screen.');
        writeln(' 3 - See some variables regarding the file.');
        writeln(' 4 - Insert some blank lines in the text.');
        writeln(' 5 - Remove some lines from the text.');
        writeln(' 6 - Copy a text block to another place in the text stream.');
        writeln(' 7 - Move a text block to another place in the text stream.');
        writeln(' 8 - Erase a text block in the text stream.');
        writeln(' 9 - Insert words into the text stream.');
        writeln(' F - End.');
        Character := upcase(readkey);
        case Character of 
            '0': initprocess;
            '1': ReadFile;
            '2': PrintText;
            '3': SeeVariables; 
            '4': InsertBlankLinesIntoText(max);
            '5': RemoveLinesFromText(max);
            '6': CopyTextBlock(max);
            '7': MoveTextBlock(max);
            '8': RemoveTextBlock(max);
            '9': InsertText;
            'F': exit;
        end;
        writeln('Done!');
        repeat until keypressed;
    end;
    writeln('Finished!');
End.
