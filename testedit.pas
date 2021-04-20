Program TESTVRAM;

Type    Pointer   = ^Byte;

{$i d:fillvram.inc}
{$i d:readvram.inc}
{$i d:wrtvram.inc}
{$i d:txtwin.inc}

const
    maxlines        = 1000;
    maxcols         = 128;
    startvram       = 5120;
    limitvram       = 65280;

type
    linestring      = string [maxcols];
    RStructure      = record
        VRAMBank:       byte;
        VRAMposition:   integer;
    end;

var
    i, j, k, l, m, max: integer;
    temp:               linestring;
    txt:                text;
    counter:            real;
    structure:          array [1..maxlines] of RStructure;
    EditWindowPtr:      Pointer;

procedure InitVRAM(linenumber: integer; var counter: real);
var
    VRAMAddress:    integer;
    
begin
    with structure[linenumber] do
    begin
        if linenumber = 1 then
        begin
            VRAMposition    := startvram;
            VRAMBank        := 0;
        end
        else
        begin
            VRAMposition    :=  structure[linenumber - 1].VRAMposition + maxcols;
            VRAMBank        :=  structure[linenumber - 1].VRAMBank;
        end;

        if counter >= limitvram then
        begin
            VRAMBank        := VRAMBank + 1;
            VRAMposition    := $0000;
            counter         := 0;
        end;
    end;
end;

procedure FromRAMToVRAM(var tempstr: linestring; linenumber: integer);
begin
    with structure[linenumber] do
        WriteVRAM(VRAMBank, VRAMposition, addr(tempstr), maxcols);
end;

procedure FromVRAMToRAM(var tempstr: linestring; linenumber: integer);
begin
    with structure[linenumber] do
        ReadVRAM(VRAMBank, VRAMposition, addr(tempstr), maxcols);
end;

procedure initprocess;
var
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

    writeln('Transfer information from RAM to VRAM.');
    writeln('Starts at ', startvram, ' with blocks of ', maxcols, ' bytes.');
end;

procedure CopyBlock(FirstLineBlock, LastLineBlock, FirstLineCopy: integer);
var
    i: integer;
begin
    i := (LastLineBlock + 1) - FirstLineBlock;
    Move(structure[FirstLineBlock], structure[FirstLineCopy],
        sizeof(structure[FirstLineBlock]) * i);
end;

procedure EraseBlock(FirstLineBlock, LastLineBlock, max: integer);
var
    i: integer;
begin
    for i := FirstLineBlock to LastLineBlock do
        fillchar(structure[i], sizeof(structure[i]), chr(32));
    i := max - FirstLineBlock;
    Move(structure[LastLineBlock + 1], structure[FirstLineBlock],
        sizeof(structure[FirstLineBlock]) * i);
end;

procedure MoveBlock(FirstLineBlock, LastLineBlock, FirstLineMove, max: integer);
begin
    CopyBlock(FirstLineBlock, LastLineBlock, FirstLineMove);
    EraseBlock(FirstLineBlock, LastLineBlock, max);
end;

Begin
    initprocess;
    
    writeln('Reading file...');
       
    assign (txt, 'c.txt');
    reset(txt);

    i := 1;
    while not eof(txt) do
    begin
        fillchar(temp, sizeof(temp), chr(32));
        readln(txt, temp);
        gotoxy(1, 5); writeln ('Reading line ', i);
        FromRAMToVRAM(temp, i);
        i := i + 1;
    end;
    
    close(txt);
    max := i - 1;

    writeln;
    writeln('There were ', max, ' lines.');
    writeln('VRAM bank: '               , structure[max].VRAMBank, 
            ' Last used VRAM address: ' , structure[max].VRAMposition);
    readln;    

    writeln('Transfering information from VRAM to RAM.');
    
    for i := 1 to max do
    begin
        fillchar(temp, sizeof(temp), chr(32));
        FromVRAMToRAM(temp, i);
        writeln(i, ' -> ', temp);
    end;

    writeln('Started at '   , startvram);
    writeln('Finished at '  , structure[max].VRAMposition);
    writeln('VRAMBank: '    , structure[max].VRAMBank);
    writeln('There were '   , max, ' lines.');
    readln;
    
    EditWindowPtr := MakeWindow(0, 1, 80, 22, 'Teste');
    GotoWindowXY(EditWindowPtr, 1, 2);
    WritelnWindow(EditWindowPtr, 'Transfering information from VRAM to RAM... Now into a window!');
    
    for i := 1 to 20 do
    begin
        fillchar(temp, sizeof(temp), chr(32));
        FromVRAMToRAM(temp, i);
        WritelnWindow(EditWindowPtr, temp);
    end;

    readln;

    EraseWindow(EditWindowPtr);
    
    
{
    writeln('And now I''ll remove 5 lines, from 7th to the 12th line.');
    EraseBlock(7, 12, max);
    writeln('Let''s print all the file again');
    readln;
    for i := 1 to 44 do
    begin
        fillchar(temp, sizeof(temp), chr(32));
        RetrieveFromVRAM(temp, i);
        writeln(i, ' -> ', temp);
    end;
    
    writeln('Let''s copy some lines... From the 10th line to the 20th line, to the 44th line.');
    CopyBlock (10, 20, 44); 
    writeln('Let''s print all the file again');
    readln;
    for i := 1 to 54 do
    begin
        fillchar(temp, sizeof(temp), chr(32));
        RetrieveFromVRAM(temp, i);
        writeln(i, ' -> ', temp);
    end;
    writeln('I''ll finish moving 3 lines, from 1st to the 3rd line, to one of the last one (54th).');
    MoveBlock(1, 3, 54, max);
    writeln('Let''s print all the file again');
    readln;
    for i := 1 to 56 do
    begin
        fillchar(temp, sizeof(temp), chr(32));
        RetrieveFromVRAM(temp, i);
        writeln(i, ' -> ', temp);
    end;
}
    writeln('Finished!');
End.
