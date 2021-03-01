/*      ECE-251 Project 3       */
/*      Daniel Mezhiborsky      */
/*         Spring 2020          */
/*            calc.S            */


.data
/* ------------------------------------------------------ */
argv1_addr:		.space 4
operands:		.space 40
operators:		.space 20
offset:			.int 0
bail:			.space 4
operand_scan_fmt:	.asciz "%lf%n"

error_bad_parens_msg:   .asciz "Error! Mismatched parentheses!"
error_arg_count_msg:    .asciz "Error! Invalid number of arguments. Please put your expression in quotes!\n"
error_bad_input_msg:	.asciz "Error! Invalid input: %s\n%*c\n"
print_result_msg:	.asciz "%lf\n"
operations_exceeded_msg:.asciz "Error: Input too long; too many operations (max 4).\n"
/* ------------------------------------------------------ */

.text
.global main
main:
	push {r4, r5, r6, lr}			@ 16 byte aligned, but still doesn't fix pow

	ldr r3, =bail				@ save return addr
	str lr, [r3]

	bl prepare				@ prepare data (addresses, etc) for the parsing
	bl parse_loop_start			@ parse the data
	bl print_result				@ eval what's left and print the result

	pop {r4, r5, r6, lr}
	bx lr

prepare:
	cmp r0, #2
	bne error_arg_count_exit
	ldr r0, =argv1_addr
	add r1, #4				@ get second arg
	ldr r1, [r1]
	str r1, [r0]
	mov r4, r1				@ r4 = input pointer
//	sub r4, #1
	ldr r5, =operands			@ r5 = operands pointer
	sub r5, #8
	ldr r6, =operators			@ r6 = operators pointer
	sub r6, #1
	//r7 loaded in parse_loop		@ r7 = current input char
	mov r8, #-1				@ r8 = last_type
	//likewise loaded later			@ r9 = current operator
	mov r10, #0				@ r10 = next_negative
	mov r11, #0				@ r11 = operations_count
	bx lr

error_arg_count_exit:
	ldr r0, =error_arg_count_msg
	bl printf
	pop {r4, r5, r6, lr}
	mov r0, #9
	bx lr


parse_loop_start:
	push {r0, r1, r2, lr}			@ 8-byte alignment
parse_loop:
	ldrb r7, [r4]				@ r7 = input character
	//COND 1				@ end of string; break loop
		cmp r7, #0
			popeq {r0, r1, r2, lr}
			bxeq lr			@ break loop
	//COND 2
		cmp r7, #' '			@ space, just increment and skip!
			addeq r4, #1
			beq parse_loop
	//COND 3
		cmp r7, #'.'			@ operand! parse and continue
			beq parse_loop_isoperand
		mov r0, #0
		cmp r7, #'0'
			addge r0, #1
		cmp r7, #'9'
			addle r0, #10
		cmp r0, #11
			beq parse_loop_isoperand
	//COND 4				@ open parenthesis
		cmp r7, #'('
			beq parse_loop_openparen
	//COND 5
		cmp r7, #')'
			beq parse_loop_closeparen
	//COND 6
		mov r0, #0			@ negative sign (not minus!)
		cmp r7, #'-'
			addeq r0, #1
		cmp r8, #1
			addlt r0, #10
		cmp r10, #0
			addeq r0, #100
		cmp r0, #111
			moveq r10, #1
			addeq r4, #1
			beq parse_loop
	//COND 7
		cmp r11, #4					@ too many ops; throw error
			beq parse_loop_operations_exceeded

	//COND 8
		cmp r8, #1					@ if the last type was 1, that means we're about to have 2 operands in a row
		blt error_bad_input_exit

	//COND 9
		mov r0, #0					@ + & -
		cmp r7, #'+'
			addeq r0, #1
		cmp r7, #'-'
			addeq r0, #1
		cmp r0, #1
			bge parse_loop_isplusminus
	//COND 10
		mov r0, #0					@ * & /
		cmp r7, #'/'
			addeq r0, #1
		cmp r7, #'*'
			addeq r0, #1
		cmp r0, #1
			bge parse_loop_ismuldiv


	//COND 11
		cmp r7, #'^'					@ ^
			beq parse_loop_ispow

	b error_bad_input_exit


parse_loop_ispow:						@ there are no evaluation criteria because nothing is of higher precedence than ^ and it's right-associative
	add r6, #1
	add r11, #1
	str r7, [r6]
	add r4, #1
	mov r8, #0
	b parse_loop

parse_loop_ismuldiv:						@ evaluate the existing list if the priority is less than or the same
	mov r1, #0
	ldrb r0, [r6]						@ eval while we have the the correct precedence, so eval *,/,^ but not +,-
	cmp r0, #'('						@ stop at open parentheses
		addne r1, #1
	cmp r0, #'+'
		addne r1, #1
	cmp r0, #'-'
		addne r1, #1
	ldr r0, =operators
	cmp r6, r0
		addge r1, #1
	cmp r1, #4
		beq parse_loop_evalmuldiv

	add r6, #1
	add r11, #1
	str r7, [r6]
	add r4, #1
	mov r8, #0
	b parse_loop
parse_loop_evalmuldiv:
	bl eval_single
	b parse_loop_ismuldiv

parse_loop_isplusminus:						@ similar to above but we just evaluate so long as we don't reach an open parenthesis due to lowest precedence
	mov r1, #0
	ldrb r0, [r6]
	cmp r0, #'('
		addne r1, #1
	ldr r0, =operators
	cmp r6, r0
		addge r1, #1
	cmp r1, #2
		beq parse_loop_evalplusminus

	add r6, #1
	add r11, #1
	str r7, [r6]
	add r4, #1
	mov r8, #0
	b parse_loop
parse_loop_evalplusminus:
	bl eval_single
	b parse_loop_isplusminus

parse_loop_isoperand:						@ record the operand.
	add r5, #8
	mov r0, r4
	ldr r1, =operand_scan_fmt
	mov r2, r5
	ldr r3, =offset
	bl sscanf

	cmp r10,#1
	bleq parse_loop_flip_operand

	mov r8, #1
	ldr r1, =offset
	ldr r1, [r1]
	add r4, r1
	b parse_loop

parse_loop_flip_operand:					@ flip the sign if indicated by a previous negative sign.
	vldr.f64 d0, [r5]
	vneg.f64 d0, d0
	vstr.f64 d0, [r5]
	mov r10, #0
	bx lr


parse_loop_openparen:						@ record open parenthesis
	cmp r8, #1
	beq error_bad_input_exit
	add r4, #1
	add r6, #1
	mov r1, #'('
	strb r1, [r6]
	mov r8, #0
	b parse_loop

parse_loop_closeparen:
	ldrb r0, [r6]						@evaluate until we reach the open parenthesis, then discard both
	cmp r0, #'('
	bne parse_loop_evalparen
	sub r6, #1
	add r4, #1						@skip the close paren in input
	b parse_loop
parse_loop_evalparen:
	sub r1, r0, r6
	cmp r1, #-1
	beq error_bad_parens
	bl eval_single
	b parse_loop_closeparen


parse_loop_operations_exceeded:					@too many ops, time head out
	ldr r0, =operations_exceeded_msg
	bl printf
	ldr r0, =bail
	ldr lr, [r0]
	mov r0, #5
	bx lr

error_bad_parens:						@ bad parentheseses error message routine
	ldr r0, =error_bad_parens_msg
	bl printf
	ldr r0, =bail
	ldr lr, [r0]
	bx lr



print_result:							@ if we have an operand OR an open parenthesis at the end, we're good to go
	cmp r8, #1
		bge print_result_eval_remaining
	ldrb r9, [r6]
	cmp r9, #'('
		beq print_result_eval_remaining
	sub r4, r4, #1
	b error_bad_input_exit					@ otherwise there's a mistake -> error out


print_result_eval_remaining:					@ evaluate the remaining operands
	ldr r0, =operators
	sub r0, r6, r0
	cmp r0, #0
	blt print_result_print
	bl eval_single
	b print_result_eval_remaining

print_result_print:						@ finally print the result
	ldr r0, =print_result_msg
	ldr r1, =operands
	vldr d0, [r1]
	vmov r2, r3, d0
	bl printf
	ldr r0, =bail
	ldr lr, [r0]
	mov r0, #0
	bx lr

eval_single:
	push {r0, r1, r2, lr}
eval_single_cont:
	ldrb r0, [r6]						@ get top operator
	cmp r0, #'('
		beq error_bad_parens
	vldr.f64 d0, [r5, #-8]
	vldr.f64 d1, [r5]

	cmp r0, #'+'
		bleq eval_add
		vstreq.f64 d3, [r5, #-8]
		beq eval_single_end
	cmp r0, #'-'
		bleq eval_sub
		vstreq.f64 d3, [r5, #-8]
		beq eval_single_end
	cmp r0, #'/'
		bleq eval_div
		vstreq.f64 d3, [r5, #-8]
		beq eval_single_end
	cmp r0, #'*'
		bleq eval_mul
		vstreq.f64 d3, [r5, #-8]
		beq eval_single_end
	cmp r0, #'^'
		bleq pow					@ !!!! pow doesn't work! seems to be an issue with the hard/soft float calling conventions, don't have hf frontend to test with
		vstreq.f64 d0, [r5, #-8]
		beq eval_single_end
eval_single_end:
	sub r5, #8
	sub r6 ,#1
	pop {r0, r1, r2, lr}
	bx lr

eval_add:	vadd.f64 d3, d0, d1
		bx lr
eval_sub:	vsub.f64 d3, d0, d1
		bx lr
eval_div:	vdiv.f64 d3, d0, d1
		bx lr
eval_mul:	vmul.f64 d3, d0, d1
		bx lr

error_bad_input_exit:						@ error for bad input. r2 contains the padding for the ^ indicator, determined by the # of chars read, and
	ldr r0, =error_bad_input_msg
	ldr r1, =argv1_addr					@ the constant offset from the message text (23).
	ldr r1, [r1]
	mov r2, r4
	sub r2, r1
	mov r2, r4
	add r2, #23
	sub r2, r1
	mov r3, #'^'
	bl printf
 	ldr r3, =bail
	ldr lr, [r3]
	mov r0, #1
	bx lr

.extern pow
.extern sscanf
