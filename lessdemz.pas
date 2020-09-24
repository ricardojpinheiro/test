{
   lessdemo.pas
}

program lessdemz;

const
    Limit = 2047;
    SizeScreen = 1839;
    LinesScreen = 23;
    PagesPerSegment = 16;
    
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
    PageIndex, ScreenBufferIndex, BufferIndex, MapperPage: integer;
    bch: byte;
    
    MaxSize: real;
    ScreenBuffer: array [1..8,0..Limit] of char absolute $8000; { Page 2 }
    B2FileHandle: file;
    TFileHandle: text;
    NoPrint, Print, AllChars: ASCII;
{    
    Mapper: TMapperHandle;
    PointerMapperVarTable: PMapperVarTable;
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
    TotalPages: integer;
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
    
    writeln('Init Mapper? ', InitMapper(Mapper));
    PointerMapperVarTable := GetMapperVarTable(Mapper);
    writeln('Number of free segments: ', PointerMapperVarTable^.nFreeSegs);
}
    TextFileName := 'd:\services';
    writeln('Reading ', TextFileName, ' file...');

{ Le arquivo 1a vez - pega o tamanho de tudo. }

    assign(B2FileHandle, TextFileName);
    reset(B2FileHandle);
    MaxSize := (FileSize(B2FileHandle) * 128);
    TotalPages := round(int(MaxSize / (SizeScreen + 1))) + 1;
    writeln('MaxSize = ', MaxSize:0:0, ' bytes.');
    writeln('TotalPages = ', TotalPages);
    close(B2FileHandle);

{ Le arquivo 2a vez. }

    assign(TFileHandle, TextFileName);
    reset(TFileHandle);
    EndOfFile := false;
    MapperPage := 4;
        
    while not EndOfFile do
    begin
        
{   Testa o fim do arquivo, seta o PageIndex em 1 e seta a página da Mapper. }
    
        EndOfFile := EOF(TFileHandle);
        PageIndex := 1;

        ScreenBufferIndex := 1;
        
        gotoxy(1, 4); writeln('MapperPage: ', MapperPage);
        
        while (PageIndex < LinesScreen) do
        begin

{   Limpa a variável buffer e lê uma linha do arquivo. }
            
            fillchar(Buffer, sizeof(Buffer), ' ' );
            readln(TFileHandle, Buffer);

            gotoxy(1, 5); writeln('PageIndex: ', PageIndex, ' Buffer: ', length(Buffer));
            gotoxy(1, 6 + PageIndex); writeln(Buffer);
            ch := readkey;
            
            BufferIndex := 1;
        
{   Agora a mágica acontece: O programa vai jogar pra variável ScreenBuffer as linhas lidas. }
        
            for BufferIndex := 1 to Length(Buffer) do 
            begin
            
                gotoxy (1, 6); writeln('BufferIndex: ', BufferIndex, ' ScreenBufferIndex: ', ScreenBufferIndex);
            
                bch := ord(Buffer[BufferIndex]);

                case bch of
                    9:  begin
                            for j := ScreenBufferIndex to ScreenBufferIndex + 8 do
                                ScreenBuffer[PageIndex, j] := chr(32);
                            ScreenBufferIndex := j;
                        end;
                    13: begin
                            for j := ScreenBufferIndex to (((ScreenBufferIndex div 80) + 1) * 80) - 2 do
                                ScreenBuffer[PageIndex, j] := chr(32);
                            ScreenBufferIndex := j;
                        end;
                    {
                    10, 127, 255: ScreenBufferIndex := ScreenBufferIndex;
                }
                end;

                if bch in Print then
                    ScreenBuffer[PageIndex, ScreenBufferIndex] := chr(bch);
                
                ScreenBufferIndex := ScreenBufferIndex + 1;
            end;
            
            PageIndex := PageIndex + 1;
        end;
        
        MapperPage := MapperPage + 1;
    end;
    
    close(TFileHandle);
END.
