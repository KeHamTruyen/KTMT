
# Data segment
    .data
fileName:    .asciiz     "FLOAT15.BIN"
size:        .word       15
array:       .space      60
# Statements for Data input 
prompt_before:    .asciiz "Before sorting: "
prompt_after:    .asciiz " After sorting: "
# Code segment
    .text
    .globl    main
main:

# ------------------Input-----------------#
    li    $v0, 13            # Set $v0=13 to open a file
    la    $a0, fileName        # Get the directory of the file
    li    $a1, 0            # Set flag=0 (0 for reading, 1 for writing) 
    li    $a2, 0            # Mode is ignored
    syscall
    move    $s0, $v0        # Placing the descriptor in $s0 for later-use 

    # read data
    li    $v0, 14            # Set $v0=14 to read the file
    move    $a0, $s0        # Move descriptor to $a0
    la    $a1, array        # Address buffer to read
    li    $a2, 60            # Hard-code buffer length = size * sizeof(float)
    syscall

    # close file
    li    $v0, 16            # Set $v0=16 to close the file
    move    $a0, $s0        # file descriptor to close
    syscall
# print
    la    $a0, prompt_before    # load prompt address
    li    $v0, 4            # ready to print string prompt 
    syscall

    jal    printArray        # call function to print float array

endfor1:
# ---------------Process-------------#
# Call mergeSort(array, 0, size - 1) 
    la    $a0, array
    add    $a1, $zero, $zero
    lw    $a2, size
    addi    $a2, $a2, -1
    jal    mergeSort

# ---------------Output--------------#
    addi    $a0, $zero, '\n'
    li    $v0, 11
    syscall

    la    $a0, prompt_after
    li    $v0, 4
    syscall

    jal    printArray        # call function to print float array
endfor2:
    
    li    $v0, 10
    syscall

#############################################################
# function mergeSort(array, left, right)
# a0: array   
# a1: left     
# a2: right
# No output
# Description: Recursively sort an array from left to right 
#############################################################

mergeSort:
# Set stack pointer
    addi    $sp, $sp, -20    # initiate stack
    sw    $a0, 0($sp)    # save array address
    sw    $a1, 4($sp)    # save left
    sw    $a2, 8($sp)    # save right
    sw    $ra, 16($sp)
# ----------------------------#
# t0 = left, t1 = right
    lw    $t0, 4($sp)    # load value of left to $t0
    lw    $t1, 8($sp)    # load value of right to $t1

# if (left < right)
    bge    $t0, $t1, endif1

# s0 = mid = left + (right - left) / 2 = t0 + (t1 - t0) / 2
    sub    $s0, $t1, $t0    # $s0 = right - left
    srl    $s0, $s0, 1    # $s0 = $s0/2 = (right - left)/2 
    add    $s0, $s0, $t0    # $s0 = $s0 + left = left + (right - left) / 2
    sw    $s0, 12($sp)    # save mid 
    
# call    mergeSort(array, left, mid)
    lw    $a0,  0($sp)    # array = $a0
    lw    $a1,  4($sp)    # left = $a1
    lw    $a2, 12($sp)     # mid = $a2
    jal     mergeSort
# print    
    addi    $a0, $zero, '\n' 
    li    $v0, 11    
    syscall
    jal    printArray    # print array
# call    mergeSort(array, mid + 1, right)
    lw    $a0,  0($sp)    # array = $a0
    lw    $a1, 12($sp)    # mid = $a1
    addi    $a1, $a1, 1    # $a1 = mid + 1
    lw    $a2, 8($sp)    # right = $a2
    jal     mergeSort
# print
    addi    $a0, $zero, '\n'
    li    $v0, 11
    syscall
    jal    printArray    
# call    merge(array, start, mid, end)
    lw    $a0,   0($sp)    # array = $a0
    lw    $a1,   4($sp)    # start = $a1
    lw    $a2,  12($sp)    # mid = $a2
    lw    $a3,   8($sp)    # end = $a3
    jal    merge
    
    addi    $a0, $zero, '\n'
    li    $v0, 11
    syscall
    jal    printArray
    
endif1:
    lw    $ra, 16($sp)
    lw    $a0,  0($sp)
    lw    $a1,  4($sp)
    lw    $a2,  8($sp)
    addi    $sp, $sp, 20
    jr    $ra

#################################################################
# function merge(array, start, mid, end)
# a0: array
# a1: start
# a2: mid
# a3: end 
# No output
# Description: merge 2 sub-arrays which are (nearly) the same size
# by choosing between 2 beginning elements of 2 sub-arrays which 
# one is smaller, then popping out.
#################################################################
merge:
    addi    $sp, $sp, -16    # Preserve stack
    sw    $a1,  0($sp)    # save start = $a1
    sw    $a2,  4($sp)    # save mid = $a2
    sw    $a3,  8($sp)    # save end = $a3
    sw    $ra, 12($sp)    # save the return address
# ----------------------------------------#
# s0 = start_r, a1 = start, a2 = mid, a3 = end
    addi    $s0, $a2, 1
    sll    $t0, $a2, 2
    add    $t0, $a0, $t0    # t0 = array + mid
    lwc1    $f0, 0($t0)    # f1 = (*t0) 
    
    sll    $t0, $s0, 2
    add    $t0, $a0, $t0    # t0 = array + start_r
    lwc1    $f1, 0($t0)    # f2 = (*t0)
# if (arr[mid] <= arr[start_r]) 
    c.le.s    $f0, $f1
    bc1t    return
# while (start <= mid && start_r <= end)

begin_while:
    slt    $t0, $a2, $a1        # mid < start
    slt    $t1, $a3, $s0        # end < start_r
    or    $t0, $t0, $t1        # (... || ...)
    bnez    $t0, end_while        # => while !(..) 
# begin_do
# s1 = arr + start, s2 = arr + start_r
    sll    $t2, $a1, 2        # calculate start x float block 
    add    $s1, $a0, $t2        # arr + start
    lwc1    $f0, 0($s1)        # f0 = arr[start]
    sll    $t2, $s0, 2        # calculate start_r x float block 
    add    $s2, $a0, $t2        # arr + start_r
    lwc1    $f1, 0($s2)        # f1 = arr[start_r]
    
# begin_if2  if (arr[start] <= arr[start_r]
    c.le.s    $f0, $f1
    bc1f    if_false2
if_true2:
    addi    $a1, $a1, 1         # start++ 
    j    end_if2
if_false2:
# reuse f1 for temp = arr[start_r]
# begin_for 
cond3:
    sub    $t0, $s2, $s1         # index--;
    beqz    $t0, end_for3        # while (index != start)
# begin_loop: arr[i] = arr[i - 1]
    lwc1    $f0, -4($s2)        # Load arr[i - 1]
    swc1    $f0, 0($s2)        # Assign arr[i] = arr[i - 1]
# end_loop:
    addi    $s2, $s2, -4
    j    cond3
end_for3:
    swc1    $f1, 0($s1)        # arr[start] = tmp
    addi    $a1, $a1, 1        # start++
    addi    $a2, $a2, 1        # mid++
    addi    $s0, $s0, 1        # start_r++
end_if2:
    j    begin_while
# end_do
end_while:
return:
    lw    $a1,  0($sp)
    lw    $a2,  4($sp)
    lw    $a3,  8($sp)
    lw    $ra, 12($sp)
    addi    $sp, $sp, 16
    jr    $ra


#####################################
# function printArray()
printArray:
# preserve a0
    addi    $sp, $sp, -8
    sw    $a0, 0($sp)        # Preserve the address $a0 of array
    sw    $ra, 4($sp)
# ------------------------------------------------#
    # s0 = size, a0 = array
    la    $s0, array        # Load the address of array to $s0
    lw    $s1, size        # Load size of array to $s1 = size = 15
    sll    $s1, $s1, 2        # byte offset from arr[0] to arr[14]
    add    $s1, $s0, $s1        # add offset to the address of arr[0]; $s1 = addr of arr[14]
    # for (i = 0; i < size; i++)
cond:
    beq    $s0, $s1, endfor    # if (i ($s0) < size ($s1)), jump to endfor
# begin_loop:
    addi    $a0, $zero, ' '        # Load a space character to $a0
    li    $v0, 11            # Print a space
    syscall

    lwc1    $f12, 0($s0)        # load float to f12 to print
    li    $v0, 2            # code 2 to print float
    syscall
# end_loop:
    addi    $s0, $s0, 4        # Move 4 bytes to the address of arr[i+1]
    j    cond
endfor:
    lw    $a0, 0($sp)
    lw    $ra, 4($sp)
    addi    $sp, $sp, 8
    jr    $ra
