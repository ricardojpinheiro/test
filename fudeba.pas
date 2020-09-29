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
{$i d:fastwrit.inc}

const
    tamanho = 1840;
    tamanhoreal = 3680;

type
    ASCII = set of 0..255;

var 
    arq : byte;
    i, j, k, retorno: integer;
    resultado, fechou: boolean;
    nomearquivo: TFileName;
    vetor : Array[0..tamanho] Of byte;
    tela : Array[0..tamanhoreal] of char;
    NoPrint, Print, AllChars: ASCII;
    dpb: TDPB;
    nDrive: Byte;
    
BEGIN
    AllChars := [0..255];
    NoPrint := [0..31, 127, 255];
    Print := AllChars - NoPrint;

    nomearquivo := 'd:services';
    arq := FileOpen(nomearquivo,'r');

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

    writeln('Abriu: ',arq);
    writeln;

    fillchar(vetor, sizeof(vetor), ' ' );
    fillchar(tela, sizeof(tela), ' ' );

{
    resultado := FileSeek(arq, 0, CtSeekSet, retorno);
}
    i := FileBlockRead(arq, vetor, tamanho);
    writeln(' 1 ', resultado, '  ', i);
    i := 0;
    j := 0;
    k := 0;
    while j < 24 do
    begin
        if vetor[i] in Print then
            tela[k] := chr(vetor[i]);
        case vetor[i] of
             9:     k := k + 8;
            10:     tela[k] := chr(32);
            13:     begin
                        tela[k] := chr(32);
                        k := k + (80 - (k mod 80)) - 2;
                        j := j + 1;
                    end;
        end;
        i := i + 1;
        k := k + 1;
    end;
{
    for i := 0 to tamanho do
        write(tela[i]);
}
    readln;
    WriteVRAM (0, $0000, addr(tela), $0780);
    readln;
    
    writeln ('i: ', i, ' j: ', j, ' k: ', k);
    halt;

    fillchar(vetor, sizeof(vetor), ' ' );
    clrscr;
    resultado := FileSeek(arq, 2 * dpb.BytesPerSector, CtSeekSet, retorno);
    i := FileBlockRead(arq, vetor, tamanho);
    writeln(' 2 ', resultado, '  ', i);
    for i := 0 to tamanho do
        tela[i] := chr(vetor[i]);
{
    for i := 0 to tamanho do
        write(tela[i]);
}
    WriteVRAM (0, $0000, addr(tela), $0730);
    readln;

    fillchar(vetor, sizeof(vetor), ' ' );
    clrscr;
    resultado := FileSeek(arq, 3 * dpb.BytesPerSector, CtSeekSet, retorno);
    i := FileBlockRead(arq, vetor, tamanho);
    writeln(' 3 ', resultado, '  ', i);
    for i := 0 to tamanho do
        tela[i] := chr(vetor[i]);
{
    for i := 0 to tamanho do
        write(tela[i]);
}
    WriteVRAM (0, $0000, addr(tela), $0730);
    readln;
    
    fechou := FileClose(arq);
	writeln('Fechou');
	
END.

