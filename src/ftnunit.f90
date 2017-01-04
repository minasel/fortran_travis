!******************************************************************************
!
!    This file is part of:
!    MC Kernel: Calculating seismic sensitivity kernels on unstructured meshes
!    Copyright (C) 2016 Simon Staehler, Martin van Driel, Ludwig Auer
!
!    You can find the latest version of the software at:
!    <https://www.github.com/tomography/mckernel>
!
!    MC Kernel is free software: you can redistribute it and/or modify
!    it under the terms of the GNU General Public License as published by
!    the Free Software Foundation, either version 3 of the License, or
!    (at your option) any later version.
!
!    MC Kernel is distributed in the hope that it will be useful,
!    but WITHOUT ANY WARRANTY; without even the implied warranty of
!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!    GNU General Public License for more details.
!
!    You should have received a copy of the GNU General Public License
!    along with MC Kernel. If not, see <http://www.gnu.org/licenses/>.
!
!******************************************************************************

!=========================================================================================
! ftnunit.f90 --
!     Module that implements part of the "ftnunit" framework:
!     It is inspired by the well-known JUnit framework for
!     integrating unit tests in a Java application.
!
!     The module offers:
!     - a set of common utilities, such as assertion checking
!       routines
!     - a general routine to run the tests if requested
!     - resources that keep track of the status
!
!     Related files:
!     runtests.sh
!
!     Modified version of:
!     $Id: ftnunit.f90,v 1.3 2008/01/27 09:08:31 arjenmarkus Exp $
!     
module ftnunit
    implicit none

    integer, private, save       :: last_test            ! Last test that was started
    integer, private, save       :: testno               ! Current test number
    integer, private, save       :: nofails              ! Number of assertions that failed
    integer, private, save       :: noruns               ! Number of runs so far
    logical, private, save       :: call_final = .true.  ! Call runtests_final implicitly?

    real, private, save          :: infinity = huge(1.0) ! used to test for infinite values
    integer, private, parameter  :: sp = selected_real_kind(6, 37)
    integer, private, parameter  :: dp = selected_real_kind(15, 307)
    
    interface assert_equal
        module procedure assert_equal_int
        module procedure assert_equal_int1d
    end interface

    interface assert_comparable
        module procedure assert_comparable_real
        module procedure assert_comparable_real1d
        module procedure assert_comparable_real2d
        module procedure assert_comparable_dble
        module procedure assert_comparable_dble1d
        module procedure assert_comparable_dble2d
    end interface
    
    interface assert_true
        module procedure assert_true_log
        module procedure assert_alltrue_log1d
    end interface

    interface assert_false
        module procedure assert_false_log
        module procedure assert_allfalse_log1d
    end interface

    interface isnan
        module procedure isnan_sp
        module procedure isnan_dp
        module procedure isnan_int
    end interface

contains

!-----------------------------------------------------------------------------------------
! test --
!     Routine to run a unit test
! Arguments:
!     proc          The subroutine implementing the unit test
!     text          Text describing the test
subroutine test( proc, text )
    external          :: proc
    character(len=*)  :: text

    integer           :: lun

    ! Check if the test should run
    testno = testno + 1
    if ( testno <= last_test ) then
        return
    endif

    ! Record the fact that we started the test
    open( newunit=lun, file = 'ftnunit.lst' )
    write( lun, * ) testno, nofails, noruns
    close( lun )

    ! Run the test
    write( *, '(2a)' ) 'Test: ', trim(text)
    call flush(6)

    call proc

    ! No runtime error or premature end of
    ! the program ...
    open( newunit=lun, file = 'ftnunit.lst' )
    write( lun, * ) testno, nofails, noruns
    close( lun )

end subroutine test
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
! runtests_init --
!     Subroutine to initialise the ftnunit system
! Arguments:
!     None
! Note:
!     Use in conjunction with runtests_final to enable multiple calls
!     to the runtests subroutine. This makes it easier to run tests
!     from different modules, as you have more than one subroutine to
!     do the actual tests.
subroutine runtests_init
    call_final = .false.
end subroutine
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
! runtests_final --
!     Subroutine to report the overall statistics
! Arguments:
!     None
! Note:
!     Use in conjunction with runtests_init to enable multiple calls
!     to the runtests subroutine. This makes it easier to run tests
!     from different modules, as you have more than one subroutine to
!     do the actual tests.
subroutine runtests_final
    if ( ftnunit_file_exists("ftnunit.run") ) then
        write(6,'(/,/,a,/,a)') 'TEST SUMMARY', '------------'
        write(*,'(a,i5)') 'Number of failed assertions:                ', nofails
        write(*,'(a,i5)') 'Number of program crashes during testing:   ', noruns - 1
        call ftnunit_remove_file( "ftnunit.lst" )
        call exit()
    endif
end subroutine
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
! runtests --
!     Subroutine to run the tests if requested
! Arguments:
!     testproc      The test subroutine that actually runs the unit test
subroutine runtests( testproc )
    interface
        subroutine testproc
        end subroutine testproc
    end interface

    integer :: lun
    integer :: ierr

    last_test = 0
    nofails   = 0
    noruns    = 0
    testno    = 0

    if ( ftnunit_file_exists("ftnunit.run") ) then

        if (noruns == 0) write(6,'(/,a,/,a)') 'TEST DETAILS', &
                '------------------------------------------------------------------------------------------'

        if ( ftnunit_file_exists("ftnunit.lst") ) then
            open( newunit=lun, file = "ftnunit.lst", iostat = ierr )
            if ( ierr == 0 ) then
                read( lun, *, iostat = ierr ) last_test, nofails, noruns
                if ( ierr /= 0 ) then
                    last_test = 0
                    nofails   = 0
                    noruns    = 0
                endif
                close( lun )
            endif
        endif

        noruns = noruns + 1

        if (noruns /= 0) write(6,'(a,i4)') 'RUN NO', noruns

        call testproc

        if ( call_final ) then
            call runtests_final
        endif

    endif

end subroutine runtests
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
! assert_true --
!     Subroutine to check if a condition is true
! Arguments:
!     cond          Condition to be checked
!     text          Text describing the assertion
! Side effects:
!     If the assertion fails, this is reported to standard
!     output. Also, nofails is increased by one.
!subroutine assert_true( cond, text )
!    logical, intent(in)          :: cond
!    character(len=*), intent(in) :: text
!
!    if ( .not. cond ) then
!        nofails = nofails + 1
!        write(*,*) '    Condition "',trim(text), '" failed'
!        write(*,*) '    It should have been true'
!    endif
!end subroutine assert_true
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
! assert_false --
!     Subroutine to check if a condition is false
! Arguments:
!     cond          Condition to be checked
!     text          Text describing the assertion
! Side effects:
!     If the assertion fails, this is reported to standard
!     output. Also, nofails is increased by one.
!subroutine assert_false( cond, text )
!    logical, intent(in)          :: cond
!    character(len=*), intent(in) :: text
!
!    if ( cond ) then
!        nofails = nofails + 1
!        write(*,*) '    Condition "',trim(text), '" failed'
!        write(*,*) '    It should have been false'
!    endif
!end subroutine assert_false
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
! assert_equal_int --
!     Subroutine to check if two integers are equal
! Arguments:
!     value1        First value
!     value2        Second value
!     text          Text describing the assertion
! Side effects:
!     If the assertion fails, this is reported to standard
!     output. Also, nofails is increased by one.
!
subroutine assert_equal_int( value1, value2, text )
    integer, intent(in)          :: value1
    integer, intent(in)          :: value2
    character(len=*), intent(in) :: text

    if ( value1 /= value2) then
        nofails = nofails + 1
        write(*,*) '    Values not equal: "',trim(text), '" - assertion failed'
        write(*,*) '    Values: ', value1, ' and ', value2
    endif
end subroutine assert_equal_int
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
! assert_equal_int1d --
!     Subroutine to check if two integer arrays are equal
! Arguments:
!     array1        First array
!     array2        Second array
!     text          Text describing the assertion
! Side effects:
!     If the assertion fails, this is reported to standard
!     output. Also, nofails is increased by one.
subroutine assert_equal_int1d( array1, array2, text )
    integer, dimension(:), intent(in) :: array1
    integer, dimension(:), intent(in) :: array2
    character(len=*), intent(in)      :: text

    integer                           :: i
    integer                           :: count

    if ( size(array1) /= size(array2) ) then
        nofails = nofails + 1
        write(*,*) '    Arrays have different sizes: "',trim(text), '" - assertion failed'
    else
        if ( any( array1 /= array2 ) ) then
            nofails = nofails + 1
            write(*,*) '    One or more values different: "',trim(text), '" - assertion failed'
            count = 0
            write(*,'(3a10)')    '    Index', '     First', '    Second'
            do i = 1,size(array1)
                if ( array1(i) /= array2(i) ) then
                    count = count + 1
                    if ( count < 50 ) then
                        write(*,'(3i10)')    i, array1(i), array2(i)
                    endif
                endif
            enddo
            write(*,*) '    Number of differences: ', count
        endif
    endif
end subroutine assert_equal_int1d
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
! assert_comparable_dble --
!     Subroutine to check if two double precision reals are approximately equal
! Arguments:
!     value1        First value
!     value2        Second value
!     margin        Allowed margin (relative)
!     text          Text describing the assertion
! Side effects:
!     If the assertion fails, this is reported to standard
!     output. Also, nofails is increased by one.
subroutine assert_comparable_dble( value1, value2, margin, text )
    real(kind=dp), intent(in)    :: value1
    real(kind=dp), intent(in)    :: value2
    real(kind=dp), intent(in)    :: margin
    character(len=*), intent(in) :: text

    if (value1 > infinity .or. -value1 > infinity) then
        write(*,*) '   value1 is infinite - assertion failed'
        write(*,*) trim(text)
        nofails = nofails + 1
    elseif (value2 > infinity .or. -value2 > infinity) then
        write(*,*) '   value2 is infinite - assertion failed'
        write(*,*) trim(text)
        nofails = nofails + 1
    elseif (isnan(value1)) then
        write(*,*) '   value1 is NAN - assertion failed'
        write(*,*) trim(text)
        nofails = nofails + 1
    elseif (isnan(value2)) then
        write(*,*) '   value2 is NAN - assertion failed'
        write(*,*) trim(text)
        nofails = nofails + 1
    endif

    if ( abs(value1-value2) > 0.5d0 * margin * (abs(value1)+abs(value2)) ) then
        nofails = nofails + 1
        write(*,*) '    Values not comparable: "',trim(text), '" - assertion failed'
        write(*,*) '    Values: ', value1, ' and ', value2
    endif
end subroutine assert_comparable_dble
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
! assert_compatable_dble1d --
!     Subroutine to check if two double precision arrays are comparable
! Arguments:
!     array1        First array
!     array2        Second array
!     margin        Allowed margin (relative)
!     text          Text describing the assertion
! Side effects:
!     If the assertion fails, this is reported to standard
!     output. Also, nofails is increased by one.
subroutine assert_comparable_dble1d( array1, array2, margin, text )
    real(kind=dp), dimension(:), intent(in)  :: array1
    real(kind=dp), dimension(:), intent(in)  :: array2
    real(kind=dp), intent(in)                :: margin
    character(len=*), intent(in)             :: text

    integer                                  :: i
    integer                                  :: count

    if ( size(array1) /= size(array2) ) then
        nofails = nofails + 1
        write(*,*) '    Arrays have different sizes: "',trim(text), '" - assertion failed'
    else
        if (any(array1 > infinity) .or. any(-array1 > infinity)) then
            write(*,*) '   array1 contains infinite values - assertion failed'
            write(*,*) trim(text)
            nofails = nofails + 1
        elseif (any(array2 > infinity) .or. any(-array2 > infinity)) then
            write(*,*) '   array2 contains infinite values - assertion failed'
            write(*,*) trim(text)
            nofails = nofails + 1
        elseif (any(isnan(array1))) then
            write(*,*) '   array1 contains NAN values - assertion failed'
            write(*,*) trim(text)
            nofails = nofails + 1
        elseif (any(isnan(array2))) then
            write(*,*) '   array2 contains NAN values - assertion failed'
            write(*,*) trim(text)
            nofails = nofails + 1
        endif

        if ( any( abs(array1-array2) > 0.5d0 * margin * (abs(array1)+abs(array2)) ) ) then
            nofails = nofails + 1
            write(*,*) '    One or more values different: "',trim(text), '" - assertion failed'
            count = 0
            write(*,'(a10,2a15)')    '    Index', '          First', '         Second'
            do i = 1,size(array1)
                if ( abs(array1(i)-array2(i)) > &
                         0.5 * margin * (abs(array1(i))+abs(array2(i))) ) then
                    count = count + 1
                    if ( count < 50 ) then
                        write(*,'(i10,e15.5,e15.5)')    i, array1(i), array2(i)
                    endif
                endif
            enddo
            write(*,*) 'Number of differences: ', count
        endif
    endif
end subroutine assert_comparable_dble1d
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
! assert_compatable_dble2d --
!     Subroutine to check if two double precision arrays are comparable
! Arguments:
!     array1        First array
!     array2        Second array
!     margin        Allowed margin (relative)
!     text          Text describing the assertion
! Side effects:
!     If the assertion fails, this is reported to standard
!     output. Also, nofails is increased by one.
subroutine assert_comparable_dble2d( array1, array2, margin, text )
    real(kind=dp), dimension(:,:), intent(in)  :: array1
    real(kind=dp), dimension(:,:), intent(in)  :: array2
    real(kind=dp), intent(in)                  :: margin
    character(len=*), intent(in)               :: text

    integer                                    :: i, j
    integer                                    :: count

    if ( size(array1) /= size(array2) ) then
        nofails = nofails + 1
        write(*,*) '    Arrays have different sizes: "',trim(text), '" - assertion failed'
    else
        if (any(array1 > infinity) .or. any(-array1 > infinity)) then
            write(*,*) '   array1 contains infinite values - assertion failed'
            write(*,*) trim(text)
            nofails = nofails + 1
        elseif (any(array2 > infinity) .or. any(-array2 > infinity)) then
            write(*,*) '   array2 contains infinite values - assertion failed'
            write(*,*) trim(text)
            nofails = nofails + 1
        elseif (any(isnan(array1))) then
            write(*,*) '   array1 contains NAN values - assertion failed'
            write(*,*) trim(text)
            nofails = nofails + 1
        elseif (any(isnan(array2))) then
            write(*,*) '   array2 contains NAN values - assertion failed'
            write(*,*) trim(text)
            nofails = nofails + 1
        endif

        if ( any( abs(array1-array2) > 0.5d0 * margin * (abs(array1)+abs(array2)) ) ) then
            nofails = nofails + 1
            write(*,*) '    One or more values different: "',trim(text), '" - assertion failed'
            count = 0
            write(*,'(2a10,2a15)')    '    Index          ', '          First', '         Second'
            do i = 1,size(array1, 1)
                do j = 1,size(array1, 2)
                    if ( abs(array1(i,j)-array2(i,j)) > &
                             0.5 * margin * (abs(array1(i,j))+abs(array2(i,j))) ) then
                        count = count + 1
                        if ( count < 50 ) then
                            write(*,'(i10,i10,e15.5,e15.5)')    i, j, array1(i,j), array2(i,j)
                        endif
                    endif
                end do
            enddo
            write(*,*) 'Number of differences: ', count
        endif
    endif
end subroutine assert_comparable_dble2d
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
! assert_comparable_real --
!     Subroutine to check if two reals are approximately equal
! Arguments:
!     value1        First value
!     value2        Second value
!     margin        Allowed margin (relative)
!     text          Text describing the assertion
! Side effects:
!     If the assertion fails, this is reported to standard
!     output. Also, nofails is increased by one.
subroutine assert_comparable_real( value1, value2, margin, text )
    real, intent(in)             :: value1
    real, intent(in)             :: value2
    real, intent(in)             :: margin
    character(len=*), intent(in) :: text

    if (value1 > infinity .or. -value1 > infinity) then
        write(*,*) '   value1 is infinite - assertion failed'
        write(*,*) trim(text)
        nofails = nofails + 1
    elseif (value2 > infinity .or. -value2 > infinity) then
        write(*,*) '   value2 is infinite - assertion failed'
        write(*,*) trim(text)
        nofails = nofails + 1
    elseif (isnan(value1)) then
        write(*,*) '   value1 is NAN - assertion failed'
        write(*,*) trim(text)
        nofails = nofails + 1
    elseif (isnan(value2)) then
        write(*,*) '   value2 is NAN - assertion failed'
        write(*,*) trim(text)
        nofails = nofails + 1
    endif

    if ( abs(value1-value2) > 0.5 * margin * (abs(value1)+abs(value2)) ) then
        nofails = nofails + 1
        write(*,*) '    Values not comparable: "',trim(text), '" - assertion failed'
        write(*,*) '    Values: ', value1, ' and ', value2
    endif
end subroutine assert_comparable_real
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
! assert_compatable_real1d --
!     Subroutine to check if two real arrays are comparable
! Arguments:
!     array1        First array
!     array2        Second array
!     margin        Allowed margin (relative)
!     text          Text describing the assertion
! Side effects:
!     If the assertion fails, this is reported to standard
!     output. Also, nofails is increased by one.
subroutine assert_comparable_real1d( array1, array2, margin, text )
    real, dimension(:), intent(in)    :: array1
    real, dimension(:), intent(in)    :: array2
    real, intent(in)                  :: margin
    character(len=*), intent(in)      :: text

    integer                           :: i
    integer                           :: count

    if ( size(array1) /= size(array2) ) then
        nofails = nofails + 1
        write(*,*) '    Arrays have different sizes: "',trim(text), '" - assertion failed'
    else
        if (any(array1 > infinity) .or. any(-array1 > infinity)) then
            write(*,*) '   array1 contains infinite values - assertion failed'
            write(*,*) trim(text)
            nofails = nofails + 1
        elseif (any(array2 > infinity) .or. any(-array2 > infinity)) then
            write(*,*) '   array2 contains infinite values - assertion failed'
            write(*,*) trim(text)
            nofails = nofails + 1
        elseif (any(isnan(array1))) then
            write(*,*) '   array1 contains NAN values - assertion failed'
            write(*,*) trim(text)
            nofails = nofails + 1
        elseif (any(isnan(array2))) then
            write(*,*) '   array2 contains NAN values - assertion failed'
            write(*,*) trim(text)
            nofails = nofails + 1
        endif

        if ( any( abs(array1-array2) > 0.5 * margin * (abs(array1)+abs(array2)) ) ) then
            nofails = nofails + 1
            write(*,*) '    One or more values different: "',trim(text), '" - assertion failed'
            count = 0
            write(*,'(a10,2a15)')    '    Index', '          First', '         Second'
            do i = 1,size(array1)
                if ( abs(array1(i)-array2(i)) > &
                         0.5 * margin * (abs(array1(i))+abs(array2(i))) ) then
                    count = count + 1
                    if ( count < 50 ) then
                        write(*,'(i10,e15.5,e15.5)')    i, array1(i), array2(i)
                    endif
                endif
            enddo
            write(*,*) 'Number of differences: ', count
        endif
    endif
end subroutine assert_comparable_real1d
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
! assert_compatable_real2d --
!     Subroutine to check if two single precision arrays are comparable
! Arguments:
!     array1        First array
!     array2        Second array
!     margin        Allowed margin (relative)
!     text          Text describing the assertion
! Side effects:
!     If the assertion fails, this is reported to standard
!     output. Also, nofails is increased by one.
subroutine assert_comparable_real2d( array1, array2, margin, text )
    real(kind=sp), dimension(:,:), intent(in)  :: array1
    real(kind=sp), dimension(:,:), intent(in)  :: array2
    real(kind=sp), intent(in)                  :: margin
    character(len=*), intent(in)               :: text

    integer                                    :: i, j
    integer                                    :: count

    if ( size(array1) /= size(array2) ) then
        nofails = nofails + 1
        write(*,*) '    Arrays have different sizes: "',trim(text), '" - assertion failed'
    else
        if (any(array1 > infinity) .or. any(-array1 > infinity)) then
            write(*,*) '   array1 contains infinite values - assertion failed'
            write(*,*) trim(text)
            nofails = nofails + 1
        elseif (any(array2 > infinity) .or. any(-array2 > infinity)) then
            write(*,*) '   array2 contains infinite values - assertion failed'
            write(*,*) trim(text)
            nofails = nofails + 1
        elseif (any(isnan(array1))) then
            write(*,*) '   array1 contains NAN values - assertion failed'
            write(*,*) trim(text)
            nofails = nofails + 1
        elseif (any(isnan(array2))) then
            write(*,*) '   array2 contains NAN values - assertion failed'
            write(*,*) trim(text)
            nofails = nofails + 1
        endif

        if ( any( abs(array1-array2) > 0.5d0 * margin * (abs(array1)+abs(array2)) ) ) then
            nofails = nofails + 1
            write(*,*) '    One or more values different: "',trim(text), '" - assertion failed'
            count = 0
            write(*,'(2a10,2a15)')    '    Index          ', '          First', '         Second'
            do i = 1,size(array1, 1)
                do j = 1,size(array1, 2)
                    if ( abs(array1(i,j)-array2(i,j)) > &
                             0.5 * margin * (abs(array1(i,j))+abs(array2(i,j))) ) then
                        count = count + 1
                        if ( count < 50 ) then
                            write(*,'(i10,i10,e15.5,e15.5)')    i, j, array1(i,j), array2(i,j)
                        endif
                    endif
                end do
            enddo
            write(*,*) 'Number of differences: ', count
        endif
    endif
end subroutine assert_comparable_real2d
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
! assert_true_log --
!     Subroutine to check if two integers are equal
! Arguments:
!     logi          logical to be tested
!     text          Text describing the assertion
! Side effects:
!     If the assertion fails, this is reported to standard
!     output. Also, nofails is increased by one.
!
subroutine assert_true_log( logi, text )
    logical, intent(in)          :: logi
    character(len=*), intent(in) :: text

    if ( .not. logi) then
        nofails = nofails + 1
        write(*,*) '    Logical is not TRUE: "',trim(text), '" - assertion failed'
    endif
end subroutine assert_true_log
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
! assert_alltrue_log1d --
!     Subroutine to check if two integer arrays are equal
! Arguments:
!     logiarray     Logical array
!     text          Text describing the assertion
! Side effects:
!     If the assertion fails, this is reported to standard
!     output. Also, nofails is increased by one.
subroutine assert_alltrue_log1d( logiarray, text )
    logical, dimension(:), intent(in) :: logiarray
    character(len=*), intent(in)      :: text

    integer                           :: i
    integer                           :: count

    if ( any(.not. logiarray) ) then
        nofails = nofails + 1
        write(*,*) '    One or more logicals are false: "',trim(text), '" - assertion failed'
        count = 0
        write(*,*) '    Indices of false values:' 
        do i = 1,size(logiarray)
            if ( .not. logiarray(i) ) then
                count = count + 1
                if ( count < 50 ) then
                    write(*,'(i10)')    i
                endif
            endif
        enddo
        write(*,*) '    Number of false values: ', count
    endif
end subroutine assert_alltrue_log1d
!-----------------------------------------------------------------------------------------


!-----------------------------------------------------------------------------------------
! assert_false_log --
!     Subroutine to check if two integers are equal
! Arguments:
!     logi          logical to be tested
!     text          Text describing the assertion
! Side effects:
!     If the assertion fails, this is reported to standard
!     output. Also, nofails is increased by one.
!
subroutine assert_false_log( logi, text )
    logical, intent(in)          :: logi
    character(len=*), intent(in) :: text

    if ( logi) then
        nofails = nofails + 1
        write(*,*) '    Logical is not FALSE: "',trim(text), '" - assertion failed'
    endif
end subroutine assert_false_log
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
! assert_allfalse_log1d --
!     Subroutine to check if two integer arrays are equal
! Arguments:
!     logiarray     Logical array
!     text          Text describing the assertion
! Side effects:
!     If the assertion fails, this is reported to standard
!     output. Also, nofails is increased by one.
subroutine assert_allfalse_log1d( logiarray, text )
    logical, dimension(:), intent(in) :: logiarray
    character(len=*), intent(in)      :: text

    integer                           :: i
    integer                           :: count

    if ( any(logiarray) ) then
        nofails = nofails + 1
        write(*,*) '    One or more logicals are true: "',trim(text), '" - assertion failed'
        count = 0
        write(*,*) '    Indices of true values:' 
        do i = 1,size(logiarray)
            if ( logiarray(i) ) then
                count = count + 1
                if ( count < 50 ) then
                    write(*,'(i10)')    i
                endif
            endif
        enddo
        write(*,*) '    Number of true values: ', count
    endif
end subroutine assert_allfalse_log1d
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
! assert_file_exists --
!     Subroutine to check if a condition is true
! Arguments:
!     filename      File to be checked for existence
!     text          Text describing the assertion
! Side effects:
!     If the assertion fails, this is reported to standard
!     output. Also, nofails is increased by one.
subroutine assert_file_exists( filename, text )
    character(len=*), intent(in) :: filename, text

    if ( .not. ftnunit_file_exists(trim(filename)) ) then
        nofails = nofails + 1
        write(*,*) '    Condition "',trim(text), '" failed'
        write(*,*) '    File "', trim(filename) ,'" does not exist'
    endif
end subroutine assert_file_exists
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
! ftnunit_file_exists --
!     Auxiliary function to see if a file exists
! Arguments:
!     filename      Name of the file to check
! Returns:File to be checked for existence
!     .true. if the file exists, .false. otherwise
logical function ftnunit_file_exists( filename )
    character(len=*), intent(in) :: filename

    inquire( file = filename, exist = ftnunit_file_exists )
end function ftnunit_file_exists
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
! ftnunit_remove_file --
!     Auxiliary subroutine to remove a file
! Arguments:
!     filename      Name of the file to be removed
subroutine ftnunit_remove_file( filename )
    character(len=*), intent(in) :: filename

    integer                      :: lun
    integer                      :: ierr

    open( newunit=lun, file = filename, iostat = ierr )
    if ( ierr /= 0 ) then
        write(*,*) '    Could not open file for removal: ', trim(filename)
        nofails = nofails + 1
    else
        close( lun, status = 'delete' )
        if ( ftnunit_file_exists( filename ) ) then
            write(*,*) '    Removal of file unsuccssful: ', trim(filename)
            nofails = nofails + 1
        endif
    endif

end subroutine ftnunit_remove_file
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
! ftnunit_make_empty_file --
!     Auxiliary subroutine to make an empty file
! Arguments:
!     filename      Name of the file to be created
subroutine ftnunit_make_empty_file( filename )
    character(len=*), intent(in) :: filename

    integer                      :: lun
    integer                      :: ierr

    if ( ftnunit_file_exists( filename ) ) then
        call ftnunit_remove_file( filename )
    endif
    open( newunit=lun, file = filename, iostat = ierr, status = 'new' )
    if ( ierr /= 0 ) then
        write(*,*) '    Failed to create empty file: ', trim(filename)
        nofails = nofails + 1
    else
        close( lun )
    endif

end subroutine ftnunit_make_empty_file
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
elemental logical function isnan_sp(array)
  real(kind=sp), intent(in) :: array

  isnan_sp = array.ne.array
end function
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
elemental logical function isnan_dp(array)
  real(kind=dp), intent(in) :: array

  isnan_dp = array.ne.array
end function
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------
elemental logical function isnan_int(array)
  integer, intent(in)       :: array

  isnan_int = array.ne.array
end function
!-----------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------

end module ftnunit
!=========================================================================================
