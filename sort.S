/* 	ECE-251 Project 2 	*/
/*	Daniel Mezhiborsky 	*/
/* 	   Spring 2020 		*/
/*            sort.S		*/

.data
/* ------------------------------------------------------ */
file_pointer_read:	.space 4
file_pointer_write:	.space 4
number_list:		.space 404
read_filename_ptr:	.space 4
write_filename:		.asciz "sorted.txt"
read_mode:		.asciz "rb"
write_mode:		.asciz "wb"
scanf_fmt:		.asciz "%dz"
scanf_fmt_unsigned:	.asciz "%uz"
printf_fmt:		.asciz "%d\n"
printf_fmt_unsigned:	.asciz "%u\n"
error_file_open_read:	.asciz "An error was encountered while reading the file \'%s\': "
error_errno_append:	.asciz "%s\n"
error_long_file_msg:	.asciz "File must be 100 integers at most, one integer per line.\n"
error_not_int_msg:	.asciz "Only integers allowed!\n"
usage:			.asciz "Usage: ./sort.out [filename] [r or n] [s or u]\nr==reverse, n==normal (ascending) ||| s==signed, u==unsigned\n"
done:			.asciz "Done. Check output [sorted.txt]\n"
size_read:		.space 4
flags:			.space 4
temp:			.space 4
/* ------------------------------------------------------ */

.text
.global main
main:
	push {r4-r12, lr}

	cmp r0, #4				@ are there at least three args?
	bne error_missing_args
	bleq process_args

	bl open_file_read			@ open and read input file
	bl sort_list
	bl open_file_output			@ open and write output file

	pop {r4-r12, lr}
	bx lr

/* ARGUMENT PROCESSING----------------------------------------------------------------------------------*/
error_missing_args:
	ldr r0, =usage				@ print usage and leave
	bl printf
	mov r0, #1
	b exit

process_args:
	push {lr}

	ldrge r2, [r1, #4]			@ load arg 1: filename
	ldrge r3, =read_filename_ptr
	str r2, [r3]

	ldr r2, [r1, #8]			@ load arg 2: reverse sort flag
	ldrb r2, [r2]
	cmp r2, #114
	blne process_check_reverse
	ldreq r3, =flags
	moveq r2, #1
	strge r2, [r3]
process_get_sign:
	ldr r2, [r1, #12]			@ load arg 3: unsigned list flag
	ldrb r2, [r2]
	cmp r2, #117
	blne process_check_signed
	ldreq r3, =flags
	ldreq r2, [r3]
	addeq r2, #10
	strge r2, [r3]

	pop {lr}
	bx lr
process_check_reverse:
	cmp r2, #110				@ since the flag wasn't r, let's make sure it's n
	blne error_missing_args
	b process_get_sign			@ skip to next arg

process_check_signed:
	cmp r2, #115				@ since the flag wasn't u, let's make sure it's s
	blne error_missing_args
	pop {lr}				@ back to main; we're done
	bx lr

/* READING INPUT FILE-----------------------------------------------------------------------------------*/
open_file_read:
	push {r5, r6, lr}			@ fopen the input file
	ldr r0, =read_filename_ptr
	ldr r0, [r0]
	ldr r1, =read_mode
	bl fopen

	cmp r0, #0				@ make sure that was successful (not null pointer)
	ldreq r0, =error_file_open_read
	ldreq r1, =read_filename_ptr
	ldreq r1, [r1]
	bleq printf
	beq error_bad_file

	ldr r1, =file_pointer_read		@ save the pointer
	str r0, [r1]
read_file:
	ldr r5, =number_list			@ load addr of the number_list block to which we will read
	mov r6, #0
read_file_loop:
	cmp r6, #400				@ make sure we haven't exceeded 100 lines
	bgt error_long_file

	ldr r0, =file_pointer_read
	ldr r0, [r0]

	ldr r1, =flags				@ choose signed or unsigned read
	ldr r1, [r1]
	cmp r1, #10
	ldrlt r1, =scanf_fmt
	ldrge r1, =scanf_fmt_unsigned

	mov r2, r5				@ r2=base address of number_list plus offset (loop counter)
	add r2, r6
	bl fscanf

	cmp r0, #0				@ make sure fscanf worked as expected
	addgt r6, #4
	bgt read_file_loop
	blt read_file_end
	beq error_not_int

read_file_end:
	ldr r5, =size_read			@ end loop; close file and return to main
	str r6, [r5]
	ldr r0, =file_pointer_read
	ldr r0, [r0]
	bl fclose
	pop {r5, r6, lr}
	bx lr

error_not_int:
	ldr r0, =error_not_int_msg		@ Not an integer
	bl printf
	mov r2, #3
	b exit
error_long_file:
	ldr r0, =error_long_file_msg		@ File too long
	bl printf
	mov r1, #2
	b exit

/* SORTING LIST-----------------------------------------------------------------------------------------*/

/*    ~~~ Selection sort ~~~

 	r0=outer_counter
	r1=inner_counter
	r2=n2
	r3=min
	r4=size_read
	r5=inner_loop_max
	r6=numbe_list+n1+n2
	r7=deref_min
	r8=number_list
	r9=deref_number_list+n1+n2
	r10=swap_temp1
	r11=swap_temp2
	r12=flags
				*/

sort_list:
	push {r4-r12, lr}		@ sort intro
	mov r0, #0
	mov r1, #0
	ldr r4, =size_read
	ldr r4, [r4]
	ldr r8, =number_list
	ldr r12, =flags
	ldr r12, [r12]
	sort_loop1:			@ <<outer loop>>
		cmp r0, r4			@ n1<size_read
		bge sort_end
		add r3, r8, r0			@ min=n1+number_list
		mov r1, #0
		sort_loop2:			@ <<inner loop>>
			sub r5, r4, r0			@ size_read-n1
			cmp r1, r5			@ n2<side_read-n1
			bge sort_loop1_end

			mov r6, r8			@ = number_list address
			add r6, r0			@ += n1
			add r6, r1			@ += n2
			ldr r9, [r6]			@ deref number_list+n1+n2

			ldr r7, [r3]			@ deref min

			cmp r12, #0			@ branch to correct signing and ordering
			beq new_minimum
			cmp r12, #1
			beq new_minimum_rev
			cmp r12, #10
			beq new_minimum_unsigned
			cmp r12, #11
			beq new_minimum_unsigned_rev
		sort_loop2_end:
			add r1, r1, #4
			b sort_loop2
	sort_loop1_end:			@ swap elements
		ldr r10, [r3]
		ldr r11, [r8, r0]
		str r11, [r3]
		str r10, [r8, r0]

		add r0, r0, #4
		b sort_loop1
sort_end:
	pop {r4-r12, lr}
	bx lr

new_minimum:				@ ascending signed
	cmp r9, r7
	movle r3, r6
	b sort_loop2_end
new_minimum_rev:			@ descending signed
	cmp r9, r7
	movge r3, r6
	b sort_loop2_end
new_minimum_unsigned:			@ ascending unsigned
	cmp r9, r7
	movls r3, r6
	b sort_loop2_end
new_minimum_unsigned_rev:		@ descending signed
	cmp r9, r7
	movhs r3, r6
	b sort_loop2_end

/* WRITING OUTPUT---------------------------------------------------------------------------------------*/
open_file_output:
	push {r4-r6, lr}			@ open output file
	ldr r0, =write_filename
	ldr r1, =write_mode
	bl fopen

	cmp r0, #0				@ make sure that was successful
	ldreq r1, =write_filename
	beq error_bad_file
	ldr r1, =file_pointer_write
	str r0, [r1]
print_list:
	ldr r5, =number_list			@ print list loop intro
	ldr r4, =size_read
	ldr r4, [r4]
	mov r6, #0
print_list_loop:
	ldr r0, =file_pointer_write		@ choose signed or unsigned, print, and iterate
	ldr r0, [r0]
	ldr r1, =flags
	ldr r1, [r1]
	cmp r1, #10
	ldrge r1, =printf_fmt_unsigned
	ldrlt r1, =printf_fmt
	ldr r2, [r5, r6]
	cmp r6, r4
	beq print_list_end
	bl fprintf
	add r6, #4				@ counter
	b print_list_loop
print_list_end:
	bl fclose
	ldr r0, =done				@ print message and return to main
	bl printf
	pop {r4, r5, r6, lr}
	bx lr


// General fopen error
// Prints message associated with current errno
error_bad_file:
	bl __errno_location			@ gcc told me
	ldr r0, [r0]
	bl strerror
	mov r1, r0
	ldr r0, =error_errno_append
	bl printf
	bl exit

# stdin
find_stdin: .word stdin

/* External */
.global fscanf
.global fprintf
.global strerror
.global fopen
.global fclose
