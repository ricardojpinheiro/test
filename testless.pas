Program TESTVRAM;

const
    maxlines        = 4000;
    maxcols         = 128;
    startvram       = 8192;
    limitvram       = 65024;

type
    linestring      = string [maxcols];
    lineptr         = ^linestring; 
    RStructure      = record
            VRAMBank:   byte;
            position:   integer;
            size:       integer;
    end;

var
    linebuffer:         array [1.. maxcols] of linestring;
    i, j, k, l, m, max: integer;
    temp:               linestring;
    tempstr:            string[3];
    txt:                text;
    counter:            real;
    EndOfRead:          boolean;
    structure:          array [1..maxlines] of RStructure;

{$i d:fillvram.inc}
{$i d:readvram.inc}
{$i d:wrtvram.inc}

procedure initprocess;
begin
    clrscr;
    counter     := startvram;
    EndOfRead   := false;
    
    writeln('Releasing the buffer');
    fillchar(linebuffer, sizeof(linebuffer), chr(32));
    
    writeln('Erasing VRAM');
    fillvram(0, startvram   , 0, $DFFF);
    fillvram(1, 0           , 0, $FFFF);
    
    writeln('Erasing structure matrix');
    fillchar(structure  , sizeof(structure) , 0);

    writeln('Transfering information from RAM to VRAM.');
    writeln('Starts at ', startvram, ' with variable increases.');
end;    

procedure SendToVRAM(tempstr: linestring; linenumber: integer; var counter: real);
var
    VRAMAddress:    integer;

begin
    with structure[linenumber] do
    begin
        if linenumber = 1 then
        begin
            position := startvram;
            VRAMBank := 0;
        end
        else
        begin
            position :=     structure[linenumber - 1].position +
                            structure[linenumber - 1].size;
            VRAMBank :=     structure[linenumber - 1].VRAMBank;
        end;

        size         :=     length(tempstr) + 1;

        if counter >= limitvram then
        begin
            VRAMBank    := VRAMBank + 1;
            position    := $0000;
            counter     := 0;
        end;

        if VRAMBank < 2 then
            WriteVRAM(VRAMBank, position, addr(tempstr), size)
        else
            EndOfRead := true;    
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
       
    assign (txt, 'b.txt');
    reset(txt);

    i := 1;
    while not EndOfRead do
    begin
        EndOfRead := eof(txt);
        fillchar(temp, sizeof(temp), chr(32));
        readln(txt, temp);
        gotoxy(1, 6); writeln ('Reading line ', i);
        counter := counter + length(temp) + 1;
        SendToVRAM(temp, i, counter);
        i := i + 1;
    end;
    
    close(txt);
    max := i - 1;

    writeln;
    writeln('There were ', max, ' lines.');
    writeln('VRAM bank: '               , structure[max].VRAMBank, 
            ' Last used VRAM address: ' , structure[max].position);
    readln;    

    writeln('Transfering information from VRAM to RAM.');
    
    for i := 1 to max do
    begin
        fillchar(temp, sizeof(temp), chr(32));
        RetrieveFromVRAM(temp, i);
        writeln(i, ' -> ', temp);
    end;

    writeln('Started at '   , startvram);
    writeln('Finished at '  , structure[max].position);
    writeln('VRAMBank: '    , structure[max].VRAMBank);
    writeln('There were '   , max, ' lines.');
    readln;

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

    writeln('Finished!');
End.
