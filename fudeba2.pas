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
    tela : Array[1..192] of string[80] absolute $8000; { Page 2 }
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
for i := 4 to 5 do
begin
    PutMapperPage(Mapper, i, 2);
    fillchar(tela, sizeof(tela), ' ' );
    l := 1;
    gotoxy (1, 1); writeln(' Mapper page: ', i);
    
{ Problema aqui... O critério de parada é quando tiver 192 linhas (24 linhas x 8 telas)
* salvas. O problema é que é bem possível que a 192a linha tenha mais do que 80 colunas,
* então esse "resto" tem que ir para o próximo segmento, começando a preencher a variável
* tela do segmento seguinte... }
    
    while l < 192 do
    begin
        fillchar(temporario, sizeof(temporario), ' ' );
        readln(arq, temporario);
        gotoxy(1, 3); writeln(temporario);
        
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
        
        j := length(temporario);
        posicaoinicial := 1;

{ Se a linha tiver mais do que 80 caracteres, pára nos primeiros 80 e segue abaixo }
        
        if j >= 80 then
            posicaofinal := 80
        else
            posicaofinal := j;
            
        comprimento := (length(temporario) div 80) + 1;
        for k := 1 to comprimento do
        begin
            tela[l] := copy(temporario, posicaoinicial, posicaofinal);
    {
            delete(tela[l], posicaofinal - 2, 2);
    }
            posicaoinicial := posicaofinal + 1;
            posicaofinal   := posicaofinal * (l + 1);
            if posicaofinal > j then
                posicaofinal := j;
            l := l + 1;
        end;
    end;
end;

writeln('Salvo. Agora vamos ver a leitura.');
readln;

for j := 4 to 5 do
begin
    i := 1;
    PutMapperPage(Mapper, j, 2);

    while i <= 8 do
    begin
        clrscr2;
    
{ Funciona muito bem, mas se eu usar o fastwrite com o conteúdo das
* páginas 5 em diante, sabe-se lá pq dá ruim, fica tudo k-gado. Vou ver
* depois e vou usando writeln por enquanto. WriteVRAM seria a solução ideal,
* mas aí teria que renderizar de novo, pra outra variável. 
}
    
        for l := 1 to 24 do
        begin
            gotoxy2(1, l);
            write(tela[l + 24 * (i - 1)]);
        end;

        gotoxy2 (54, 1); writeln ('Mapper page: ', j, ' Pagina ', i);
        i := i + 1;
{
     WriteVRAM (0, $0000, addr(tela[24 * (i - 1)]), $0730);
}
        readln;
    end;
end;

close(arq);

    writeln('Fechou');
END.

