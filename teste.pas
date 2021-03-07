{
   teste.pas
   
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

program teste;

type
	str15 = string[15];

var i : integer;
    c : char;

{$i d:types.inc}
{$i d:msxbios.inc}
{$i d:conio.pas}

function msx_version:byte;
var versie:byte;
begin
  inline($3e/$80/              { LD A,&H80        }
         $21/$2d/$00/          { LD HL,&H002D     }
         $cd/$0c/$00/          { CALL &H000C      }
         $32/versie/           { LD (VERSIE),A    }
         $fb);                 { EI               }
  msx_version:=versie+1
end;

procedure SetFnKey(i: byte; st: str15);
var 
    ei, a, c: integer;
    cm: str15;

begin
  if (length(st) = 0) then
    exit;

  fillchar(cm, sizeof(cm), chr(0));

  for a:=1 to 14 do
    cm := cm + chr(0);

  st := st + cm;
  ei := $F87f + 16 * (i - 1) - 1;
  
  for a := 1 to 15 do
  begin
    c := ord(copy(st, a, 1)); 
    mem[ei + a] := c;
  end;
  
  mem[ei + a + 1] := 0;
end;

function GetFnKey(i: byte): str15;
var 
    ei, a, c: integer;
    cm: str15;

begin
    fillchar(cm, sizeof(cm), chr(0));

    for a:=1 to 14 do
        cm := cm + chr(0);
  
    ei := $F87f + 16 * (i - 1) - 1;
  
    for a := 1 to 15 do
        cm[a] := chr(mem[ei + a]);
    
    GetFnKey := cm;
end;

function pressed_function_key:byte;
var nummer:byte;
begin
  nummer:=0;
  if (mem[$fbeb] and 32)=0 then nummer:=1;
  if (mem[$fbeb] and 64)=0 then nummer:=2;
  if (mem[$fbeb] and 128)=0 then nummer:=3;
  if (mem[$fbec] and 1)=0 then nummer:=4;
  if (mem[$fbec] and 2)=0 then nummer:=5;
  if ((mem[$fbeb] and 1)=0) and (nummer<>0) then nummer:=nummer+5;
  pressed_function_key:=nummer
end;

function Readkey : char;
var
    bt: integer;
    qqc: byte absolute $FCA9;
 
begin
    readkey := chr(0);
    qqc := 1;
    Inline($f3/$fd/$2a/$c0/$fc/$DD/$21/$9F/00/$CD/$1c/00/$32/bt/$fb);
    readkey := chr(bt);
    qqc := 0;
end;


BEGIN
    writeln(GetFnKey(1));
    SetFnKey(1, chr(11) + chr(13));
    SetFnKeyStatus (true);
    writeln('MSX version: ', msx_version);
    i := -20;
    writeln ('i=',i, ' abs(i)=', abs(i));
{    
    for i := 1 to 20 do
        writeln(pressed_function_key);
       
    for i := 1 to 20 do
        writeln(ord(readkey));
}    
    c := readkey;
    if ord(c) = 11 then
    begin
        writeln('Control K');
        c := readkey;
        if ord(c) = 98 then
            writeln('B');
    end;

    c := readkey;
    case ord(c) of
        89, 121:    writeln('Y');
        90, 122:    writeln('Z');
    end;
    SetFnKeyStatus (false);

END.

