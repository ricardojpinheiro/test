{
   lessdemo.pas
}

program lessdemo;

{$i d:types.inc}
{$i d:dos.inc}
{$i d:dos2err.inc}
{$i d:dos2file.inc}
{$i d:fastwrit.inc}
{$i d:msxbios.inc}
{$i d:extbio.inc}
{$i d:maprbase.inc}
{$i d:maprvars.inc}
{$i d:maprpage.inc}
{$i d:blink.inc}

const
    Limit = 2047;
    SizeScreen = 1839;
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

var i, j, k, l, Page, MaxBlock, FirstSegment: integer;
    ScreenBufferIndex, BufferIndex, MapperIndex: integer;
    bch: byte;
    
    MaxSize: real;
    ScreenBuffer: array [1..8,0..Limit] of char absolute $8000; { Page 2 }
    BFileHandle: byte;
    B2FileHandle: file;
    NoPrint, Print, AllChars: ASCII;
    
    Mapper: TMapperHandle;
    PointerMapperVarTable: PMapperVarTable;
    NextPage, SeekResult, CloseResult: boolean;
    BlockReadResult, Position: byte;
    NewPosition: integer;
    TextFileName: TFileName;
    Buffer: array[0..Limit] of byte absolute $C000; { Page 3 }
    EndOfPage: array[0..PagesPerSegment] of integer;
    OriginalRegister9Value: byte;
    ch: char;
    NextSegment: boolean;

    TempString: TString;
    TempTinyString: string[5];
    MaxTotalPagesPerSegment, Segment, TotalPages: integer;
    VDPSAV1: array[0..7]  of byte absolute $F3DF;
    VDPSAV2: array[8..23] of byte absolute $FFE7;
    TXTNAM : integer absolute $F3B3;
    CRTCNT : byte absolute $F3B1;

procedure ErrorCode (ExitOrNot: boolean);
var
    ErrorCodeNumber: byte;
    ErrorMessage: TMSXDOSString;
    
begin
    ErrorCodeNumber := GetLastErrorCode;
    GetErrorMessage (ErrorCodeNumber, ErrorMessage);
    WriteLn (ErrorMessage);
    if ExitOrNot = true then
        Exit;
end;

Procedure FillVRAM (VRAMaddress: Integer; NumberOfBytes: Integer;Value: Byte);
begin
    inline ($DD/$21/$6B/$01/
            $ED/$4B/NumberOfBytes/$2A/VRAMaddress/$3A/Value/$C3/_CALROM);
end;

Procedure ClrScr2;
Const
        ctCLS     = $00C3;  { Clear screen, including graphic modes }
Var
        regs   : TRegs;
        CSRY   : Byte Absolute $F3DC; { Current row-position of the cursor    }
        CSRX   : Byte Absolute $F3DD; { Current column-position of the cursor }
        EXPTBL : Byte Absolute $FCC1; { Slot 0 }

Begin
  regs.IX := ctCLS;
  regs.IY := EXPTBL;
  (*
   * The Z80 zero flag must be set before calling the CLS BIOS function.
   * Check the MSX BIOS specification
   *)
  Inline( $AF );            { XOR A    }

  CALSLT( regs );
  CSRX := 1;
  CSRY := 1;
End;

Procedure GotoXY2( nPosX, nPosY : Byte );
Var
       CSRY : Byte Absolute $F3DC; { Current row-position of the cursor    }
       CSRX : Byte Absolute $F3DD; { Current column-position of the cursor }
Begin
  CSRX := nPosX;
  CSRY := nPosY;
End;

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

procedure SetLastLine (TextFileName: TFileName; PagePerDocument, TotalPages, Line: integer);
begin

{ Faz todo o trabalho para colocar informacao na ultima linha. }
            
    fillchar(TempString, sizeof(TempString), ' ');
    TempString := concat('File: ', TextFileName, '  Page ');
    fillchar(TempTinyString, sizeof(TempTinyString), ' ');
    str(PagePerDocument, TempTinyString);
    TempString := concat(TempString, TempTinyString);
    fillchar(TempTinyString, sizeof(TempTinyString), ' ');
    str(TotalPages, TempTinyString);
    TempString := concat(TempString, ' of ', TempTinyString, ' Line ');
    str(Line, TempTinyString);
    TempString := concat(TempString, TempTinyString, ' ');
    gotoxy2(1, 24);
    fastwriteln(TempString);
    blink (1, 24, 80);
end;

BEGIN
    clrscr2;
    AllChars := [0..255];
    NoPrint := [0..31, 127, 255];
    Print := AllChars - NoPrint;
{    
    SetExtendedScreen;
}    
    writeln('Init Mapper? ', InitMapper(Mapper));
    PointerMapperVarTable := GetMapperVarTable(Mapper);
    writeln('Number of free segments: ', PointerMapperVarTable^.nFreeSegs);
    writeln('Reading services file...');
    TextFileName := 'd:\services';

{ Le arquivo 1a vez - pega o tamanho de tudo. }

    assign(B2FileHandle, TextFileName);
    reset(B2FileHandle);
    MaxSize := (FileSize(B2FileHandle) * 128);
    TotalPages := round(int(MaxSize / (SizeScreen + 1))) + 1;
    writeln('MaxSize = ', MaxSize:0:0, ' bytes.');
    writeln('TotalPages = ', TotalPages);
    close(B2FileHandle);

{ Le arquivo 2a vez - le e joga na Mapper. }

    BFileHandle := FileOpen (TextFileName, 'r');
    SeekResult := FileSeek (BFileHandle, 0, ctSeekSet, NewPosition);

{ Comeca com o segmento 4 da memoria. }

    FirstSegment := 4;
    MapperIndex := FirstSegment;
    MaxBlock := round(int(MaxSize / Limit)) + 1;
    writeln ('MaxBlock: ', MaxBlock);

{ Segmento da Mapper setado: MapperIndex marca o segmento, 2 é a página. }

{        PutMapperPage (Mapper, MapperIndex, 2);    }
        
{ Limpa a variável ScreenBuffer, q será alocada no segmento da Mapper. }        
        
        fillchar(ScreenBuffer, sizeof (ScreenBuffer), ' ' );
{        gotoxy(20, 5); writeln('Block: ', MapperIndex, ' MaxBlock + FirstSegment: ', MaxBlock + FirstSegment); }
        
{ Lê via Blockread um bloco com o tamanho da variável SizeScreen. }        
        
        for i := 1 to 8 do
        begin

{ Limpa a variável Buffer, q fará a leitura do arquivo do disco, em pedaços do tamanho
  da constante SizeScreen. }

            fillchar(Buffer, sizeof (Buffer), 0 );

{ Zera o contador das variáveis BufferIndex e ScreenBufferIndex. }
        
            BufferIndex := 0;
            ScreenBufferIndex := 0;
            
            BlockReadResult := FileBlockRead (BFileHandle, Buffer, SizeScreen);
{
            writeln('BlockReadResult:=', BlockReadResult);
            
            for j := 1 to 80 do
                write(Buffer[j], ' ');
            readln;
}
            clrscr;
            while (BufferIndex < SizeScreen) do 
            begin
                bch := Buffer[BufferIndex];
                case bch of
                    9:  begin
                            for j := ScreenBufferIndex to ScreenBufferIndex + 8 do
                                ScreenBuffer[i, j] := chr(32);
                            ScreenBufferIndex := j;
                        end;
                    13: begin
                            k := (((ScreenBufferIndex div 80) + 1) * 80) - 2;
                            for j := ScreenBufferIndex to k do
                                ScreenBuffer[i, j] := chr(32);
                            ScreenBufferIndex := j;
                        end;

                    10, 127, 255: ScreenBufferIndex := ScreenBufferIndex;
                end;

                if bch in Print then
                    ScreenBuffer[i, ScreenBufferIndex] := chr(bch);
                
                BufferIndex := BufferIndex + 1;
                ScreenBufferIndex := ScreenBufferIndex + 1;
            end;
            
            for j := 0 to SizeScreen do
                write(ScreenBuffer[i, j]);
{
             writeln('i: ', i);
}
            readln;
{
             SeekResult := FileSeek (BFileHandle, SizeScreen * i, ctSeekSet, NewPosition);
}            
        end;
        writeln;
        writeln(BufferIndex, ' ', ScreenBufferIndex);
{    PutMapperPage (Mapper, 2, 2);}

    CloseResult := FileClose(BFileHandle);
END.
