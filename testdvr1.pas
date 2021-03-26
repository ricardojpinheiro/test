Program TESTVRAM;

const
    maxlines = 224;
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
        
    assign (txt, 'f.txt');
    reset(txt);

    i := 1;
    while not eof(txt) do
    begin
        readln(txt, linebuffer[i]);
        i := i + 1;
    end;
    close(txt);
    max := i - 1;
    readln;
    
    writeln('Transfering information from RAM to VRAM.');
    k := $2000;
    m := $0080;
    
    for i := 1 to 192 do
    begin
        gotoxy (1, 4); write('->', i,' ', k, ' ', max);
        WriteVRAM(0, k, addr(linebuffer[i]), sizeof(linebuffer[i]));
        k := k + m;
    end;

    k := $8080;
    m := $0080;
    
    for i := 193 to max do
    begin
        gotoxy (1, 4); write('-->', i,' ', k, ' ', max);
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
    
    for i := 1 to 192 do
    begin
        gotoxy (1, 8); write('->', i,' ', k, ' ', max);
        ReadVRAM(0, k, addr(linebuffer[i]), sizeof(linebuffer[i]));
        k := k + m;
    end;

    k := $8080;
    m := $0080;
    
    for i := 193 to max do
    begin
        gotoxy (1, 8); write('-->', i,' ', k, ' ', max);
        ReadVRAM(0, k, addr(linebuffer[i]), sizeof(linebuffer[i]));
        k := k + m;
    end;
    
    writeln;
    writeln('Started at $2000, finished at ', k, '. It was ', max, ' lines.');
    readln;
    
    writeln('Printing information retrieved from VRAM.');
    for i := 1 to max do
        writeln(i, ' -> ', linebuffer[i]);
    readln;
    writeln('Finished!');
    exit;
End.
