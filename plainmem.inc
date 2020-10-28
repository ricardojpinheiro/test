(*<plainmem.inc>
 * Memory mapper abstraction layer routines.
 * CopyLeft (c) since 2020 by Ricardo Jurczyk Pinheiro.
 *)

(**
  *
  * $Id: $
  * $Author: $
  * $Date: $
  * $Revision: $
  * $HeadURL: $
  *)

(*
 * This module depends on folowing include files (respect the order):
 * Yada-yada-yada
 *)

{$i d:types.inc}
{$i d:msxbios.inc}
{$i d:extbio.inc}
{$i d:maprbase.inc}
{$i d:maprvars.inc}
{$i d:maprrw.inc}
{$i d:maprallc.inc}
{$i d:maprpage.inc}
 
 
(*
* Constants
*)
const
    LastPositionAtSegment: Integer = 16384;
    LastPositionSegment = 16384;
    FirstSegment: Integer = 4;

(*
* Types and definitions
*)

type 
        PPlainMem   =   ^TPlainMem;
        TPlainMem   = record
        nTotalSegments      :   Byte;   { Total number of segments available    }
        nAvailableSegments  :   Byte;   { How many segments are available       }
        nUsedSegments       :   Byte;   { How many segments are used            }
        nFirstSegment       :   Byte;   { First segment that would be used      }
        nLastSegment        :   Byte;   { Last segment that would be used       }
    end;
    aBuffer =   array[1..LastPositionSegment] of byte;

function IntegerDivision (a, b: real): integer;
begin
    IntegerDivision := round(int((a - (a - (b * (a / b)))) / b));
end;

function IntegerModulo (a, b: real): integer;
begin
    IntegerModulo := round(int(a - (b * round(int(a / b)))));
end;

(*
* Returns info about the allocated memory.
*)

procedure InfoAboutPlainMem (var PlainMemData : TPlainMem);
begin
{
    PlainMemData.nTotalSegments := 
}
end;

(*
* Allocates segments to be used by the abstraction layer.
*)

function AllocatePlainMem (PMapperTable: PMapperVarTable; PlainMemData : TPlainMem; 
                            FirstAllocatedSegment, LastAllocatedSegment: byte) : boolean;
begin
    AllocatePlainMem := false;
    if FirstAllocatedSegment < FirstSegment then
        FirstAllocatedSegment := FirstSegment;
    if LastAllocatedSegment > PMapperTable^.nTotalSegs then
        LastAllocatedSegment := PMapperTable^.nTotalSegs;
    PlainMemData.nFirstSegment  := FirstAllocatedSegment;
    PlainMemData.nLastSegment   :=  LastAllocatedSegment;
    AllocatePlainMem := true;
end;

(*
* Release segments used by the abstraction layer.
*)

function ReleasePlainMem    (PMapperTable: PMapperVarTable; PlainMemData : TPlainMem; 
                            FirstAllocatedSegment, LastAllocatedSegment: byte) : boolean;
begin
    ReleasePlainMem := false;
    PlainMemData.nFirstSegment  := 0;
    PlainMemData.nLastSegment   := 0;
    ReleasePlainMem := true;
end;

(*
*  Read a bunch of bytes from the memory mapper.
*)
procedure ReadFromPlainMemory (handle: TMapperHandle; PlainMemData : TPlainMem; 
                            FirstPosition, LastPosition: real; var Buffer: aBuffer);
var
    FirstSegmentToBeUsed, LastSegmentToBeUsed: byte;
    FirstAddressInSegment, LastAddressInSegment: integer;
    Segments: byte;
    Addresses: integer;
    iBuffer: integer;
begin
    
(*
*  First we need to define some limits, due to First and Last Positions.
*)
    FirstSegmentToBeUsed    := FirstSegment + IntegerDivision(FirstPosition , LastPositionAtSegment);
    LastSegmentToBeUsed     := FirstSegment + IntegerDivision(LastPosition  , LastPositionAtSegment);
    FirstAddressInSegment   := IntegerModulo(FirstPosition  , LastPositionAtSegment);
    LastAddressInSegment    := IntegerModulo(LastPosition   , LastPositionAtSegment);
    iBuffer := 1;
(*
*   Here the magic begins.
*)
    for Segments := FirstSegmentToBeUsed to LastSegmentToBeUsed do
        for Addresses := FirstAddressInSegment to LastAddressInSegment do
        begin
            Buffer[iBuffer] := ReadMapperSegment(handle, Segments, Addresses);
            iBuffer := iBuffer + 1;
        end;    
end;

(*
*   Write a bunch of bytes into the memory mapper.
*)
procedure WriteToPlainMemory (handle: TMapperHandle; PlainMemData : TPlainMem; 
                            FirstPosition, LastPosition: real; var Buffer: aBuffer);
var
    FirstSegmentToBeUsed, LastSegmentToBeUsed: byte;
    FirstAddressInSegment, LastAddressInSegment: integer;
    Segments: byte;
    Addresses: integer;
    iBuffer: integer;
    AllRight: boolean;
    LastPositionSegment: integer;
begin
    
(*
*  First we need to define some limits, due to First and Last Positions.
*)
    FirstSegmentToBeUsed    := FirstSegment + IntegerDivision(FirstPosition , LastPositionAtSegment);
    LastSegmentToBeUsed     := FirstSegment + IntegerDivision(LastPosition  , LastPositionAtSegment);
    FirstAddressInSegment   := IntegerModulo(FirstPosition  , LastPositionAtSegment);
    LastAddressInSegment    := IntegerModulo(LastPosition   , LastPositionAtSegment);
    iBuffer := 1;
(*
*   Here the magic begins.
*)
    for Segments := FirstSegmentToBeUsed to LastSegmentToBeUsed do
        for Addresses := FirstAddressInSegment to LastAddressInSegment do
        begin
            AllRight := WriteMapperSegment(handle, Segments, Addresses, Buffer[iBuffer]);
            iBuffer := iBuffer + 1;
        end;    
end;

begin
end.
