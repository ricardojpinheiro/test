PROGRAM GETCHARPATTERN;


{$I charpatt.inc }

Var i:          byte;
    PA1,PA2:    PatternArray8;

Begin
    ClrScr;
    Writeln('AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA');
    Writeln('Now I`ll get the char pattern of A.' );

    GetCharPattern(65, PA1);
    for i := 0 to 7 do
        PA2[i] := not PA1[i];

    delay (1000);
    Writeln('Now I`ll invert the pattern of A .');

    delay (1000);

    ChangeCharPattern(65,   PA2);

    Repeat Until KeyPressed;

    Writeln('Restored A. ');

    ChangeCharPattern(65,   PA1);
End.
