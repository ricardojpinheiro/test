{
   neca.pas
   
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

program UpDateProductFile;
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
    I, Pnr: Integer;
begin
    Assign(ProductFile,'PRODUCT.DTA'); Reset(ProductFile);
    ClrScr;
    Write('Enter product number (0= stop) '); Readln(Pnr);
    while Pnr in [1..MaxNumber0fProducts] do
    begin
        Seek(ProductFile,Pnr-1); Read(ProductFile,ProductRec);
        with ProductRec do
        begin
            Write('Enter name of product (',Name:20,') ');
            Readln(Name);
            Write('Enter number in stock (',InStock:20:0,') ');
            Readln(InStock);
            Write('Enter supplier number (',Supplier:20,') ');
            Readln(Supplier);
            ItemNumber:=Pnr;
        end;
        Seek(ProductFile,Pnr-1);
        Write(ProductFile,ProductRec);
        ClrScr;
        Writeln;
        Write('Enter product number (0= stop) '); Readln(Pnr);
    end;
    Close( ProductFile);
end.

