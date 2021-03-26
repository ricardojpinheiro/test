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
    i, j, k, l, m, max: integer;
    temp:               TString;
    tempstr:            string[3];
    txt:                text;

{$i d:readvram.inc}
{$i d:wrtvram.inc}

Begin
    clrscr; 

    writeln('Releasing the buffer');
    fillchar(linebuffer, sizeof(linebuffer), chr(32));
    
    writeln('Reading file...');

    writeln('Transfering information from RAM to VRAM.');
    k := $2000;
    m := $0080;

    writeln('Starts at ', k, ' with increases of ', m);

    readln;
        
    assign (txt, 'f.txt');
    reset(txt);

    i := 1;
    while not eof(txt) do
    begin
        fillchar(temp, sizeof(temp), chr(32));
        readln(txt, temp);
        j := addr(temp);
        l := sizeof(temp);
        gotoxy(1, 5); writeln (i, ' ', k, ' ', j, ' ', l);
        WriteVRAM(0, k, j, l);
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
    
    for i := 1 to max do
    begin
        fillchar(temp, sizeof(temp), chr(32));
        j := addr(temp);
        l := sizeof(temp);
        ReadVRAM(0, k, j, l);
        linebuffer[i] := temp;

        writeln(i, ' ', k, ' -> ', linebuffer[i]);

        k := k + m;
    end;
    writeln;
    writeln('Started at $2000, finished at ', k, '. It was ', max, ' lines.');
    readln;
    writeln('Finished!');
End.
