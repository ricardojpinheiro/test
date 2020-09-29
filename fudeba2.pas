{
   fudeba2.pas
   
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


program fudeba2;

{$i d:memory.inc}
{$i d:types.inc}
{$i d:dos.inc}
{$i d:dos2file.inc}
{$i d:dpb.inc}

const
    tamanho = 16384;

var 
    arq: file;
    i : byte;
    inicio, fim: integer;
    retorno, j : integer;
    resultado, fechou: boolean;
    nomearquivo: TFileName;
    vetor : Array[1..tamanho] Of byte; 
(*    vetor : string[tamanho];  *)
(**)
        dpb: TDPB;
        nDrive: Byte;
    
BEGIN
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
    clrscr;

    writeln('Abriu: ');
    writeln('Filesize: ', FileSize(arq));
    writeln('Filepos: ', FilePos(arq));

    fillchar(vetor, sizeof(vetor), ' ' );

    Seek(arq, 0);
    BlockRead(arq, vetor, 8, i);
    writeln(' 1 ', resultado, '  ', i);
    for i := 0 to 512 do
        write(chr(vetor[i]));

    readln;

    fillchar(vetor, sizeof(vetor), ' ' );
    clrscr;
    Seek(arq, 1);
    BlockRead(arq, vetor, 8, i);
    writeln(' 2 ', resultado, '  ', i);
    for i := 0 to 512 do
        write(chr(vetor[i]));

    readln;

    fillchar(vetor, sizeof(vetor), ' ' );
    clrscr;
    Seek(arq, 2);
    BlockRead(arq, vetor, 8, i);
    writeln(' 3 ', resultado, '  ', i);
    for i := 0 to 512 do
        write(chr(vetor[i]));

    readln;
    
    Close(arq);
	writeln('Fechou');
	
END.

