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

const
    Limit = 16383;
    
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

type
    ASCII = set of 0..255;

var i, j, k, l, MaxBlock, FirstSegment: integer;
    MaxSize: real;
    buffer: array [0..Limit] of Byte absolute $8000; { Page 2 }
    BFileHandle: byte;
    B2FileHandle: file;
    NoPrint, Print, AllChars: ASCII;
    
    Mapper: TMapperHandle;
    PointerMapperVarTable: PMapperVarTable;
    SeekResult, CloseResult, StopReadingFile: boolean;
    BlockReadResult: byte;
    NewPosition: integer;
    TextFileName: TFileName;
    ScreenBuffer: array[0..2047] of char;

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

Procedure CallBas(AC: byte; BC, DE, HL, IX: integer);
begin
    inline($F3/$CD/*+19/$FB/$32/AC/$22/HL/$43ED/BC/$53ED/DE/$1B18/
            $2ADD/IX/$3A/AC/$2A/HL/$4BED/BC/$5BED/DE/$08/$DB/$A8/$F5/
            $F0E6/$C3/$F38C);
END;

BEGIN
    clrscr;
    AllChars := [0..255];
    NoPrint := [0..31, 127, 255];
    Print := ALlChars - NoPrint;
    
    writeln('Init Mapper? ', InitMapper(Mapper));
    PointerMapperVarTable := GetMapperVarTable(Mapper);
    writeln('Number of free segments: ', PointerMapperVarTable^.nFreeSegs);
    writeln('Reading services file...');
    TextFileName := 'd:\services';

    assign(B2FileHandle, TExtFileName);
    reset(B2FileHandle);
    MaxSize := (FileSize(B2FileHandle) * 128);
    writeln('FileSize = ', MaxSize:0:0, ' bytes.');
    close(B2FileHandle);

    BFileHandle := FileOpen (TextFileName, 'r');
    SeekResult := FileSeek (BFileHandle, 0, ctSeekSet, NewPosition);

    FirstSegment := 4;
    i := FirstSegment;
    MaxBlock := round(int(MaxSize / Limit));
    writeln ('MaxBlock: ', MaxBlock);
    StopReadingFile := true;
    while (i <= (MaxBlock + FirstSegment)) do
    begin
        PutMapperPage (Mapper, i, 2);
        gotoxy(1, 6); writeln('Block: ', i, ' New Position: ', NewPosition);
        fillchar(Buffer, sizeof (Buffer), 0 );
{
        if not (FileSeek (BFileHandle, Limit, ctSeekCur, NewPosition)) then
            ErrorCode(true);
}
        BlockReadResult := FileBlockRead (BFileHandle, Buffer, Limit);
        i := i + 1;
    end;

    CloseResult := FileClose(BFileHandle);

    i := 0;
    j := $3000;
    PutMapperPage (Mapper, FirstSegment, 2);
    for l := 1 to 2 do
    begin
        k := 0;
        fillchar(ScreenBuffer, sizeof(ScreenBuffer), ' ' );
        while (k < 1920) do
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
        ScreenBuffer[73] := '-';
        ScreenBuffer[74] := '=';
        ScreenBuffer[75] := '>';
        ScreenBuffer[76] := chr(64 + l);
        ScreenBuffer[77] := '<';
        ScreenBuffer[78] := '=';
        ScreenBuffer[79] := '-';
        WriteVRAM (0, j, addr(ScreenBuffer), 1920);
        j := j - $1000;
    end;

    j := $3000;
    for l := 1 to 2 do
    begin
        TXTNAM := j; 
        CallBas (0, 0, 0, 0, SETTXT);
        readln;
        j := j - $1000;
    end;
    TXTNAM := 0;
    CallBas (0, 0, 0, 0, SETTXT);

{
*     for i := 0 to 1600 do
        write(ScreenBuffer[i]);
}    
{    
    j := FirstSegment;
    k := Limit;
    while (j <> 99) do
    begin
        writeln('Let me see... Segment number ', j);
        readln (j);
        if j = 99 then exit;
        PutMapperPage (Mapper, j, 2);
        writeln('Printing the first ', k, ' characters of Buffer...');
        for i := 1 to k do
            write(chr(Buffer[i]));
        readln;
        clrscr;
    end;
}
END.
