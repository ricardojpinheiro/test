Program TESTVRAM;

const
    maxlines = 256;
    maxcols  = 128;

type
    linestring          = string [maxcols];
    lineptr             = ^linestring; 
    TString             = string[255];

var
    linebuffer:         array [1.. maxlines] of linestring;
    i, j, k, m, max:    integer;
    temp:               TString;
    tempstr:            string[3];
    txt:                text;

{$i d:readvram.inc}
{$i d:fillvram.inc}
{$i d:wrtvram.inc}

Begin
    clrscr; 
    randomize;

    writeln('Reading file...');
    writeln;
    
    assign (txt, 'f.txt');
    reset(txt);

    i := 1;
    while not eof(txt) do
    begin
        readln(txt, linebuffer[i]);
        writeln(linebuffer[i]);
        i := i + 1;
    end;
    close(txt);
    max := i - 1;
    readln;
    
    writeln('Transfering information from RAM to VRAM.');
    k := $2000;
    m := $0080;
    
    FillVRAM(0, k, 0, m * 10);
    
    for i := 1 to max do
    begin
        WriteVRAM(0, k, addr(linebuffer[i]), sizeof(linebuffer[i]));
        k := k + m;
    end;
    readln;

    writeln('Releasing the buffer');
    fillchar(linebuffer, sizeof(linebuffer), chr(32));
    readln;
   
    writeln('Transfering information from VRAM to RAM.');
    k := $2000;
    m := $0080;
    for i := 1 to max do
    begin
        fillchar(temp, sizeof(temp), chr(32));
        ReadVRAM(0, k, addr(temp), maxcols);
        linebuffer[i] := temp;
        k := k + m;
    end;
    readln;
    
    writeln('Printing information retrieved from VRAM.');
    for i := 1 to max do
        writeln(linebuffer[i]);
    readln;
    writeln('Finished!');
    exit;
End.
