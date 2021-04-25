Procedure  Copy_xy (Source_x,Source_y:Integer;SourcePage:Byte;
                   Destination_x,Destination_y:Integer;DestinationPage:Byte;
                   Number_x,Number_y:Integer;Direction:Byte);


Begin
   _cmd:= HMMM ;
   _sy := SourcePage * 256 + Source_y ;
   _dy := DestinationPage * 256 + Destination_y ;
   _arg:= Direction ;
   _dx := Destination_x;
   _sx := Source_x;
   _nx := Number_x;
   _ny := Number_y;

   Inline (
     $F3/$3E/$20/$D3/$99/$3E/$11/$F6/$80/$D3/$99/$06/$0F/$0E/$9B/$21/
     $62/$F5/$ED/$B3/$3E/$02/$D3/$99/$3E/$0F/$F6/$80/$D3/$99/$DB/$99/
     $CB/$47/$20/$F0/$AF/$D3/$99/$3E/$8F/$D3/$99
          );
End ; {Copy_xy}