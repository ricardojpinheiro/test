Program TESTVRAM;

const
    maxlines        = 32;
    maxcols         = 128;
    startvram       = $2000;
    incvram         = $0080;
    maxlinesfile    = 960;

type
    linestring      = string [maxcols];
    lineptr         = ^linestring; 
    RStructure      = record
            position:   integer;
            size:       byte;
            VRAMBank:   byte;
    end;

var
    linebuffer:         array [1.. maxlines] of linestring;
    i, j, k, l, m, max: integer;
    temp:               linestring;
    tempstr:            string[3];
    txt:                text;
    structure:          array [1..maxlinesfile] of RStructure;

{$i d:fillvram.inc}
{$i d:readvram.inc}
{$i d:wrtvram.inc}

procedure initprocess;
begin
    clrscr;
    k := startvram;
    m := incvram;
    
    writeln('Releasing the buffer');
    fillchar(linebuffer, sizeof(linebuffer), chr(32));
    
    writeln('Erasing VRAM');
    fillvram(0, k, 0, $DFFF);
    fillvram(1, 0, 0, $FFFF);
    
    writeln('Erasing structure matrix');
    fillchar(structure, sizeof(structure), 0);

    writeln('Transfering information from RAM to VRAM.');
    writeln('Starts at ', k, ' with increases of ', m);
end;    

procedure SendToVRAM(tempstr: linestring; linenumber: integer);
var
    VRAMAddress:    integer;
begin
    VRAMAddress := startvram + ((linenumber - 1) * incvram);
    with structure[linenumber] do
    begin
        if VRAMAddress = $ff80 then
            VRAMBank := 1
        else
            VRAMBank := 0;
        size := incvram;
        position := VRAMAddress;
        WriteVRAM(VRAMBank, position, addr(tempstr), size);
    end;
end;

procedure RetrieveFromVRAM(var tempstr: linestring; linenumber: integer);
begin
    with structure[linenumber] do
        ReadVRAM(VRAMBank, position, addr(tempstr), size);
end;

procedure CopyBlock(FirstLineBlock, LastLineBlock, FirstLineCopy: integer);
var
    i: integer;
begin
    i := (LastLineBlock + 1) - FirstLineBlock;
    Move(structure[FirstLineBlock], structure[FirstLineCopy], 
        sizeof(structure[FirstLineBlock]) * i);
end;

procedure EraseBlock(FirstLineBlock, LastLineBlock: integer);
var
    i: integer;
begin
    for i := FirstLineBlock to LastLineBlock do
        fillchar(structure[i], sizeof(structure[i]), chr(32));
    i := maxlinesfile - FirstLineBlock;
    Move(structure[LastLineBlock + 1], structure[FirstLineBlock],
        sizeof(structure[FirstLineBlock]) * i);
end;

procedure MoveBlock(FirstLineBlock, LastLineBlock, FirstLineMove: integer);
begin
    CopyBlock(FirstLineBlock, LastLineBlock, FirstLineMove);
    EraseBlock(FirstLineBlock, LastLineBlock);
end;

Begin
    initprocess;
    
    writeln('Reading file...');
       
    assign (txt, 's.txt');
    reset(txt);

    i := 1;
    while not eof(txt) do
    begin
        fillchar(temp, sizeof(temp), chr(32));
        readln(txt, temp);
        gotoxy(1, 6); writeln ('Reading line ',i);
        SendToVRAM(temp, i);
        i := i + 1;
    end;
    close(txt);
    max := i - 1;
   
    writeln('There were ', max, ' lines.');
    readln;    
   
    writeln('Transfering information from VRAM to RAM.');
    k := $2000;
    m := $0080;
    j := 0;
    
    for i := 1 to max do
    begin
        fillchar(temp, sizeof(temp), chr(32));
        RetrieveFromVRAM(temp, i);
        writeln(i, ' ', k, ' -> ', temp);
    end;
    writeln;
    writeln('Started at $2000, finished at ', k, '. It was ', max, ' lines.');
    readln;
    writeln('Let''s copy some lines... From the 10th line to the 20th line, to the 51th line.');
    CopyBlock (10, 20, 51); 
    writeln('Let''s print all the file again');
    readln;
    for i := 1 to 61 do
    begin
        fillchar(temp, sizeof(temp), chr(32));
        RetrieveFromVRAM(temp, i);
        writeln(i, ' ', k, ' -> ', temp);
    end;
    writeln('And now I''ll remove 5 lines, from 7th to the 12th line.');
    EraseBlock(7, 12);
    writeln('Let''s print all the file again');
    readln;
    for i := 1 to 55 do
    begin
        fillchar(temp, sizeof(temp), chr(32));
        RetrieveFromVRAM(temp, i);
        writeln(i, ' ', k, ' -> ', temp);
    end;
    writeln('I''ll finishing trying to move 3 lines, from 1st to the 3rd line, to one of the last one (51th).');
    MoveBlock(1, 3, 51);
    writeln('Let''s print all the file again');
    readln;
    for i := 1 to 52 do
    begin
        fillchar(temp, sizeof(temp), chr(32));
        RetrieveFromVRAM(temp, i);
        writeln(i, ' ', k, ' -> ', temp);
    end;
    
    writeln('Finished!');
End.
