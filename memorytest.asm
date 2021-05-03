          *=$0801
          BasicUpstart(start-1)

          *= $0820
            sei
start:      lda #$02
            sta $d020
            sta $d021
            lda #$15
            sta $d018
            ldx #$00
clrscr:     lda #$20
            sta $0400,x
            sta $0500,x
            sta $0600,x
            sta $0700,x
            lda #$01
            sta $d800,x
            sta $d900,x
            sta $da00,x
            sta $db00,x
            inx
            bne clrscr
            lda #>screen //copy from f0-f1
            sta $f1
            lda #<screen
            sta $f0
            lda #$04
            sta $f3      //copy to f2-f3
            lda #$00
            sta $f2
            jsr strcpy
          //hide ok text
            ldx #$25
            lda #$02
hideok:     sta $d941,x
            dex
            bne hideok
            lda #$00
            sta ramstatus
            ldx #$00
clrchips:   sta badchips,x
            inx
            cpx #$08
            bne clrchips
            //Set ram-area to be tested
            lda #<$1000
            sta $04     //04-05 = FROM $1000
            lda #>$1000
            sta $05
            lda #<$0000 //
            sta $06     //06-07 = TO $0000 (all the way through $ffff)
            lda #>$0000
            sta $07
            lda #$ff    //pattern FF
            sta $08
            lda #$37
            sta $01
            jsr hilipatf
            lda #$30
            sta $01
            jsr ramfill
            jsr ramwait
            jsr ramtest

            lda #$aa
            sta $08
            lda #$37
            sta $01
            jsr hilipata
            lda #$30
            sta $01
            jsr ramfill
            jsr ramwait
            jsr ramtest
            lda #$55
            sta $08
            lda #$37
            sta $01
            jsr hilipat5
            lda #$30
            sta $01
            jsr ramfill
            jsr ramwait
            jsr ramtest
            lda #$00
            sta $08
            lda #$37
            sta $01
            jsr hilipat0
            lda #$30
            sta $01
            jsr ramfill
            jsr ramwait
            jsr ramtest
            lda #$37
            sta $01
            //indicate no status
            lda #$57
            sta $04a2
            sta $04ca
            sta $04f2
            jsr nohilite
            //if no errors were seen
            lda ramstatus
            bne errors
            //display OK
            lda #$0f
            sta $0542
            lda #$0b
            sta $0543
            lda #$01
            sta $d942
            sta $d943
            jmp noerrors
errors:     lda #>errend
            sta $f1
            lda #<errend
            sta $f0
            lda lastline
            clc
            adc #$28
            sta $f2
            lda lastline+1
            adc #$00
            sta $f3
            jsr strcpy
            //more errors than show?
            lda ramstatus
            cmp #$02
            bne noerrors
            lda #>errmore
            sta $f1
            lda #<errmore
            sta $f0
            lda #$07
            sta $f3
            lda #$dd
            sta $f2
            jsr strcpy
        //end with chipstatus
noerrors:
            lda #>chipstat
            sta $f1
            lda #<chipstat
            sta $f0
            lda #$04
            sta $f3
            lda #$50
            sta $f2
            jsr strcpy
            ldx #$20
greyout:    lda #$0f
            sta $d8a3,x
            dex
            bne greyout
            ldx #$00
showchips:  lda badchips,x
            beq nextchip
            txa
            asl
            asl
            tay
            lda #$02
            sta $04cc,y
            lda #$01
            sta $04cd,y
            lda #$04
            sta $04ce,y
            lda #$07
            sta $d8cc,y
            sta $d8cd,y
            sta $d8ce,y
nextchip:   inx
            cpx #$08
            bne showchips
      // show try again text
            ldx #$1b
showtry:    lda #$07
            sta $d94b,x
            dex
            bne showtry
wait:       lda $dc00
            and #$10
            beq restart
            lda $dc01
            and #$10
            beq restart
            jmp wait
restart:    jmp start
//---------------------------------------
//ram-test routines directly from diag64
//---------------------------------------
ramfill:    lda #$51   // status indicator
            sta $04a2
            lda #$57
            sta $04ca
            sta $04f2
            lda $04
            sta $02
            lda $05
            sta $03
            ldy #$00
fillloop:   lda $08
            sta ($02),y
            inc $02
            bne fillloop
            inc $03
            lda $03
            jsr disppage
            cmp $07
            bne fillloop
            rts
ramwait:    lda #$51
            sta $04ca
            lda #$57
            sta $04a2
            sta $04f2
            ldx #$00
wait1:      dex
            bne wait1
            ldx #$00
wait2:      dex
            bne wait2
            rts
ramtest:    lda #$51
            sta $04f2
            lda #$57
            sta $04a2
            sta $04ca
            lda $04
            sta $02
            lda $05
            sta $03
            ldy #$00
testloop:   lda ($02),y
            cmp $08
            beq match
            jsr rambad
match:      inc $02
            bne testloop
            inc $03
            lda $03
            jsr disppage
            cmp $07
            bne testloop
            rts
ramstatus:  .byte $00
rambad:     pha
            tya
            pha
            txa
            pha
            //check if this is the first err
            lda ramstatus
            cmp #$02
            bne notfull
            jmp exitbad
notfull:    cmp #$00
            bne wasbad
//this is the first time we see something
//bad, so show BAD and the error address
//area ...
            lda #$37  //turn on IO
            sta $01
            lda #$02  //B
            sta $0542
            lda #$01  //A
            sta $0543
            lda #$04  //D
            sta $0544
            lda #$0a  //pink
            sta $d942
            sta $d943
            sta $d944
            lda #>errstart
            sta $f1
            lda #<errstart
            sta $f0
            lda #$05
            sta $f3
            lda #$69
            sta $f2
            jsr strcpy
            lda #$00
            sta adrcount
            sta adrtotal
            lda #$05
            sta lastline+1
            lda #$69
            sta lastline
            lda #$01
            sta ramstatus
            //start address
            lda #$05
            sta $0b
            lda #$93
            sta $0a
   //show the bad address
wasbad:     lda adrcount
            cmp #$00
            bne writeadr
            lda lastline
            clc
            adc #$28
            sta lastline
            lda lastline+1
            adc #$00
            sta lastline+1
            lda #>errline
            sta $f1
            lda #<errline
            sta $f0
            lda lastline+1
            sta $f3
            lda lastline
            sta $f2
            jsr strcpy
writeadr:   ldy #$00
            lda #$24     // $
            sta ($0a),y
            iny
            lda $03
            jsr dispaddr
            iny
            lda $02
            jsr dispaddr
            jsr nextaddr
exitbad:    lda #$30
            sta $01
            pla
            tax
            pla
            tay
            pla
            eor $08
            sta $09
//now 09 has the bad pattern in it - test
//which bits are bad, store in badchips
            ldx #$01
            lda $09
            and #$01
            beq bit0ok
            stx badchips+7
bit0ok:     lda $09
            and #$02
            beq bit1ok
            stx badchips+6
bit1ok:     lda $09
            and #$04
            beq bit2ok
            stx badchips+5
bit2ok:     lda $09
            and #$08
            beq bit3ok
            stx badchips+4
bit3ok:     lda $09
            and #$10
            beq bit4ok
            stx badchips+3
bit4ok:     lda $09
            and #$20
            beq bit5ok
            stx badchips+2
bit5ok:     lda $09
            and #$40
            beq bit6ok
            stx badchips+1
bit6ok:     lda $09
            and #$80
            beq bit7ok
            stx badchips+0
bit7ok:     rts

badchips:   .byte $00,$00,$00,$00,$00,$00,$00,$00
dispaddr:   pha
            lsr
            lsr
            lsr
            lsr
            and #$0f
            jsr dispit
            pla
            and #$0f
            iny
dispit:     cmp #$0a
            bcc dispnum
            sbc #$39
dispnum:    adc #$30
            sta ($0a),y
            rts
nextaddr:   inc adrcount
            inc adrtotal
            lda adrtotal
            cmp #$54     //max visible adrs
            bne roomleft
            lda #>errmore
            sta $f1
            lda #<errmore
            sta $f0
            lda #$07
            sta $f3
            lda #$dd
            sta $f2
            jsr strcpy
            lda #$02
            sta ramstatus
            rts
roomleft:   lda adrcount
            cmp #$06
            bne justnext
            lda #$00
            sta adrcount
            lda #$0a
            jmp nextline
justnext:   lda #$06
nextline:   clc
            adc $0a
            sta $0a
            bcc nxtad2
            inc $0b
nxtad2:     rts
lastline:   .byte $00,$00
adrcount:   .byte $00
adrtotal:   .byte $00
//---------------------------------------
disppage:   pha
            and #$0f
            tax
            lda hex,x
            sta $0468
            pla
            pha
            lsr
            lsr
            lsr
            lsr
            and #$0f
            tax
            lda hex,x
            sta $0467
            pla
            rts

hex:      .text "0123456789"
          .byte 1,2,3,4,5,6
//---------------------------------------
//highlight the pattern being tested
//---------------------------------------
hilipatf:   jsr nohilite
            lda #$07
            sta $d8b4
            sta $d8b5
            sta $d8b6
            rts
hilipata:   jsr nohilite
            lda #$07
            sta $d8b8
            sta $d8b9
            sta $d8ba
            rts
hilipat5:   jsr nohilite
            lda #$07
            sta $d8bc
            sta $d8bd
            sta $d8be
            rts
hilipat0:   jsr nohilite
            lda #$07
            sta $d8c0
            sta $d8c1
            sta $d8c2
            rts
nohilite:   ldx #$00
            lda #$0c
nohiloop:   sta $d8b4,x
            inx
            cpx #$10
            bne nohiloop
            rts
//---------------------------------------
//strcpy copies from ($f0) to ($f2) until
//       a $00 byte is met
//---------------------------------------
strcpy:     ldy #$00
stcploop:   lda ($f0),y
            beq stcpend
            sta ($f2),y
            inc $f0
            bne stcpinto
            inc $f1
stcpinto:   inc $f2
            bne stcploop
            inc $f3
            jmp stcploop
stcpend:    rts

screen:     .byte $55,$73,$0d,$05,$0d,$14,$05,$13,$14,$20,$32,$30
            .byte $32,$31,$20,$16,$30,$2e,$31,$20,$2d,$20,$02,$19
            .byte $20,$10,$05,$14,$05,$12,$20,$0c,$09,$0e,$04,$6b
            .byte $43,$43,$43,$49,$42,$20,$20,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$20,$20,$20,$20,$42,$42,$20,$14,$05
            .byte $13,$14,$09,$0e,$07,$20,$0d,$05,$0d,$0f,$12,$19
            .byte $20,$10,$01,$07,$05,$20,$24,$31,$30,$20,$20,$20
            .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$42
            .byte $42,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$42,$42,$20,$57,$60,$17,$12,$09,$14
            .byte $09,$0e,$07,$20,$10,$01,$14,$14,$05,$12,$0e,$20
            .byte $24,$06,$06,$20,$24,$01,$01,$20,$24,$35,$35,$20
            .byte $24,$30,$30,$20,$20,$20,$20,$42,$42,$20,$57,$20
            .byte $17,$01,$09,$14,$09,$0e,$07,$20,$06,$0f,$12,$20
            .byte $12,$05,$06,$12,$05,$13,$08,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$42
            .byte $42,$20,$57,$20,$12,$05,$01,$04,$09,$0e,$07,$20
            .byte $10,$01,$14,$14,$05,$12,$0e,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$42,$42,$20,$20,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$20,$20,$20,$20,$42,$42,$20,$0f,$0b
            .byte $20,$20,$20,$20,$20,$20,$20,$20,$a0,$90,$92,$85
            .byte $93,$93,$a0,$a7,$86,$89,$92,$85,$a7,$a0,$94,$8f
            .byte $a0,$92,$95,$8e,$a0,$81,$87,$81,$89,$8e,$a0,$42
            .byte $42,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$42,$4a,$43,$43,$43,$43,$43,$43,$43
            .byte $43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43
            .byte $43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43
            .byte $43,$43,$43,$43,$43,$43,$43,$4b,$00

 errstart:  .byte $70,$73,$05,$12,$12,$0f,$12,$13,$20,$06,$0f,$15
            .byte $0e,$04,$20,$01,$14,$6b,$43,$43,$43,$43,$43,$43
            .byte $43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43
            .byte $43,$6e,$00

errline:    .byte $42,$3e,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
            .byte $20,$42,$00
         
errend:     .byte $6d,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43
            .byte $43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43
            .byte $43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43
            .byte $43,$7d,$00
 
errmore:    .byte $6e,$0d,$0f,$12,$05,$2e,$2e,$2e,$70,$7d,$20,$00

chipstat:   .byte $42,$20,$55,$43,$43,$73,$03,$08,$09,$10,$20,$13
            .byte $14,$01,$14,$15,$13,$6b,$43,$43,$43,$43,$43,$43
            .byte $43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43
            .byte $49,$20,$20,$42,$42,$20,$42,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$20,$42,$20,$20,$42,$42,$20,$42,$20
            .byte $15,$31,$32,$20,$15,$32,$34,$20,$15,$31,$31,$20
            .byte $15,$32,$33,$20,$15,$31,$30,$20,$15,$32,$32,$20
            .byte $15,$39,$20,$20,$15,$32,$31,$20,$42,$20,$20,$42
            .byte $42,$20,$42,$20,$0f,$0b,$20,$20,$0f,$0b,$20,$20
            .byte $0f,$0b,$20,$20,$0f,$0b,$20,$20,$0f,$0b,$20,$20
            .byte $0f,$0b,$20,$20,$0f,$0b,$20,$20,$0f,$0b,$20,$20
            .byte $42,$20,$20,$42,$42,$20,$42,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
            .byte $20,$20,$20,$20,$42,$20,$20,$42,$42,$20,$4a,$43
            .byte $43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43
            .byte $43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43
            .byte $43,$43,$43,$43,$43,$43,$43,$43,$4b,$20,$20,$42
            .byte $42,$00