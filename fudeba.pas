{
   fudeba.pas
   
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


program fudeba;

var i, retorno : integer;

    Linha: string[255];
    BUffer: array [1..255] of byte;

BEGIN
    Linha := 'Isto e um teste de texto.         Teste de espaco.      Teste de tabulacao.';
    writeln(Linha);
    for i := 1 to Length(Linha) do
        Buffer[i] := ord(Linha[i]);
    readln;
    for i := 1 to Length(Linha) do
        write(chr(Buffer[i]));
    writeln;
    readln;
	
END.

