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

{$i d:conio.inc}

var i, j : integer;
    c : char;
    epa: real;
    Regs: TRegs;
    ScreenStatus: TScreenStatus;
    Vetor: array[1..15] of byte;
    
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
    randomize;

    for i := 1 to 10 do
        SetFnKey(i, 'Fudeba');

    SetFnKeyStatus (true);

    readln;

    SetFnKeyStatus (false);
    
{    
    regs.IX := ctINIFNK;
    CALSLT (regs);
}    
    writeln('MSX version: ', msx_version);

    GetScreenStatus(ScreenStatus);
    writeln('Width: ', ScreenStatus.nWidth);
    writeln('Background Color: ', ScreenStatus.nBkColor);
    writeln('Border Color: ', ScreenStatus.nBdrColor);
    writeln('Foreground Color: ', ScreenStatus.nFgColor);
    writeln('Function keys: ', ScreenStatus.bFnKeyOn);

    j := 0;
    i := -20;
    writeln ('i=',i, ' abs(i)=', abs(i));

    for i := 1 to 15 do 
        Vetor[i] := i;

    Move(Vetor[4], Vetor[10], sizeof(Vetor[4]) * 5);
    
    for i := 1 to 15 do
        writeln(i, ' ', Vetor[i]);

{
    for i := 1 to 64 do
    begin
        j := j + $0400;
        epa := epa + $0400;
        writeln(j, ' ', epa:5:0, ' ', round(int(epa)));
    end;
}
{    
    for i := 1 to 20 do
        writeln(pressed_function_key);
       
    for i := 1 to 20 do
        writeln(ord(readkey));
    
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
}
END.

