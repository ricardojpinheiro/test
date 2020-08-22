{
   filedemo.pas
   
   Copyright 2020 Ricardo Jurczyk Pinheiro <ricardo@aragorn>
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
   MA 02110-1301, USA.
   
   
}


program filedemo;

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
    Limit = 16383;
    SizeScreen = 1919;
    SizeTextScreen = 1839;
    
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
    
    BS      = #08;
    TAB     = #09;
    HOME    = #11;
    CLS     = #12;
    ENTER   = #13;
    INSERT  = #18;
    SELECT  = #24;
    ESC     = #27;
    RightArrow  = #28;
    LeftArrow   = #29;
    UpArrow     = #30;
    DownArrow   = #31;
    Space   = #32;
    Delete  = #127;
    
    _CALROM: array[0..6] of byte = ($FD,$21,$00,$00,$C3,$D4,$20);
    _CALSUB: array[0..6] of byte = ($FD,$21,$00,$00,$C3,$D4,$20);   

type
    ASCII = set of 0..255;

var i, j, k, l, Page, MaxBlock, FirstSegment: integer;
    MaxSize: real;
    buffer: array [0..Limit] of Byte absolute $8000; { Page 2 }
    BFileHandle: byte;
    B2FileHandle: file;
    NoPrint, Print, AllChars: ASCII;
    
    Mapper: TMapperHandle;
    PointerMapperVarTable: PMapperVarTable;
    NextPage, SeekResult, CloseResult: boolean;
    BlockReadResult, Position: byte;
    NewPosition: integer;
    TextFileName: TFileName;
    ScreenBuffer: array[0..SizeScreen] of char;
    OriginalRegister9Value: byte;
    ch, sch: char;

    TempString: TString;
    TempTinyString: string[5];
    TotalPages: integer;
    VDPSAV1: array[0..7]  of byte absolute $F3DF;
    VDPSAV2: array[8..23] of byte absolute $FFE7;
    TXTNAM : integer absolute $F3B3;

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

Function Vpeek (VRAMaddress: Integer): Byte;
begin
    inline($DD/$21/$74/$01/
           $2A/VRAMaddress/$CD/_CALROM/$6F/$26/$00/$C9);
end;

procedure Vpoke (VRAMaddress: Integer;Value: Byte);
begin
    inline($DD/$21/$77/$01/
            $2A/VRAMaddress/$3A/Value/$C3/_CALROM);
end;

Procedure CallBas(AC: byte; BC, DE, HL, IX: integer);
begin
    inline($F3/$CD/*+19/$FB/$32/AC/$22/HL/$43ED/BC/$53ED/DE/$1B18/
            $2ADD/IX/$3A/AC/$2A/HL/$4BED/BC/$5BED/DE/$08/$DB/$A8/$F5/
            $F0E6/$C3/$F38C);
END;

function GetVDP (register: byte): byte;
begin
    if register < 8 then
        GetVDP:=VDPSAV1[register]
    else
        GetVDP:=VDPSAV2[register];
end;

procedure SetExtendedScreen;
begin
    OriginalRegister9Value := getVDP(9);
    SetVDP(9, OriginalRegister9Value + 128);
    CallBas(32, $0C00, 0, 0, FILVRM);    
end;

procedure SetOriginalScreen;
begin
    TXTNAM := 0;
    CallBas (0, 0, 0, 0, INITXT);
    setVDP(9, OriginalRegister9Value);
end;

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

procedure FromRAMToVRAM (Segment, Page: byte);
begin

{ Aqui, joga da RAM pra VRAM. }
    
    i := (Page - 1) * $0730;
    PutMapperPage (Mapper, Segment, 2);
    k := 0;
    fillchar(ScreenBuffer, sizeof(ScreenBuffer), ' ' );
    while (k < $0730) do
    begin
        if (Buffer[i] in Print) then
            ScreenBuffer[k] := chr(Buffer[i])
        else
        begin
            if (chr(Buffer[i]) = #9) then
                k := k + 8;
            if (chr(Buffer[i]) = #13) then
                k := (((k div 80) + 1) * 80) - 2;
        end;
        i := i + 1;
        k := k + 1;    
    end;
    WriteVRAM (0, $0000, addr(ScreenBuffer), $0730);
end;

procedure SetLastLine (TextFileName: TFileName; Page, TotalPages, Line: integer; Mode: boolean);
var
    StrMode: string[80];
begin

{ Faz todo o trabalho para colocar informacao na ultima linha. }
            
        if Mode = true then
            StrMode := 'Modo linha'
        else
            StrMode := 'Modo pagina';

        fillchar(TempString, sizeof(TempString), ' ');
        TempString := concat('Arquivo: ', TextFileName, '  Pagina ');
        fillchar(TempTinyString, sizeof(TempTinyString), ' ');
        str(Page, TempTinyString);
        TempString := concat(TempString, TempTinyString);
        fillchar(TempTinyString, sizeof(TempTinyString), ' ');
        str(TotalPages, TempTinyString);
        TempString := concat(TempString, ' de ', TempTinyString, ' Linha ');
        str(Line, TempTinyString);
        TempString := concat(TempString, TempTinyString, ' ', StrMode, '   ');
        gotoxy2(1, 24);
        fastwriteln(TempString);
        blink (1, 24, 80);
end;

BEGIN
    clrscr;
    AllChars := [0..255];
    NoPrint := [0..31, 127, 255];
    Print := AllChars - NoPrint;
    
    writeln('Init Mapper? ', InitMapper(Mapper));
    PointerMapperVarTable := GetMapperVarTable(Mapper);
    writeln('Number of free segments: ', PointerMapperVarTable^.nFreeSegs);
    writeln('Reading services file...');
    TextFileName := 'd:\services';

{ Le arquivo 1a vez - pega o tamanho de tudo. }

    assign(B2FileHandle, TextFileName);
    reset(B2FileHandle);
    MaxSize := (FileSize(B2FileHandle) * 128);
    TotalPages := round(int(MaxSize / (SizeTextScreen + 1)));
    writeln('FileSize = ', MaxSize:0:0, ' bytes.');
    close(B2FileHandle);

{ Le arquivo 2a vez - le e joga na Mapper. }

    BFileHandle := FileOpen (TextFileName, 'r');
    SeekResult := FileSeek (BFileHandle, 0, ctSeekSet, NewPosition);

{ Comeca com o segmento 4 da memoria. }

    FirstSegment := 4;
    i := FirstSegment;
    MaxBlock := round(int(MaxSize / Limit)) + 1;
    writeln ('MaxBlock: ', MaxBlock);
    while (i <= (MaxBlock + FirstSegment)) do
    begin
        PutMapperPage (Mapper, i, 2);
        gotoxy(1, 6); writeln('Block: ', i, ' New Position: ', NewPosition);
        fillchar(Buffer, sizeof (Buffer), 0 );
        BlockReadResult := FileBlockRead (BFileHandle, Buffer, Limit);
        i := i + 1;
    end;

    CloseResult := FileClose(BFileHandle);

{ Aqui, ele mostra a pagina. Se teclar ESC, sai do programa. }

    ch := #00;
    sch := #00;
    j := FirstSegment;
    Page := 1;
    l := 1;

{ Limpa os blinks }

    ClearAllBlinks;
    SetBlinkColors(DBlue, White);
    SetBlinkRate(1, 0);
{
     SetExtendedScreen;
}    
    while ch <> ESC do
    begin
        NextPage := false;
        FromRAMToVRAM (j, Page);
        
{ Faz todo o trabalho para colocar informacao na ultima linha. }

        SetLastLine (TextFileName, Page, TotalPages, l, true);
        
        while not NextPage do
        begin
            ch := readkey;
            ClearBlink(1, l, 80);
            case ch of
                Home: Position := 1;
                Select: begin
                            SetLastLine (TextFileName, Page, TotalPages, l, false);
                            while sch <> ESC do
                            begin
                                sch := readkey;
                                case sch of
                                    UpArrow: begin
                                                Page := Page + 1;
                                                NextPage := true;
                                            end;
                                    DownArrow: begin
                                                Page := Page - 1;
                                                NextPage := true;
                                            end;
                                    Home: begin
                                            end;
                                    Delete: begin
                                            end;
                                end;
                                if Page < 1 then Page := 1;
                                if Page > TotalPages then Page := TotalPages;
                            end;
                            SetLastLine (TextFileName, Page, TotalPages, l, true);
                        end;
                UpArrow: begin
                            l := l - 1;
                            if l < 1 then l := 1;
                        end;
                DownArrow: begin
                                l := l + 1;
                                if l > 24 then 
                                begin
                                    ch := Space;
                                    l := 1;
                                end;
                            end;
                Space: begin
                            Page := Page + 1;
                            NextPage := true;
                        end;
            end;
{
            blink (1, 24, 80);
}
            blink (1, l, 80);
            SetLastLine (TextFileName, Page, TotalPages, l, true);
        end;
    end;
    SetOriginalScreen;
END.
