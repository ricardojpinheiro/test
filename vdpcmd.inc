{This code contains variables and constants needed with copy-procedures}

{lammassa@great.fi}


{Command array for the Vdp access }

Var _sx  :Integer Absolute $f562 ;
    _sy  :Integer Absolute $f564 ;
    _dx  :Integer Absolute $f566 ;
    _dy  :Integer Absolute $f568 ;
    _nx  :Integer Absolute $f56a ;
    _ny  :Integer Absolute $f56c ;
    _col :Byte Absolute    $f56e ;
    _arg :Byte Absolute    $f56f ;
    _cmd :Byte Absolute    $f570 ;



{Vdp Copy commands }

Const HMMC = $F0 ; {High speed Byte Cpu  -> Vram }
      YMMM = $E0 ; {High speed Byte Vram -> Vram in y-axis }
      HMMM = $D0 ; {High speed Byte Vram -> Vram in x- and y-axis }
      HMMV = $C0 ; {High speed Byte Vdp  -> Vram = paint a box }

      LMMC = $B0 ; {Logical Dot     Cpu  -> Vram }
      LMCM = $A0 ; {Logical Dot     Vram -> Cpu  }
      LMMM = $90 ; {Logical Dot     Vram -> Vram }
      LMMV = $80 ; {Logical Dot     Vdp  -> Vram = paint a box }


{Copy directions for the ARG-register }

      Copy_Right = 0;
      Copy_Down  = 0;
      Copy_Left  = 4;
      Copy_Up    = 8;

{You can concatenate these directions (actually bits) by addition:
 Copy_Right+Copy_Up , Copy_Left+Copy_Down and so on ... }

      ExpansionVram   = 32 ;
      Vram  = 0 ;

{One of these two constants must be added to _arg so, that Copy-procedure
 knows where to/from to copy . Use as a parameter to VramDestination}

{This file contains Graphic logic operands needed with vdp-commands}

Const G_Imp = 0 ; {writes over}
      G_And = 1;  {does logical AND with the colours}
      G_Or  = 2;  {and so on..}
      G_Xor = 3;
      G_Not = 4;

      G_Timp    = 8 ; {Does not change colour if 'new' colour is 0-colour}
      G_Tand    = 9;
      G_Tor     = 10;
      G_Txor    = 11;
      G_Tnot    = 12;

{Colours }

      Transparent = 0;
      Black       = 1;
      BrightGreen = 2;
      LightGreen  = 3;
      DeepBlue    = 4;
      LightBlue   = 7;
      BrightBlue  = 5;
      DeepRed     = 6;
      BrightRed   = 8;
      LightRed    = 9;
      BrightYellow = 10;
      PaleYellow   = 11;
      DeepGreen    = 12;
      Purple       = 13;
      Grey         = 14;
      White        = 15;
