{
   blktst.pas
   
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

program blktst;
{$i d:types.inc}
{$i d:dos.inc}
{$i d:fastwrit.inc}
{$i d:blink.inc}

var i : byte;
    Caminho, temporario: TFileName;
    Registros: TRegs;
    FORCLR : Byte Absolute    $F3E9; { Foreground color                        }
    BAKCLR : Byte Absolute    $F3EA; { Background color                        }
    BDRCLR : Byte Absolute    $F3EB; { Border color                            }

BEGIN
    clrscr;
    
    fillchar(Caminho, sizeof(Caminho), ' ' );
    fillchar(temporario, sizeof(temporario), ' ' );
    
    temporario[0] := 'c';
    temporario[1] := 'o';
    temporario[2] := 'l';
    temporario[3] := 'o';
    temporario[4] := 'r';
    temporario[5] := #0;
    
    Caminho[0] := 'o';
    Caminho[1] := 'f';
    Caminho[2] := 'f';
    Caminho[3] := #0;
    
    with Registros do
    begin
        B := sizeof (Caminho);
        C := ctSetEnvironmentItem;
        HL := addr (temporario);
        DE := addr (Caminho);
    end;
       
    MSXBDOS (Registros);
    
    ClearAllBlinks;
    for i := 1 to 20 do
        fastwriteln('Teste de blink Teste de blink Teste de blink Teste de blink Teste de blink');
    setblinkcolors(DBlue, White);
    setblinkrate(3, 3);
    blink(1, 10, 14);
    blink(1, 21, 2);
    for i := 0 to Length(Caminho) do
        write(Caminho[i]);
    writeln;
{
    blinkchar(3, 5);
    CursorBlink(5);
}
    delay(5000);
    clearallblinks;
    writeln(FORCLR, ' ', BAKCLR);
END.

