################## GLOBAL SYMBOLS ##################
	# STRING ROUTINES
	.globl readString
	.globl strcmp
	.globl strlen
	.globl nlnTrim
	# LIST ROUTINES
	.globl insert
	.globl printList
	.globl main
	.globl findPPD
	# PSEUDO STANDARD LIBRARY
	.globl malloc
	.globl printNewLine
	.globl printString
	.globl getString
	.globl printSpace
	.globl printFloat

################### CONSTANTS ###################
.data
	pizzaNamePrompt: .asciiz "Pizza name:      "
	pizzaDiamPrompt: .asciiz "Pizza diameter:  "
	pizzaCostPrompt: .asciiz "Pizza cost:      "
	DONE: .asciiz "DONE"
	space: .asciiz " "
	nln: .asciiz "\n";
	PI: .float 3.14159265358979323846
	four: .float 4.0
	MAX_CHAR: .word 64

.text
# MAIN gets user inputs and enters them in a list
# continues adding until "DONE" is entered;
# prints list in order when done 
#
main:
	addi $sp, $sp, 4
	sw $ra, 0($sp)
	li $s0, 0                     # list_head = NULL

mainLoop:
	# Prompt Pizza Name
	la $a0, pizzaNamePrompt
	jal printString
	
	# Get Pizza Name from User
	jal readString

	# Save the string pointer as we'll  use it repeatedly
	move $s1, $v0

	# Strip new line 
	move $a0, $s1
	jal nlnTrim

	# Save the newly trimmed string pointer as we'll  use it repeatedly
	move $s1, $v0

	# Get string length and save it 
	move $a0, $s1 
	jal strlen

	# stop if given empty string
	blez $v0, mainExit

	# Check to see if string that was read is "DONE"
	move $a0, $s1
	la $a1, DONE
	jal strcmp
	beqz $v0, mainExit

	# Prompt user for diameter, cost, then spit out the PPD, store in f0
	jal findPPD
	## at this point, the current pizza's PPD is stored in $f0

	# Insert the pizza struct in the SORTED linked list 
	move $a0, $s1
	# PPD stored in $f0!!!!!!
	jal insert 

	# Repeat the process until you exit with mainExit and DONE string
	j mainLoop
mainExit:
	move $a0, $s0
	jal printList

	# exit the program
	lw $ra, 0($sp)
	add $sp, $sp, 4
	jr $ra

#################### COLLECT PIZZA PPD ####################
findPPD:
	addi $sp, $sp, -4 # Keeps track of where we need to go back in our main function
	sw $ra, 0($sp)

	# Prompt pizza diameter
	la $a0, pizzaDiamPrompt
	jal printString

	# read in integer from user, store in t0
	jal readFloat
	mov.s $f4, $f0

	# Prompt pizza cost
	la $a0, pizzaCostPrompt
	jal printString
	
	# Read in float from user, store in t1
	jal readFloat
	mov.s $f5, $f0

	neg.s $f1, $f0      # negate the cost
	add.s $f0, $f0, $f1 # add the negation to the original user input
	c.eq.s $f5, $f0 # code = 1 if what the user inputted is zero
	bc1t exitPPD # exit with $f0 being 0 if the user input was zero

	# Calculate the PPD and store in $v0
	l.s $f6, PI
	l.s $f7, four
	mul.s $f0, $f4, $f4 # diam squared
	mul.s $f0, $f0, $f6 # diam squared times PI
	div.s $f0, $f0, $f7 # (diam squared times PI)/4
	div.s $f0, $f0, $f5 # (diam squared times PI)/ 4(cost)
exitPPD:
	# Exit the function
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

################### INSERT PIZZA ###################
# insert: inserts new linked-list node in appropriate place in the list (that is, in descending order by price)
# if the PPD is the same, then compare the two strings
insert:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# allocate a new node
	li $a0, 72 # 72 bytes in the whole node, because 64 for name, 4 for PPD, 4 for next node
	jal malloc
	move $s2, $v0 # remember the address of this new node

	# initialize this new node
	sw $zero, 68($s2)
	sw $s1, 0($s2)
	s.s $f0, 64($s2)

	# set up the loop
	li $s3, 0         # prev = NULL
	move $s4, $s0     # cur = list_head
	j insertTest
insertLoop:
	l.s $f8, 64($s2) # get new node's PPD
	l.s $f9, 64($s4) # get cur node's PPD
	c.le.s $f8, $f9  # if new node PPD < cur node PPD, code = 1, else code = 0
	bc1f insertNow # since we try to insert in descending order, we say that if the code returned is 0, meaning newPPD > curPPD, insert now

	c.eq.s $f8, $f9 # code = 1 if newPPD = curPPD, else code = 0
	bc1t compNames # if they are equal, then compare names, else continue on

	move $s3, $s4    # prev = cur
	lw $s4, 68($s4)  # cur = cur->node.next
insertTest:
	bnez $s4, insertLoop # if curr != NULL, then loop thru
insertNow:
	sw $s4, 68($s2)        # new->node.next = cur
	beqz $s3, insertFront  # prev = NULL? If yes, then fly
	sw $s2, 68($s3)        # prev->node.next = new
	j insertDone
compNames:
	lw $a0, 0($s2) # get new node's string
	lw $a1, 0($s4) # get cur node's string
	jal strcmp     # compare the two strings, result should be in $v0
	beqz $v0, insertNow # if new = cur, insert it now
	bltz $v0, insertNow # since we're doing names ascending alphabetically, we insert now if new > cur

	move $s3, $s4    # else, just continue to traverse the list
	lw $s4, 68($s4)
	j insertTest
insertFront:
	move $s0, $s2  # list_head = new
insertDone:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

################# PRINT THE LIST ###################
printList: 
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp) # storing the head pointer
	beq $s0, $zero, printListExit # if empty list, exit
printListLoop:
	lw $a0, 0($s0)
	jal printString
	jal printSpace
	l.s $f12, 64($s0)
	jal printFloat
	jal printNewLine
	lw $s0, 68($s0) # node = node->node.next
	bnez $s0, printListLoop # if the list is not empty, then continue the loop
printListExit:
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 8
	jr $ra


################# STRING ROUTINES ###################

# strcmp: given strings s, t stored at addresses in $a0, $a1
# returns < 0 if s < t; 0 if s == t, > 0 if s > t
strcmp:
	lb $t0, 0($a0) # get byte of first char in string s
	lb $t1, 0($a1) # get byte of first char in string t

	sub $v0, $t0, $t1 # compare them
	bnez $v0, strcmpDone # mismatch? if so, then leave

	addi $a0,$a0,1 # advance s pointer
	addi $a1,$a1,1 # advance t pointer

	bnez $t0, strcmp # at EOS? no = loop, otherwise, go to done
strcmpDone:
	jr $ra # exits and just returns $v0

readString:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)

	lw $a1, MAX_CHAR # a1 gets the max string length

	move $a0, $a1 # tell malloc the size
	jal malloc    # allocate space for the string
	
	move $a0, $v0 # move pointer to allocated memory in $a0

	lw $a1, MAX_CHAR # a1 gets MAX_CHAR
	jal getString    # get the string into $v0 
	move $v0, $a0    # restore string addresses

	# Clean things up
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 8
	jr $ra
printString:
	li $v0, 4
	syscall
	jr $ra
getString: 
	li $v0, 8
	syscall
	jr $ra

# nlnTrim: modified string stored at address in $a0 so that
# first occurence of new line is replaced by null terminator
nlnTrim:                       # TRIMS NEW LINE FROM THE STRING INPUTS
	li $t0, 0x0A     # ASCII value for new line
nlnTrimLoop:
	lb $t1, 0($a0) # get next char in string
	beq $t1, $t0, nlnTrimReplace # is it new line? if yes, then replace
	beqz $t1, nlnTrimDone # is it EOS? if yes, then exit
	addi $a0, $a0, 1 # increment by 1 to point to next character
	j nlnTrimLoop
nlnTrimReplace:
	sb $zero, 0($a0) # zero out newline
nlnTrimDone:
	jr $ra

# strlen: given string stored at address in $a0
# returns its length in $v0
strlen: 
	move $v0, $a0    # remember base address
strlenLoop: 
	lb $t1,0($a0)    # get the current char
	addi $a0, $a0, 1 # pre-incremement to the next byte of string
	bnez $t1, strlenLoop # is the character 0? if not, then loop

	subu $v0,$a0,$v0 # get length + 1
	subu $v0,$v0, 1  # get length (compensate for pre-increment)
	jr $ra


################# STD LIB ROUTINE ###################
malloc:
	li $v0, 9
	syscall
	jr $ra
printNewLine:
	li $v0, 4
	la $a0, nln
	syscall
	jr $ra
readFloat:
	li $v0, 6
	syscall
	jr $ra
printSpace:
	li $v0, 4
	la $a0, space
	syscall
	jr $ra
printFloat:
	li $v0, 2
	syscall
	jr $ra