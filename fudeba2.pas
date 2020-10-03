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
    tamanhoreal = 3840;
    tabulacao = #9;
type
    ASCII = set of 0..255;

var 
    arq : text;
    Mapper: TMapperHandle;
    PointerMapperVarTable: PMapperVarTable;
    i, j, k, l, m, n, o, retorno: integer;
    posicaoinicial, posicaofinal, comprimento: byte;
    resultado, fechou: boolean;
    nomearquivo: TFileName;
    vetor : Array[1..64] of string[255] absolute $8000; { Page 2 }

{    tela: array [1..24] of string[80] absolute $C000; }  { Page 3 }

    tela: array [1..24, 1..80] of char absolute $C000;   { Page 3 }
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

Procedure ClrScr2;
Const
        ctCLS     = $00C3;  { Clear screen, including graphic modes }
Var
        regs   : TRegs;
        CSRY   : Byte Absolute $F3DC; { Current row-position of the cursor    }
        CSRX   : Byte Absolute $F3DD; { Current column-position of the cursor }
        EXPTBL : Byte Absolute $FCC1; { Slot 0 }

Begin
  regs.IX := ctCLS;
  regs.IY := EXPTBL;
  (*
   * The Z80 zero flag must be set before calling the CLS BIOS function.
   * Check the MSX BIOS specification
   *)
  Inline( $AF );            { XOR A    }

  CALSLT( regs );
  CSRX := 1;
  CSRY := 1;
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
    j := 1;
{
while not eof(arq) do
begin
}
    PutMapperPage(Mapper, i, 2);
    for l := 1 to 64 do
    begin
        fillchar(temporario, sizeof(temporario), ' ' );
        readln(arq, temporario);
        repeat
            j := Pos (tabulacao, temporario);
            if j <> 0 then 
            begin
                delete (temporario, j, 1);
                insert('    ', temporario, j);
            end;
        until j = 0; 
        vetor[l] := concat(temporario);
{
        gotoxy (1, 1); writeln('Mapper page: ', i, ' Line: ', l);
}
    end;
    i := i + 1;
{
end;
}

i := 1;

for m := 1 to 3 do
begin
    fillchar(tela, sizeof(tela), ' ' );
    l := 1;
    while l < 24 do
    begin
        j := length(vetor[i]);
        posicaoinicial := 1;
        if j >= 80 then
            posicaofinal := 80
        else
            posicaofinal := j;
        comprimento := (length(vetor[i]) div 80) + 1;
        for k := 1 to comprimento do
        begin
            fillchar(temporario, sizeof(temporario), ' ' );
            temporario := copy(vetor[i], posicaoinicial, posicaofinal);
            for n := 1 to length(temporario) do
                tela[l, n] := temporario[n];
    {
            delete(tela[l], posicaofinal - 2, 2);
    }
            posicaoinicial := posicaofinal + 1;
            posicaofinal   := posicaofinal * (l + 1);
            if posicaofinal > j then
                posicaofinal := j;
            l := l + 1;
        end;
        i := i + 1;
    end;
{    
    for l := 1 to 24 do
    begin
        gotoxy2(1, l);
        fastwriteln(tela[l]);
    end;
}
    WriteVRAM (0, $0000, addr(tela), $0730);
    readln;
    
end;


close(arq);

	writeln('Fechou');
END.

