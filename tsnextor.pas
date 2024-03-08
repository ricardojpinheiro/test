{
   tsnextor.pas
   
   Copyright 2024 Ricardo Jurczyk Pinheiro <ricardojpinheiro@gmail.com>
   
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

program untitled;
{$i d:types.pas}
{$i d:msxdos.pas}
{$i d:msxdos2.pas}

const
    ctFOUT      = $71;
    ctZSTROUT   = $72;
    ctRDDRV     = $73;
    ctWRDRV     = $74;
    ctRALLOC    = $75;
    ctDSPACE    = $76;
    ctLOCK      = $77;
    ctGDRVR     = $78;
    ctGDLI      = $79;
    ctGPART     = $7A;
    ctCDRVR     = $7B;
    ctMAPDRV    = $7C;
    ctZ80MODE   = $7D;
    ctGETCLUS   = $7E;

    ctGetFastStroutMode     =   $00;
    ctSetFastStroutMode     =   $01;
    ctDisableFastStroutMode =   $00;
    ctEnableFastStroutMode  =   $01;
    ctGetFreeSpace          =   $00;
    ctGetTotalSpace         =   $01;
    ctGetLockStatus         =   $00;
    ctSetLockStatus         =   $01;
    ctLockDrive             =   $FF;
    ctUnlockDrive           =   $00;

    ctICLUS = $B0; (* Invalid cluster number or sequence. *)
    ctBFSZ  = $B1; (* Bad file size. *)
    ctFMNT  = $B2; (* File is mounted. *)
    ctPUSED = $B3; (* Partition is already in use. *)
    ctIPART = $B4; (* Invalid partition number. *)
    ctIDEVL = $B5; (* Invalid device or LUN. *)
    ctIDRVR = $B6; (* Invalid device driver. *)
    
type
    String8 = String[8];
    BinNumber = array [0..31] of byte;

var
    MSXDOSVersao: TMSXDOSVersion;
    regs: TRegs;
    i, j, k: byte;
    Bin1, Bin2, BinaryNumber: BinNumber;
    HL, DE: integer;

procedure dec2bin(x : integer);
begin
    (* general case *)
    if (x > 1) then dec2bin(x div 2);

    (* to print the result *)
    if (x mod 2 = 0) then write('0')
    else write('1');
end;

procedure Decimal2Binary(x: longint; var Binary: BinNumber);
var
    i: byte;
begin
    i := 0;
    FillChar(Binary, sizeof(Binary), 0);
    repeat
        if (x mod 2 = 0) then
            Binary[i] := 0
        else
            Binary[i] := 1;
        x := x div 2;
        i := i + 1;
    until x = 0;
end;

function Power (a, b: integer): integer;
var
    i, j: byte;
begin
    j := 1;
    for i := 1 to b do
        j := j * a;
    Power := j;
end;

function Binary2Decimal(Binary: BinNumber):integer;
var
    i: byte;
    x: integer;
begin
    i := 0;
    x := 0;
    for i := 15 downto 0 do
        x := x + Binary[i] * Power(2, i);
    Binary2Decimal := x;
end;

(*  Finds the last occurence of a char which is different into a string. *)

Function RUnlikePos(Character: char; Phrase: TString): integer;
var
    Found: boolean;
    i: byte;
    
begin
    i := length(Phrase);
    Found := false;

    repeat
        if Phrase[i] <> Character then
        begin
            RUnlikePos := i;
            Found := true;
        end;
        i := i - 1;
    until Found or (i <= 1);

    if Not Found then RUnlikePos := 0;
end;

procedure FOUTExample;
begin
    for i := 1 to 10 do
        writeln('writeln sem FOUT.');
    
    readln;
    
    FillChar( regs, SizeOf( regs ), 0 );
    regs.A := ctSetFastStroutMode;
    regs.C := ctFOUT;
    MSXBDOS (regs);

    for i := 1 to 10 do
        writeln('writeln com FOUT.');
    
    writeln('regs.A = ', regs.A);
    writeln('regs.B = ', regs.B);
end;

procedure ZSTROUTExample;
var
    linha: string[40] absolute $D000;

begin
    FillChar( regs, SizeOf( regs ), 0 );
{
    regs.A := ctSetFastStroutMode;
    regs.C := ctFOUT;
    MSXBDOS (regs);
}    
    FillChar( regs, SizeOf( regs ), 0 );
    regs.C  := ctZSTROUT;
    regs.DE := $D001;
    linha := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ.0123456789';
    
    MSXBDOS (regs);
    writeln;
    writeln('regs.A = ', regs.A);   
end;

procedure RALLOCExample;
begin
    FillChar( regs, SizeOf( regs ), 0 );
    
    (* ctRALLOC. *)
    regs.C  := ctRALLOC;
    
    (* set vector. *)
    regs.A  := 1;
    (* get current vector if regs.A := 0 *)
    
    (* new vector (only if A=01H) *)
    regs.HL := 255;
    
    MSXBDOS (regs);
end;

procedure DSPACEExample;
var
    temp1, temp2, totalbytes, freebytes: real;
    driveletter: byte;
    
begin
    FillChar( regs, SizeOf( regs ), 0 );

    (* ctDSPACE. *)
    regs.C := ctDSPACE;

    (* get free space. *)
    regs.A := ctGetFreeSpace;
    
    (* drive number (0 = default, 1 = A:, etc) *)
    regs.E := 2;
    driveletter := regs.E;
    
    MSXBDOS (regs);

    if regs.DE < 0 then
        temp1 := -1 * regs.DE;
    
    if regs.HL < 0 then
        temp2 := -1 * regs.HL;

    temp1 := 65536 - temp1;
    temp2 := 65536 * temp2;
    freebytes := temp2 + temp1;

    writeln ('regs.A (Error code): ', regs.A,  ' Free Space on drive ', 
                     chr(64 + driveletter), ': ', freebytes:0:0, ' Kb');

    writeln ('Extra free space in bytes: ', regs.BC);

    FillChar( regs, SizeOf( regs ), 0 );

    (* ctDSPACE. *)
    regs.C := ctDSPACE;

    (* get total space. *)
    regs.A := ctGetTotalSpace;
    
    (* drive number (0 = default, 1 = A:, etc) *)
    regs.E := 2;
    driveletter := regs.E;
    
    MSXBDOS (regs);

    if regs.DE < 0 then
        temp1 := -1 * regs.DE;
    
    if regs.HL < 0 then
        temp2 := -1 * regs.HL;

    temp1 := 65536 - temp1;
    temp2 := 65536 * temp2;
    totalbytes := temp1 + temp2; 
    
    writeln ('regs.A (Error code): ', regs.A, ' Total Space on drive ', 
                    chr(64 + driveletter), ': ', totalbytes:0:0, ' Kb');

    writeln ('Extra free space in bytes: ', regs.BC);
end;

procedure LockExample;
begin
    FillChar( regs, SizeOf( regs ), 0 );
    regs.C := ctLOCK;
    regs.E := 0; (* Drive A.*)
    regs.A := ctGetLockStatus;
    MSXBDOS ( regs );
    writeln (' Lock Status of drive A: ', regs.B);

    FillChar( regs, SizeOf( regs ), 0 );
    regs.C := ctLOCK;
    regs.E := 0; (* Drive A.*)
    regs.A := ctLockDrive;
    MSXBDOS ( regs );
    writeln (' Locked Drive.');

    FillChar( regs, SizeOf( regs ), 0 );
    regs.C := ctLOCK;
    regs.E := 0; (* Drive A.*)
    regs.A := ctSetLockStatus;
    MSXBDOS ( regs );
    writeln (' Lock Status of drive A: ', regs.B);

    FillChar( regs, SizeOf( regs ), 0 );
    regs.C := ctLOCK;
    regs.E := 0; (* Drive A.*)
    regs.A := ctUnlockDrive;
    MSXBDOS ( regs );
    writeln (' Unlocked Drive.');
end;

procedure GDRVRExample;
var
    DRVNotFound: byte;
    Data: byte absolute $D000;
    DeviceDriverName, temp: string[32];
begin
    i := 1;
    DRVNotFound := 0;
    
    while (DRVNotFound <> ctIDRVR) or (i < 8) do
    begin
        FillChar( regs, SizeOf( regs ), 0 );
        FillChar( Data, SizeOf( Data ), 0 );
        FillChar( DeviceDriverName, SizeOf( DeviceDriverName ), chr(32) );
        for j := 0 to 7 do
            Mem[$D000 + j] := $00;
        
        (* ctGDRVR. *)
        regs.C  := ctGDRVR;
        
        (* Driver index, or 0 to specify slot and segment *)
        regs.A  := i; 
        
        (* Pointer to 64 byte data buffer *)
        regs.HL := $D000;
{
        regs.D := $01; (* Driver slot number.       *)
        regs.E := $FF; (* Driver segment number.    *)
}   
        MSXBDOS ( regs );
        DRVNotFound := regs.A;

        if DRVNotFound <> ctIDRVR then
        begin
            writeln ('Device Driver: ', i, ' Error: ', regs.A);
            write   (' Data: ');
            for j := 0 to 7 do
            begin
                dec2bin(Mem[$D000 + j]);
                write(' ');
            end;
            
            writeln;
            writeln (   'Slot number: ' ,       Mem[$D000 + 0], 
                        ' Segment number: ' ,   Mem[$D000 + 1]);
            writeln (   'How many drive letters are assigned to this driver: ', 
                                                Mem[$D000 + 2],
                        ' First drive letter: ',
                                                chr(65 + Mem[$D000 + 3]));
            
            Decimal2Binary(Mem[$D000 + 4], BinaryNumber);
            if BinaryNumber[7] = 1 then
                writeln ( ' Nextor driver.')
            else
                writeln ( ' MSX-DOS driver.');

            if BinaryNumber[2] = 1 then
                writeln ( ' Driver contains DRV_CONFIG routine. ')
            else
                writeln ( ' Driver doesn''t contains DRV_CONFIG routine. ');
                
            if BinaryNumber[0] = 1 then
                writeln ( ' Device based driver. ')
            else
                writeln ( ' Driver based driver. ');
            
            for j := 8 to 40 do
                DeviceDriverName[j - 7] := chr((Mem[$D000 + j]));
            write('Driver name: ', DeviceDriverName);
            write('v. ',    Mem[$D000 + 5], '.', Mem[$D000 + 6], '.', 
                            Mem[$D000 + 7]);
            
            writeln;
            readln;
        end;

        i := i + 1;
    end;
    
end;

procedure GDLIExample;
var
    ErrorCode, DriveLetter: byte;
    Data: byte absolute $D000;
begin
        FillChar( regs, SizeOf( regs ), 0 );
        FillChar( Data, SizeOf( Data ), chr(32) );
        
        (* ctGDLI. *)
        regs.C  := ctGDLI;
        
        (* physical drive (0=A:, 1=B:, etc) *)
        regs.A  := 1; 
        DriveLetter := regs.A;
        
        (* Pointer to 64 byte data buffer *)
        regs.HL := $D000;
   
        MSXBDOS ( regs );
        
        (* ErrorCode - returned from function. *)
        ErrorCode := regs.A;
        
        writeln ('Drive: ', chr(64 + DriveLetter), ' Error: ', regs.A);

        case Mem[$D000] of
            0: writeln ('Unassigned.'); 
            1: writeln ('Assigned to a storage device attached to a Nextor or MSX-DOS driver.');
            2: writeln ('Unused.');
            3: writeln ('A file is mounted in the drive.');
            4: writeln ('Assigned to the RAM disk.');
        end;

        writeln('Slot number: ', Mem[$D000 + 1]);
        
        if Mem[$D000 + 2] = 255 then
            writeln( 'Segment - The driver is embedded within a Nextor or MSX-DOS kernel ROM.')
        else
            writeln( 'Segment: ', Mem[$D000 + 2]);
            
        if Mem[$D000 + 3] = 255 then
            writeln ( 'Relative drive number - It''s a device-based driver.')
        else
            writeln ( 'Relative drive number within the driver: ', Mem[$D000 + 3]);

        if Mem[$D000 + 4] = 0 then
            writeln ( 'Device index - It''s a drive-based driver, or a MSX-DOS driver.')
        else
            writeln ( 'Device index: ', Mem[$D000 + 4]);
        
        if Mem[$D000 + 5] = 0 then
            writeln ( 'Logical unit index - It''s a drive-based driver, or a MSX-DOS driver.')
        else
            writeln ( 'Logical unit index: ', Mem[$D000 + 5]);

        if Mem[$D000 + 6] = 0 then
            writeln ( 'First device sector number - It''s a drive-based driver, or a MSX-DOS driver.')
        else
            writeln ( 'First device sector number: ', Mem[$D000 + 6], ' ', 
                        Mem[$D000 + 7], ' ', Mem[$D000 + 8], ' ', Mem[$D000 + 9]);
    
        writeln;
end;

procedure GPARTExample;
var
    slot, segment: byte;
    i, j: byte;

begin
    FillChar( regs, SizeOf( regs ), 0 );
    
    (* ctGPART. *)
    regs.C := ctGPART;
    
    (* Slot 1. *)
    regs.A := 1;
    
    (* Segment number. 255 for drivers in ROM. *)
    regs.B := 255;
    
    (* Device 1. *)
    regs.D := 1;
    
    (* LUN 1. *)
    regs.E := 1;
    
    (* Get info from partition. *)
    regs.H := 2;
    regs.L := 4; 

    writeln (' Slot ', regs.A, ' Device ', regs.D, ' LUN ', regs.E, '. ');

    MSXBDOS ( regs );

    case regs.A of
        ctIDRVR: writeln(' Invalid device driver.');
        ctIDEVL: writeln(' Invalid device or LUN.');
        ctIPART: writeln(' Invalid partition number.');
        ctPUSED: writeln(' Partition is already in use.');
        ctFMNT:  writeln(' File is mounted. ');
        ctBFSZ:  writeln(' Bad file size. ');
        ctICLUS: writeln(' Invalid cluster number or sequence. ');
        else writeln('Error: ', regs.A);
    end;
    
    if regs.L = 0 then 
        writeln (' Primary partition.')
    else
        writeln (' Logic partition.');

    write ('Filesystem: ');
    case regs.B of
        0:  write (' Partition doesn''t exist.');
        1:  write (' FAT12.');
        4:  write (' FAT16 less than 32 Mb.');
        5:  write (' Extended.');
        6:  write (' FAT16 (CHS).');
        14: write (' FAT16 (LBA).');
        else write (' Who cares?');
    end;

    writeln(' Partition status: ', regs.C); 
    writeln(' Starting device absolute sector number of the partition: ', 
                                                regs.HL, ' ', regs.DE);
    writeln(' Partition size in sectors: ', regs.IX, ' ', regs.IY);

    HL := regs.HL;
    DE := regs.DE;
end;

procedure MAPDRVExample;
type 
    Estrutura = record
        Slot, Segment, Device, LUN: byte;
        DE, HL: integer;
    end;
var
    aParms: Estrutura absolute $D000;
    
begin
    FillChar( regs, SizeOf( regs ), 0 );
    
    (* ctMAPDRV. *)
    regs.C  := ctMAPDRV;
    
    (* Physical drive B. *)
    regs.A  := 1;
    
    (* Action. Map the drive by using specific mapping data. *)
    regs.B  := 2;
    
    (* Address of a 8 byte buffer with mapping data. *)
    regs.HL := $D000;
    
    (* File mount type. *)
    regs.D := 0;

    writeln ( 'HL: ', HL, ' DE: ', DE);

    (* Driver slot number. *)
    aParms.Slot := 1;
    
    (* Driver segment number. *)
    aParms.Segment := 255;
    
    (* Device number. *)
    aParms.Device := 1;
    
    (* Logical unit number. *)
    aParms.LUN := 1;
    
    (* Starting sector. *)
    aParms.DE := DE;
    aParms.HL := HL;

    MSXBDOS ( regs );

    case regs.A of
        ctIDRVR: writeln(' Invalid device driver.');
        ctIDEVL: writeln(' Invalid device or LUN.');
        ctIPART: writeln(' Invalid partition number.');
        ctPUSED: writeln(' Partition is already in use.');
        ctFMNT:  writeln(' File is mounted. ');
        ctBFSZ:  writeln(' Bad file size. ');
        ctICLUS: writeln(' Invalid cluster number or sequence. ');
        else writeln('Error: ', regs.A);
    end;
end;

procedure Z80MODEExample;
var
    DriverSlot: byte;

begin
    FillChar( regs, SizeOf( regs ), 0 );
    
    (*ctZ80MODE. *)
    regs.C := ctZ80MODE;
    
    (* Driver slot number. *)
    regs.A := 1;
    DriverSlot := regs.A;
    
    (* get current Z80 access mode *)
    regs.B := 0;
    
    MSXBDOS ( regs );
    
    writeln (' Get Z80 access mode status for a driver: ');
    writeln (' Driver slot: ', DriverSlot);
    writeln (' Current Z80 access mode: ', regs.D);

    case regs.A of
        ctIDRVR: writeln(' Invalid device driver.');
        ctIDEVL: writeln(' Invalid device or LUN.');
        ctIPART: writeln(' Invalid partition number.');
        ctPUSED: writeln(' Partition is already in use.');
        ctFMNT:  writeln(' File is mounted. ');
        ctBFSZ:  writeln(' Bad file size. ');
        ctICLUS: writeln(' Invalid cluster number or sequence. ');
        else writeln('Error: ', regs.A);
    end;
    
    FillChar( regs, SizeOf( regs ), 0 );
    
    (*ctZ80MODE. *)
    regs.C := ctZ80MODE;
    
    (* Driver slot number. *)
    regs.A := 1;
    DriverSlot := regs.A;
    
    (* set current Z80 access mode *)
    regs.B := 255;
    
    (* enable Z80 access mode *)
    regs.D := 255;
    
    MSXBDOS ( regs );
    
    writeln (' Set Z80 access mode status for a driver: ');
    writeln (' Driver slot: ', DriverSlot);
    writeln (' Current Z80 access mode: ', regs.D);

    case regs.A of
        ctIDRVR: writeln(' Invalid device driver.');
        ctIDEVL: writeln(' Invalid device or LUN.');
        ctIPART: writeln(' Invalid partition number.');
        ctPUSED: writeln(' Partition is already in use.');
        ctFMNT:  writeln(' File is mounted. ');
        ctBFSZ:  writeln(' Bad file size. ');
        ctICLUS: writeln(' Invalid cluster number or sequence. ');
        else writeln('Error: ', regs.A);
    end;
end;

procedure DOSVEREnhancedExample;
begin
    FillChar (regs, SizeOf ( regs ), 0 );
    regs.C := ctGetMSXDOSVersionNumber;
    regs.B  := $005A;
    regs.HL := $1234;
    regs.DE := $ABCD;
    regs.IX := $0000;

    MSXBDOS ( regs );
    
    if regs.B < 2 then
        writeln (' MSX-DOS 1 detected. ')
    else
        if regs.IX = 0 then
        begin
            writeln (' MSX-DOS 2 detected. ');
            writeln (' MSXDOS2.SYS ', regs.D, '.', regs.E);
        end
        else
        begin
            writeln (' Nextor detected. ');
            writeln (' NEXTOR.SYS ', regs.D, '.', regs.E);
        end;
    
end;

BEGIN
{
    writeln (' GDLI ');
    GDLIExample;
}
    writeln (' GPART ');
    GPARTExample;
    writeln (' MAPDRV ');
    MAPDRVExample; 
    writeln (' DSPACE ');
    DSPACEExample;
{
    writeln (' RALLOC ');
    RALLOCExample; 
    writeln ('ZSTROUT');
    ZSTROUTExample;
}
    writeln (' Z80MODE ');
    Z80MODEExample; 

    GetMSXDOSVersion ( MSXDOSVersao );
    writeln (MSXDOSVersao.nKernelMajor, '.', MSXDOSVersao.nKernelMinor);
    writeln (MSXDOSVersao.nSystemMajor, '.', MSXDOSVersao.nSystemMinor);

    DOSVEREnhancedExample;
END.
