;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2021 Daniel Serpell
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License along
; with this program.  If not, see <http://www.gnu.org/licenses/>
;

; State machine actions (external subs)
; -------------------------------------

        .export         E_REM, E_EOL, E_NUMBER_WORD, E_NUMBER_BYTE
        .export         E_PUSH_LT, E_POP_LOOP, E_POP_REPEAT
        .export         E_POP_IF, E_ELSEIF, E_EXIT_LOOP
        .export         E_POP_WHILE, E_POP_FOR, E_POP_PROC_DATA, E_POP_PROC_2
        .export         E_CONST_STRING
        .export         E_VAR_CREATE, E_VAR_WORD, E_VAR_SEARCH
        .export         E_VAR_SET_TYPE, E_LABEL_SET_TYPE
        .export         E_LABEL, E_LABEL_DEF
        .export         E_PUSH_VAR, E_POP_VAR
        .exportzp       VT_WORD, VT_STRING, VT_FLOAT, VT_UNDEF
        .exportzp       VT_ARRAY_WORD, VT_ARRAY_BYTE, VT_ARRAY_STRING, VT_ARRAY_FLOAT
        .exportzp       LT_PROC_DATA, LT_PROC_2, LT_DO_LOOP, LT_REPEAT, LT_WHILE_1, LT_WHILE_2, LT_FOR_1, LT_FOR_2, LT_EXIT, LT_IF, LT_ELSE, LT_ELIF
        .importzp       loop_sp, bpos, bptr, tmp1, tmp2, tmp3, opos
        .exportzp       reloc_addr
        ; From runtime.asm
        .import         read_word
        ; From vars.asm
        .import         var_search, name_new
        .import         list_search
        .importzp       var_namelen, label_count, var_count
        ; From alloc.asm
        .import         alloc_laddr
        .importzp       prog_ptr, laddr_ptr, laddr_buf, var_ptr, label_ptr, label_buf
        ; From parser.asm
        .import         parser_error, parser_skipws, parser_emit_byte, parser_inc_opos
        ; From error.asm
        .importzp       ERR_LOOP

.ifdef FASTBASIC_FP
        ; Exported only in Floating Point version
        .export         E_NUMBER_FP

read_fp = AFP
.endif ; FASTBASIC_FP

        .include        "atari.inc"
;----------------------------------------------------------
        ; Types of variables
        .enum
                ; ODD variables are created on assignments, so the set type rule fails.
                ; EVEN variables are created on "DIM", so the set_type rule succeeds
                VT_UNDEF      = 0
                VT_WORD       = 1
                VT_ARRAY_WORD = 2
                VT_ARRAY_BYTE = 4
                VT_STRING     = 5
                VT_ARRAY_STRING = 6
                VT_ARRAY_FLOAT = 8
                VT_FLOAT      = $FB ; Value > 128 to signal 6bytes per variable!
        .endenum
        ; Types of labels
        .enum
                LBL_UNDEF       = 0
                LBL_PROC
        .endenum
        ; Types of loops
        .enum
                ; Loop-Types: used to keep the type of loop in the loop
                ;             parsing stack.
                ;
                ; The numeric value is used to signal if we need to push
                ; a destination address (reserving 2 bytes of program data),
                ; and if the loop should be ignored by the EXIT statement.
                ;
                ;                     ; EXIT?   PUSH?
                ;                     ; bit-7   bit-6
                LT_EXIT               ; error   yes
                LT_PROC_DATA          ; error   yes
                LT_FOR_2              ; yes     yes
                LT_LAST_JUMP = 63
                LT_PROC_2             ; yes     no
                LT_DO_LOOP            ; yes     no
                LT_REPEAT             ; yes     no
                LT_WHILE_1            ; yes     no

                LT_WHILE_2= 128       ; ignore  yes
                LT_IF                 ; ignore  yes
                LT_ELSE               ; ignore  yes
                LT_ELIF               ; ignore  yes

                LT_FOR_1 = 128 + 64   ; ignore  no
        .endenum

;----------------------------------------------------------
; Use cassette buffer for loop stack, max 128 bytes
; Note that at $480 we store the interpreter stack.
loop_stk        =       $400


;----------------------------------------------------------
        .zeropage
        ; Relocation amount
reloc_addr:     .res    2

        .code

; Removes one token from output, returns it
.proc   get_last_tok
        dec     opos
        ldy     opos
        lda     (prog_ptr),y
        rts
.endproc

; Returns the current code pointer in AX
.proc   get_codep
        lda     prog_ptr
        ldx     prog_ptr+1
        clc
        adc     opos
        bcc     ok
        inx
        clc
ok:     rts
.endproc

; Pops code pointer from loop stack and emit
.proc   pop_emit_addr
        jsr     pop_codep
.endproc        ; Fall through
; Emits address into codep, relocating if necessary.
.proc   emit_addr
        clc
        adc     reloc_addr
        pha
        txa
        adc     reloc_addr+1
        tax
        pla
.endproc        ; Fall through
;
; Emits 16bit AX into codep
.proc   emit_AX
        clc
        jsr     parser_emit_byte
        txa
        jmp     parser_emit_byte
.endproc

; Parser external subs
.proc   E_REM
        ; Accept all the line
        ldy     bpos
loop:   iny
        lda     (bptr), y
        cmp     #$9b
        bne     loop
        sty     bpos
ok:     clc
        rts
.endproc

.proc   E_EOL
        jsr     parser_skipws
        lda     (bptr),y
        cmp     #$9b ; Atari EOL
        beq     E_REM::ok
        cmp     #$27 ; "'" starts a comment
        beq     E_REM::loop
        cmp     #':' ; ':' separates commands
        beq     E_REM::ok
xit:    sec
        rts
.endproc

.proc   E_NUMBER_WORD
        jsr     parser_skipws

        lda     (bptr), y
        eor     #'$'
        beq     read_hex

        jsr     read_word

.ifdef FASTBASIC_FP
        bcs     E_EOL::xit

        ; In FP version, fails if number is followed by decimal dot
        sta     tmp1
        lda     (bptr), y
        cmp     #'.'
        beq     E_EOL::xit
        lda     tmp1

        sty     bpos
        jmp     emit_AX
.else
        bcc     xit_emit
        rts
.endif ; FASTBASIC_FP

read_hex:
        ; We have A==0 here
        tax             ; X = low-part of result
        stx     tmp1+1  ; tmp1+1: hi-part of result

nloop:
        ; Read next hex digit
        iny
        lda     (bptr),y
        eor     #'0'
        cmp     #10
        bcc     digit

        sbc     #'A'^'0'
        cmp     #6
        bcs     xit ; Not an hex number
        adc     #10 ; set to range 10-15

digit:
        sta     tmp1    ; and save digit

        ; Multiply tmp by 16
        txa
        ldx     #4
:       asl
        rol     tmp1+1
        bcs     ret     ; Exit with C = 1 on overflow
        dex
        bne     :-

        ; Add new digit
        ora     tmp1
        tax
        bcc     nloop

ret:
        rts

xit:
        ; Check that we consumed at least one character after the "$"
        dey
        cpy     bpos
        beq     ret     ; Exit with C = 1 (if Y-1 == bpos, C = 1)
        iny

        txa
        ldx     tmp1+1
xit_emit:

        sty     bpos
        jmp     emit_AX
.endproc

.proc   E_NUMBER_BYTE
        jsr     E_NUMBER_WORD
        bcs     xit
        dec     opos
        cpx     #1
xit:    rts
.endproc

.proc   E_CONST_STRING
        ; Get characters until a '"' - emit all characters read!
        ldx     #0
        ; Skip one byte (string length), and store original output position into tmp1
        jsr     parser_emit_byte
        sty     tmp1
nloop:
        ; Check length
        ldy     bpos
        lda     (bptr), y
        cmp     #'"'
        beq     eos
        cmp     #$9b
        beq     xrts   ; Exit with error, C = 1 on EQ.
        ; Store
store:  inx
        inc     bpos
        jsr     parser_emit_byte
        bne     nloop  ; Jump always

eos:    iny
        lda     (bptr), y
        inc     bpos
        cmp     #'"'    ; Check for "" to encode one ".
        beq     store
        ; Store token and length
eos_ok: ldy     tmp1
        txa
        sta     (prog_ptr), y
        clc
xrts:   rts
.endproc

; Following two routines are only used in FP version
.ifdef FASTBASIC_FP
.proc   E_NUMBER_FP
        jsr     read_fp
        bcs     E_CONST_STRING::xrts
        lda     FR0
        ldx     FR0+1
        jsr     emit_AX
        lda     FR0+2
        ldx     FR0+3
        jsr     emit_AX
        lda     FR0+4
        ldx     FR0+5
        jmp     emit_AX
.endproc
.endif ; FASTBASIC_FP

; Variable matching.
; The parser calls the routine to check if there is a variable
; with the correct type
.proc   E_VAR_SEARCH
        jsr     get_last_tok    ; Get variable TYPE from last token
        .byte   $2C   ; Skip 2 bytes over next "LDA"
.endproc        ; Fall through
.proc   E_VAR_WORD
        lda     #VT_WORD
        sta     tmp3    ; Store variable type
        ; Check if we have a valid name - this exits on error!
        ; Search existing var
        jsr     var_search
        bcs     exit
        cmp     tmp3
        beq     emit_varn
not_found:
        sec
exit:
        rts
.endproc

; Creates a new variable, with no type (the type will be set by parser next)
.proc   E_VAR_CREATE
        ; Check if we have a valid name - this exits on error!
        ; Search existing var
        jsr     var_search
        bcc     E_VAR_WORD::not_found ; Exit with error if already exists
        ; Create new variable - exits on error
        ldx     #var_ptr - prog_ptr
        jsr     name_new
        ldx     var_count
        inc     var_count
        ; Fall through
.endproc
        ; Emits the variable, advancing pointers.
.proc   emit_varn
        ; Store VARN
        txa
        jsr     parser_emit_byte
        ; Fall through
.endproc
        ; Advances variable name in source pointer
.proc   advance_varn
        lda     bpos
        clc
        adc     var_namelen
        sta     bpos
        clc
        rts
.endproc

; Sets the type of a variable - variable number and new type must be in the stack:
.proc   E_VAR_SET_TYPE
        jsr     get_last_tok    ; Get variable TYPE from last token

.ifdef FASTBASIC_FP
        .assert VT_FLOAT & 128 , error, "VT_FLOAT must be > 127"
        bpl     no_float        ; float is > 127

        ; Increment variable count to allocate 4 more bytes
        inc     var_count
        inc     var_count

no_float:
.endif ; FASTBASIC_FP

        ldy     #$FF
        dec     var_ptr+1
        sta     (var_ptr), y    ; Store to (var_ptr - 1)
        inc     var_ptr+1

        ; Return error on "odd" variable types, this is needed for the parser
        ; to retry after creating the variable:
        lsr
xit:    rts
.endproc

; Support for labels (DATA/PROC/EXEC)
; ------------------------------
;
; We keep two lists:
;  - label_buf/ptr: a list of all the labels, sorted by the label number.
;                   one byte for each character in the name, last byte with
;                   bit 7 set.
;                   After the name there is one byte with the label type,
;                   same as var-types.
;
;  - laddr_buf/ptr: a list with each label reference:
;                   byte 0: the label number,
;                   byte 1: the type of reference,
;                   byte 2: high byte of address of reference,
;                   byte 3: low byte of address of reference.
;
;  The type of references are:
;                   0 : A call (EXEC) of the label, to be patched with the
;                       correct address when known.
;                   1 : Same as above, but already patched (resolved).
;                 128 : The address of a label (target).
;
; Each time a label is referenced (EXEC), the laddr list is searched for an
; entry with the address (type = 128). If no entry is found, a new entry of
; type 0 is created with the address to be patched.
;
; Each time a label is defined (PROC), the laddr list is searched for any
; entry with type = 0 to patch the correct address and the type is set to 1.
; Also, a new entry is created with the PROC address and type = 128.
;
; At end of parsing, we check that all entries in the laddr list are <> 0.
;
; Label definition search/create
.proc   E_LABEL_DEF
        lda     #0              ; Type of label: undefined
        jsr     label_create

        ; Fills all undefined labels with current position:
        bcs     nfound

        ; If we found a *definition* for the label, error out (label already
        ; defined).
cloop:  bmi     xit_label_err

        ; Write current codep to AX
        jsr     patch_codep

        ; Mark the label as "resolved", so we can show error if not all
        ; labels are defined after parsing ends.
        tya     ; Y = 1 from patch_codep
        sta     (tmp1), y

        ; Continue searching the address list
next:   jsr     next_laddr
        bcc     cloop

        ; No more entries, adds our address as a "definition" (A = 128)
nfound:
        lda     #128
        jsr     add_laddr_list
        ; Ok, advance parsing pointer with the label length
        bcc     advance_varn
        rts
.endproc

; Sets the type of the last label defined
.proc   E_LABEL_SET_TYPE
        jsr     get_last_tok    ; Get variable TYPE from last token

        ldy     #$FF
        dec     label_ptr+1
        sta     (label_ptr), y  ; Store to (label_ptr - 1)
        inc     label_ptr+1
        clc
xit:    rts
.endproc

        ; Create a label if not exists and starts searching in the label
        ; address list.
        ;
        ; This jumps to next_laddr, so it returns the same values.
.proc   label_create
        ; Check if we have a valid name - this exits on error!
        sta     tmp3    ; Store label type
        ldx     #label_buf - prog_ptr
        ldy     label_count
        jsr     list_search
        bcs     do_create
        ; Check if type is compatible
        cmp     tmp3
        beq     no_create       ; Yes, search address
xit_pop_2:              ; Exit from caller with error
        pla
        pla
::xit_label_err:
        sec
        rts

do_create:
        ; See if we need to create it
        lda     tmp3
        bne     xit_pop_2
        ; Create a new label
        ldx     #label_ptr - prog_ptr
        jsr     name_new
        ldx     label_count
        inc     label_count
no_create:
        lda     laddr_buf
        ldy     laddr_buf+1
        sty     tmp1+1
        stx     laddr_search_num
        bne     laddr_search_start      ; Assume laddr_buf+1 is never 0
.endproc

        ; Search next matching label in the label address table.
        ;
        ; Returns C=1 if there are no more address stored.
        ;
        ; Returns C=0, AX = address of label or reference, Y = type.
        ; If the label is already defined, Y = 128 and the N flag is
        ; set on return.
        ;
        ; On first call, laddr_search_num must be set to the number of
        ; the label to be searched (as returned by "label_search").
.proc   next_laddr
loop:
        lda     tmp1
        clc
        adc     #4
        bcc     comp
        inc     tmp1+1
comp:
        sta     tmp1
        cmp     laddr_ptr
        lda     tmp1+1
        sbc     laddr_ptr+1
        bcs     xit             ; Exit if no more addresses found

        ldy     #0
        lda     (tmp1), y       ; Read label number and compare
cpnum:  eor     #$00
        bne     loop            ; Not our label, retry
        iny
        lda     (tmp1), y       ; Read label address type
        php                     ; and store flags in stack
        iny
        lda     (tmp1), y       ; Yes, read hi address in X
        tax
        iny
        lda     (tmp1), y       ; lo address in A
        plp                     ; And type in P
xit:    rts
::laddr_search_num = cpnum + 1
::laddr_search_start = comp
.endproc

; Adds a label address pointer to the list
.proc   add_laddr_list
        pha

        lda     laddr_ptr
        sta     tmp2
        lda     laddr_ptr+1
        sta     tmp2+1

        lda     #4
        jsr     alloc_laddr

        ldy     #0
        lda     laddr_search_num
        sta     (tmp2), y

        pla

        iny
        sta     (tmp2), y
        jsr     get_codep
        ldy     #3
        sta     (tmp2), y
        dey
        txa
        sta     (tmp2), y
      ; clc     ; get_codep clears carry
        rts
.endproc

; Label search / create (on use)
.proc   E_LABEL
        jsr     get_last_tok    ; Get label TYPE from last token
        jsr     label_create
        ; Emits a label, searching the label address in the label list
        bcs     nfound

        ; Check label status
cloop:  bpl     next    ; 0 == label not defined, 1 == label defined, 128 == label address
        ; Found, get address from label and emit
emit_end:
        jsr     emit_addr
        jmp     advance_varn
next:
        jsr     next_laddr
        bcc     cloop
        ; Not found, add to the label address list
nfound: lda     #0
        jsr     add_laddr_list
        bcc     emit_end
ret:    rts
.endproc

; PUSH/POP variables
.proc   E_PUSH_VAR
        jsr     get_last_tok    ; Get variable ID from last token
        sta     E_POP_VAR+1
        clc
        rts
.endproc

.proc   E_POP_VAR
        lda     #0
        jmp     parser_emit_byte
.endproc

; Actions for LOOPS

.proc   E_PUSH_LT
        ; Push current position, don't emit
        jsr     get_last_tok    ; Get LOOP TYPE from last token
.endproc        ; Fall through
.proc   push_codep
        ; Saves current code position in loop stack
        ldy     loop_sp
        sta     loop_stk, y
        pha
        jsr     get_codep
        sta     loop_stk + 1, y
        txa
        sta     loop_stk + 2, y
        iny
        iny
        iny
        bmi     loop_error
        sty     loop_sp
        pla
        asl     ; Check BIT 6
        bmi     xit
::inc_opos_2:
        jsr     parser_inc_opos
        jsr     parser_inc_opos
xit:    clc
        rts     ; C is cleared on exit!
.endproc

.proc   loop_error
        ldy     #ERR_LOOP
        jmp     parser_error
.endproc

.proc   pop_codep
        ; Reads code position from loop stack
        ldy     loop_sp
        dey
        dey
        dey
        sty     loop_sp
        bmi     loop_error
        ; Check if loop type is correct
retry:  cmp     loop_stk, y
        beq     ok
        ; If loop type is "ELSE", accept also "IF"
        cmp     #LT_ELSE
        bne     loop_error
        lda     #LT_IF
        bne     retry
ok:     ; Get saved position
        iny
        iny
        ldx     loop_stk, y
        dey
        lda     loop_stk, y
rtsclc: clc
        rts     ; C is cleared on exit!
.endproc

.proc   E_POP_PROC_2
        ; Pop saved position, store
        lda     #LT_PROC_2
        jsr     pop_codep
.endproc        ; Falls through
.proc   check_loop_exit
        ; Checks if there is an "EXIT" in the stack, and adjust target pointer
        ldy     loop_sp
        dey
        dey
        dey
        bmi     pop_codep::rtsclc
        lda     loop_stk, y
        .assert LT_EXIT = 0, error, "LT_EXIT must be 0"
        bne     pop_codep::rtsclc
        ; Yes, pop and patch
        sty     loop_sp
        iny
        iny
        ldx     loop_stk, y
        dey
        lda     loop_stk, y
        jsr     patch_codep
        ; And check for more possible EXIT's
        jmp     check_loop_exit
.endproc

.proc   E_EXIT_LOOP
        ; Search the loop stack for a loop (not "I"f nor "E"lse) and inserts a
        ; patching code before
        ldy     loop_sp
retry:  dey
        dey
        dey
        bmi     loop_error
        lda     loop_stk, y
        bmi     retry           ; FOR(2)/WHILE(2)/IF/ELSE/ELIF are > 127
        cmp     #LT_PROC_DATA+1 ; PROC(1)/DATA
        bcc     loop_error
ok:
        ; Store slot
        sty     comp_y+1
        ; Check if enough stack
        ldx     loop_sp
        inx
        inx
        inx
        bmi     loop_error

        ; Move all stack 3 positions up
        stx     loop_sp
move:
        dex
        lda     loop_stk-3, x
        sta     loop_stk, x
comp_y: cpx     #$FC
        bne     move

        ; Store our new stack entry
        lda     loop_sp
        pha
        ldy     comp_y+1
        sty     loop_sp
        lda     #LT_EXIT
        jsr     push_codep
        pla
        sta     loop_sp
        clc
        rts
.endproc

.proc   E_POP_WHILE
        ; Pop saved "jump to end" position
        lda     #LT_WHILE_2
        ; Save current position + 2 (skip over jump)
        jsr     inc_opos_2
        jsr     pop_patch_codep
        ; Pop saved "loop reentry" position
        lda     #LT_WHILE_1
        ; And store
        dec     opos
        dec     opos
        jsr     pop_emit_addr
        ; Checks for an "EXIT"
        jmp     check_loop_exit
.endproc

.proc   E_POP_LOOP
        ; Pop saved position, store
        lda     #LT_DO_LOOP
        .byte   $2C   ; Skip 2 bytes over next "LDA"
.endproc        ; Fall through
.proc   E_POP_REPEAT
        ; Pop saved position, store
        lda     #LT_REPEAT
        jsr     pop_emit_addr
        ; Checks for an "EXIT"
        jmp     check_loop_exit
.endproc

.proc   E_POP_FOR
        ; Remove unused "variable number" from code
        dec     opos
        ; Pop saved "loop reentry" position
        lda     #LT_FOR_1
        ; And store
        jsr     pop_emit_addr
        ; Pop saved "jump to end" position
        lda     #LT_FOR_2
        ; Save current position
        jsr     pop_patch_codep
        ; Checks for an "EXIT"
        jmp     check_loop_exit
.endproc

.proc   E_POP_IF
        ; Patch IF/ELSE with current position
        lda     #LT_ELSE
check_elif:
        jsr     pop_patch_codep
        ; Check and remove all ELIF targets
        ldy     loop_sp
        dey
        dey
        dey
        bmi     no_elif
        lda     #LT_ELIF
        cmp     loop_stk, y
        beq     check_elif
no_elif:
        clc
        rts
.endproc

.proc   E_POP_PROC_DATA
        ; Pop saved "jump to end" position
        lda     #LT_PROC_DATA
.endproc        ; Fall through

.proc   pop_patch_codep
        jsr     pop_codep
.endproc        ; Fall through
.proc   patch_codep
        ; Patches saved position with current position
        ; RETURNS  C cleared, Y = 1.
        sta     tmp2
        stx     tmp2+1
        jsr     get_codep
        ldy     #0
     ;  clc     ; get_codep clears carry
        adc     reloc_addr
        sta     (tmp2),y
        iny
        txa
        adc     reloc_addr+1
        sta     (tmp2),y
        clc
        rts     ; C is cleared on exit!
.endproc

.proc   E_ELSEIF
        ; Pop the old position to patch (from IF)
        lda     #LT_IF
        jsr     pop_codep
        sta     tmp1
        stx     tmp1+1
        ; Emit a jump to a new position (loop type ELIF/ELSE from code)
        jsr     E_PUSH_LT
        ; Parch current position + 2 (over jump)
        lda     tmp1
        ldx     tmp1+1
        bne     patch_codep
.endproc

; vi:syntax=asm_ca65
