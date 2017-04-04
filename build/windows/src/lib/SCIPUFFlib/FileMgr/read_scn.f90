!*******************************************************************************
!$RCSfile$
!$Revision$
!$Date$
!*******************************************************************************
!===============================================================================
!     ReadNamelistScn
!===============================================================================
SUBROUTINE ReadNamelistScn( iunit )

USE convert_fd
USE relparam_fd
USE scipuff_fi

IMPLICIT NONE

INTEGER, INTENT( IN ) :: iunit

INTEGER, PARAMETER :: STATUS_COMPLETE  = 1

INTEGER ios

LOGICAL opready
INTEGER relEffect

REAL    size                     !Local to avoid conflict with implicit function name
REAL    lognorm_mmd
REAL    lognorm_sigma
REAL    random_spread
REAL    random_spreadT
REAL    random_spreadV
REAL    random_dir
REAL    horiz_uncertainty
REAL    vert_uncertainty
REAL    slurry_fraction
REAL    active_fraction
INTEGER number_random
INTEGER random_seed

INTEGER, EXTERNAL :: FindNML
REAL,    EXTERNAL :: Int2Real, ScaleReal

REAL                 :: PArel    !For compatibility with NWPN

REAL, DIMENSION(150) :: rel_mc   !For compatibility with MULTCOMP

NAMELIST / scn / trel, xrel, yrel, zrel, cmass, subgroup, tdur, &
                 size, sigx, sigy, sigz, urel, vrel, wrel, &
                 sigRxy, sigRxz, sigRyz, umom, vmom, wmom, buoy, &
                 lognorm_mmd, lognorm_sigma, slurry_fraction, active_fraction, &
                 number_random, random_spread, random_seed, &
                 random_spreadT, random_spreadV, random_dir, &
                 horiz_uncertainty, vert_uncertainty, &
                 PArel, &
                 reltyp, name_rel, relmat, &
                 rel_mc, rel_param, &
                 relName, relDisplay, relStatus, &
                 opid, opmod, opready, relEffect !For backward compatability

!==== Initialize

number_random = NOT_SET_I
random_seed   = NOT_SET_I

size              = NOT_SET_R
lognorm_mmd       = NOT_SET_R
lognorm_sigma     = NOT_SET_R
random_spread     = NOT_SET_R
random_spreadT    = NOT_SET_R
random_spreadV    = NOT_SET_R
random_dir        = NOT_SET_R
slurry_fraction   = NOT_SET_R
opid             =  0
active_fraction = 1.0

!==== Read

ios = FindNML( iunit,'scn' )

IF( ios == 0 )THEN
  READ(UNIT=iunit,NML=scn,IOSTAT=ios)
END IF
IF( ios > 0 )THEN
  nError   = RD_ERROR
  eRoutine = 'ReadNamelistScn'
  eMessage = 'Error reading SCN namelist'
  GOTO 9999
ELSE IF( ios < 0 )THEN
  nError   = EOF_ERROR
  eRoutine = 'ReadNamelistScn'
  eMessage = 'EOF reading SCN namelist'
  GOTO 9999
END IF

IF( size /= NOT_SET_R )size_rel = size

CALL cupper( relmat )

!==== Check for old-style single character release definitions

IF( reltyp(1:2) == 'C ' )THEN
  IF( tdur == DEF_VAL_R )THEN
    reltyp = 'CP'
  ELSE IF( urel /= 0.0 .OR. vrel /= 0.0 .OR. wrel /= 0.0 )THEN
    reltyp = 'CM'
  END IF
ELSE IF( reltyp(1:2) == 'I ' )THEN
  IF( LEN_TRIM(name_rel) > 0 )reltyp ='IF'
END IF

!==== Check old Opid

IF( TRIM(relName) == '<empty>' )THEN

  IF( opid /= NOT_SET_I )THEN
    WRITE(relName,'(i8)')opid
  ELSE
    relName = ' '
  END IF

  IF( relStatus == NOT_SET_I )THEN
    IF( opid > 0 )THEN
      relStatus = opmod(OPREADY_INDEX)
    ELSE
      relStatus = STATUS_COMPLETE
    END IF
  END IF

END IF

!==== Reset

trel = ScaleReal( trel,HCF_HOUR2SEC )
IF( reltyp(1:1) == 'C' )THEN
  IF( tdur <= 0. )THEN
    nError   = IV_ERROR
    eRoutine = 'ReadNamelistScn'
    eMessage = 'Must set TDUR for RELTYP=C in scenario input'
    GOTO 9999
  END IF
  tdur = ScaleReal( tdur,HCF_HOUR2SEC )
END IF

!==== umom/vmom initialzed to DEF_VAL_R but only CS has them on the NAMELIST so zero out for all others
IF( reltyp(1:2) /= 'CS' .OR. reltyp(1:3) == 'CSP' )THEN
  umom = 0.0
  vmom = 0.0
END IF
IF( reltyp(1:2) == 'CS' )THEN
  !--Force update of CS release
  relStatus = 0 !STATUS_INVALID
END IF

IF( slurry_fraction == DEF_VAL_R )slurry_fraction = NOT_SET_R
IF( lognorm_mmd /= NOT_SET_R )THEN
  CALL CheckRangeReal( lognorm_mmd  ,1.E-30,1.E30,'Lognormal MMD' )
  CALL CheckRangeReal( lognorm_sigma,1.0   ,1.E30,'Lognormal sigma' )
  IF( nError /= NO_ERROR )GOTO 9999
  rel_param(REL_MMD_INDX)   = lognorm_mmd
  rel_param(REL_SIGMA_INDX) = lognorm_sigma
ELSE
  rel_param(REL_MMD_INDX)   = NOT_SET_R
  rel_param(REL_SIGMA_INDX) = NOT_SET_R
END IF

IF( slurry_fraction /= NOT_SET_R )THEN
  CALL CheckRangeReal( slurry_fraction  ,1.E-30,1.0,'Slurry fraction' )
  IF( nError /= NO_ERROR )GOTO 9999
END IF
rel_param(REL_WMFRAC_INDX) = slurry_fraction

CALL CheckRangeReal( active_fraction  ,1.E-30,1.0,'Active fraction' )
IF( nError /= NO_ERROR )GOTO 9999
rel_param(REL_AFRAC_INDX) = active_fraction

IF( number_random /= NOT_SET_I )THEN
  CALL CheckRangeReal( random_spread,0.0,1.E30,'Random spread' )
  IF( nError /= NO_ERROR )GOTO 9999

  rel_param(REL_RAND_INDX)   = Int2Real( number_random )
  rel_param(REL_SPREAD_INDX) = random_spread
  rel_param(REL_SEED_INDX)   = Int2Real( random_seed )
  IF( reltyp == 'IX3' )THEN
    rel_param(REL_SPREADT_INDX) = random_spreadT
    rel_param(REL_SPREADV_INDX) = random_spreadV
    rel_param(REL_RANDIR_INDX)  = random_dir
  ELSE
    rel_param(REL_SPREADT_INDX) = NOT_SET_R
    rel_param(REL_SPREADV_INDX) = NOT_SET_R
    rel_param(REL_RANDIR_INDX)  = NOT_SET_R
  END IF
ELSE
  rel_param(REL_RAND_INDX)    = NOT_SET_R
  rel_param(REL_SPREAD_INDX)  = NOT_SET_R
  rel_param(REL_SEED_INDX)    = NOT_SET_R
  rel_param(REL_SPREADT_INDX) = NOT_SET_R
  rel_param(REL_SPREADV_INDX) = NOT_SET_R
  rel_param(REL_RANDIR_INDX)  = NOT_SET_R
END IF

CALL ReadNamelistMC( iunit )
IF( nError /= NO_ERROR )GOTO 9999

9999 CONTINUE

RETURN
END
!===============================================================================
!     CountNamelistScn
!===============================================================================
SUBROUTINE CountNamelistScn( iunit,nRel )

USE convert_fd
USE relparam_fd
USE scipuff_fi

IMPLICIT NONE

INTEGER, INTENT( IN )    :: iunit
INTEGER, INTENT( INOUT ) :: nRel

INTEGER, PARAMETER :: STATUS_COMPLETE  = 1

INTEGER ios

LOGICAL opready
INTEGER relEffect

REAL    size                     !Local to avoid conflict with implicit function name
REAL    lognorm_mmd
REAL    lognorm_sigma
REAL    random_spread
REAL    random_spreadT
REAL    random_spreadV
REAL    random_dir
REAL    horiz_uncertainty
REAL    vert_uncertainty
REAL    slurry_fraction
REAL    active_fraction
INTEGER number_random
INTEGER random_seed

INTEGER, EXTERNAL :: FindNML

REAL                 :: PArel    !For compatibility with NWPN

REAL, DIMENSION(150) :: rel_mc   !For compatibility with MULTCOMP


NAMELIST / scn / trel, xrel, yrel, zrel, cmass, subgroup, tdur, &
                 size, sigx, sigy, sigz, sigRxy, sigRxz, sigRyz, urel, vrel, wrel, &
                 umom, vmom, wmom, buoy, &
                 lognorm_mmd, lognorm_sigma, slurry_fraction, active_fraction, &
                 number_random, random_spread, random_seed, &
                 random_spreadT, random_spreadV, random_dir, &
                 horiz_uncertainty, vert_uncertainty, &
                 PArel, &
                 reltyp, name_rel, relmat, &
                 rel_mc, rel_param, &
                 relName, relDisplay, relStatus, &
                 opid, opmod, opready, relEffect !For backward compatability

!==== Initialize

size = NOT_SET_R

!==== Read

ios = FindNML( iunit,'scn' )

IF( ios == 0 )THEN
  READ(UNIT=iunit,NML=scn,IOSTAT=ios)
END IF
IF( ios > 0 )THEN
  nError   = RD_ERROR
  eRoutine = 'CountNamelistScn'
  eMessage = 'Error reading SCN namelist'
  GOTO 9999
ELSE IF( ios < 0 )THEN
  nError   = EOF_ERROR
  eRoutine = 'CountNamelistScn'
  eMessage = 'EOF reading SCN namelist'
  GOTO 9999
END IF

IF( size /= NOT_SET_R )size_rel=size

nRel = nRel + 1

9999 CONTINUE

RETURN
END
!===============================================================================
!     ReadNamelistMC
!===============================================================================
SUBROUTINE ReadNamelistMC( iunit )

USE scipuff_fi

IMPLICIT NONE

INTEGER, INTENT( IN ) :: iunit

INTEGER ios, n_arg, nch
LOGICAL lerr

CHARACTER(128) line
CHARACTER(4)   kwrd

CHARACTER(32), DIMENSION(2) :: c_arg

TYPE( MCrelData ), POINTER :: nextRelMC

IF( ASSOCIATED(RelMC%rel) )CALL ClearMCrelList()

RelMC%nList = 0

READ(iunit,'(A)',IOSTAT=ios) line
IF( ios < 0 )THEN
  GOTO 9999
ELSE IF( ios > 0 )THEN
  nError   = RD_ERROR
  eRoutine = 'ReadNamelistMC'
  eMessage = 'Error reading multi-component release data'
  GOTO 9999
END IF

CALL cupper( line )
IF( TRIM(line) /= '#START_MC' )THEN
  BACKSPACE(UNIT=iunit,IOSTAT=ios)
  GOTO 9999
END IF

ALLOCATE( RelMC%rel,STAT=ios )
IF( ios /= 0 )THEN
  nError   = UK_ERROR
  eRoutine = 'ReadNamelistMC'
  eMessage = 'Error allocating array for multi-component release data'
  GOTO 9999
END IF
NULLIFY( RelMC%rel%next )

nextRelMC => RelMC%rel

CALL get_next_data( iunit,line,nch,kwrd,n_arg,c_arg,2,lerr )
IF( lerr )THEN
  nError   = RD_ERROR
  eRoutine = 'ReadNamelistMC'
  eMessage = 'Error reading multi-component release data'
  eInform  = 'Data record must be component name and release mass/rate'
  GOTO 9999
END IF

DO

  IF( n_arg /= 2 )THEN
    nError   = RD_ERROR
    eRoutine = 'ReadNamelistMC'
    eMessage = 'Error reading multi-component release data'
    GOTO 9999
  END IF

  CALL cupper( c_arg(1) )

  nextRelMC%MCname = TRIM(c_arg(1))
  READ(c_arg(2),*,IOSTAT=ios) nextRelMC%MCmass
  IF( ios /= 0 )THEN
    nError   = RD_ERROR
    eRoutine = 'ReadNamelistMC'
    eMessage = 'Error reading multi-component release data'
    GOTO 9999
  END IF

  RelMC%nList = RelMC%nList + 1

  CALL get_next_data( iunit,line,nch,kwrd,n_arg,c_arg,2,lerr )
  IF( lerr )THEN
    nError   = RD_ERROR
    eRoutine = 'ReadNamelistMC'
    eMessage = 'Error reading multi-component release data'
    eInform  = 'Data record must be component name and release mass/rate'
    GOTO 9999
  END IF

  IF( TRIM(line) == '#END_MC' )EXIT

  ALLOCATE( nextRelMC%next,STAT=ios )
  IF( ios /= 0 )THEN
    nError   = UK_ERROR
    eRoutine = 'ReadNamelistMC'
    eMessage = 'Error allocating array for multi-component release data'
    GOTO 9999
  END IF
  nextRelMC => nextRelMC%next
  NULLIFY( nextRelMC%next )

END DO

9999 CONTINUE

RETURN
END
!===============================================================================
!     CountNamelistMC
!===============================================================================
SUBROUTINE CountNamelistMC( iunit,nMCrel )

USE scipuff_fi

IMPLICIT NONE

INTEGER, INTENT( IN )    :: iunit
INTEGER, INTENT( INOUT ) :: nMCrel

INTEGER ios

CHARACTER(128) line

READ(iunit,'(A)',IOSTAT=ios) line
IF( ios < 0 )THEN
  GOTO 9999
ELSE IF( ios > 0 )THEN
  nError   = RD_ERROR
  eRoutine = 'CountNamelistMC'
  eMessage = 'Error reading multi-component release data'
  eInform  = 'Section header #Start_MC not found'
  GOTO 9999
END IF
CALL cupper( line )
IF( TRIM(line) /= '#START_MC' )THEN
  BACKSPACE(UNIT=iunit,IOSTAT=ios)
  GOTO 9999
END IF

READ(iunit,'(A)',IOSTAT=ios) line
IF( ios /= 0 )THEN
  nError   = RD_ERROR
  eRoutine = 'CountNamelistMC'
  eMessage = 'Error reading multi-component release data'
  GOTO 9999
END IF
CALL cupper( line )

DO WHILE( TRIM(line) /= '#END_MC' )
  nMCrel = nMCrel + 1

  READ(iunit,'(A)',IOSTAT=ios) line
  IF( ios /= 0 )THEN
    nError   = RD_ERROR
    eRoutine = 'CountNamelistMC'
    eMessage = 'Error reading multi-component release data'
    GOTO 9999
  END IF
  CALL cupper( line )

END DO

9999 CONTINUE

RETURN
END
!===============================================================================
!     WriteNamelistMC
!===============================================================================
SUBROUTINE WriteNamelistMC( iunit )

USE scipuff_fi

IMPLICIT NONE

INTEGER, INTENT( IN ) :: iunit

INTEGER ios

TYPE( MCrelData ), POINTER :: rel

IF( RelMC%nList == 0 )GOTO 9999

WRITE(iunit,'(A)',IOSTAT=ios) '#START_MC'
IF( ios /= 0 )THEN
  nError   = WR_ERROR
  eRoutine = 'WriteNamelistMC'
  eMessage = 'Error writing multi-component release data'
  GOTO 9999
END IF

rel => RelMC%rel

DO WHILE( ASSOCIATED(rel) )

  WRITE(iunit,'(A16,1X,1ES14.6)',IOSTAT=ios) TRIM(rel%MCname),rel%MCmass
  IF( ios /= 0 )THEN
    nError   = WR_ERROR
    eRoutine = 'WriteNamelistMC'
    eMessage = 'Error writing multi-component release data'
    GOTO 9999
  END IF

  rel => rel%next

END DO

WRITE(iunit,'(A)',IOSTAT=ios) '#END_MC'
IF( ios /= 0 )THEN
  nError   = WR_ERROR
  eRoutine = 'WriteNamelistMC'
  eMessage = 'Error writing multi-component release data'
  GOTO 9999
END IF

9999 CONTINUE

CALL ClearMCrelList()

RETURN
END
!===============================================================================
!     ClearMCrelList
!===============================================================================
SUBROUTINE ClearMCrelList()

USE scipuff_fi

IMPLICIT NONE

TYPE( MCrelData ), POINTER :: Rel, Next

Rel => RelMC%rel

DO WHILE( ASSOCIATED(Rel) )
  Next => Rel%next
  NULLIFY( Rel )
  Rel => Next
END DO

RelMC%nList = 0

RETURN
END
!===============================================================================
!     WriteNamelistScn
!===============================================================================
SUBROUTINE WriteNamelistScn( iunit )

USE convert_fd
USE scipuff_fi

IMPLICIT NONE

INTEGER, INTENT( IN ) :: iunit

REAL, EXTERNAL :: ScaleReal

trel = ScaleReal( trel,HCF_SEC2HOUR )
IF( reltyp(1:1) == 'C' )THEN
  tdur = ScaleReal( tdur,HCF_SEC2HOUR )
END IF

SELECT CASE( TRIM(reltyp) )
  CASE( 'I','IA' )
    CALL WriteNamelistScnInst( iunit )

  CASE( 'IX' )
    CALL WriteNamelistScnXInst( iunit )

  CASE( 'IX3' )
    CALL WriteNamelistScnXInst3( iunit )

  CASE( 'IF' )
    CALL WriteNamelistScnFile( iunit )

  CASE( 'C' )
    CALL WriteNamelistScnCont( iunit )

  CASE( 'CM' )
    CALL WriteNamelistScnMove( iunit )

  CASE( 'CP' )
    CALL WriteNamelistScnPool( iunit )

  CASE( 'CS','CSP' )
    CALL WriteNamelistScnStack( iunit )

  CASE DEFAULT
    nError = IV_ERROR
    eRoutine = 'WriteNamelistScn'
    eMessage = 'Invalid release type designation'
    eInform  = 'Type = '//TRIM(reltyp)

END SELECT

IF( nError /= NO_ERROR )GOTO 9999

trel = ScaleReal( trel,HCF_HOUR2SEC )
IF( reltyp(1:1) == 'C' )tdur = ScaleReal( tdur,HCF_HOUR2SEC )

CALL WriteNamelistMC( iunit )
IF( nError /= NO_ERROR )GOTO 9999

9999 CONTINUE

RETURN
END
!===============================================================================
!     WriteNamelistScnInst
!===============================================================================
SUBROUTINE WriteNamelistScnInst( iunit )

USE relparam_fd
USE scipuff_fi

IMPLICIT NONE

INTEGER, INTENT( IN ) :: iunit

INTEGER ios

REAL    lognorm_mmd
REAL    lognorm_sigma
REAL    random_spread
REAL    slurry_fraction
REAL    active_fraction
INTEGER number_random
INTEGER random_seed

INTEGER, EXTERNAL :: Real2Int

NAMELIST / scn / relName,relDisplay,trel, xrel, yrel, zrel, cmass, subgroup, &
                 sigx, sigy, sigz, &
                 wmom, buoy, &
                 lognorm_mmd, lognorm_sigma, slurry_fraction, active_fraction, &
                 number_random, random_spread, random_seed, &
                 relStatus, &
                 reltyp, relmat

lognorm_mmd     = rel_param(REL_MMD_INDX)
lognorm_sigma   = rel_param(REL_SIGMA_INDX)
slurry_fraction = rel_param(REL_WMFRAC_INDX)
active_fraction   = rel_param(REL_AFRAC_INDX)

number_random = Real2Int( rel_param(REL_RAND_INDX) )
random_seed   = Real2Int( rel_param(REL_SEED_INDX) )
random_spread = rel_param(REL_SPREAD_INDX)


WRITE( UNIT=iunit,NML=scn,IOSTAT=ios )
IF( ios /= 0 )THEN
  nError   = WR_ERROR
  eRoutine = 'WriteNamelistScnInst'
  eMessage = 'Error writing instantaneous SCN namelist'
END IF

RETURN
END
!===============================================================================
!     WriteNamelistScnXInst
!===============================================================================
SUBROUTINE WriteNamelistScnXInst( iunit )

USE relparam_fd
USE scipuff_fi

IMPLICIT NONE

INTEGER, INTENT( IN ) :: iunit

INTEGER ios

REAL    lognorm_mmd
REAL    lognorm_sigma
REAL    random_spread
REAL    slurry_fraction
REAL    active_fraction
INTEGER number_random
INTEGER random_seed

INTEGER, EXTERNAL :: Real2Int

NAMELIST / scn / relName,relDisplay,trel, xrel, yrel, zrel, cmass, subgroup, &
                 sigx, sigy, sigz, sigRxy, sigRxz, sigRyz, &
                 wmom, buoy, &
                 lognorm_mmd, lognorm_sigma, slurry_fraction, active_fraction, &
                 number_random, random_spread, random_seed, &
                 relStatus, &
                 reltyp, relmat

lognorm_mmd     = rel_param(REL_MMD_INDX)
lognorm_sigma   = rel_param(REL_SIGMA_INDX)
slurry_fraction = rel_param(REL_WMFRAC_INDX)
active_fraction   = rel_param(REL_AFRAC_INDX)

number_random = Real2Int( rel_param(REL_RAND_INDX) )
random_seed   = Real2Int( rel_param(REL_SEED_INDX) )
random_spread = rel_param(REL_SPREAD_INDX)


WRITE( UNIT=iunit,NML=scn,IOSTAT=ios )
IF( ios /= 0 )THEN
  nError   = WR_ERROR
  eRoutine = 'WriteNamelistScnXInst'
  eMessage = 'Error writing instantaneous SCN namelist'
END IF

RETURN
END
!===============================================================================
!     WriteNamelistScnXInst3
!===============================================================================
SUBROUTINE WriteNamelistScnXInst3( iunit )

USE relparam_fd
USE scipuff_fi

IMPLICIT NONE

INTEGER, INTENT( IN ) :: iunit

INTEGER ios

REAL    lognorm_mmd
REAL    lognorm_sigma
REAL    random_spread
REAL    random_spreadT
REAL    random_spreadV
REAL    random_dir
REAL    slurry_fraction
REAL    active_fraction
INTEGER number_random
INTEGER random_seed

INTEGER, EXTERNAL :: Real2Int

NAMELIST / scn / relName,relDisplay,trel, xrel, yrel, zrel, cmass, subgroup, &
                 sigx, sigy, sigz, sigRxy, sigRxz, sigRyz, &
                 wmom, buoy, &
                 lognorm_mmd, lognorm_sigma, slurry_fraction, active_fraction, &
                 number_random, random_spread, random_seed, &
                 random_spreadT, random_spreadV, random_dir, &
                 relStatus, &
                 reltyp, relmat

lognorm_mmd     = rel_param(REL_MMD_INDX)
lognorm_sigma   = rel_param(REL_SIGMA_INDX)
slurry_fraction = rel_param(REL_WMFRAC_INDX)
active_fraction   = rel_param(REL_AFRAC_INDX)

number_random  = Real2Int( rel_param(REL_RAND_INDX) )
random_seed    = Real2Int( rel_param(REL_SEED_INDX) )
random_spread  = rel_param(REL_SPREAD_INDX)
random_spreadT = rel_param(REL_SPREADT_INDX)
random_spreadV = rel_param(REL_SPREADV_INDX)
random_dir     = rel_param(REL_RANDIR_INDX)


WRITE( UNIT=iunit,NML=scn,IOSTAT=ios )
IF( ios /= 0 )THEN
  nError   = WR_ERROR
  eRoutine = 'WriteNamelistScnXInst'
  eMessage = 'Error writing instantaneous SCN namelist'
END IF

RETURN
END
!===============================================================================
!     WriteNamelistScnCont
!===============================================================================
SUBROUTINE WriteNamelistScnCont( iunit )

USE relparam_fd
USE scipuff_fi

IMPLICIT NONE

INTEGER, INTENT( IN ) :: iunit

INTEGER ios

REAL    lognorm_mmd
REAL    lognorm_sigma
REAL    slurry_fraction
REAL    active_fraction

NAMELIST / scn / relName,relDisplay,trel, xrel, yrel, zrel, cmass, subgroup, tdur, &
                 sigx, sigy, sigz, &
                 wmom, buoy, &
                 lognorm_mmd, lognorm_sigma, slurry_fraction, active_fraction, &
                 relStatus, &
                 reltyp, relmat

lognorm_mmd       = rel_param(REL_MMD_INDX)
lognorm_sigma     = rel_param(REL_SIGMA_INDX)
slurry_fraction   = rel_param(REL_WMFRAC_INDX)
active_fraction   = rel_param(REL_AFRAC_INDX)

WRITE( iunit,scn,IOSTAT=ios )
IF( ios /= 0 )THEN
  nError   = WR_ERROR
  eRoutine = 'WriteNamelistScnCont'
  eMessage = 'Error writing continuous SCN namelist'
END IF

RETURN
END
!===============================================================================
!     WriteNamelistScnMove
!===============================================================================
SUBROUTINE WriteNamelistScnMove( iunit )

USE relparam_fd
USE scipuff_fi

IMPLICIT NONE

INTEGER, INTENT( IN ) :: iunit

INTEGER ios

REAL    lognorm_mmd
REAL    lognorm_sigma
REAL    slurry_fraction
REAL    active_fraction

NAMELIST / scn / relName,relDisplay,trel, xrel, yrel, zrel, cmass, subgroup, tdur, &
                 sigx, sigy, sigz, urel, vrel, wrel, &
                 wmom, buoy, &
                 lognorm_mmd, lognorm_sigma, slurry_fraction, active_fraction, &
                 relStatus, &
                 reltyp, relmat

lognorm_mmd       = rel_param(REL_MMD_INDX)
lognorm_sigma     = rel_param(REL_SIGMA_INDX)
slurry_fraction   = rel_param(REL_WMFRAC_INDX)
active_fraction   = rel_param(REL_AFRAC_INDX)

WRITE( iunit,scn,IOSTAT=ios )
IF( ios /= 0 )THEN
  nError   = WR_ERROR
  eRoutine = 'WriteNamelistScnMove'
  eMessage = 'Error writing moving SCN namelist'
END IF

RETURN
END
!===============================================================================
!     WriteNamelistScnPool
!===============================================================================
SUBROUTINE WriteNamelistScnPool( iunit )

USE relparam_fd
USE scipuff_fi

IMPLICIT NONE

INTEGER, INTENT( IN ) :: iunit

INTEGER ios

NAMELIST / scn / relName,relDisplay,trel, xrel, yrel, zrel, cmass, subgroup, tdur, &
                 sigx, sigy, sigz, &
                 wmom, buoy, &
                 relStatus, &
                 reltyp, relmat

WRITE( iunit,scn,IOSTAT=ios )
IF( ios /= 0 )THEN
  nError   = WR_ERROR
  eRoutine = 'WriteNamelistScnPool'
  eMessage = 'Error writing pool SCN namelist'
END IF

RETURN
END
!===============================================================================
!     WriteNamelistScnFile
!===============================================================================
SUBROUTINE WriteNamelistScnFile( iunit )

USE relparam_fd
USE scipuff_fi

IMPLICIT NONE

INTEGER, INTENT( IN ) :: iunit

INTEGER ios

REAL    random_spread
INTEGER number_random
INTEGER random_seed

INTEGER, EXTERNAL :: Real2Int

NAMELIST / scn / relName, relDisplay, trel, xrel, yrel, zrel, &
                 number_random, random_spread, random_seed, &
                 reltyp, name_rel, relmat, &
                 relStatus

number_random = Real2Int( rel_param(REL_RAND_INDX) )
random_seed   = Real2Int( rel_param(REL_SEED_INDX) )
random_spread = rel_param(REL_SPREAD_INDX)

WRITE( iunit,scn,IOSTAT=ios )
IF( ios /= 0 )THEN
  nError   = WR_ERROR
  eRoutine = 'WriteNamelistScnFile'
  eMessage = 'Error writing file SCN namelist'
END IF

RETURN
END
!===============================================================================
!     WriteNamelistScnStack
!===============================================================================
SUBROUTINE WriteNamelistScnStack( iunit )

USE relparam_fd
USE scipuff_fi

IMPLICIT NONE

INTEGER, INTENT( IN ) :: iunit

INTEGER ios

REAL    size                     !Local to avoid conflict with implicit function name
REAL    lognorm_mmd
REAL    lognorm_sigma
REAL    slurry_fraction
REAL    active_fraction

NAMELIST / scn / relName,relDisplay,trel, xrel, yrel, zrel, cmass, subgroup, tdur, &
                 size, &
                 umom, vmom, wmom, buoy, &
                 lognorm_mmd, lognorm_sigma, slurry_fraction, active_fraction, &
                 relStatus, &
                 reltyp, relmat

size              = size_rel
lognorm_mmd       = rel_param(REL_MMD_INDX)
lognorm_sigma     = rel_param(REL_SIGMA_INDX)
slurry_fraction   = rel_param(REL_WMFRAC_INDX)
active_fraction   = rel_param(REL_AFRAC_INDX)

WRITE( iunit,scn,IOSTAT=ios )
IF( ios /= 0 )THEN
  nError   = WR_ERROR
  eRoutine = 'WriteNamelistScnStack'
  eMessage = 'Error writing stack SCN namelist'
END IF

RETURN
END
!===============================================================================
!     WriteNamelistScnStatus
!===============================================================================
SUBROUTINE WriteNamelistScnStatus( iunit )

USE scipuff_fi

IMPLICIT NONE

INTEGER, INTENT( IN ) :: iunit

INTEGER ios

NAMELIST / scn / opid,opmod

WRITE( iunit,scn,IOSTAT=ios )
IF( ios /= 0 )THEN
  nError   = WR_ERROR
  eRoutine = 'WriteNamelistScnStatus'
  eMessage = 'Error writing SCN(Status) namelist'
END IF

RETURN
END