#!/bin/sh
# runtests.sh --
#    Bourne shell script to control a program that uses funit
#    Name of the program: first argument
#
#    $Id: runtests.sh,v 1.2 2008/01/26 11:15:10 arjenmarkus Exp $
#
set -e 
rm -f netcdf_out_*.tmp; 
rm -f OUTPUT_test
rm -f mckernel_tests.log
rm -f fail_messages.txt

echo "Running test"
set +e 
echo ALL >ftnunit.run

chk=1
until test ! -f ftnunit.lst -a $chk -eq 0 ; do
    chk=0
    #valgrind --tool=memcheck $1 $2 $3 $4 $5 $6 $7 $8 $9 >>runtests.log 2>&1
    mpirun -n 1 $1 $2 >>mckernel_tests.log 2>&1
done
set -e 

rm ftnunit.run

# Present some test results
tail -n 5 mckernel_tests.log
if grep -C 1 "assertion failed" ./mckernel_tests.log > fail_messages.txt
then
  echo 
  echo "Details of failed tests:"
  cat fail_messages.txt
  echo 
  echo "See tests/mckernel_tests.log for details"
  return -1
fi
