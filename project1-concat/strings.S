/* 	ECE-251 Project 1 	*/
/*	Daniel Mezhiborsky 	*/
/* 	   Spring 2020 		*/

.data
/* ------------------------------------------------------ */
# allocate 16 zero bytes each for the strings
.balign 4
string1:
	.space 16

.balign 4
string2:
	.space 16

# exit error text
.balign 4
longstring_msg:
	.asciz "\033[0;31mError: %d\n\033[0m"

#prompt text
.balign 4
prompt_msg:
	.asciz "\033[1;32mEnter string %d: \033[0m"

#char count format
.balign 4
number_fmt:
	.asciz "\033[1;34mNumber of characters: \033[0;32m%d\n"

#concatenation format
.balign 4
concat_fmt:
	.asciz "\033[1;34m\nConcatenated string:  \033[0;32m%s%s"
/* ------------------------------------------------------ */
.text
.global main
main:
	push {lr}		@ save lr

	mov r5, #0		@ r5 indicates string1 or string2 (0 or 1)
	ldr r4, =string1	@ load address of string1 into r4
	bl getstrings		@ get string1

	mov r5, #1		@ indicate string2
	ldr r4, =string2	@ load address of string2 into r4
	bl getstrings		@ get string2

	ldr r4, =string1	@ load address of string1 into r4
	bl findlength		@ go to findlength

	ldr r0, =concat_fmt	@ load concatentation printf format
	ldr r1, =string1	@ load string1 address arg
	ldr r2, =string2	@ ^ string2
	bl printf		@ print concatenated string

	sub r0, #38		@ subtract 2 from printf returned count (two \n's)
	mov r1, r0		@ set r1 to the count
	mov r4, r0		@ save the count in r4 for exit code
	ldr r0, =number_fmt	@ load printf format
	bl printf		@ print number of characters

	mov r0, r4		@ set return code

	pop {lr}		@ get lr
	bx lr			/* bye! */

/* gets user input and checks if length > 10
 args:
	r4: address to save string to */
getstrings:
	push {lr} 		@ save lr

	ldr r0, =prompt_msg	@ load address of prompt message
	mov r1, r5		@ load string number
	add r1, #1		@ 0->1 and 1->2 for user friendliness
	bl printf		@ print prompt

	mov r0, r4		@ copy r4 (string address) into r0
	mov r1, #13		@ fgets number of chars to read
	ldr r2, find_stdin	@ get stdin address
	ldr r2, [r2]		@ load value of stdin
	bl fgets		@ call fgets to get user input

	ldrb r0, [r4, #11]	@ load single byte into r0: 12th char of string
	cmp r0, #0		@ check if that byte is nonzero (not NULL)
	bgt longstring		@ if so, exit with longstring

	pop {lr}		@ get lr
	bx lr			@ return to main

/* handles the case where the string is too long */
longstring:
	add r5, #21		@ get either 21 or 22 error code
	ldr r0, =longstring_msg	@ load error message
	mov r1, r5		@ copy error code
	bl printf		@ print error

	mov r0, r5		@ set return code
	pop {lr}		@ discard getstrings's lr to main
	pop {lr}		@ get exit() lr
	bx lr			/* bye! */

/* finds string length and removes newline
 args:
	r4: string address */
findlength:
	ldrb r1, [r4]		@ load character at r4+i
	cmp r1, #10		@ compare with ASCII newline

	moveq r3, #0		@ if equal, set r3 to 0
	streqb r3, [r4]		@ if equal, store zero at that location
	bxeq lr			@ if equal, return to main

	add r4, #1		@ increment address pointer by 1 byte/char
	b findlength		@ ^ otherwise, loop

# stdin
find_stdin: .word stdin

/* External */
.global fgets
.global puts
.global printf
