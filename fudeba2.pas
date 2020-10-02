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

{$i d:memory.inc}
{$i d:types.inc}
{$i d:dos.inc}
{$i d:dos2file.inc}
{$i d:dpb.inc}
{$i d:msxbios.inc}
{$i d:extbio.inc}
{$i d:fastwrit.inc}
{$i d:maprbase.inc}
{$i d:maprvars.inc}
{$i d:maprpage.inc}

const
    tamanho = 1920;
    tamanhoreal = 3840;
    tabulacao = #9;
type
    ASCII = set of 0..255;

var 
    arq : text;
    Mapper: TMapperHandle;
    PointerMapperVarTable: PMapperVarTable;
    i, j, k, l, m, retorno: integer;
    resultado, fechou: boolean;
    nomearquivo: TFileName;
    vetor : Array[1..64] of string[255] absolute $8000; { Page 2 }
    temporario: string[255];
    NoPrint, Print, AllChars: ASCII;
    dpb: TDPB;
    nDrive: Byte;

Procedure GotoXY2( nPosX, nPosY : Byte );
Var
       CSRY : Byte Absolute $F3DC; { Current row-position of the cursor    }
       CSRX : Byte Absolute $F3DD; { Current column-position of the cursor }
Begin
  CSRX := nPosX;
  CSRY := nPosY;
End;
   
BEGIN
    AllChars := [0..255];
    NoPrint := [0..31, 127, 255];
    Print := AllChars - NoPrint;

    writeln('Init Mapper? ', InitMapper(Mapper));
    PointerMapperVarTable := GetMapperVarTable(Mapper);
    writeln('Number of free segments: ', PointerMapperVarTable^.nFreeSegs);
    writeln('Reading services file...');

    nomearquivo := 'd:services';
    assign(arq, nomearquivo);
    reset(arq);

    nDrive := 0;
    if (GetDPB(nDrive, dpb) = ctError ) then
    begin
        writeln('Erro ao obter o DPB');
        halt;
    end;
      
    with dpb do
    begin
        writeln('DPB: ');
        writeln('Numero do drive: ',DrvNum);
        writeln('Formato do disco: ', DiskFormat);
        writeln('Bytes por setor: ', BytesPerSector);
        writeln('Lados do disco: ', DiskSides);
        writeln('Setores por cluster: ',SectorsbyCluster);
        writeln('Setores reservados: ',ReservedSectors);
        writeln('Numero de FATs: ',FATCount);
        writeln('Entradas de diretorio: ',DirectoryEntries);
        writeln('Clusters no disco: ',DiskClusters);
        writeln('Setores por FAT: ',SectorsByFAT);
    end;

    readln;
    fillchar(vetor, sizeof(vetor), ' ' );
{    
    fillchar(tabulacao, sizeof(tabulacao), chr(32));
}
    clrscr;
    i := 4;
{
while not eof(arq) do
begin
}
    PutMapperPage(Mapper, i, 2);
    for l := 1 to 24 do
    begin
        fillchar(temporario, sizeof(temporario), ' ' );
        readln(arq, temporario);
        j := Pos (tabulacao, temporario);
        delete (temporario, j, 1);
        insert('        ', temporario, j);
        vetor[l] := concat(temporario);
{
        gotoxy (1, 1); writeln('Mapper page: ', i, ' Line: ', l);
}
    end;
    i := i + 1;
{
end;
}
for l := 1 to 24 do
begin
    gotoxy2(1, l);
    writeln(vetor[l]);
end;


close(arq);

	writeln('Fechou');
END.

