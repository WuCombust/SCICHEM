!*******************************************************************************
!$RCSfile$
!$Revision$
!$Date$
!*******************************************************************************
!*******************************************************************************
!            SCIPButton
!*******************************************************************************
INTEGER FUNCTION SCIPButton( userID,buttonID )

USE SCIMgr_fd

!Handle Button clicks in User-supplied in Progress dialog

IMPLICIT NONE

!DEC# ATTRIBUTES DLLEXPORT :: SCIPButton

INTEGER, INTENT( IN  ) :: userID      !USER ID Tag
INTEGER, INTENT( IN  ) :: buttonID    !Progress Box Button ID

INTEGER, EXTERNAL :: ButtonHandler

SCIPButton = ButtonHandler( userID,buttonID )

RETURN
END

!*******************************************************************************
!            SCIPCheckButtons
!*******************************************************************************
INTEGER FUNCTION SCIPCheckButtons( userID )

!Checks for files generated by Button clicks in external process Progress dialog

IMPLICIT NONE

!DEC# ATTRIBUTES DLLEXPORT :: SCIPCheckButtons

INTEGER, INTENT( IN  ) :: userID      !USER ID Tag

INTEGER, EXTERNAL  :: CheckButtons

!==== Initialize

SCIPCheckButtons = CheckButtons( userID )

RETURN
END
