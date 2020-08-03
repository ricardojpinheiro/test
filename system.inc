procedure poke(pr_slot,sec_slot:byte;adres:integer;waarde:byte);

var a:byte;

  begin
    a:=0;
    a:=a or (pr_slot+128);
    sec_slot:=sec_slot shl 2;
    a:=a or sec_slot;
    inline($3a/waarde/           { LD A,(WAARDE)    }
           $5f/                  { LD E,A           }
           $3a/a/                { LD A,(A)         }
           $2a/adres/            { LD HL,(ADRES)    }
           $cd/$14/$00/          { CALL &H0014      }
           $fb);                 { EI               }
  end;


function peek(pr_slot,sec_slot:byte;adres:integer):byte;

var a:byte;

  begin
    a:=0;
    a:=a or (pr_slot+128);
    sec_slot:= sec_slot shl 2;
    a:=a or sec_slot;
    inline($3a/a/                { LD A,(A)         }
           $2a/adres/            { LD HL,(ADRES)    }
           $cd/$0c/$00/          { CALL &H000C      }
           $32/a/                { LD (A),A         }
           $fb);                 { EI               }
    peek:=a;
  end;


procedure sound(reg,waarde:byte);

  begin
    inline($3a/waarde/           { LD A,(WAARDE)    }
           $5f/                  { LD E,A           }
           $3a/reg/              { LD A,(REG)       }
           $fd/$2a/$c0/$fc/      { LD IY,(&HFCC0)   }
           $dd/$21/$93/$00/      { LD IX,&H0093     }
           $cd/$1c/$00/          { CALL &H001C      }
           $fb)                  { EI               }
  end;


function psg_reg(reg:byte):byte;

var data:byte;

  begin
    inline($3a/reg/              { LD A,(REG)       }
           $fd/$2a/$c0/$fc/      { LD IY,(&HFCC0)   }
           $dd/$21/$96/$00/      { LD IX,&H0096     }
           $cd/$1c/$00/          { CALL &H001C      }
           $32/data/             { LD (DATA),A      }
           $fb);                 { EI               }
    psg_reg:=data
  end;


procedure stop_sound;

  begin
    inline($fd/$2a/$c0/$fc/      { LD IY,(&HFCC0)   }
           $dd/$21/$90/$00/      { LD IX,&H0090     }
           $cd/$1c/$00/          { CALL &H001C      }
           $fb)                  { EI               }
  end;


function stick(optie:byte):byte;

var data:byte;

  begin
    inline($3a/optie/            { LD A,(OPTIE)     }
           $fd/$2a/$c0/$fc/      { LD IY,(&HFCC0)   }
           $dd/$21/$d5/$00/      { LD IX,&H00D5     }
           $cd/$1c/$00/          { CALL &H001C      }
           $32/data/             { LD (DATA),A      }
           $fb);                 { EI               }
    stick:=data
  end;


function strig(optie:byte):boolean;

  begin
    inline($3a/optie/            { LD A,(OPTIE)     }
           $fd/$2a/$c0/$fc/      { LD IY,(&HFCC0)   }
           $dd/$21/$d8/$00/      { LD IX,&H00D8     }
           $cd/$1c/$00/          { CALL &H001C      }
           $32/optie/            { LD (OPTIE),A     }
           $fb);                 { EI               }
    strig:=(optie=255)
  end;


procedure switch_to_Z80;

  begin
    inline($3e/$00/              { LD A,0           }
           $fd/$2a/$c0/$fc/      { LD IY,(&HFCC0)   }
           $dd/$21/$80/$01/      { LD IX,&H0180     }
           $cd/$1c/$00/          { CALL &H001C      }
           $fb)                  { EI               }
  end;


procedure switch_to_R800;

  begin
    inline($3e/$00/              { LD A,1           }
           $fd/$2a/$c0/$fc/      { LD IY,(&HFCC0)   }
           $dd/$21/$80/$01/      { LD IX,&H0180     }
           $cd/$1c/$00/          { CALL &H001C      }
           $fb)                  { EI               }
  end;


function processor_type:byte;

var soort:byte;

  begin
    inline($fd/$2a/$c0/$fc/      { LD IY,(&HFCC0)   }
           $dd/$21/$83/$01/      { LD IX,&H0183     }
           $cd/$1c/$00/          { CALL &H001C      }
           $32/soort/            { LD (SOORT),A     }
           $fb);                 { EI               }
    processor_type:=soort
  end;


procedure create_ramdisk;

  begin
    inline($01/$68/$fe/          { LD BC,&HFE68     }
           $cd/$05/$00)          { CALL &H0005      }
  end;


function dos_version:byte;

var versie:byte;

  begin
    inline($3e/$00/              { LD A,0           }
           $0e/$6f/              { LD C,&H6F        }
           $cd/$05/$00/          { CALL &H0005      }
           $78/                  { LD A,B           }
           $32/versie);          { LD (VERSIE),A    }
    if versie=2 then dos_version:=2
                else dos_version:=1
  end;


procedure change_drive(drive:txt);

  begin
     bdos($0e,(ord(drive) or 32)-97)
  end;


function current_drive:txt;

  begin
    current_drive:=chr(lo(bdoshl($19))+65)
  end;


procedure assign_drive(drive,drive2:txt);

var logical,physical:byte;

  begin
    logical:=(ord(drive) or 32)-96;
    physical:=(ord(drive2) or 32)-96;
    inline($0e/$6a/              { LD C,&H6A        }
           $3a/logical/          { LD A,(LOGICAL)   }
           $47/                  { LD B,A           }
           $3a/physical/         { LD A,(PHYSICAL)  }
           $57/                  { LD D,A           }
           $cd/$05/$00)          { CALL &H0005      }
  end;


procedure dski(drive:byte;sector,adres:integer);

  begin
    bdos($1a,adres);
    inline($ed/$5b/sector/       { LD DE,(SECTOR)   }
           $3a/drive/            { LD A,(DRIVE)     }
           $6f/                  { LD L,A           }
           $26/$01/              { LD H,1           }
           $0e/$2f/              { LD C,&H2F        }
           $cd/$05/$00)          { CALL &H0005      }
  end;


procedure dsko(drive:byte;sector,adres:integer);

  begin
    bdos($1a,adres);
    inline($ed/$5b/sector/       { LD DE,(SECTOR)   }
           $3a/drive/            { LD A,(DRIVE)     }
           $6f/                  { LD L,A           }
           $26/$01/              { LD H,1           }
           $0e/$30/              { LD C,&H30        }
           $cd/$05/$00)          { CALL &H0005      }
  end;


procedure mkdir(pad:txt;var fout:byte);

var error:byte;
    path,fib:txt;

  begin
    path:=pad+chr(0);
    inline($06/$10/              { LD B,&H10        }
           $0e/$42/              { LD C,&H42        }
           $11/path/             { LD DE,PATH       }
           $13/                  { INC DE           }
           $dd/$21/              { LD IX,FIB        }
           $dd/$23/              { INC IX           }
           $cd/$05/$00/          { CALL &H0005      }
           $32/error);           { LD (ERROR),A     }
    fout:=error
  end;


procedure rmdir(pad:txt;var fout:byte);

var error:byte;
    path:txt;

  begin
    path:=pad+chr(0);
    inline($0e/$4d/              { LD C,&H4D        }
           $11/path/             { LD DE,PATH       }
           $13/                  { INC DE           }
           $cd/$05/$00/          { CALL &H0005      }
           $32/error);           { LD (ERROR),A     }
    fout:=error
  end;


procedure chdir(pad:txt;var fout:byte);

var error:byte;
    path:txt;

  begin
    path:=pad+chr(0);
    inline($0e/$5a/              { LD C,&H5A        }
           $11/path/             { LD DE,PATH       }
           $13/                  { INC DE           }
           $cd/$05/$00/          { CALL &H0005      }
           $32/error);           { LD (ERROR),A     }
    fout:=error
  end;


procedure getdir(var pad:txt;var fout:byte);

var error:byte;
    path,path2:txt;
    adres:integer;

  begin
    adres:=addr(path);path2:='';
    inline($06/$00/              { LD B,0           }
           $0e/$59/              { LD C,&H59        }
           $ed/$5b/adres/        { LD DE,(ADRES)    }
           $cd/$05/$00/          { CALL &H0005      }
           $32/error);           { LD (ERROR),A     }
    if error=0
      then
        begin
          while mem[adres]<>0 do
            begin
              path2:=path2+chr(mem[adres]);
              adres:=adres+1
            end;
          pad:='\'+path2
        end;
    fout:=error
  end;


function date:txt;

type strvar=string[10];
     strvar2=string[4];

var dagmaand,jaar:integer;
         position:byte;
            datum:strvar;
           datum2:strvar2;

  begin
    datum:='';datum2:='';
    inline($0e/$2a/              { LD C,&H2A        }
           $cd/$05/$00/          { CALL &H0005      }
           $22/jaar/             { LD (JAAR),HL     }
           $ed/$53/dagmaand);    { LD (DAGMAAND),DE }
    str(lo(dagmaand):2,datum2);
    datum:=datum+datum2+':';
    str(hi(dagmaand):2,datum2);
    datum:=datum+datum2+':';
    str(jaar:4,datum2);
    datum:=datum+datum2;
    while pos(' ',datum)<>0 do
      begin
        position:=pos(' ',datum);
        delete(datum,position,1);
        insert('0',datum,position)
      end;
    date:=datum
  end;


function time:txt;

type strvar=string[10];
     strvar2=string[2];

var uurmin,sec:integer;
      position:byte;
          tijd:strvar;
         tijd2:strvar2;

  begin
    tijd:='';tijd2:='';
    inline($0e/$2c/              { LD C,&H2C        }
           $cd/$05/$00/          { CALL &H0005      }
           $22/uurmin/           { LD (UURMIN),HL   }
           $ed/$53/sec);         { LD (SEC),DE      }
    str(hi(uurmin):2,tijd2);
    tijd:=tijd+tijd2+':';
    str(lo(uurmin):2,tijd2);
    tijd:=tijd+tijd2+':';
    str(hi(sec):2,tijd2);
    tijd:=tijd+tijd2;
    while pos(' ',tijd)<>0 do
      begin
        position:=pos(' ',tijd);
        delete(tijd,position,1);
        insert('0',tijd,position)
      end;
    time:=tijd
  end;


procedure set_date(dag,maand:byte;jaar:integer);

  begin
    inline($2a/jaar/             { LD HL,(JAAR)     }
           $3a/dag/              { LD A,(DAG)       }
           $5f/                  { LD E,A           }
           $3a/maand/            { LD A,(MAAND)     }
           $57/                  { LD D,A           }
           $0e/$2b/              { LD C,&H2B        }
           $cd/$05/$00)          { CALL &H0005      }
  end;


procedure set_time(uur,min,sec:byte);

  begin
    inline($3a/uur/              { LD A,(UUR)       }
           $67/                  { LD H,A           }
           $3a/min/              { LD A,(MIN)       }
           $6f/                  { LD L,A           }
           $3a/sec/              { LD A,(SEC)       }
           $57/                  { LD D,A           }
           $0e/$2d/              { LD C,&H2D        }
           $cd/$05/$00)          { CALL &H0005      }
  end;


function x_move(poort:byte):byte;

var pad,pad2,move:byte;

  begin
    pad:=8+poort*4;
    pad2:=9+poort*4;
    inline($fd/$2a/$f7/$fa/      { LD IY,(&HFAF7)   }
           $dd/$21/$ad/$01/      { LD IX,&H01AD     }
           $3a/pad/              { LD A,(PAD)       }
           $cd/$1c/$00/          { CALL &H001C      }
           $3a/pad2/             { LD A,(PAD2)      }
           $cd/$1c/$00/          { CALL &H001C      }
           $32/move/             { LD (MOVE),A      }
           $fb);                 { EI               }
    x_move:=move
  end;


function y_move(poort:byte):byte;

var pad,pad2,move:byte;

  begin
    pad:=8+poort*4;
    pad2:=10+poort*4;
    inline($fd/$2a/$f7/$fa/      { LD IY,(&HFAF7)   }
           $dd/$21/$ad/$01/      { LD IX,&H01AD     }
           $3a/pad/              { LD A,(PAD)       }
           $cd/$1c/$00/          { CALL &H001C      }
           $3a/pad2/             { LD A,(PAD2)      }
           $cd/$1c/$00/          { CALL &H001C      }
           $32/move/             { LD (MOVE),A      }
           $fb);                 { EI               }
    y_move:=move
  end;


function printer_ready:boolean;

var status:byte;

  begin
    inline($fd/$2a/$c0/$fc/      { LD IY,(&HFCC0)   }
           $dd/$21/$a8/$00/      { LD IX,&H00A8     }
           $cd/$1c/$00/          { CALL &H001C      }
           $32/status/           { LD (STATUS),A    }
           $fb);                 { EI               }
    printer_ready:=(status>0)
  end;


procedure caps_on;

  begin
    inline($fd/$2a/$c0/$fc/      { LD IY,(&HFCC0)   }
           $dd/$21/$32/$01/      { LD IX,&H0132     }
           $3e/$0/               { LD A,0           }
           $cd/$1c/$00/          { CALL &H001C      }
           $fb);                 { EI               }
    mem[$fcab]:=255
  end;


procedure caps_off;

  begin
    inline($fd/$2a/$c0/$fc/      { LD IY,(&HFCC0)   }
           $dd/$21/$32/$01/      { LD IX,&H0132     }
           $3e/$1/               { LD A,1           }
           $cd/$1c/$00/          { CALL &H001C      }
           $fb);                 { EI               }
    mem[$fcab]:=0
  end;


procedure kill_buffer;

  begin
    inline($fd/$2a/$c0/$fc/      { LD IY,(&HFCC0)   }
           $dd/$21/$56/$01/      { LD IX,&H0156     }
           $cd/$1c/$00/          { CALL &H001C      }
           $fb)                  { EI               }
  end;


function csrlin:byte;

  begin
    csrlin:=mem[$f3dc]
  end;


function csrcol:byte;

  begin
    csrcol:=mem[$f3dd]
  end;


function msx_version:byte;

var versie:byte;

  begin
    inline($3e/$80/              { LD A,&H80        }
           $21/$2d/$00/          { LD HL,&H002D     }
           $cd/$0c/$00/          { CALL &H000C      }
           $32/versie/           { LD (VERSIE),A    }
           $fb);                 { EI               }
    msx_version:=versie+1
  end;


procedure beep;

  begin
    inline($fd/$2a/$f7/$fa/      { LD IY,(&HFAF7)   }
           $dd/$21/$7d/$01/      { LD IX,&H017D     }
           $cd/$1c/$00/          { CALL &H001C      }
           $fb)                  { EI               }
  end;


function char_string(aantal:byte;letter:txt):txt;

var teller:byte;
    help_string:txt;

  begin
    help_string:='';
    for teller:=1 to aantal do
      help_string:=help_string+letter;
    char_string:=help_string
  end;


function ctrl_stop_pressed:boolean;

var ctrl,stop:boolean;

  begin
    ctrl:=((mem[$fbeb] and 2)=0);
    stop:=((mem[$fbec] and 16)=0);
    ctrl_stop_pressed:=ctrl and stop
  end;


function hex_string(getal:integer):txt;

const hex_digit:array[0..15] of char=
                ('0','1','2','3','4','5','6','7','8','9',
                 'A','B','C','D','E','F');

var hex_str:txt;

  begin
    hex_str:=hex_digit[getal shr 12]+
             hex_digit[(getal shr 8) and $000f]+
             hex_digit[(getal shr 4) and $000f]+
             hex_digit[getal and $000f];
    hex_string:=hex_str
  end;


function bin_string(getal:integer):txt;

const bin_digit:array[0..1] of char=('0','1');

var bin_str:txt;
    teller:byte;

  begin
    bin_str:='';
    for teller:=15 downto 0 do
      bin_str:=bin_str+bin_digit[(getal shr teller) and 1];
    bin_string:=bin_str
  end;


procedure hide_cursor;

  begin
    write(chr(27)+'x5')
  end;


procedure show_cursor;

  begin
    write(chr(27)+'y5')
  end;


procedure halveer_cursor;

  begin
    write(chr(27)+'y4')
  end;


procedure maak_cursor_vol;

  begin
    write(chr(27)+'x4')
  end;


procedure motor_on;

  begin
    inline($3e/$01/              { LD A,1           }
           $dd/$21/$f3/$00/      { LD IX,&H00F3     }
           $fd/$2a/$c0/$fc/      { LD IY,(&HFCC0)   }
           $cd/$1c/$00/          { CALL &H001C      }
           $fb)                  { EI               }
  end;


procedure motor_off;

  begin
    inline($3e/$00/              { LD A,0           }
           $dd/$21/$f3/$00/      { LD IX,&H00F3     }
           $fd/$2a/$c0/$fc/      { LD IY,(&HFCC0)   }
           $cd/$1c/$00/          { CALL &H001C      }
           $fb)                  { EI               }
  end;


procedure get_file_attributes(pad:txt;var attribuut,fout:byte);

var path:txt;
    error,atr:byte;

  begin
    path:=pad+chr(0);
    inline($3e/$00/              { LD A,0           }
           $0e/$50/              { LD C,&H50        }
           $11/path/             { LD DE,PATH       }
           $13/                  { INC DE           }
           $cd/$05/$00/          { CALL &H0005      }
           $32/error/            { LD (ERROR),A     }
           $7d/                  { LD A,L           }
           $32/atr);             { LD (ATR),A       }
    attribuut:=atr;
    fout:=error
  end;


procedure set_file_attributes(pad:txt;attribuut:byte;var fout:byte);

var path:txt;
    error:byte;

  begin
    path:=pad+chr(0);
    inline($3a/attribuut/        { LD A,(ATTRIBUUT) }
           $6f/                  { LD L,A           }
           $3e/$01/              { LD A,1           }
           $0e/$50/              { LD C,&H50        }
           $11/path/             { LD DE,PATH       }
           $13/                  { INC DE           }
           $cd/$05/$00/          { CALL &H0005      }
           $32/error);           { LD (ERROR),A     }
    fout:=error
  end;


procedure set_disk_buffers(aantal:byte;var fout:byte);

var error:byte;

  begin
    inline($3a/aantal/           { LD A,(AANTAL)    }
           $47/                  { LD B,A           }
           $0e/$69/              { LD C,&H69        }
           $cd/$05/$00/          { CALL &H0005      }
           $32/error);           { LD (ERROR),A     }
    fout:=error
  end;


function aantal_disk_buffers:byte;

var aantal:byte;

  begin
    inline($06/$00/              { LD B,0           }
           $0e/$69/              { LD C,&H69        }
           $cd/$05/$00/          { CALL &H0005      }
           $78/                  { LD A,B           }
           $32/aantal);          { LD (AANTAL),A    }
    aantal_disk_buffers:=aantal
  end;


procedure set_environment_item(naam,waarde:txt;var fout:byte);

var error:byte;
    item,value:txt;

  begin
    item:=naam+chr(0);
    value:=waarde+chr(0);
    inline($21/item/             { LD HL,ITEM       }
           $23/                  { INC HL           }
           $11/value/            { LD DE,VALUE      }
           $13/                  { INC DE           }
           $0e/$6c/              { LD C,&H6C        }
           $cd/$05/$00/          { CALL &H0005      }
           $32/error);           { LD (ERROR),A     }
    fout:=error
  end;


procedure get_environment_item(naam:txt;var waarde:txt;var fout:byte);

var error:byte;
    adres:integer;
    item,value,buffer:txt;

  begin
    item:=naam+chr(0);
    value:='';
    adres:=addr(buffer);
    inline($21/item/             { LD HL,ITEM       }
           $23/                  { INC HL           }
           $11/buffer/           { LD DE,BUFFER     }
           $06/$ff/              { LD B,255         }
           $0e/$6b/              { LD C,&H6B        }
           $cd/$05/$00/          { CALL &H0005      }
           $32/error);           { LD (ERROR),A     }
    if error=0
      then
        begin
          while mem[adres]<>0 do
            begin
              value:=value+chr(mem[adres]);
              adres:=adres+1
            end;
          waarde:=value
        end;
    fout:=error
  end;


function pressed_function_key:byte;

var nummer:byte;

  begin
    nummer:=0;
    if (mem[$fbeb] and 32)=0 then nummer:=1;
    if (mem[$fbeb] and 64)=0 then nummer:=2;
    if (mem[$fbeb] and 128)=0 then nummer:=3;
    if (mem[$fbec] and 1)=0 then nummer:=4;
    if (mem[$fbec] and 2)=0 then nummer:=5;
    if ((mem[$fbeb] and 1)=0) and (nummer<>0) then nummer:=nummer+5;
    pressed_function_key:=nummer
  end;


function error_explanation(fout_code:byte):txt;

var buffer,help_string:txt;
    adres:integer;

  begin
    help_string:='';
    adres:=addr(buffer);
    inline($3a/fout_code/        { LD A,(FOUT_CODE) }
           $47/                  { LD B,A           }
           $0e/$66/              { LD C,&H66        }
           $11/buffer/           { LD DE,BUFFER     }
           $cd/$05/$00);         { CALL &H0005      }
    while mem[adres]<>0 do
      begin
        help_string:=help_string+chr(mem[adres]);
        adres:=adres+1
      end;
    error_explanation:=help_string
  end;


procedure set_adjust(horizontaal,verticaal:integer);

var reg,horiz,verti:byte;

  begin
    if horizontaal<=0
      then
        horiz:=-horizontaal
      else
        horiz:=15-horizontaal;
    if verticaal<=0
      then
        verti:=15+verticaal
      else
        verti:=verticaal;
    reg:=16*verti+horiz;
    inline($3a/reg/              { LD A,(REG)       }
           $47/                  { LD B,A           }
           $0e/$12/              { LD C,&H12        }
           $dd/$21/$2d/$01/      { LD IX,&H012D     }
           $fd/$2a/$f7/$fa/      { LD IY,(&HFAF7)   }
           $cd/$1c/$00/          { CALL &H001C      }
           $fb)                  { EI               }
  end;


procedure init_scc(pr_slot,sec_slot:byte);

var slot_id:byte;

  begin
    slot_id:=128;
    slot_id:=slot_id or pr_slot;
    slot_id:=slot_id or (sec_slot shl 2);
    inline($3a/slot_id/          { LD A,(SLOT_ID)   }
           $1e/$3f/              { LD E,&H3F        }
           $21/$00/$90/          { LD HL,&H9000     }
           $cd/$14/$00/          { CALL &H0014      }
           $fb)                  { EI               }
  end;


procedure write_scc_reg(pr_slot,sec_slot,reg,waarde:byte);

var slot_id:byte;
    adres:integer;

  begin
    slot_id:=128;
    slot_id:=slot_id or pr_slot;
    slot_id:=slot_id or (sec_slot shl 2);
    adres:=$9800+reg;
    inline($3a/waarde/           { LD A,(WAARDE)    }
           $5f/                  { LD E,A           }
           $3a/slot_id/          { LD A,(SLOT_ID)   }
           $2a/adres/            { LD HL,(ADRES)    }
           $cd/$14/$00/          { CALL &H0014      }
           $fb)                  { EI               }
  end;


procedure stop_scc_sound(pr_slot,sec_slot:byte);

var slot_id,reg:byte;
    adres:integer;

  begin
    slot_id:=128;
    slot_id:=slot_id or pr_slot;
    slot_id:=slot_id or (sec_slot shl 2);
    for reg:=0 to $ff do
      begin
        adres:=$9800+reg;
        inline($3a/slot_id/      { LD A,(SLOT_ID)   }
               $1e/$00/          { LD E,0           }
               $2a/adres/        { LD HL,(ADRES)    }
               $cd/$14/$00/      { CALL &H0014      }
               $fb)              { EI               }
      end;
  end;


procedure stop_drive;

var teller:byte;

  begin
    for teller:=0 to 255 do
      inline($cd/$9f/$fd);       { CALL &HFD9F      }
  end;


function dskf(drive:txt):integer;

var nummer,sectors:byte;
    clusters,vrije_ruimte:integer;

  begin
    nummer:=(ord(drive) or 32)-96;
    inline($3a/nummer/           { LD A,(NUMMER)    }
           $5f/                  { LD E,A           }
           $0e/$1b/              { LD C,&H1B        }
           $cd/$05/$00/          { CALL &H0005      }
           $32/sectors/          { LD (SECTORS),A   }
           $22/clusters);        { LD (CLUSTERS),HL }
    vrije_ruimte:=(sectors*clusters) div 2;
    if vrije_ruimte<0
      then
        vrije_ruimte:=-vrije_ruimte;
    dskf:=vrije_ruimte
  end;


procedure restore_screen;

  begin
    inline($37/                    { SCF              }
           $3f/                    { CCF              }
           $dd/$21/$85/$01/        { LD IX,&H0185     }
           $fd/$2a/$f7/$fa/        { LD IY,(&HFAF7)   }
           $cd/$1c/$00/            { CALL &H001C      }
           $fb)                    { EI               }
  end;


procedure write_clock_ram(blok,adres,waarde:byte);

var ram_adres:byte;

  begin
    ram_adres:=blok*16+adres;
    inline($3a/ram_adres/          { LD A,(RAM_ADRES) }
           $4f/                    { LD C,A           }
           $3a/waarde/             { LD A,(WAARDE)    }
           $dd/$21/$f9/$01/        { LD IX,&H01F9     }
           $fd/$2a/$f7/$fa/        { LD IY,(&HFAF7)   }
           $cd/$1c/$00/            { CALL &H001C      }
           $fb)                    { EI               }
  end;


function clock_ram_adres(blok,adres:byte):byte;

var ram_adres,waarde:byte;

  begin
    ram_adres:=blok*16+adres;
    inline($3a/ram_adres/          { LD A,(RAM_ADRES) }
           $4f/                    { LD C,A           }
           $dd/$21/$f5/$01/        { LD IX,&H01F5     }
           $fd/$2a/$f7/$fa/        { LD IY,(&HFAF7)   }
           $cd/$1c/$00/            { CALL &H001C      }
           $32/waarde/             { LD (WAARDE),A    }
           $fb);                   { EI               }
    clock_ram_adres:=waarde
  end;


procedure write_mmod_reg(reg,waarde:byte);

  begin
    port[$c0]:=reg;
    port[$c1]:=waarde
  end;


function mmod_aanwezig:boolean;

  begin
    mmod_aanwezig:=(port[$c0]<>255)
  end;
procedure destroy_ramdisk;

  begin
    inline($0e/$68/               { LD C,&H68          }
           $06/$00/               { LD B,0             }
           $cd/$05/$00)           { CALL &H0005        }
  end;


function ramdisk_size:integer;

var segmenten,error:byte;
      grootte:integer;

  begin
    inline($0e/$68/               { LD C,&H68          }
           $06/$ff/               { LD B,&HFF          }
           $cd/$05/$00/           { CALL &H0005        }
           $32/error/             { LD (ERROR),A       }
           $78/                   { LD A,B             }
           $32/segmenten);        { LD (SEGMENTEN),A   }
    if error=0
      then
        grootte:=segmenten*16
      else
        grootte:=0;
    ramdisk_size:=grootte
  end;


procedure set_diskcheck_on;

  begin
    inline($0e/$6e/               { LD C,&H6E          }
           $06/$00/               { LD B,0             }
           $3e/$01/               { LD A,1             }
           $cd/$05/$00)           { CALL &H0005        }
  end;


procedure set_diskcheck_off;

  begin
    inline($0e/$6e/               { LD C,&H6E          }
           $3e/$01/               { LD A,255           }
           $06/$ff/               { LD B,&HFF          }
           $cd/$05/$00)           { CALL &H0005        }
  end;


function diskcheck_status:byte;

var status:byte;

  begin
    inline($0e/$6e/               { LD C,&H6E          }
           $af/                   { XOR A              }
           $cd/$05/$00/           { CALL &H0005        }
           $78/                   { LD A,B             }
           $32/status);           { LD (STATUS),A      }
    if status<>0
      then
        status:=255;
    diskcheck_status:=status
  end;


procedure set_verify_on;

  begin
    inline($0e/$2e/               { LD C,&H2E          }
           $1e/$ff/               { LD E,&HFF          }
           $cd/$05/$00)           { CALL &H0005        }
  end;


procedure set_verify_off;

  begin
    inline($0e/$2e/               { LD C,&H2E          }
           $1e/$00/               { LD E,0             }
           $cd/$05/$00)           { CALL &H0005        }
  end;


function verify_status:byte;

var flag:byte;

  begin
    inline($0e/$58/               { LD C,&H58          }
           $cd/$05/$00/           { CALL &H0005        }
           $78/                   { LD A,B             }
           $32/flag);             { LD (FLAG),A        }
    verify_status:=flag xor 255
  end;


function touchpad_touched(poort:byte):boolean;

var flag,port:byte;

  begin
    port:=(poort-1)*4;
    inline($3a/port/              { LD A,(PORT)        }
           $dd/$21/$db/$00/       { LD IX,&H00DB       }
           $fd/$2a/$c0/$fc/       { LD IY,(&HFCC0)     }
           $cd/$1c/$00/           { CALL &H001C        }
           $32/flag/              { LD (FLAG),A        }
           $fb);                  { EI                 }
    if flag=255
      then
        touchpad_touched:=true
      else
        touchpad_touched:=false;
  end;


function touchpad_x(poort:byte):byte;

var data,port:byte;

  begin
    port:=poort*4-3;
    inline($3a/port/              { LD A,(PORT)        }
           $dd/$21/$db/$00/       { LD IX,&H00DB       }
           $fd/$2a/$c0/$fc/       { LD IY,(&HFCC0)     }
           $cd/$1c/$00/           { CALL &H001C        }
           $32/data/              { LD (DATA),A        }
           $fb);                  { EI                 }
    touchpad_x:=data
  end;


function touchpad_y(poort:byte):byte;

var data,port:byte;

  begin
    port:=poort*4-2;
    inline($3a/port/              { LD A,(PORT)        }
           $dd/$21/$db/$00/       { LD IX,&H00DB       }
           $fd/$2a/$c0/$fc/       { LD IY,(&HFCC0)     }
           $cd/$1c/$00/           { CALL &H001C        }
           $32/data/              { LD (DATA),A        }
           $fb);                  { EI                 }
    touchpad_y:=data
  end;


function touchpad_button_pressed(poort:byte):boolean;

var data,port:byte;

  begin
    port:=poort*4-1;
    inline($3a/port/              { LD A,(PORT)        }
           $dd/$21/$db/$00/       { LD IX,&H00DB       }
           $fd/$2a/$c0/$fc/       { LD IY,(&HFCC0)     }
           $cd/$1c/$00/           { CALL &H001C        }
           $32/data/              { LD (DATA),A        }
           $fb);                  { EI                 }
    if data=0
      then
        touchpad_button_pressed:=false
      else
        touchpad_button_pressed:=true;
  end;


function barcode_reader_port:byte;

  begin
    if port[24]<>255
      then
        barcode_reader_port:=24
      else
        if port[184]<>255
          then
            barcode_reader_port:=184
          else
            barcode_reader_port:=0;
  end;


function barcode_data(poort:byte):txt;

var barcode:txt;
       data:byte;

  begin
    barcode:='';
    repeat
      data:=port[poort]
    until data<128;
    repeat
      data:=port[poort];
      barcode:=barcode+chr(data and 127)
    until data>127;
    barcode_data:=barcode
  end;


procedure disable_barcode_scan(poort:byte);

  begin
    port[poort]:=208
  end;


procedure enable_barcode_scan(poort:byte);

  begin
    port[poort]:=200
  end;


procedure clear_barcode_buffer(poort:byte);

var data:byte;

  begin
    repeat
      data:=port[poort]
    until data>=128
  end;


function vdp_type:byte;

var data:byte;

  begin
    inline($3e/$01/               { LD A,1             }
           $dd/$21/$31/$01/       { LD IX,&H0131       }
           $fd/$2a/$f7/$fa/       { LD IY,(&HFAF7)     }
           $cd/$1c/$00/           { CALL &H001C        }
           $32/data/              { LD (DATA),A        }
           $fb);
    if data and 4<>0
      then
        vdp_type:=2
      else
        vdp_type:=1;
  end;


function ioresult_explanation(fout:byte):txt;

var tekst:txt;

  begin
    case fout of
      01,255 :tekst:='File not found';
      02,04  :tekst:='File not open';
      03     :tekst:='Write error';
      16     :tekst:='Wrong string format';
      32,33  :tekst:='CHAIN or EXECUTE not allowed here';
      34     :tekst:='Standard file not allowed';
      144    :tekst:='Wrong blocklength';
      145,153:tekst:='Input past end';
      240    :tekst:='Disk full';
      241    :tekst:='Directory full';
      242    :tekst:='Recordnumber too big';
      else
              tekst:='Unprintable error';
    end;
    ioresult_explanation:=tekst
  end;


function mouse_port:byte;

var x1,y1,x2,y2,dummy,teller:byte;

function pad(nummer:byte):byte;
var data:byte;
begin
  inline($3a/nummer/              { LD A,(NUMMER)      }
         $dd/$21/$ad/$01/         { LD IX,&H01AD       }
         $fd/$2a/$f7/$fa/         { LD IY,(&HFAF7)     }
         $cd/$1c/$00/             { CALL &H001C        }
         $32/data/                { LD (DATA),A        }
         $fb);                    { EI                 }
  pad:=data
end;

  begin
    x1:=0;y1:=0;x2:=0;y2:=0;
    for teller:=0 to 25 do
      begin
        dummy:=pad(12);
        x1:=x1 or pad(13);
        y1:=y1 or pad(14);
        dummy:=pad(16);
        x2:=x2 or pad(17);
        y2:=y2 or pad(18)
      end;
    if (x1<>1) or (y1<>1)
      then
        mouse_port:=1
      else
        if (x2<>1) or (y2<>1)
          then
            mouse_port:=2
          else
            mouse_port:=0;
  end;

