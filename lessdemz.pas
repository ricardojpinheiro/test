{
   lessdemo.pas
}

program lessdemz;

{$i d:types.inc}
{$i d:msxbios.inc}
{$i d:extbio.inc}
{$i d:maprbase.inc}
{$i d:maprvars.inc}
{$i d:maprpage.inc}

const
    Limit = 2047;
    MaxCharsPerLine = 80;
    MaxCharsPerScreen = 1840;
    MaxLinesPerScreen = 23;
    MaxPagesPerSegment = 8;
    
    WRTVDP = $0047;
    RDVRM  = $004A;
    WRTVRM = $004D;
    SETRD  = $0050;
    SETWRT = $0053;
    FILVRM = $0056;
    LDIRMV = $0059;
    LDIRVM = $005C;
    INITXT = $006C;
    SETTXT = $0078;
    NAMBAS = $F922;
    EXPTBL = $FCC1;
    
    CONTROLB    = #02;
    CONTROLE    = #05;
    CONTROLF    = #06;
    CONTROLK    = #11;
    CONTROLN    = #14;
    CONTROLP    = #16;
    CONTROLV    = #22;
    CONTROLY    = #25;
    BS          = #08;
    TAB         = #09;
    HOME        = #11;
    CLS         = #12;
    ENTER       = #13;
    INSERT      = #18;
    SELECT      = #24;
    ESC         = #27;
    RightArrow  = #28;
    LeftArrow   = #29;
    UpArrow     = #30;
    DownArrow   = #31;
    Space       = #32;
    DELETE      = #127;
    
    _CALROM: array[0..6] of byte = ($FD,$21,$00,$00,$C3,$D4,$20);
    _CALSUB: array[0..6] of byte = ($FD,$21,$00,$00,$C3,$D4,$20);   

type
    ASCII = set of 0..255;

var i, j, k, l: integer;
    LineIndex, PageIndex, ScreenBufferIndex, BufferIndex, MapperPage: integer;
    bch: byte;
    
    MaxSize: real;
    ScreenBuffer: array [1..MaxPagesPerSegment, 1..MaxCharsPerScreen] of char absolute $8000; { Page 2 }
    B2FileHandle: file;
    TFileHandle: text;
    NoPrint, Print, AllChars: ASCII;

    Mapper: TMapperHandle;
    PointerMapperVarTable: PMapperVarTable;
{
    TextFileName: TFileName;
}
    TextFileName, Buffer: string[255];
    OriginalRegister9Value: byte;
    ch: char;

    EndOfFile: boolean;

{
    TempString: TString;
    TempTinyString: string[5];
}
    TotalSegments: integer;
    VDPSAV1: array[0..7]  of byte absolute $F3DF;
    VDPSAV2: array[8..23] of byte absolute $FFE7;
    TXTNAM : integer absolute $F3B3;
    CRTCNT : byte absolute $F3B1;

function Readkey : char;
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

BEGIN
    clrscr;
    AllChars := [0..255];
    NoPrint := [0..31, 127, 255];
    Print := AllChars - NoPrint;
{    
    SetExtendedScreen;
}
    writeln('Init Mapper? ', InitMapper(Mapper));
    PointerMapperVarTable := GetMapperVarTable(Mapper);
    writeln('Number of free segments: ', PointerMapperVarTable^.nFreeSegs);
    TextFileName := 'd:\services';
    writeln('Reading ', TextFileName, ' file...');

{ Le arquivo 1a vez - pega o tamanho de tudo. }

    assign(B2FileHandle, TextFileName);
    reset(B2FileHandle);
    MaxSize := (FileSize(B2FileHandle) * 128);
    TotalSegments := round(int(MaxSize / (MaxPagesPerSegment * MaxCharsPerScreen)));
    writeln('MaxSize = ', MaxSize:0:0, ' bytes.');
    writeln('TotalSegments = ', TotalSegments);
    close(B2FileHandle);

    EndOfFile := false;
    LineIndex := 1;
    ScreenBufferIndex := 1;
    PageIndex := 1;
    BufferIndex := 1;
    MapperPage := 4;
    PutMapperPage (Mapper, MapperPage, 2);
    fillchar(ScreenBuffer, sizeof(ScreenBuffer), 32 );
    writeln('FirstSegment: ', MapperPage);
    writeln('LastSegment: ', MapperPage + TotalSegments);

{ Le arquivo 2a vez. }
    assign(TFileHandle, TextFileName);
    reset(TFileHandle);

    writeln('MapperPage: ', MapperPage);
        
    while not EndOfFile do
    begin
        
{   Testa o fim do arquivo, seta o PageIndex em 1 e seta a página da Mapper. }
    
        EndOfFile := EOF(TFileHandle);

{   Se o contador de linhas for maior do que o numero de linhas da tela... }

        If LineIndex > MaxLinesPerScreen then
        begin

{
writeln('Page: ', PageIndex);
for j := 1 to MaxCharsPerScreen do
    write(ScreenBuffer[PageIndex, j]);
    writeln;
ch := readkey;
}

{ Aumenta a contagem das paginas, reinicia o contador do ScreenBuffer e o numero de linhas. }

            PageIndex := PageIndex + 1;
            ScreenBufferIndex := 1;
            LineIndex := 1;
        end;
        
{   Se o contador de paginas for maior do que o numero de paginas por segmento... }        
        
        If PageIndex > MaxPagesPerSegment then
        begin
            MapperPage := MapperPage + 1;   { Incrementa o contador de segmentos da Mapper. }
            PageIndex := 1;                 { Reinicia o contador de paginas na Mapper }
            ScreenBufferIndex := 1;         { Reinicia o contador da variavel ScreenBuffer }
            LineIndex := 1;                 { Reinicia o contador de linhas }
            PutMapperPage (Mapper, MapperPage, 2);  { Rotina pra trocar de segmento na Mapper }
            fillchar(ScreenBuffer, sizeof(ScreenBuffer), 32 ); { Limpa a variavel ScreenBuffer }
            
            writeln('MapperPage: ', MapperPage);
            
        end;

{
gotoxy(1, 4); writeln('MapperPage: ', MapperPage);
gotoxy(1, 5); writeln('Buffer: ', length(Buffer), ' PageIndex: ', PageIndex, 
                        ' ScreenBufferIndex: ', ScreenBufferIndex, '    ');
gotoxy(1, 7); writeln(Buffer);
ch := readkey;
}

{   Limpa a variável buffer e lê uma linha do arquivo. }
            
        fillchar(Buffer, sizeof(Buffer), ' ' );
        readln(TFileHandle, Buffer);
            
{   O programa vai jogar pra variável ScreenBuffer as linhas lidas. }
        
        for BufferIndex := 1 to Length(Buffer) do
        begin
            if Buffer[BufferIndex] = #9 then
                ScreenBufferIndex := ScreenBufferIndex + 7
            else
                ScreenBuffer[PageIndex, ScreenBufferIndex] := Buffer[BufferIndex];
            ScreenBufferIndex := ScreenBufferIndex + 1;
        end;
        ScreenBufferIndex := (MaxCharsPerLine * LineIndex) + 1;
            
{
writeln('PageIndex: ', PageIndex, ' LineIndex: ', LineIndex, 
        ' BufferIndex: ', BufferIndex, ' ScreenBufferIndex: ', ScreenBufferIndex);
}
        LineIndex := LineIndex + 1;
    end;
    close(TFileHandle);
END.
