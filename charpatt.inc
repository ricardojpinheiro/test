{Charpatt.inc by Kari Lammassaari 1998 }

{Changes/Reads the character pattern of any char in all text screens. }
{Direct code. No ROM routines used.)
{Reads the location of CharacterPatternTable from RG4SAV. Supports
 128 Kb video ram }

{  Defines type:

Type PatternArray8 = Array[0..7] Of Byte;

  and procedures :

ChangeCharPattern(CharNum:Byte;PatternArray:PatternArray8);

GetCharPattern(CharNum:Byte;Var PatternArray:PatternArray8);

         - CharNum = Ord(Character); Ie. 65 = 'A'
         - PatternArray is an eight byte array containing the 8 pattern
           bytes.

}

Type PatternArray8 = Array[0..7] Of Byte;

Procedure ChangeCharPattern( Ch:Byte; A:PatternArray8);
 Var c :Byte;
    ar :Integer;
 Begin
  c := Ch; ar := Addr(A);
  Inline (
   $3A/Ch /$26/$0/$6F/$CB/$15/$CB/$14/$CB/$15/$CB/$14/$CB/$15/
   $CB/$14/$3A/$E3/$F3/$1E/$0/$CB/$27/$CB/$13/$CB/$27/$CB/$13/$CB/
   $27/$CB/$13/$47/$7B/$E/$0/$9/$CE/$0/$E5/$CB/$14/$17/$CB/$14/
   $17/$F3/$D3/$99/$3E/$E/$F6/$80/$D3/$99/$E1/$7D/$D3/$99/$7C/$E6/
   $3F/$F6/$40/$D3/$99/$6/$8/$2A/ Ar /$7E/$D3/$98/$23/$10/$FA/
   $FB
       );
End;

Procedure GetCharPattern(CharNum:Byte;Var PA:PatternArray8);

 Var Address :Integer;
     c       :Byte;
 Begin
   c := CharNum; Address := Addr(PA);
   Inline (
    $3A/ c /$26/$0/$6F/$CB/$15/$CB/$14/$CB/$15/$CB/$14/$CB/$15/
    $CB/$14/$3A/$E3/$F3/$1E/$0/$CB/$27/$CB/$13/$CB/$27/$CB/$13/$CB/
    $27/$CB/$13/$47/$7B/$E/$0/$9/$CE/$0/$E5/$CB/$14/$17/$CB/$14/
    $17/$F3/$D3/$99/$3E/$E/$F6/$80/$D3/$99/$E1/$7D/$D3/$99/$7C/$E6/
    $3F/$D3/$99/$6/$8/$2A/ Address /$DB/$98/$77/$23/$10/$FA/$FB
          );
  End;


