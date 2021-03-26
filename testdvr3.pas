Program TESTVRAM;

const
    maxlines = 32;
    maxcols  = 128;

type
    linestring          = string [maxcols];
    lineptr             = ^linestring; 
    TString             = string[255];

var
    linebuffer:         array [1.. maxlines] of linestring;
    i, j, k, l, m, max: integer;
    temp:               TString;
    tempstr:            string[3];
    txt:                text;

{$i d:fillvram.inc}
{$i d:readvram.inc}
{$i d:wrtvram.inc}

Begin
    clrscr; 

    k := $2000;
    m := $0080;

    writeln('Releasing the buffer');
    fillchar(linebuffer, sizeof(linebuffer), chr(32));
    
    fillvram(0, k, 0, $DFFF);
    fillvram(1, 0, 0, $FFFF);
    
    writeln('Reading file...');
    writeln('Transfering information from RAM to VRAM.');
    writeln('Starts at ', k, ' with increases of ', m);
    readln;
        
    assign (txt, 'f.txt');
    reset(txt);

    i := 1;
    j := 0;
    while not eof(txt) do
    begin
        fillchar(temp, sizeof(temp), chr(32));
        readln(txt, temp);
        gotoxy(1, 5); writeln (i, ' ', k);
        WriteVRAM(j, k, addr(temp), sizeof(temp));
        if k = $ff80 then
        begin
            j := 1;
            k := $0000;
        end
        else
            k := k + m;
        i := i + 1;
    end;
    close(txt);
    max := i - 1;
   
    writeln;
    writeln('There were ', max, ' lines.');
    readln;    
   
    writeln('Transfering information from VRAM to RAM.');
    k := $2000;
    m := $0080;
    j := 0;
    
    for i := 1 to max do
    begin
        fillchar(temp, sizeof(temp), chr(32));
        ReadVRAM(j, k, addr(temp), sizeof(temp));
        writeln(i, ' ', k, ' -> ', temp);
        if k = $ff80 then
        begin
            j := 1;
            k := $0000;
        end
        else
            k := k + m;
    end;
    writeln;
    writeln('Started at $2000, finished at ', k, '. It was ', max, ' lines.');
    readln;
    writeln('Finished!');
End.
