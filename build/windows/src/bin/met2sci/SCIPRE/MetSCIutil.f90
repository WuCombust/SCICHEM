SUBROUTINE cupper( line )

CHARACTER(*), INTENT( INOUT ) :: line

INTEGER i

DO i = 1,LEN(line)
  IF( line(i:i) < 'a' )CYCLE
  IF( line(i:i) > 'z' )CYCLE
  line(i:i) = CHAR(ICHAR(line(i:i)) - 32)
END DO

RETURN
END

!==============================================================================

SUBROUTINE get_next_data( lun,line,nch,kwrd,n_arg,c_arg,maxn,lerr )

IMPLICIT NONE

!------ argument declarations

INTEGER,                    INTENT( IN    ) :: lun
CHARACTER(*),               INTENT( INOUT ) :: line
INTEGER,                    INTENT( OUT   ) :: nch
CHARACTER(*),               INTENT( OUT   ) :: kwrd
INTEGER,                    INTENT( OUT   ) :: n_arg
CHARACTER(*), DIMENSION(*), INTENT( OUT   ) :: c_arg
INTEGER,                    INTENT( IN    ) :: maxn
LOGICAL,                    INTENT( OUT   ) :: lerr

!------ parameters

CHARACTER(1), PARAMETER :: TAB   = CHAR(9)
CHARACTER(1), PARAMETER :: SPACE = CHAR(32)

!------ locals

CHARACTER(LEN=LEN(line)) string, data_string

INTEGER i, j, ios, ic

INTEGER, EXTERNAL :: first_nblank

n_arg = 0
kwrd  = 'NONE'
lerr  = .FALSE.

!------ read line from file

IF( lun > 0 )THEN

  DO

    READ(lun,'(A)',IOSTAT=ios) line
    lerr = ( ios /= 0 )
    IF( lerr )RETURN

!------ ignore blank lines and comments

    i = first_nblank( line )
    IF( i == 0 )CYCLE
    IF( line(i:i) /= '!' )EXIT

  END DO

ELSE !------ line passed as input

  i = first_nblank( line )
  IF( i == 0 )RETURN
  IF( line(i:i) == '!' )RETURN

END IF

CALL cupper( line )

!------ ignore comments on the end of line

nch = LEN_TRIM(line)
ic  = INDEX(line,'!')
IF( ic /= 0 )nch = ic-1

string = line(i:nch)
nch    = nch - i + 1

!------ replace tabs with spaces

DO i = 1,nch
  IF( string(i:i) == TAB )string(i:i) = SPACE
END DO

!------ check for keywords by searching for "="

i = INDEX(string,'=')

IF( i == 0 )THEN

  kwrd        ='NONE'
  data_string = string

ELSE

!------ extract keyword and data string

  i = i - 1

  kwrd = string(1:i)

  IF( nch >= i+2 )THEN
    j = first_nblank( string(i+2:nch) )
  ELSE
    j = 0
  END IF

  IF( j > 0 )THEN
    data_string = string(j+i+1:nch)
  ELSE
    data_string = ' '
  END IF

END IF

!------ parse data string

CALL parse_string( data_string,n_arg,c_arg,maxn,lerr )
IF( lerr )RETURN

IF( kwrd /= 'NONE' )THEN
  line = TRIM(data_string)
  nch  = LEN_TRIM(line)
ELSE
  line = string(1:nch)
END IF

RETURN
END

!===========================================================================

INTEGER FUNCTION first_nblank( string )

IMPLICIT NONE

CHARACTER(*), INTENT( IN ) :: string

INTEGER i

IF( ICHAR(string(1:1)) == 0 )THEN
  first_nblank = 0
  RETURN
END IF

DO i = 1,LEN(string)
  IF( string(i:i) /= ' ' )THEN
     first_nblank = i
     RETURN
  END IF
END DO

first_nblank = 0

RETURN
END

!===========================================================================

SUBROUTINE parse_string( string,n_arg,c_arg,maxn,lerr )

IMPLICIT NONE

!------ argument declarations

CHARACTER(*),               INTENT( IN )  :: string
INTEGER,                    INTENT( OUT ) :: n_arg
CHARACTER(*), DIMENSION(*), INTENT( OUT ) :: c_arg
INTEGER,                    INTENT( IN )  :: maxn
LOGICAL,                    INTENT( OUT ) :: lerr

!------ locals

INTEGER i, j, nch, jlen

INTEGER, EXTERNAL :: first_nblank

n_arg = 0
lerr  = .FALSE.

DO i = 1,maxn
  c_arg(i) = ''  !Blank out strings
END DO

nch = LEN_TRIM(string)
IF( nch == 0 )RETURN

i = first_nblank( string(1:nch) )

IF( i == 0 )RETURN

DO

  j = INDEX(string(i:nch),' ')
  IF( j > 0 )THEN
    j = j + i - 1
  ELSE
    j = nch
  END IF

  n_arg = n_arg + 1
  IF( n_arg > maxn )THEN
    lerr = .TRUE.
    EXIT
  END IF

  jlen = MIN(j-i+1,LEN(c_arg(n_arg)))
  c_arg(n_arg) = string(i:i+jlen-1)

  IF( j == nch )EXIT

  i = first_nblank( string(j:nch) ) + j - 1

END DO

RETURN
END

!==============================================================================

SUBROUTINE init_next_data( lun,line,max_nch,n_arg,lerr )

!------ Output number of arguments and max character length

IMPLICIT NONE

!------ argument declarations

INTEGER,                    INTENT( IN    ) :: lun
CHARACTER(*),               INTENT( INOUT ) :: line
INTEGER,                    INTENT( OUT   ) :: max_nch
INTEGER,                    INTENT( OUT   ) :: n_arg
LOGICAL,                    INTENT( OUT   ) :: lerr

!------ parameters

CHARACTER(1), PARAMETER :: TAB   = CHAR(9)
CHARACTER(1), PARAMETER :: SPACE = CHAR(32)

!------ locals

INTEGER ios, i, ic, nch, nchi
LOGICAL lspace

INTEGER, EXTERNAL :: first_nblank

n_arg   = 0
max_nch = 0
lerr    = .FALSE.

!------ read line from file

IF( lun > 0 )THEN

  DO

    READ(lun,'(A)',IOSTAT=ios) line
    lerr = ( ios /= 0 )
    IF( lerr )RETURN

!------ ignore blank lines and comments

    i = first_nblank( line )
    IF( i == 0 )CYCLE
    IF( line(i:i) /= '!' )EXIT

  END DO

ELSE !------ line passed as input

  i = first_nblank( line )
  IF( i == 0 )RETURN
  IF( line(i:i) == '!' )RETURN

END IF

!------ ignore comments on the end of line

nch = LEN_TRIM(line)
ic  = INDEX(line,'!')
IF( ic /= 0 )nch = ic-1

!------ parse line for space/tab separated strings
!       keep track of max character length

lspace = .TRUE.
nchi   = 0
DO ic = i,nch
  IF( line(ic:ic) == SPACE .OR. line(ic:ic) == TAB )THEN
    lspace = .TRUE.
    nchi   = 0
  ELSE
    IF( lspace )THEN
      n_arg = n_arg + 1
      lspace = .FALSE.
    END IF
    nchi    = nchi + 1
    max_nch = MAX(max_nch,nchi)
  END IF
END DO

RETURN
END
