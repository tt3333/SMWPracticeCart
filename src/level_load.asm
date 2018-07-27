ORG $128000

; this code is run once on level load (during the black screen)
level_load:
		PHP
		PHB
		PHK
		PLB
		SEP #$20
		
		JSR check_midway_entrance
		
		LDA !l_r_function
		BEQ .no_l_r_reset
		
		DEC A
		ASL A
		TAX
		JSR (l_r_functions,X)
		BRA .merge
		
	.no_l_r_reset:
		JSR save_room_properties
	
		LDA $141A ; sublevel count
		BNE .merge
		JSR save_level_properties
		
	.merge:
		LDA $148F ; held item flag
		DEC A
		STA !held_item_slot
		STZ !freeze_timer_flag
		LDA #$28
		STA $0F30 ; igt timer
		LDA #$FF
		STA !save_timer_address+2
		
	.done:
		PLB
		PLP
		
		RTL
		
l_r_functions:
		dw setup_room_reset
		dw setup_level_reset
		dw setup_room_advance

; check if we should advance to the midway entrance of the level
check_midway_entrance:
		LDA.L !status_lrreset
		BNE .done
		LDA !l_r_function
		CMP #$02
		BEQ .skip_sublevel_count
		LDA $141A
		AND #$7F
		BNE .done
	.skip_sublevel_count:
		LDA !util_axlr_hold
		AND #%00110000
		CMP #%00110000
		BNE .done
		
		LDA #$01
		STA !start_midway
		
	.done:
		RTS

; prepare the level load if we just did a room reset
setup_room_reset:
		LDA #$01
		STA.L !spliced_run
		
		LDA !restore_room_powerup
		STA $19 ; powerup
		LDA !restore_room_itembox
		STA $0DC2 ; item box
		LDA !restore_room_yoshi
		STA $13C7 ; yoshi color
		STA $0DBA ; ow yoshi color
		STA $0DC1 ; persistent yoshi
		LDA !restore_room_coins
		STA $0DBF ; coins
		LDA !restore_room_takeoff
		STA $149F ; takeoff
		LDA !restore_room_dragoncoins
		STA $1420 ; dragon coins
		LDA !restore_room_igt
		STA $0F31
		LDA !restore_room_igt+1
		STA $0F32
		LDA !restore_room_igt+2
		STA $0F33 ; in game timer
		LDA !restore_level_timer_minutes
		STA !level_timer_minutes
		LDA !restore_level_timer_seconds
		STA !level_timer_seconds
		LDA !restore_level_timer_frames
		STA !level_timer_frames
		DEC $141A ; sublevel count
		LDA !restore_room_xpos
		STA $D1 ; mario x position low byte
		LDA !restore_room_xpos+1
		STA $D2 ; mario x position high byte
		
		LDX #$03
	.loop_tables:
		LDA !restore_room_boo_ring,X
		STA $0FAE,X ; boo ring angles
		LDA !restore_room_rng,X
		STA $148B,X ; rng
		DEX
		BPL .loop_tables
		
		LDA !restore_room_item
		BEQ .no_item
		STA $9E ; sprite 0 id
		LDA #$0B ; carried
		STA $14C8 ; sprite 0 status
		
	.no_item:
		JSR restore_common_aspects
		RTS

; prepare the level load if we just did a level reset
setup_level_reset:
		LDA #$00
		STA.L !spliced_run
		
	.begin:
		LDA !restore_level_powerup
		STA $19 ; powerup
		LDA !restore_level_itembox
		STA $0DC2 ; item box
		LDA !restore_level_yoshi
		STA $13C7 ; yoshi color
		STA $0DBA ; ow yoshi color
		STA $0DC1 ; persistent yoshi
		STZ $0DBF ; coins
		STZ $149F ; takeoff
		LDA !restore_level_igt
		STA $0F31
		STZ $0F32
		STZ $0F33 ; in game timer
		STZ $1B95 ; yoshi heaven flag
		STZ $1420 ; dragon coins
		STZ $2A ; mode 7 center
		STZ $13CE ; midway flag
		STZ !level_timer_minutes
		STZ !level_timer_seconds
		STZ !level_timer_frames
		STZ !record_used_powerup
		STZ !record_used_cape
		STZ !record_used_yoshi
		STZ !record_used_orb
		STZ !record_lunar_dragon
		LDA !restore_level_xpos
		STA $D1 ; mario x position low byte
		LDA !restore_level_xpos+1
		STA $D2 ; mario x position high byte
		
		; set msb so it's not 00, which is a special case for entering the level
		; we'll turn this byte into fnnnnnnn, f = 0 if just entered level, n = sublevel count
		LDA #$80 
		STA $141A ; sublevel count
		
		LDX #$03
	.loop_tables:
		LDA !restore_level_boo_ring,X
		STA $0FAE,X ; boo ring angles
		STZ $148B,X ; rng
		DEX
		BPL .loop_tables
		
		JSR restore_common_aspects
		
		LDA $13BF ; translevel
		LDX #$05
	.loop:
		CMP water_entrance_levels,X
		BEQ .disable_lock
		DEX
		BPL .loop
		BRA .done
	.disable_lock:
		STZ $9D ; sprite lock
		
	.done:
		RTS

; translevels that start with an underwater pipe entrance
; and coincidentally start with sprite lock OFF for some reason
water_entrance_levels:
		db $0A,$0B,$11,$18,$44,$54

; prepare the level load if we just did a room advance
setup_room_advance:
		LDA #$01
		STA.L !spliced_run
		
		LDA !restore_room_xpos
		PHA
		LDA !restore_room_xpos+1
		PHA
		
		; bad form but this bug sucks and I'm done dealing with it
		; hey, this is assembly. if it works, it's good Kappa b
		JSR save_room_properties_but_not_xpos
		JSR restore_common_aspects
		
		PLA
		STA $D2
		PLA
		STA $D1
				
		RTS

; restore things that are common to both room and level resets
restore_common_aspects:
		STZ $14A3 ; punch yoshi timer
		STZ $36
		STZ $37 ; mode 7 angle
		STZ $14AF ; on/off switch
		STZ $1432 ; coin snake
		STZ $1B9F ; reznor floor
		STZ $14B1
		STZ $14B5
		STZ $14B6 ; bowser timers
		LDA $0D9B ; boss flag
		STZ $1434 ; keyhole timer
		STZ $1493 ; end level timer
		CMP #$C1
		BNE .not_bowser
		LDA #$02
		STA $1884 ; bowser HP
	.not_bowser:
		STZ $1496
		STZ $1497 ; mario animation timers
		LDA #$FF
		STA $1B9D ; layer 3 tide timer
		STZ $1B9A ; scrolling background
		STZ !room_timer_minutes
		STZ !room_timer_seconds
		STZ !room_timer_frames
		STZ !pause_timer_minutes
		STZ !pause_timer_seconds
		STZ !pause_timer_frames
		
		LDX #$03
	.loop_camera:
		STZ $1A,X ; layer 1 x/y positions
		STZ $1E,X ; layer 2 x/y positions
		STZ $26,X ; layer 2 - layer 1 x/y positions
		DEX
		BPL .loop_camera
		
		REP #$10
		LDX #$017F
	.loop_memory:
		STZ $19F8,X ; item memory
		DEX
		BPL .loop_memory
		SEP #$10
		RTS
		
; save everything after entering a new room
save_room_properties:
		LDA $D1 ; mario x position low byte
		STA !restore_room_xpos
		LDA $D2 ; mario x position high byte
		STA !restore_room_xpos+1
	.but_not_xpos:
		LDA $19 ; powerup
		STA !restore_room_powerup
		LDA $0DC2 ; item box
		STA !restore_room_itembox
		LDA $187A ; riding yoshi flag
		BNE .yoshi_exists
		STZ !restore_room_yoshi
		BRA .yoshi_done
	.yoshi_exists:
		LDA $13C7 ; yoshi color
		STA !restore_room_yoshi
	.yoshi_done:
		LDA $149F ; takeoff
		STA !restore_room_takeoff
		LDA $0DBF ; coins
		STA !restore_room_coins
		LDA $1420 ; dragon coins
		STA !restore_room_dragoncoins
		
		LDX #$0B
	.loop_item:
		LDA $14C8,X ; sprite status
		CMP #$0B ; carried
		BEQ .restore_item
		DEX
		BPL .loop_item
		STZ !restore_room_item
		BRA .item_done
	.restore_item:
		LDA $9E,X ; sprite id
		STA !restore_room_item
	.item_done:

		LDX #$03
	.loop_tables:
		LDA $0FAE,X ; boo ring angle
		STA !restore_room_boo_ring,X
		LDA $148B,X ; rng
		STA !restore_room_rng,X
		DEX
		BPL .loop_tables
		
		LDX #$02
	.loop_time:
		LDA $0F31,X ; timer
		STA !restore_room_igt,X
		DEX
		BPL .loop_time
		
		LDA !level_timer_minutes
		STA !restore_level_timer_minutes
		LDA !level_timer_seconds
		STA !restore_level_timer_seconds
		LDA !level_timer_frames
		STA !restore_level_timer_frames
		STZ !room_timer_minutes
		STZ !room_timer_seconds
		STZ !room_timer_frames
		STZ !pause_timer_minutes
		STZ !pause_timer_seconds
		STZ !pause_timer_frames
		
		RTS
		
; add the frame count stored in A to the timer
add_many_to_timer:
		CLC
		ADC !level_timer_frames
	.check_frames:
		CMP #$3C
		BCS .carry_frame
		STA !level_timer_frames
		LDA !level_timer_seconds
		BRA .check_seconds
	.carry_frame:
		SEC
		SBC #$3C
		INC !level_timer_seconds
		BRA .check_frames
	.check_seconds:
		CMP #$3C
		BCS .carry_seconds
		STA !level_timer_seconds
		LDA !level_timer_minutes
		BRA .check_minutes
	.carry_seconds:
		SEC
		SBC #$3C
		INC !level_timer_minutes
		BRA .check_seconds
	.check_minutes:
		CMP #$0A
		BCS .timer_overflow
		STA !level_timer_minutes
		RTL
	.timer_overflow:
		LDA #$09
		STA !level_timer_minutes
		LDA #$3B
		STA !level_timer_seconds
		STA !level_timer_frames
		RTL
		
; save everything after entering a new level
save_level_properties:
		LDA $19 ; powerup
		STA !restore_level_powerup
		LDA $0DC2 ; item box
		STA !restore_level_itembox
		LDA $187A ; riding yoshi flag
		BNE .yoshi_exists
		STZ !restore_level_yoshi
		BRA .yoshi_done
	.yoshi_exists:
		LDA $13C7 ; yoshi color
		STA !restore_level_yoshi
	.yoshi_done:
		LDA $D1 ; mario x position low byte
		STA !restore_level_xpos
		LDA $D2 ; mario x position high byte
		STA !restore_level_xpos+1
		
		LDX #$03
	.loop_tables:
		LDA $0FAE,X ; boo ring angle
		STA !restore_level_boo_ring,X
		DEX
		BPL .loop_tables
		
		STZ $0DBF ; coins
		STZ !level_timer_minutes
		STZ !level_timer_seconds
		STZ !level_timer_frames
		STZ !pause_timer_minutes
		STZ !pause_timer_seconds
		STZ !pause_timer_frames
		STZ !record_used_powerup
		STZ !record_used_cape
		STZ !record_used_yoshi
		STZ !record_used_orb
		STZ !record_lunar_dragon
		STZ !level_finished
		
		RTS

; copy screen exit to backup registers
; this isn't done in the above code because $17BB is only available during the load routine
level_load_exit_table:
		CPX #$20
		BCC .no_fix
		LDX #$00
	.no_fix:
		LDA $1B93
		STA !recent_secondary_flag
		LDA $19B8,X ; exit table
		STA $17BB ; exit backup
		STA !recent_screen_exit
		RTL

; save starting time to backup register
; this isn't done in the above code because X is only the level index during the load routine
; also check for lemmy's castle region difference
level_load_timer:
		LDA.L !status_region
		BEQ .continue
		LDA $13BF ; translevel
		CMP #$40 ; lemmy's castle
		BNE .continue
		LDA #$03
		BRA .merge
	.continue:
		LDA $0584D7,X ; timer table
	.merge:
		STA !restore_level_igt
		RTL

; load $01 - $03 with source of music bank
; X = music bank 0-2
set_music_bank:
		PHB
		PHK
		PLB
		
		LDA.L !status_music
		BEQ .not_muted
		LDA muted_music_location
		STA $00
		LDA muted_music_location+1
		STA $01
		LDA muted_music_location+2
		STA $02
		BRA .done
	
	.not_muted:
		STX $00
		TXA
		ASL A
		CLC
		ADC $00
		TAX
		LDA music_bank_locations,X
		STA $00
		LDA music_bank_locations+1,X
		STA $01
		LDA music_bank_locations+2,X
		STA $02
		
	.done
		PLB
		RTL

music_bank_locations:
		dl $0E98B1,$0EAED6,$03E400
muted_music_location:
		dl muted_music_bank
muted_music_bank:
		incbin "bin/music_empty_bank.bin"

; upload the graphics for the sprite slots and dynmeter, if they are enabled
load_slots_graphics:
		PHP
		REP #$10
		SEP #$20
		LDA.L !status_slots
		BNE .continue
		LDA.L !status_dynmeter
		BEQ .done
		
	.continue:
		LDY #$0080
		LDA #$80
		STA $2115 ; vram increment
		PHK
		PLA
		
		LDX #$6440
		STX $2116 ; vram address
		LDX #sprite_slots_graphics
		JSL load_vram
		
		LDX #$6540
		STX $2116 ; vram address
		LDX #sprite_slots_graphics+$80
		JSL load_vram
		
		LDX #$6680
		STX $2116 ; vram address
		LDX #sprite_slots_graphics+$100
		JSL load_vram
		
		LDX #$6780
		STX $2116 ; vram address
		LDX #sprite_slots_graphics+$180
		JSL load_vram
		
	.done:
		PLP
		RTL

; upload the tiles used for the timer during the bowser fight
upload_bowser_timer_graphics:
		PHP
		SEP #$20
		REP #$10
		
		LDA $0D9B ; boss flag
		CMP #$C1
		BNE .done
		
		LDA #$80
		STA $2100 ; force blank
		STZ $4200 ; nmi disable
		
		LDA #$80
		STA $2115 ; vram properties
		PHK
		PLA
		LDY #$0140
		LDX #$6A80
		STX $2116 ; vram address
		LDX #sprite_slots_graphics
		JSL load_vram
		
		LDY #$00C0
		LDX #$6B80
		STX $2116 ; vram address
		LDX #sprite_slots_graphics+$140
		JSL load_vram
		
		LDY #$0080
		LDX #$6980
		STX $2116 ; vram address
		LDX #sprite_slots_graphics+$200
		JSL load_vram
		
		LDA #$81
		STA $4200 ; nmi enable
		LDA #$0F
		STA $2100 ; exit force blank
		
	.done:
		PLP
		RTL
		
sprite_slots_graphics:
		incbin "bin/sprite_slots_graphics.bin"

; fix the graphics upload routine for reznor, iggy, & larry
; this really should have been done already, they were just lucky that
; the last thing they uploaded ended at $7FFF :p
fix_iggy_larry_graphics:
		STZ $2116
		STZ $2117 ; vram address write
		LDY #$0000
		LDX #$03FF
		RTL

; at the very start of level loading, latch the apu timer so we can figure out the load time
latch_apu:
		PHP
		REP #$20
	.bounce:
		LDA $2140
		BEQ .bounce
		STA !apu_timer_latch
		PLP
		RTL

; complete the level load by updating the timer with the calculated load time
do_final_loading:
		LDA $141A ; sublevel count
		BEQ .final_level_reset
		LDA !l_r_function
		ASL A
		TAX
		JMP (.final_l_r_functions,X)
		
	.final_l_r_functions:
		dw .final_normal_advance
		dw .final_room_reset
		dw .final_level_reset
		dw .final_room_advance
		dw .final_level_reset
		
	.final_normal_advance:
	.final_room_advance:
		JSL calculate_load_time
	.final_room_reset:
		LDA !apu_timer_difference
		JSL add_many_to_timer
	.final_level_reset:
		
		STZ !l_r_function
		RTL

; at the very end of level loading, latch the apu timer and calculate the load time
calculate_load_time:
		REP #$20
	.bounce:
		LDA $2140
		BEQ .bounce
		SEC
		SBC !apu_timer_latch ; divide difference by 0x1C0
		STA $4204 ; dividend
		LDX #$07
		STX $4206 ; divisor
		NOP #10
		LDA $4214 ; quotient
		LSR #6
		CLC
		ADC #$001F ; add #$1F to account for the fade in time
		LDX $2A ; mode 7 center
		BNE .done
		CLC
		ADC #$001F ; add #$1F to account for the fade out time
	.done:
		SEP #$20
		STA !apu_timer_difference
		RTL

; load a different sprite pointer depending on region
load_level_sprite_ptr:
		LDA $EC00,Y
		STA $CE
		LDA $EC01,Y
		STA $CF
		LDA #$07
		STA $D0
		LDA.L !status_region
		BEQ .done
		CPY #$01EE ; ghost ship
		BNE .done
		LDA #$3F
		STA $CE
		LDA #$F9
		STA $CF
		LDA #$12
		STA $D0
	.done:
		RTL
		
; load a different layer 1 pointer depending on region
load_level_layer1_ptr:
		LDA.L !status_region
		BNE .j
		LDA $E000,Y
		STA $65
		LDA $E001,Y
		STA $66
		LDA $E002,Y
		STA $67
		BRA .done
	.j:
		PHX
		TYX
		LDA.L j_level_layer1_ptrs,X
		STA $65
		LDA.L j_level_layer1_ptrs+1,X
		STA $66
		LDA.L j_level_layer1_ptrs+2,X
		STA $67
		PLX
	.done:
		RTL

; initialize status bar properties
init_statusbar_properties:
		PHP
		PHB
		SEP #$30
		
		LDX #$A0
		LDA #$38
	-	STA $0904,X
		DEX
		BNE -
		
		LDA #$7E
		STA $02
		LDA #$09
		STA $01
		
		LDA #$70
		PHA
		PLB
		
		LDY #$5C
		
	-	LDA.W !statusbar_meters+3,Y
		CLC
		ADC #$05 ; 7E0905 - temporary mirror for statusbar properties (shared with fade palette)
		STA $00
		
		LDA.W !statusbar_meters,Y
		CMP #$13
		BCS +
		ASL A
		TAX
		JSR (.meter,X)
	+	DEY #4
		BPL -
		
		PHK
		PLB
		
		LDX #$04
	.loop_tile_lines:
		LDA #$00
		STA $4310
		LDA #$19
		STA $4311
		LDA #$7E
		STA $4314
		LDA #$20
		STA $4315
		LDA #$00
		STA $4316
		
		LDA #$80
		STA $2115
		LDA .line_pos,X
		STA $2116
		LDA #$50
		STA $2117
		LDA .tiles_low,X
		STA $4312
		LDA .tiles_high,X
		STA $4313
		LDA #$02
		STA $420B
		DEX
		BPL .loop_tile_lines
		
		PLB
		PLP
		RTL
		
	.line_pos:
		db $00,$20,$40,$60,$80
	.tiles_high:
		db $09,$09,$09,$09,$09
	.tiles_low:
		db $05,$25,$45,$65,$85
	
	.meter:
		dw .nothing
		dw .item_box
		dw .mario_speed
		dw .mario_takeoff
		dw .mario_pmeter
		dw .yoshi_subpixel
		dw .held_subpixel
		dw .lag_frames
		dw .timer_level
		dw .timer_room
		dw .timer_stopwatch
		dw .coin_count
		dw .in_game_time
		dw .slowdown
		dw .input_display
		dw .name
		dw .movie_recording
		dw .memory_7e
		dw .memory_7f
		
	.mario_speed:
		LDA #$2C
		JMP .store_2
		
	.memory_7e:
	.mario_takeoff:
		LDA #$38
		JMP .store_2
		
	.mario_pmeter:
	.yoshi_subpixel:
		LDA #$28
		JMP .store_2
		
	.memory_7f:
	.held_subpixel:
		LDA #$3C
		JMP .store_2
		
	.lag_frames:
		LDA #$2C
		JMP .store_5
		
	.timer_level:
		LDA.W !statusbar_meters+1,Y
		CMP #$02
		PHP
		LDA #$3C
		PLP
		BEQ .store_6
		JMP .store_8
		
	.timer_room:
		LDA.W !statusbar_meters+1,Y
		CMP #$02
		PHP
		LDA #$38
		PLP
		BEQ .store_5
		JMP .store_7
		
	.timer_stopwatch:
		LDA.W !statusbar_meters+1,Y
		CMP #$02
		PHP
		LDA #$28
		PLP
		BEQ .store_5
		JMP .store_7
		
	.coin_count:
		LDA #$3C
		STA [$00]
		INC $00
		LDA.W !statusbar_meters+1,Y
		PHP
		LDA #$38
		PLP
		BEQ .store_2
		JMP .store_1
		
	.in_game_time:
		LDA #$3C
		STA [$00]
		INC $00
		STA [$00]
		INC $00
		STA [$00]
		INC $00
		LDA.W !statusbar_meters+1,Y
		CMP #$01
		PHP
		LDA #$38
		PLP
		BEQ .store_2
		BCS .store_1
		RTS
	
	.slowdown:
		LDA #$2C
		JMP .store_1
		
	.name:
		PHB
		PHK
		PLB
		LDA !in_playback_mode
		BEQ +
		PLB
		LDA #$2C
		JMP .store_4
	+	PLB
		LDA.W !statusbar_meters+1,Y
		TAX
		LDA.L name_colors,X
		JMP .store_4
		
	.store_8:
		STA [$00]
		INC $00
	.store_7:
		STA [$00]
		INC $00
	.store_6:
		STA [$00]
		INC $00
	.store_5:
		STA [$00]
		INC $00
	.store_4:
		STA [$00]
		INC $00
	.store_3:
		STA [$00]
		INC $00
	.store_2:
		STA [$00]
		INC $00
	.store_1:
		STA [$00]
		RTS
		
	.movie_recording:
		LDA.W !statusbar_meters+1,Y
		BEQ +
		LDA #$2C
		JMP .store_3
	+	LDA #$28
		STA [$00]
		INC $00
		STA [$00]
		INC $00
		STA [$00]
		INC $00
		STA [$00]
		INC $00
		STA [$00]
		INC $00
		STA [$00]
		INC $00
		LDA #$48
		STA [$00]
		RTS
	
	.input_display:
		LDA.W !statusbar_meters+1,Y
		ASL A
		TAX
		JMP (.input_properties,X)
		
	.input_properties:
		dw .wide
		dw .compact_horiz
		dw .compact_horiz
		dw .compact_vert
		dw .compact_vert
		
	.wide:
		LDA #$28
		INC $00
		STA [$00]
		INC $00
		INC $00
		STA [$00]
		INC $00
		STA [$00]
		INC $00
		INC $00
		STA [$00]
		LDA $00
		CLC
		ADC #$1A
		STA $00
		LDA #$28
		STA [$00]
		INC $00
		INC $00
		STA [$00]
		INC $00
		INC $00
		INC $00
		STA [$00]
		INC $00
		INC $00
		STA [$00]
		LDA $00
		CLC
		ADC #$1A
		STA $00
		LDA #$28
		STA [$00]
		INC $00
		INC $00
		STA [$00]
		INC $00
		STA [$00]
		INC $00
		INC $00
		STA [$00]
		RTS
		
	.compact_horiz:
		LDA #$28
		STA [$00]
		INC $00
		STA [$00]
		INC $00
		STA [$00]
		INC $00
		STA [$00]
		INC $00
		STA [$00]
		INC $00
		STA [$00]
		LDA $00
		CLC
		ADC #$1B
		STA $00
		LDA #$28
		STA [$00]
		INC $00
		STA [$00]
		INC $00
		STA [$00]
		INC $00
		STA [$00]
		INC $00
		STA [$00]
		INC $00
		STA [$00]
		RTS
		
	.compact_vert:
		LDA #$28
		STA [$00]
		INC $00
		STA [$00]
		INC $00
		STA [$00]
		LDA $00
		CLC
		ADC #$1E
		STA $00
		LDA #$28
		STA [$00]
		INC $00
		STA [$00]
		INC $00
		STA [$00]
		LDA $00
		CLC
		ADC #$1E
		STA $00
		LDA #$28
		STA [$00]
		INC $00
		STA [$00]
		INC $00
		STA [$00]
		LDA $00
		CLC
		ADC #$1E
		STA $00
		LDA #$28
		STA [$00]
		INC $00
		STA [$00]
		INC $00
		STA [$00]
		RTS
	
	.item_box:
		PHD
		PEA $0905
		PLD
		
		LDA #$38
		STA $2E
		STA $2F
		STA $30
		STA $4E
		STA $6E
		LDA #$78
		STA $31
		STA $51
		STA $71
		LDA #$B8
		STA $8E
		STA $8F
		STA $90
		LDA #$F8
		STA $91
		
		PLD
	.nothing:
		RTS

name_colors:
		db $28,$38,$3C

ORG $12F000

j_levels:
		incbin "bin/j_levels.bin"
j_level_layer1_ptrs:
		incbin "bin/j_level_layer1_ptrs.bin"