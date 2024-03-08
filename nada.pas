{
   nada.pas
   
   Copyright 2022 Ricardo Jurczyk Pinheiro <ricardojpinheiro@gmail.com>
   
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

program InitProductFile;
const
    MaxNumber0fProducts = 20;
type
    ProductName = string[20];
    Product = record
        Name: ProductName;
        ItemNumber: Integer;
        InStock: Real;
        Supplier: Integer;
end;
Var
    ProductFile: file of Product;
    ProductRec: Product;
    I: Integer;
begin
    Assign(ProductFile,'PRODUCT.DTA');
    Rewrite(ProductFile); {open the file and delete any data}
    with ProductRec do
    begin
        Name := ''; InStock := 0; Supplier := 0;
        for I := 1 to MaxNumber0fProducts do
        begin
            ItemNumber := I;
            Write(ProductFile,ProductRec);
        end;
    end;
    Close(ProductFile);
end.
