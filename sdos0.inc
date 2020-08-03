{ This is a short version of the KERNEL.PAS from the GrafPak.
  It includes just the text procedures, which has been optimised
  for speed and code size by Juan Salas.                         }


var CALSLT: array[0..2] of byte absolute $001C;
procedure  ENASLT;external $0024;

var
ATRBAS:integer absolute $F928;
ATRBYT:byte absolute $F3F2;
BAKCLR:byte absolute $F3EA;
BASE:  array[0..19] of integer absolute $F3B3;
BDRCLR:byte absolute $F3EB;
border:byte absolute BDRCLR;
CGPBAS:integer absolute $F924;
CNSDFG:byte absolute $F3DE;
CRTCNT:byte absolute $F3B1;
CSRX:  byte absolute $F3DD;
CSRY:  byte absolute $F3DC;
CSTYLE:boolean absolute $FCAA;
EXBRSA:byte absolute $FAF8;
EXPTBL:array[0..3] of byte absolute $FCC1;
FILNAM:array[1..11]of byte absolute $F866;
FORCLR:byte absolute $F3E9;
ink:   byte absolute FORCLR;
LINL40:byte absolute $F3AE;
LINLEN:byte absolute $F3B0;
LINWRK:array[0..79] of byte absolute $F975;
NAMBAS:integer absolute $F922;
paper: byte absolute BAKCLR;
PATBAS:integer absolute $F926;
SCRMOD:byte absolute $FCAF;
TIME:  integer absolute $FC9E;
TXTCOL:integer absolute $F3B5;
VDPSAV1:array[0..7]of byte absolute $F3DF;
VDPSAV2:array[8..23]of byte absolute $FFE7;
VRAMflag:byte absolute $FAFC;
SaveScr : Array[0..5] of byte;
MSX2,blinkflg,BlinkEnable: boolean;
dxGRPPRT,_LINLEN,_wx1,_wy1,_wx2,_wy2,_nxpos: integer;
AttrBits: array[0..239] of byte;


const

_CALROM: array[0..6] of byte = ($FD,$21,$00,$00,$C3,$D4,$20);
_CALSUB: array[0..6] of byte = ($FD,$21,$00,$00,$C3,$D4,$20);

procedure _CALP1;
begin
inline ($D9/$08/$DB/$A8/$32/*+$56/$E6/$03/$4F/$06/$00/$21/EXPTBL/$09/$B6/$F2/
        *+$13/$4F/$23/$23/$23/$23/$7E/$32/*+$48/$22/*+$47/$E6/$03/$07/$07/$B1/
        $32/*+$39/$21/*+$19/$E5/$ED/$5B/heapptr/$7A/$E6/$C0/$20/$03/$11/$4000/
        $D5/$21/*+$0C/$01/$22/$00/$ED/$B0/$C9/$FB/$08/$D9/$C9/$DD/$E5/$3A/
        EXPTBL/$21/$59/$01/$CD/$24/$00/$08/$D9/$DD/$E1/$CD/$59/$01/$D9/$08/$3E/
        $00/$D3/$A8/$3E/$00/$B7/$F0/$3E/$00/$32/$00/$00/$C9);
end;


procedure SetVDP (register, value: byte);
  begin inline($4D/$3A/value/$47/$DD/$21/$47/$00/$C3/_CALROM); end;

function GetVDP (register: byte): byte;
  begin
    if register < 8
    then GetVDP:=VDPSAV1[register]
    else GetVDP:=VDPSAV2[register];
  end;

function VDPstatus (register: byte): byte;
  begin inline($DD/$21/$31/$01/$CD/_CALSUB/$6F/$26/$00/$C9); end;


procedure ReadVRAM (VRAMaddress: integer;var RAMaddress;NumberOfbytes: integer);
  begin
   inline ($DD/$21/$59/$00/$ED/$4B/NumberOfbytes/
           $ED/$5B/RAMaddress/$2A/VRAMaddress/$C3/_CALROM);
  end;

procedure WriteVRAM (VRAMaddress: integer;var RAMaddress;NumberOfbytes: integer);
  begin
   inline ($DD/$21/$5C/$00/$ED/$4B/NumberOfbytes/
           $ED/$5B/VRAMaddress/$2A/RAMaddress/$C3/_CALROM);
  end;

procedure fillVRAM (VRAMaddress: integer;NumberOfbytes: integer;value: byte);
  begin
   inline ($DD/$21/$6B/$01/
           $ED/$4B/NumberOfbytes/$2A/VRAMaddress/$3A/value/$C3/_CALROM);
  end;

function vpeek (VRAMaddress: integer): byte;

  begin
    inline($DD/$21/$74/$01/
           $2A/VRAMaddress/$CD/_CALROM/$6F/$26/$00/$C9);
  end;

procedure vpoke (VRAMaddress: integer;value: byte);
begin
inline($DD/$21/$77/$01/
       $2A/VRAMaddress/$3A/value/$C3/_CALROM);
end;

procedure Beep;
 begin
 inline ($DD/$21/$C0/$00/$C3/_CALROM)
 end;

procedure BlinkInit;
begin
 fillchar (AttrBits, 240, 0);
 fillVRAM (TXTCOL, 240, 0)
end;

procedure BlinkColor (ink, paper, blinkon, blinkoff: integer);
  begin
      if not BlinkEnable then BlinkInit;
      SetVDP (12, (ink shl 4) + paper);
      SetVDP (13, (blinkon shl 4) + blinkoff);
      BlinkEnable:=TRUE
  end;

procedure BlinkOff;
  begin
      SetVDP (12, (FORCLR shl 4) + BAKCLR);
      SetVDP (13, 0);
      BlinkEnable:=FALSE;
      blinkflg   :=FALSE
  end;


procedure HighVideo;
  begin
      blinkflg:=TRUE;
  end;


procedure NormVideo;
  begin
    blinkflg:=FALSE;
  end;


procedure SetAttribute (x,y: integer;InversEin: boolean);
const
   bittab: array[0..7] of byte = ($80,$40,$20,$10,$08,$04,$02,$01);
begin
 inline ($3A/x/$3D/$47/$E6/$07/$5F/$16/$00/$21/bittab/$19/$4E/$3A/y/$3D/
         $87/$5F/$87/$87/$83/$5F/$78/$0F/$0F/$0F/$E6/$1F/$83/$5F/$21/
         AttrBits/$19/$46/$3A/InversEin/$0F/$9F/$A8/$A1/$C8/$78/$A9/$77/
         $2A/TXTCOL/$19/$DD/$21/$77/$01/$C3/_CALROM);
  end;


function GetAttribute (x,y: integer): boolean;
  begin
    GetAttribute:= (AttrBits[pred(y)*10+(pred(x)shr 3)] and(128 shr(pred(x)and 7)))<>0;
  end;


procedure _WindowMask (x1,x2,y: integer;var at1,at2,m1,m2: integer);
  begin
    at1:=10*y + (x1 shr 3);at2:=10*y + (x2 shr 3);
    m1:=not pred (256 shr (x1 and 7));
    m2:=pred (128 shr (x2 and 7))
  end;

procedure gotoXY (x, y: integer);
  var bottom: integer;
  begin
      bottom:=lo(CRTCNT+CNSDFG);
      if _wy1>bottom then _wy1:=bottom;
      if _wy2>bottom then _wy2:=bottom;
      CSRX:=pred(_wx1)+x;CSRY:=pred(_wy1)+y;
      if CSRX > _wx2 then CSRX:=_wx2;
      if CSRY > _wy2 then CSRY:=_wy2;
      _nxpos:=NAMBAS+pred(CSRY)*_LINLEN+pred(CSRX)
  end;

function whereX: integer;
  begin
   whereX:=succ(CSRX-_wx1)
  end;

function whereY: integer;
  begin
   whereY:=succ(CSRY-_wy1)
  end;

procedure _checkwindow;
  var bottom:integer;
  begin
    bottom:=lo(CRTCNT+CNSDFG);
    if _wy1>bottom then _wy1:=bottom;
    if _wy2>bottom then _wy2:=bottom;
    if CSRY>bottom then
       begin
       CSRY:=bottom;_nxpos:=NAMBAS+pred(CSRY)*_LINLEN+pred(CSRX);
       end;
  end;

procedure window (x1,y1,x2,y2: integer);
  begin
  _wx1:=x1;_wy1:=y1;_wx2:=x2;_wy2:=y2;_checkwindow;gotoXY (1,succ(y2-y1));
  end;

Procedure FillAttr(at1,at2,m1,m2: integer);
begin
      AttrBits[at1]:=(AttrBits[at1] and m1);
      AttrBits[at2]:=(AttrBits[at2] and m2);
      if at2 > succ(at1) then fillchar (AttrBits[succ(at1)], pred(at2-at1), 0);
      WriteVRAM (TXTCOL+at1, AttrBits[at1], succ(at2-at1));
end;

procedure ClrEOL;
  var at1,at2,m1,m2: integer;
  begin
    _WindowMask (pred(CSRX),pred(_wx2),pred(CSRY),at1,at2,m1,m2);
    FillVRAM (_nxpos, succ(_wx2-CSRX), 32);
    if BlinkEnable then FillAttr(at1,at2,m1,m2);
  end;


procedure ClrEOS;
  var i,at1,at2,m1,m2: integer;
  begin
    ClrEOL;_checkwindow;
    _WindowMask (pred(_wx1),pred(_wx2),CSRY,at1,at2,m1,m2);
    for i:=succ(CSRY) to _wy2 do
      begin
      FillVRAM (NAMBAS+pred(i)*_LINLEN+pred(_wx1),succ(_wx2-_wx1),32);
      if BlinkEnable then
       begin
        FillAttr(at1,at2,m1,m2);
        at1:=at1+10;at2:=at2+10;
       end;
      end;
  end;


procedure ScrollWindowDown (x1,y1,x2,y2: integer);
  var i, zl, at1, at2, m1, m2: integer;
  begin
    x1:=pred(x1);x2:=pred(x2);y1:=pred(y1);y2:=pred(y2);
    _WindowMask (x1,x2,y2,at1,at2,m1,m2);
    zl:=succ(x2-x1);
    i:=NAMBAS+y2*_LINLEN+x1;
    for y2:=y2 downto succ(y1) do
      begin
          readVRAM  (i-_LINLEN, LINWRK, zl);
          writeVRAM (i, LINWRK, zl);
          i:=i - _LINLEN;
      end;
    FillVRAM (NAMBAS+y1*_LINLEN+x1, succ(x2-x1), 32);
  end;

procedure ScrollWindowUp (x1,y1,x2,y2: integer);
  var i, zl, at1, at2, m1, m2: integer;
  begin
    x1:=pred(x1);x2:=pred(x2);y1:=pred(y1);y2:=pred(y2);
    _WindowMask (x1,x2,y1,at1,at2,m1,m2);
    zl:=succ(x2-x1);
    i:=NAMBAS+y1*_LINLEN+x1;
    for y1:=y1 to pred(y2) do
      begin
          readVRAM  (i+_LINLEN, LINWRK, zl);
          writeVRAM (i, LINWRK, zl);
          i:=i + _LINLEN;
      end;
    FillVRAM (NAMBAS+y2*_LINLEN+x1, succ(x2-x1), 32);
  end;

procedure DelLine;
  begin
    _checkwindow;write (#13);ScrollWindowUp (_wx1,CSRY,_wx2,_wy2);
  end;

procedure InsLine;
  begin
    _checkwindow;write (#13);ScrollWindowDown (_wx1,CSRY,_wx2,_wy2);
  end;


procedure FullWindow;
  begin
   window (succ((_LINLEN-LINLEN) shr 1), 1, ((_LINLEN-LINLEN) shr 1)+LINLEN, lo(CRTCNT+CNSDFG))
  end;

procedure screen (n: byte);
  begin
    inline ($18/$06/$33/$14/$55/$02/$0F/$03/$FE/$04/$38/$12/$FE/$09/$30/$06/$3A/
    MSX2/$0F/$38/$08/$DD/$E1/$11/$91/$02/$C3/$2C/$20/$E5/$CD/BLINKOFF/$E1/$7D/
    $DD/$21/$5F/$00/$CD/_CALROM/$FB/$3A/$AF/$FC/$21/$20/$00/$3D/$28/$0D/$3A/$B0/
    $F3/$21/$28/$00/$FE/$29/$38/$03/$21/$50/$00/$22/_LINLEN/$3A/MSX2/$0F/$30/
    $0B/$CD/BLINKINIT/$DD/$21/$41/$01/$CD/_CALSUB/$FB/$CD/FULLWINDOW/$21/$01/
    $00/$E5/$E5/$CD/GOTOXY);
  end;

procedure CrtExit;
  begin
    inline ($DD/$21/$D2/$00/$CD/_CALROM);
    BlinkOff;
    inline ($DD/$21/$85/$01/$CD/_CALSUB);
    CRTCNT:=24;
    Inline($3A/SaveScr+1/$32/forclr/$3A/SaveScr+2/$32/bakclr/   { get Colors }
           $3A/SaveScr+3/$32/bdrclr/
           $DD/$21/$62/$00/$CD/_CALROM/                         { set Colors }
           $3A/SaveScr+4/$32/linl40/$3A/SaveScr+5/$32/linlen/    { get width }
           $DD/$21/$6C/$00/$CD/_CALROM)                      { set old width }
  end;

procedure CrtInit;

 function constatus: boolean;
 begin inline
   ($DD/$21/$9C/$00/$CD/_CALROM/$21/$00/$00/$C8/$23/$C9)
 end;

 function conin: char;
 var memo: integer;
 begin
   memo:=LINLEN;
   LINLEN:=_LINLEN;
   inline ($DD/$21/$9F/$00/$CD/_CALROM/$6F/$26/$00/$3A/memo/$32/LINLEN/$C9);
 end;

 {$A-}
 procedure conout (chr: char);
 const i: integer = 0;
 begin
   case chr of
    #1: i:=-64;
    #8: if CSRX > _wx1
        then begin CSRX:=pred(CSRX);_nxpos:=pred(_nxpos);end
        else if CSRY > _wy1
        then begin CSRY:=pred(CSRY);CSRX:=_wx2;
                   _nxpos:=NAMBAS+pred(CSRY)*_LINLEN+pred(CSRX);end;
    #9: repeat conout(' ') until ((CSRX-_wx1) and 7) = 0;
   #10: begin
        _checkwindow;
        if CSRY = _wy2 then ScrollWindowUp (_wx1,_wy1,_wx2,_wy2)
        else begin CSRY:=succ(CSRY);_nxpos:=_nxpos+_LINLEN;end;
        end;
   #13: begin CSRX:=_wx1;_nxpos:=NAMBAS + pred(CSRY)*_LINLEN + pred(CSRX);end;
   else begin
        if BlinkEnable then SetAttribute (CSRX,CSRY,blinkflg);
        inline ($2A/_nxpos/$3A/chr/$4F/$3A/i/$81/$DD/$21/$4D/$00/
                $CD/_CALROM/$23/$22/_nxpos);
        CSRX:=succ(CSRX);
        i:=0;
        end;
   end {case};
   if CSRX > _wx2 then begin conout (#13);conout (#10);end;
  end;

 {$A+}

 procedure lstout (chr: char);
 begin inline
   ($DD/$21/$A5/$00/$3A/chr/$C3/_CALROM)
 end;

 procedure Error (dummy1, dummy2: integer);
 begin
   CrtExit
 end;

begin inline
  ($3A/forclr/$32/SaveScr+1/$3A/bakclr/$32/SaveScr+2/         { save Colors }
   $3A/bdrclr/$32/SaveScr+3/$3E/$00/$32/SaveScr/
   $3A/linl40/$32/SaveScr+4/$3A/linlen/$32/SaveScr+5/         { save width }
   $21/$00/$00/$39/$7C/$FE/$82/$30/$08/$DD/$E1/$11/$FF/$02/$C3/$2C/$20/
   $CD/$0A/$03/$11/$0B/$00/$2A/*+$0045/$19/$0E/$04/$11/$00/$00/$37/$F5/
   $06/$08/$F1/$F5/$30/$02/$CB/$06/$CB/$13/$CB/$12/$30/$08/$7A/$EE/$80/
   $57/$7B/$EE/$05/$5F/$10/$EA/$23/$0D/$20/$E4/$F1/$30/$05/$B7/$0E/$02/
   $18/$DB/$2B/$2B/$1B/$7B/$BE/$20/$05/$23/$7A/$BE/$28/$0D/$2A/*+$000A/
   $36/$F3/$23/$36/$76/$18/$03/$CD/SCREEN/$CD/$00/$02/$1B/$78/$35/$00/
   $21/$02/$00/$22/DXGRPPRT/$21/$20/$00/$3A/$AF/$FC/$3D/$28/$0D/$21/
   $28/$00/$3A/$B0/$F3/$FE/$29/$38/$03/$21/$50/$00/$22/_LINLEN/$11/$03/
   $00/$21/_CALROM/$19/$3A/$C1/$FC/$77/$23/$EB/$21/$1C/$00/$01/$03/$00/
   $ED/$B0);

   if EXBRSA <> 0 then begin inline
     ($DD/$2A/$1D/$00/$11/$BF/$00/$DD/$19/$3E/$47/$DD/$BE/$00/$20/$44/
      $3E/$7B/$DD/$BE/$01/$20/$3D/$DD/$22/*+$0039/$F3/$DD/$36/$FD/$C3/
      $DD/$36/$FE/$9A/$DD/$36/$FF/$F3/$11/$9A/$F3/$21/*+$001B/$01/$0D/
      $00/$ED/$B0/$DB/$A8/$E6/$03/$5F/$16/$00/$21/$C5/$FC/$19/$DD/$75/
      $2D/$DD/$74/$2E/$FB/$18/$0D/$E5/$6F/$DB/$A8/$92/$E6/$03/$7D/$E1/
      $C0/$C3/$00/$00);
      _CALSUB[3] :=EXBRSA;move (CALSLT, _CALSUB[4], 3);
      if (VRAMflag and 6) <> 0 then VRAMflag := VRAMflag or 8;
      BlinkOff;
      SetVDP(8,GetVDP(8) and $DF);
      end;

    FullWindow;
    ConStPtr :=addr(constatus);
    ConInPtr :=addr(conin);
    ConOutPtr:=addr(conout);
    LstOutPtr:=addr(lstout);
    ErrorPtr :=addr(Error);
  end;


procedure color (c1, c2, c3: byte);
begin
  FORCLR:=c1;BAKCLR:=c2;BDRCLR:=c3;ATRBYT:=c1;
  inline ($DD/$21/$62/$00/$C3/_CALROM);
 end;

procedure ClrScr;
  begin
   gotoxy(1,1);
   ClrEOS
  end;

procedure width (n: byte);
  begin
    inline ($3A/$B0/$F3/$BD/$C8/$3A/$AF/$FC/$B7/$4F/$7D/$28/$05/$32/$AF/$F3/
            $18/$03/$32/$AE/$F3/$C5/$CD/SCREEN);
  end;

Procedure WBorder;
var i, j: integer;
begin
  if _wy1 > 1
  then begin
    if _wx1 > 1 then vpoke (NAMBAS+pred(pred(_wy1))*_LINLEN+pred(pred(_wx1)),$18);
    fillVRAM (NAMBAS+pred(pred(_wy1))*_LINLEN+pred(_wx1),succ(_wx2-_wx1),$17);
    if _wx2 < _LINLEN then vpoke (NAMBAS+pred(pred(_wy1))*_LINLEN+_wx2,$19);
    end;
  if _wx1 > 1
  then begin
    j := NAMBAS + pred(_wy1)*_LINLEN + pred(pred(_wx1));
    for i := _wy1 to _wy2 do
      begin
      vpoke (j, $16);
      j := j + _LINLEN;
      end;
    end;
  if _wx2 < _LINLEN
  then begin
    j := NAMBAS + pred(_wy1)*_LINLEN + _wx2;
    for i := _wy1 to _wy2 do
      begin
      vpoke (j, $16);
      j := j + _LINLEN;
      end;
    end;
  if _wy2 < CRTCNT
  then begin
    if _wx1 > 1 then vpoke (NAMBAS+_wy2*_LINLEN+pred(pred(_wx1)),$1A);
    fillVRAM (NAMBAS+_wy2*_LINLEN+pred(_wx1),succ(_wx2-_wx1),$17);
    if _wx2 < _LINLEN then vpoke (NAMBAS+_wy2*_LINLEN+_wx2,$1B);
    end;
end;

type
  goBASIC_filename = string[20];

Procedure goBASIC (s: goBASIC_filename);
  type
    arr = array [0..$0005] of byte;
  var
    SWPTMP: arr absolute $F7BC;
    prog:   goBASIC_filename absolute $80;
  const
    GOCODE: arr = ($CD,$68,$F3,$C3,$22,$40);
  begin
    prog   := s;
    SWPTMP := GOCODE;
    inline ($C3/SWPTMP);
  end;


