hex_editor:
        LDA $13D4                   ; pause flag
        BNE +
        LDA !hex_editor_cursor
        BEQ .done
        JMP hex_editor_close        ; close hex editor when pause is released with hex editor open

      + JSR test_hex_editor
        LDA !hex_editor_cursor
        BEQ .done
        CMP #$07
        BCS +
        JSR hex_editor_load_value   ; load value if cursor is at address
      + JSR draw_hex_editor
        REP #$02                    ; zero flag

    .done:
        RTS

test_hex_editor:
        INC !fast_scroll_timer
        LDA !util_byetudlr_hold
        AND #%00001100
        ORA !util_axlr_hold
        AND #%00111100
        BNE +
        STZ !fast_scroll_timer
      + LDY !fast_scroll_timer
        CPY #!fast_scroll_delay
        BCC +
        LDY #!fast_scroll_delay
        STY !fast_scroll_timer
        BIT #%00100000
        BNE .left
        BIT #%00010000
        BNE .right
        BIT #%00001000
        BNE .dup
        BIT #%00000100
        BNE .ddown

      + LDA !util_byetudlr_frame
        AND #%11001111
        ORA !util_axlr_frame
        BIT #%10000000
        BNE .ab
        BIT #%01000000
        BNE .xy
        BIT #%00100000
        BNE .left
        BIT #%00010000
        BNE .right
        BIT #%00001000
        BNE .dup
        BIT #%00000100
        BNE .ddown
        BIT #%00000010
        BNE .dleft
        BIT #%00000001
        BNE .dright

    .done:
        RTS

    .left:
        JMP hex_editor_dec_with_carry

    .right:
        JMP hex_editor_inc_with_carry

    .dup:
        JMP hex_editor_inc_without_carry

    .ddown:
        JMP hex_editor_dec_without_carry

    .dleft:
        LDX !hex_editor_cursor
        LDA hex_editor_dleft_table,X
        STA !hex_editor_cursor
        RTS

    .dright:
        LDX !hex_editor_cursor
        LDA hex_editor_dright_table,X
        STA !hex_editor_cursor
        RTS

    .ab:
        LDA !hex_editor_cursor
        BEQ hex_editor_open
        CMP #$07
        BCC hex_editor_edit
        BRA hex_editor_apply

    .xy:
        LDA !hex_editor_cursor
        BEQ .done
        CMP #$07
        BCC hex_editor_close
        BRA hex_editor_cancel

hex_editor_open:
        LDA !hex_editor_exists
        CMP #$BD
        BEQ +

        LDA #$00
        STA !hex_editor_address
        STA !hex_editor_address+1
        STA !hex_editor_address+2
        LDA #$BD
        STA !hex_editor_exists

      + LDA #$06
        STA !hex_editor_cursor
        LDA #$B6
        STA !statusbar_size
        RTS

hex_editor_close:
        JSR clear_hex_editor
        LDA #$26
        STA !statusbar_size
        STZ !hex_editor_cursor
        RTS

hex_editor_edit:
        LDA #$08
        STA !hex_editor_cursor

hex_editor_load_value:
        LDA !hex_editor_address
        STA $00
        LDA !hex_editor_address+1
        STA $01
        LDA !hex_editor_address+2
        STA $02
        LDA [$00]
        STA !hex_editor_value
        RTS

hex_editor_apply:
        LDA !hex_editor_address
        STA $00
        LDA !hex_editor_address+1
        STA $01
        LDA !hex_editor_address+2
        STA $02
        LDA !hex_editor_value
        STA [$00]

hex_editor_cancel:
        LDA #$06
        STA !hex_editor_cursor
        RTS

hex_editor_inc_without_carry:
        LDA !hex_editor_cursor
        TAY
        AND #$01
        TAX

        LDA !hex_editor_value
        JSR .sub
        STA !hex_editor_value
        INY #2

        LDA !hex_editor_address
        JSR .sub
        STA !hex_editor_address
        INY #2

        LDA !hex_editor_address+1
        JSR .sub
        STA !hex_editor_address+1
        INY #2

        LDA !hex_editor_address+2
        JSR .sub
        STA !hex_editor_address+2
        RTS

    .sub
        PHA
        AND hex_editor_inc_mask,X
        CMP hex_editor_inc_mask,X
        BNE +
        PLA
        RTS
      + PLA
        CLC
        ADC hex_editor_inc_table,Y
        RTS

hex_editor_dec_without_carry:
        LDA !hex_editor_cursor
        TAY
        AND #$01
        TAX

        LDA !hex_editor_value
        JSR .sub
        STA !hex_editor_value
        INY #2

        LDA !hex_editor_address
        JSR .sub
        STA !hex_editor_address
        INY #2

        LDA !hex_editor_address+1
        JSR .sub
        STA !hex_editor_address+1
        INY #2

        LDA !hex_editor_address+2
        JSR .sub
        STA !hex_editor_address+2
        RTS

    .sub
        BIT hex_editor_inc_mask,X
        BEQ +
        SEC
        SBC hex_editor_inc_table,Y
      + RTS

hex_editor_inc_with_carry:
        LDX !hex_editor_cursor

        CLC
        LDA !hex_editor_value
        ADC hex_editor_inc_table,X
        STA !hex_editor_value

        CLC
        LDA !hex_editor_address
        ADC hex_editor_inc_table+2,X
        STA !hex_editor_address
        LDA !hex_editor_address+1
        ADC hex_editor_inc_table+4,X
        STA !hex_editor_address+1
        LDA !hex_editor_address+2
        ADC hex_editor_inc_table+6,X
        STA !hex_editor_address+2

        RTS

hex_editor_dec_with_carry:
        LDX !hex_editor_cursor

        SEC
        LDA !hex_editor_value
        SBC hex_editor_inc_table,X
        STA !hex_editor_value

        SEC
        LDA !hex_editor_address
        SBC hex_editor_inc_table+2,X
        STA !hex_editor_address
        LDA !hex_editor_address+1
        SBC hex_editor_inc_table+4,X
        STA !hex_editor_address+1
        LDA !hex_editor_address+2
        SBC hex_editor_inc_table+6,X
        STA !hex_editor_address+2

        RTS

hex_editor_dleft_table:
        db $00,$01,$01,$02,$03,$04,$05,$07,$07

hex_editor_dright_table:
        db $00,$02,$03,$04,$05,$06,$06,$08,$08

hex_editor_inc_mask:
        db $0F,$F0

hex_editor_inc_table:
        db $00,$00,$00,$00,$00,$00,$00,$10,$01,$00,$00,$00,$00,$00,$00

draw_hex_editor:
        STZ $00
        REP #$30                    ; 16bit
        LDA $7F837B                 ; DynStripeImgSize
        TAX
        LDA !hex_editor_address+1
        STA $01

        LDA #$C050
        STA $7F837D,X               ; DynamicStripeImage
        INX #2
        LDA #$1304                  ; 1044Byte
        STA $7F837D,X               ; DynamicStripeImage
        INX #2

    .loop:
        LDA $00
        CMP !hex_editor_address
        BNE +
        LDY #$2800                  ; green
        BRA ++
      + BIT #$0001
        BNE +
        LDY #$3800                  ; white
        BRA ++
      + LDY #$3C00                  ; yellow
     ++ STY $03

        LDA [$00]
        LSR #4
        AND #$000F
        ORA $03
        STA $7F837D,X
        INX #2

        LDA [$00]
        AND #$000F
        ORA $03
        STA $7F837D,X
        INX #2

        INC $00
        LDA #$00FF
        AND $00
        BNE .loop

        LDY #$0001
        LDA !hex_editor_address+2
        JSR .draw
        LDA !hex_editor_address+1
        JSR .draw
        LDA !hex_editor_address
        JSR .draw

        LDA #$38FC
        STA $7F837D,X               ; DynamicStripeImage
        INX #2
        STA $7F837D,X               ; DynamicStripeImage
        INX #2

        LDA !hex_editor_value
        JSR .draw

    .done:
        LDA #$FFFF
        STA $7F837D,X               ; DynamicStripeImage
        TXA
        STA $7F837B                 ; DynStripeImgSize
        SEP #$30                    ; 8bit
        RTS

    .draw:
        PHA
        LSR #4
        AND #$000F
        ORA #$2800                  ; green
        CPY !hex_editor_cursor
        BEQ +
        ORA #$3800                  ; white
      + STA $7F837D,X               ; DynamicStripeImage
        INX #2
        INY

        PLA
        AND #$000F
        ORA #$2800                  ; green
        CPY !hex_editor_cursor
        BEQ +
        ORA #$3800                  ; white
      + STA $7F837D,X               ; DynamicStripeImage
        INX #2
        INY
        RTS

clear_hex_editor:
        REP #$30                    ; 16bit
        LDA $7F837B                 ; DynStripeImgSize
        TAX

        LDA #$C050
        STA $7F837D,X               ; DynamicStripeImage
        INX #2
        LDA #$1304                  ; 1044Byte
        STA $7F837D,X               ; DynamicStripeImage
        INX #2

        LDA #$38FC
        LDY #$0209
    .loop
        STA $7F837D,X
        INX #2
        DEY
        BPL .loop

        TYA
        STA $7F837D,X               ; DynamicStripeImage
        TXA
        STA $7F837B                 ; DynStripeImgSize
        SEP #$30                    ; 8bit
        RTS

; disable mode 7 if in hex editor
bg_mode_7:
        LDA !hex_editor_cursor
        BNE +
        LDA #$07
        STA $2105                   ; HW_BGMODE
        CLC
        RTL
      + SEC
        RTL
