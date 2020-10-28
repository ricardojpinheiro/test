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
{$i d:maprallc.inc}
{$i d:maprrw.inc}

const
    tabulacao = #9;

type
    ASCII = set of 0..255;

var 
    arq : text;
    Mapper: TMapperHandle;
    PointerMapperVarTable: PMapperVarTable;
    i, j: byte;
    k, l, m, n, o, retorno: integer;
    posicaoinicial, posicaofinal, comprimento: byte;
    AllRight, resultado, fechou: boolean;
    nomearquivo: TFileName;
    buffer : Array[1..192,1..80] of char absolute $8000; { Page 2 }
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
{    
    fillchar(tabulacao, sizeof(tabulacao), chr(32));
}
    clrscr;
    i := 4;
    j := 1;
{
    while not eof(arq) do
    begin
        i := 4;
    }
    for i := 4 to 4 do
    begin
        fillchar(buffer, sizeof(buffer), ' ' );
        l := 1;
        o := 1;
        gotoxy (1, 1); writeln('Mapper page: ', i);
    
{ Problema aqui... O critério de parada é quando tiver 192 linhas (24 linhas x 8 buffers)
* salvas. O problema é que é bem possível que a 192a linha tenha mais do que 80 colunas,
* então esse "resto" tem que ir para o próximo segmento, começando a preencher a variável
* buffer do segmento seguinte... }

        writeln('Allocating segment: ', AllocMapperSegment(Mapper, Mapper.nPriMapperSlot, UserSegment, i));
        writeln('Allocated segment: ', i);
    
        while l <= 3 do
        begin
            fillchar(temporario, sizeof(temporario), ' ' );
            readln(arq, temporario);
        
{ Tem q verificar se ele tá identificando apenas uma tabulação. Tem que ser capaz
* de identificar mais de uma. }
        
            repeat
                j := pos (tabulacao, temporario);
                if j <> 0 then 
                begin
                    delete (temporario, j, 1);
                    insert('    ', temporario, j);
                end;
            until j = 0;
            
            for m := o to o + length(temporario) do
                AllRight := WriteMapperSegment(Mapper, i, m, ord(temporario[m]));
            writeln(temporario, ' -> ', o, ' - ', o + length(temporario));
            l := l + 1;
            o := o + length(temporario);
        end;
        writeln('Writing results: ', AllRight);
        writeln('Releasing segment: ', FreeMapperSegment(Mapper, Mapper.nPriMapperSlot, i));            
    end;

writeln('Salvo. Agora vamos ver a leitura.');
readln;

    for j := 4 to 4 do
    begin
        i := 1;
        o := 1;
        while i <= 3 do
        begin
            fillchar(temporario, sizeof(temporario), ' ' );
            for m := o to o + length(temporario) do
                    temporario[m] := chr(ReadMapperSegment(Mapper, j, m));
            writeln(temporario, ' -> ', o, ' - ', o + length(temporario));
            i := i + 1;
            o := o + length(temporario);
        end;
        readln;
    end;

close(arq);

	writeln('Fechou');
END.

