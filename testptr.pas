{
   testptr.pas
   
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


program testptr;

var p : ^integer;
    i, e : integer;

procedure testa_ptr;
begin
  if p = nil then
    writeln('Ponteiro nulo.')
  else
    writeln('Ponteiro referenciado.');
end;

begin
  p := nil;
  testa_ptr;
  new(p);
  testa_ptr;
  p^ := 4;
  writeln('Valor em p: ', p^);
  writeln('Endereco da variavel i: ', addr(i));
  writeln('Endereco do ponteiro p: ', addr(p));

  i := 5;
  e := addr(i);
  p := ptr(e);
  writeln('Endereco da variavel i: ', e);
  writeln('Valor de endereco apontado por p: ', p^);
end.

