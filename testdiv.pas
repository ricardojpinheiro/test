{
   testdiv.pas
   
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

program testdiv;

function IntegerDivision (a, b: real): integer;
begin
    IntegerDivision := round(int((a - (a - (b * (a / b)))) / b));
end;

function IntegerModulo (a, b: real): integer;
begin
    IntegerModulo := round(int(a - (b * round(int(a / b)))));
end;


BEGIN
        writeln('Divisao inteira 704000 por 16384: ', IntegerDivision(704000, 16384)); 
        writeln('Resto da divisao de 14 por 3: ', IntegerModulus(14, 3)); 
END.

