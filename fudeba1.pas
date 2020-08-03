PROGRAM MSXDOS;

{$I d:types.pas}
{$I d:dvram.pas}
{$I d:msxbios.pas}
{$I d:conio.pas}

Var
	scrHandle : TOutputHandle;
    i: byte;
    
Begin
	OpenDirectTextMode(scrHandle);
    _ClrScr;
	_GotoXY(1,1);
	for i := 1 to 25 do
        Writeln('ABCDEFGH');
	CloseDirectTextMode(scrHandle);
END.
