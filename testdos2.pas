{
   testdos2.pas
   
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


program testdos2;
{$i d:types.inc}
{$i d:msxdos.pas}

Const
    ctOpenFileHandle                = $43;
    ctCreateFileHandle              = $44;
    ctCloseFileHandle               = $45;
    ctEnsureFileHandle              = $46;
    ctDuplicateFileHandle           = $47;
    ctReadFromFileHandle            = $48;
    ctWriteToFileHandle             = $49;
    ctMoveFileHandlePointer         = $4A;
    ctMoveFileHandle                = $54;
    ctChangeCurrentDir              = $5A;
    ctGetPreviousErrorCode          = $65;
    ctExplainErrorCode              = $66;
    ctGetEnvironmentItem            = $6B;
    ctSetEnvironmentItem            = $6C;
    ctGetMSXDOSVersionNumber        = $6F;
    
Type TMSXDOSVersion = Record
  nKernelMajor,
  nKernelMinor,
  nSystemMajor,
  nSystemMinor    : Byte;
End;

var Caminho, temporario: TFileName;
    Registros: TRegs;

(* Return the MSXDOS version. *)
Procedure GetMSXDOSVersion( Var version : TMSXDOSVersion );
Var
       regs  : TRegs;
Begin
  FillChar( regs, SizeOf( regs ), 0 );
  regs.C:= ctGetMSXDOSVersionNumber;
  MSXBDOS( regs );

  If( regs.A = 0 )  Then
    With version Do
    Begin
      nKernelMajor := regs.B;
      nKernelMinor := regs.C;
      nSystemMajor := regs.D;
      nSystemMinor := regs.E;
    End;
End;


(**
  * Call a MSXDOS/CPM/80 executable.
  * @param strFileName The executable file name to call.
  *)
Procedure CallExec( strFileName : TFileName );
Var
        fExecModule  : File;
        regs         : TRegs;
        szParm       : Array[0..5] Of Char; { MSXDD environment value }
        szPath       : Array[0..ctMaxPath] Of Char;
        version      : TMSXDOSVersion;
        nDriveNumber : Byte;

Begin
  GetMSXDOSVersion( version );

  If( version.nKernelMajor >= 2 )  Then
  Begin
    szParm[0] := 'M';
    szParm[1] := 'S';
    szParm[2] := 'X';
    szParm[3] := 'D';
    szParm[4] := 'D';
    szParm[5] := #0;
    szPath[0] := #0;

    With regs Do
    Begin
      B  := SizeOf( szPath );
      C  := ctGetEnvironmentItem;
      HL := Addr( szParm );
      DE := Addr( szPath );
    End;

    MSXBDOS( regs );

    If( szPath[0] <> #0 )  Then
    Begin
      If( szPath[1] = ':' )  Then   { Path contains the drive specification }
      Begin
        If( Upcase( szPath[0] ) In ['A'..'H'] )  Then
          nDriveNumber := Abs( Byte( 'A' ) - Byte( UpCase( szPath[0] ) ) );
          With regs Do
          Begin
            C := ctSetDrive;
            E := nDriveNumber;
          End;

          MSXBDOS( regs );
      End;

      With regs Do
      Begin
        C  := ctChangeCurrentDir;
        DE := Addr( szPath );
      End;

      MSXBDOS( regs );
    End;
  End;

  Assign( fExecModule, strFileName );
  {$i-}
  Execute( fExecModule );
  {$i+}

  If( IOResult <> 0 )  Then
    WriteLn( strFileName + ' not found' );

End;

var
    fExecModule : file;

BEGIN
    fillchar(Caminho, sizeof(Caminho), ' ' );
    Caminho := paramstr(1);
    writeln(Caminho);
    readln;
    assign ( fExecModule , Caminho );
    execute ( fExecModule ); 
   
{
    insert(chr(13), Caminho, 4);
    writeln(Caminho);
    Registros.C := ctStrOut;
    Registros.DE := addr(Caminho);
    MSXBDOS (Registros);
}
END.

