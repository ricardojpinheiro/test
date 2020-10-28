{
   mappdemo.pas
   
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

program mappdemo;

{$i d:types.inc}
{$i d:msxbios.inc}
{$i d:extbio.inc}
{$i d:maprbase.inc}
{$i d:maprvars.inc}
{$i d:maprrw.inc}
{$i d:maprallc.inc}
{$i d:maprpage.inc}

const
    Limit = 79;

var i, j, l : integer;
    StringTest: string[80] absolute $C000; { Page 3 } 
    Allright: boolean;
    buffer: array [0..Limit] of Byte absolute $8000; { Page 2 }
    Character: char;
    
    Mapper: TMapperHandle;
    PointerMapperVarTable: PMapperVarTable;
    SegmentId: byte;

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

Procedure MAPRBASE;
begin
    writeln('MAPRBASE:');
    writeln('Get Mapper Var Table...');
    PointerMapperVarTable := GetMapperVarTable(Mapper);
    writeln('Slot address of primary mapper: ', Mapper.nPriMapperSlot);
    writeln('Total segments of primary mapper: ', Mapper.nTotalMapperSegs);
    writeln('Free segments of primary mapper: ', Mapper.nFreePriMapperSegs);
    writeln('Slot id of the mapper slot: ', PointerMapperVarTable^.nSlotId);
    writeln('Total number of 16Kb RAM segments: ', PointerMapperVarTable^.nTotalSegs);
    writeln('Number of free segments: ', PointerMapperVarTable^.nFreeSegs);
    writeln('Number of allocated system segments: ', PointerMapperVarTable^.nSystemSegs);
    writeln('Number of allocated user segments: ', PointerMapperVarTable^.nUserSegs);
    writeln('Free space: ', PointerMapperVarTable^.aFreeSpace[0], PointerMapperVarTable^.aFreeSpace[1], 
        PointerMapperVarTable^.aFreeSpace[2]);
end;

Procedure MAPRALLC_and_MAPRRW;
begin
    writeln('MAPRALLC and MAPRRW:');
    writeln('Allocating segment: ', AllocMapperSegment(Mapper, Mapper.nPriMapperSlot, UserSegment, SegmentId));
    writeln('Allocated segment: ', SegmentId);

    StringTest := 'MSX r0x a lot, dudez.';
    writeln('Text: ', StringTest);
    writeln('Saving it in the Mapper segment ', SegmentId, '...');

    for i := addr(StringTest) to addr(StringTest) + sizeof(StringTest) do
        AllRight := WriteMapperSegment(Mapper, SegmentId, i, ord(StringTest[i - addr(StringTest)]));

    writeln('Writing results: ', AllRight);
    writeln('Releasing segment: ', FreeMapperSegment(Mapper, Mapper.nPriMapperSlot, SegmentId));

    StringTest := '';
    writeln('Text: ', StringTest);
    writeln('Reading it in the Mapper segment ', SegmentId, '... ');

    for i := addr(StringTest) to addr(StringTest) + sizeof(StringTest) do
        StringTest[i - addr(StringTest)] := chr(ReadMapperSegment(Mapper, SegmentId, i));
        
    writeln('Text: ', StringTest);
end;

Procedure MAPRPAGE1;
begin
    writeln('MAPRPAGE:');
    writeln('Let me see which segment is allocated to which page.');
    for i := 0 to 3 do
        writeln('Page ',i, ' is allocated to segment ', GetMapperPage(Mapper, i));
end;

Procedure MAPRPAGE2;
begin
    writeln('More MAPRPAGE:');
    writeln('Putting a specified mapper segment to page 2. Let me see...');
    j := random(Mapper.nTotalMapperSegs - 3);
    writeln('It would be segment number ', j, '. So, let''s do it!');
    PutMapperPage (Mapper, j, 2);
    writeln('Generating rubbish in the Buffer array...');
    randomize;
    for i := 0 to Limit do
        Buffer[i] := (random(85) + 41);
    writeln('Printing all the rubbish in the screen...');
    for i := 0 to Limit do
        write(chr(Buffer[i]));
    writeln('Now, we''ll change to another segment...');
    l := random(Mapper.nTotalMapperSegs - 3);
    writeln('It would be segment number ', l, '. So, let''s do it!');
    PutMapperPage (Mapper, l, 2);
    writeln('Is there anything in the Buffer array now?');
    for i := 0 to Limit do
        write(chr(Buffer[i]));
    writeln;
    writeln('Putting back segment ', j);
    PutMapperPage (Mapper, j, 2);
    writeln('Hope there is the old data from Buffer array here...');
    for i := 0 to Limit do
        write(chr(Buffer[i]));
    writeln('Let me see which segment is allocated to which page.');
    for i := 0 to 3 do
        writeln('Page ',i, ' is allocated to segment ', GetMapperPage(Mapper, i));
    writeln('Ops. It seems that I should place the right segment in the right page. ');
    writeln('So, what about placing segment 1 to page 2?');
    PutMapperPage (Mapper, 1, 2);
    writeln('Ah, much better.');
end;    

Procedure MAPRPAGE3;
begin
    writeln('Yet MAPRPAGE:');
    writeln('Now we''ll retrieve a mapper segment based on a specific address.');
    writeln('We''ll use the StringTest''s address, which is ', addr(StringTest));
    writeln('We know that it''s in the page ', GetMapperPageByAddress(Mapper, addr(StringTest)));
    Character := readkey;
end;

Procedure MAPRVARS;
begin
    writeln('MAPRVARS: ');
    writeln('Current page 0: ', CURSEGPAGE0);
    writeln('Current page 1: ', CURSEGPAGE1);
    writeln('Current page 2: ', CURSEGPAGE2);
    writeln('Current page 3: ', CURSEGPAGE3);
    writeln('Segment page 2: ', LASTSEGPAGE2);
    writeln('Segment page 0: ', LASTSEGPAGE0);
    Character := readkey;
end;

BEGIN
    Character := ' ';
    writeln('Init Mapper? ', InitMapper(Mapper));
    while (Character <> 'F') do
    begin
        clrscr;
        writeln(' Mapper routines demo program: ');
        writeln(' Choose your weapon: ');
        writeln(' 1 - MAPRBASE');
        writeln(' 2 - MAPRALLC_and_MAPRRW');
        writeln(' 3 - MAPRPAGE1');
        writeln(' 4 - MAPRPAGE2');
        writeln(' 5 - MAPRPAGE3');
        writeln(' 6 - MAPRVARS');
        writeln(' F - End.');
        Character := upcase(readkey);
        case Character of 
            '1': MAPRBASE;
            '2': MAPRALLC_and_MAPRRW; 
            '3': MAPRPAGE1;
            '4': MAPRPAGE2;
            '5': MAPRPAGE3;
            '6': MAPRVARS;
            'F': exit;
        end;
        Character := readkey;
    end;
END.

