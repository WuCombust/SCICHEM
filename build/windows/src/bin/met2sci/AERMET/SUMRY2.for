      SUBROUTINE SUMRY2( ISTAGE )
C=====================================================================**
C          Module SUMRY2 of the AERMET Meteorological Preprocessor
C
C     Purpose:  To create a summary table of all informational,
C               warning, error and QA messages generated by AERMET.
C               In addition, the warning and error messages are
C               reiterated at the end of the summary.
C
C     Called by:     FINISH, MAIN PROGRAM OF STAGE 3
C
C     Calls to:      BANNER
C
C     Initial Release:  15 DEC 1992
C
C     Programmed by: Pacific Environmental Services, Inc. (PES)
C                    Research Triangle Park, NC
C
C-----------------------------------------------------------------------


      IMPLICIT NONE
      
      LOGICAL       LVAR
      INTEGER       SUMTBL(6,0:4,10), SEVER,IOST60,IP,ICODE1,ICODE2,
     &              NCNT, PSTAT(6),ITOT1(10),ITOT2(6,0:4),TOTAL,SUMM,
     &              ISTAGE, IOST70, NHDRS, DEVRPT, DEVERR
      INTEGER       I, ICOD, M7080
      CHARACTER*1   ETYPE(0:4)
      CHARACTER*96  CVAR1

      INCLUDE 'MAIN1.INC'
      INCLUDE 'MAIN2.INC'
      INCLUDE 'WORK1.INC'
      INCLUDE 'SF1.INC'


      DATA SUMTBL/300*0/, NCNT/0/, ITOT1/10*0/, ITOT2/30*0/, TOTAL/0/
      DATA ETYPE /'T','Q','I','W','E'/

      NHDRS = 0

C     SUMTBL        TABLE OF MESSAGE COUNTS
C     SEVER         MESSAGE TYPE (0:4) CORRESPONDING TO ETYPE
C     PSTAT         PATHWAY STATUSES
C     ITOT1,ITOT2   COLUMN AND ROW TOTALS
C     TOTAL         TOTAL NUMBER OF MESSAGES
C     ISTAGE        PROCESSING STAGE - SUBROUTINE CALLING ARGUMENT
C                   = 1 FOR STAGES 1 AND 2; = 3 FOR STAGE 3
C     ETYPE         MESSAGE CATEGORIES

C-----------------------------------------------------------------------
C ***   DETERMINE WHETHER TO WRITE TO A REPORT FILE OR DEFAULT OUTPUT.
C       DETERMINE IF A MESSAGE FILE AND TEMPORARY FILE ARE OPEN.
C       PLACE THE PATHWAY STATUSES IN AN ARRAY. PSTAT(6) IS A DUMMY
C       STATUS FOR STAGE 3 PROCESSING

      IF( STATUS(1,1) .EQ. 2 )THEN
         DEVRPT = DEV50
      ELSE
         DEVRPT = DEVIO
      ENDIF

      IF( STATUS(1,2) .EQ. 2 )THEN
         DEVERR = DEV60
      ELSE
         DEVERR = DEVIO
      ENDIF

      INQUIRE (UNIT=DEV70,OPENED=LVAR,NAME=CVAR1)

      PSTAT(1) = JBSTAT
      PSTAT(2) = UASTAT
      PSTAT(3) = SFSTAT
      PSTAT(4) = OSSTAT
      PSTAT(5) = MRSTAT
      PSTAT(6) = 0

C *** IF THIS IS STAGE 1 PROCESSING, WRITE ANY SCAN REPORTS TO THE
C      MESSAGE FILE BEFORE PROCEEDING

      IF( ISTAGE .EQ. 1 .AND. LVAR )THEN
         REWIND DEV70
  101    BUF80(1) = BLN132
         READ(DEV70,6088,END=200,ERR=120,IOSTAT=IOST70)
     1      BUF08(1),BUF80(1)
         IF( INDEX(BUF08(1),'$UASCAN$') .NE. 0 )THEN
            WRITE(DEVERR,6002)

C ***   SCAN INFORMATION FOR SOUNDINGS TO FOLLOW
  110       BUF80(1) = BLN132
            BUF08(1) = BLNK08
            READ(DEV70,6088,END=130,ERR=120,IOSTAT=IOST70)
     1           BUF08(1),BUF80(1)
            IF( INDEX(BUF08(1),'$UASCAN$') .NE. 0 )THEN

C ***    SCAN INFORMATION COMPLETED
               GO TO 200
            ELSE

C ***    WRITE SCAN INFORMATION
               WRITE(DEVERR,6000) BUF80(1)
               GO TO 110
            ENDIF
         ELSE
            GO TO 101
         ENDIF

  120    WRITE(DEVERR,6050) IOST70
         GO TO 200
  130    WRITE(DEVERR,6060)

C *** SURFACE OBSERVATIONS
  200    REWIND DEV70
         NHDRS = 0
  301    BUF80(1) = BLN132
         READ(DEV70,6088,END=400,ERR=320,IOSTAT=IOST70)
     1        BUF08(1),BUF80(1)
         NHDRS = NHDRS + 1
         IF( INDEX(BUF08(1),'$SFSCAN$') .NE. 0 )THEN
            WRITE(DEVERR,6002)

C ***    SCAN INFORMATION FOR SURFACE OBS TO FOLLOW
  310       BUF80(1) = BLN132
            READ(DEV70,6088,END=330,ERR=320,IOSTAT=IOST70)
     1        BUF08(1),BUF80(1)
            NHDRS = NHDRS + 1
            IF( INDEX(BUF08(1),'$SFSCAN$') .NE. 0 )THEN

C ***     SCAN INFORMATION COMPLETED
               GO TO 400
            ELSE

C ***     WRITE SCAN INFORMATION
               WRITE(DEVERR,6000) BUF80(1)
               GO TO 310
            ENDIF
         ELSE
            GO TO 301
         ENDIF

  320    WRITE(DEVERR,6050) IOST70
         GO TO 400

  330    WRITE(DEVERR,6060)
      ENDIF

C------------------------------------------------------------------
C *** BEGIN WRITING THE TABLE WITH THE BANNER AND DATE/TIME

  400 CONTINUE
      PGNUM = PGNUM + 1
      CALL BANNER( PGNUM,ISTAGE,VERSNO,DEVRPT )

C *** INDICATE THE TERMINATION STATUS OF THE JOB RUN

      IF( STATUS(1,3) .EQ. 0 )THEN
         IF( RUNERR )THEN
            WRITE(DEVRPT,5110)
            IF( DEVRPT .NE. DEVIO ) WRITE( DEVIO, 5110 )
         ELSEIF( .NOT.SETERR )THEN
            WRITE(DEVRPT,5120)
            IF( DEVRPT .NE. DEVIO ) WRITE( DEVIO, 5120 )
         ELSEIF( SETERR )THEN
            WRITE(DEVRPT,5130)
            IF( DEVRPT .NE. DEVIO ) WRITE( DEVIO, 5130 )
         ENDIF

      ELSEIF( STATUS(1,3) .GT. 0 )THEN
         WRITE(DEVRPT,5100)
      ENDIF

      IF( ISTAGE .EQ. 1  .AND.  MRSTAT .EQ. 0 )THEN
         WRITE( DEVRPT,5001 )

      ELSEIF( ISTAGE .EQ. 3  )THEN
         WRITE( DEVRPT,5003 )
      ENDIF

      WRITE(DEVRPT,5005)

C--------------------------------------------------------------------
C *** CHECK FOR THE EXISTENCE OF A MESSAGE FILE (DEV60)
C     AND TEMPORARY FILE - SKIP THIS LOGIC IF EITHER IS MISSING;
C     REWIND THE MESSAGE FILE AND POSITION THE TEMPORARY FILE TO READ
C     THE RECORD IMMEDIATELY FOLLOWING THE HEADER RECORDS;

      IF( (STATUS(1,2).EQ.2) .AND. LVAR  )THEN
         REWIND DEV60
         REWIND DEV70
         DO I=1,NHDRS
           READ(DEV70,6080) BUF132
         ENDDO

  10     BUF132 = BLN132
         NCNT = NCNT + 1
         READ(DEVERR,6005,END=6100,ERR=6200,IOSTAT=IOST60) BUF132

         DO IP = 1,6
            IF( BUF132(10:19) .EQ. PATHWD(IP) )THEN
               IF( BUF132(21:21) .EQ. 'E' )THEN
                  SEVER = 4
                  WRITE(DEV70,6005) BUF132
               ELSEIF( BUF132(21:21) .EQ. 'W' .AND. 
     &                 BUF132(21:23) .NE. 'WDS' )THEN
                  SEVER = 3
                  WRITE(DEV70,6005) BUF132
               ELSEIF( BUF132(21:23) .EQ. 'WDS' )THEN
                  SEVER = 2
               ELSEIF( BUF132(21:21) .EQ. 'I' )THEN
                  SEVER = 2
               ELSEIF( BUF132(21:21) .EQ. 'Q' )THEN
                  SEVER = 1
               ELSEIF( BUF132(21:21) .EQ. 'T' )THEN
                  SEVER = 0
               ELSE
                  CYCLE
               ENDIF

C              Note that the code 'WDS' is used if a zero wind speed/
C              nonzero wind direction is detected; the 'W' conflicts
C              with the 'W' used in warning messages, so check for this
C              (rare) occurrence, as well as 'TDT', 'CLM' and 'PPT' codes,
C              otherwise the READ statement will cause AERMET to abort 
C              unexpectedly.
               IF( BUF132(21:23) .NE. 'WDS' .AND. 
     &             BUF132(21:23) .NE. 'TDT' .AND.   
     &             BUF132(21:23) .NE. 'CLM' .AND.
     &             BUF132(21:23) .NE. 'PPT' )THEN
                  READ(BUF132(22:23),6001,ERR=6300,IOSTAT=IOST60)
     &                                                           ICODE1
                  ICODE2  = ICODE1/10 + 1
                  SUMTBL(IP,SEVER,ICODE2) = SUMTBL(IP,SEVER,ICODE2) + 1
               ENDIF
            ENDIF
         ENDDO

         GO TO 10

C ***    Continue here when the end of the error file is reached

 6100    CONTINUE

C ***    Accumulate the totals horizontally and vertically
C        Total the messages vertically; the final message category
C        reports messages 70-89, so for ICODE2 = 9, reset it to 8

         DO ICODE2 = 1,9
            IF( ICODE2 .EQ. 9 )THEN
               ICOD = 8
            ELSE
               ICOD = ICODE2
            ENDIF
            DO SEVER = 0,4
               DO IP = 1,6
                  ITOT1(ICOD) = ITOT1(ICOD) + SUMTBL(IP,SEVER,ICODE2)
                  ITOT2(IP,SEVER) = ITOT2(IP,SEVER) +
     &                                 SUMTBL(IP,SEVER,ICODE2)
               ENDDO
            ENDDO
         ENDDO

C        Total the messages vertically for the final (TOTAL) column

         DO ICODE2 = 1,9
            TOTAL = TOTAL + ITOT1(ICODE2)
         ENDDO

C        Generate the column headers of the form "message# - message#"
         DO IP = 1,8
            IWORK1(IP+100) = (IP - 1)*10
            IWORK1(IP+120) = IP*10 - 1
            IF( IP .EQ. 8 ) IWORK1(128) = 89
         ENDDO
         WRITE(DEVRPT,5010) (IWORK1(I+100),IWORK1(I+120),I=1,8)
        
C        Write a dashed line
         WRITE(DEVRPT,5020)
        
C        Print the contents of the table, beginning with row identifiers.
         DO IP = 1,6
            SUMM = ITOT2(IP,0) + ITOT2(IP,1) + ITOT2(IP,2) +
     &             ITOT2(IP,3) + ITOT2(IP,4)
            IF(SUMM .EQ. 0) CYCLE
            WRITE(DEVRPT,5030) PATHWD(IP)
            DO SEVER = 4,0,-1
        
C ***          THERE ARE NO TRACE ERRORS FOR PATHS 1 - 5
               IF( (SEVER .EQ. 0) .AND. (IP.NE. 6) ) CYCLE
        
C ***          IF THIS IS THE QA CODE, DON'T PRINT FOR PATHS: JB, MR, MP
               IF(SEVER .EQ. 1) THEN
                  IF( (IP.LT.2) .OR. (IP.GT.4) )THEN
                     CYCLE
                  ELSE
        
C ***                DID WE QA DATA? IF NOT, GO TO 50
                     IF( (PSTAT(IP) .LT. 2) .OR. (PSTAT(IP).EQ.4) )THEN
                        CYCLE
                     ENDIF
                  ENDIF
               ENDIF
        
C              Print the contents of the table
               M7080 = SUMTBL(IP,SEVER,8)+SUMTBL(IP,SEVER,9)
               WRITE(DEVRPT,5040) ETYPE(SEVER),
     &              (SUMTBL(IP,SEVER,ICODE2),ICODE2=1,7),
     &               M7080,ITOT2(IP,SEVER)
            ENDDO
         ENDDO
        
C        Print a dashed line followed by the column totals
         WRITE(DEVRPT,5020)
         WRITE(DEVRPT,5042) (ITOT1(ICODE2),ICODE2=1,8),TOTAL
        
        
C ***    Rewind DEV70 (temporary file); reiterate the error messages by path
        
         ICODE1 = 0
         WRITE(DEVRPT,5055)
         DO IP = 1,6
            REWIND DEV70
            DO I=1,NHDRS
               READ(DEV70,6080) BUF132
            ENDDO
            NCNT = 0
  75        BUF132 = BLN132
            NCNT = NCNT + 1
            READ(DEV70,6005,END=70,ERR=6400,IOSTAT=IOST60) BUF132
            IF( BUF132(10:19) .EQ. PATHWD(IP) .AND.
     &         (BUF132(21:21) .EQ. 'E') )THEN
               WRITE(DEVRPT,6005) BUF132
               ICODE1 = 1
            ENDIF
            GO TO 75
  70        CONTINUE
         ENDDO
        
         IF( ICODE1 .EQ. 0 )THEN
            WRITE(DEVRPT,6010)
         ENDIF
        
      ELSE
C        There is no message file and/or temporary file
         WRITE(DEVRPT,5070)
      ENDIF


C *** Rewind DEV70 (temporary file); reiterate the warning messages by path

      ICODE1 = 0
      WRITE(DEVRPT,5050)
      DO IP = 1,6
         REWIND DEV70
         DO I=1,NHDRS
            READ(DEV70,6080) BUF132
         ENDDO
         NCNT = 0
  65     BUF132 = BLN132
         NCNT = NCNT + 1
         READ(DEV70,6005,END=60,ERR=6400,IOSTAT=IOST60) BUF132
         IF( BUF132(10:19) .EQ. PATHWD(IP) .AND.
     &      (BUF132(21:21) .EQ. 'W') )THEN
            WRITE(DEVRPT,6005) BUF132
            ICODE1 = 1
         ENDIF
         GO TO 65
   60    CONTINUE
      ENDDO

      IF( ICODE1 .EQ.0 )THEN
         WRITE(DEVRPT,6010)
      ENDIF

C---- Check for ASOS commission date for SURFACE data in Stage 1  
C     or 1-min ASOS data in Stage 2, and write message to report 
C     file with results
      IF( (ISTAGE.EQ.1 .OR. ISTAGE.EQ.3) .AND. SFLOC .NE. BLNK08 )THEN
         IF( GotCommDate )THEN
            WRITE(DEVRPT,5062) SFLOC, iCommDate
C           Check for use of ISHD ASOS flag
            IF( ISHD_ASOS )THEN 
C----          User specified ASOS flag for ISHD data, but station
C              is included in the ASOS commission list - issue
C              additional warning.
               WRITE(DEVRPT,5069)
C              Also write message to screen
               WRITE(DEVIO,*) ' '
               WRITE(DEVIO,5069) 
            ENDIF
         ELSEIF( SrchCommDate )THEN
C----       ASOS commission date search was performed, but station not found;
C           don't issue message if no search was performed
            WRITE(DEVRPT,5063) SFLOC
         ENDIF
      ELSEIF( ISTAGE .EQ. 2 .AND. STATUS(3,33) .EQ. 2 )THEN
C----    Checking for use of 1-minute ASOS data in Stage 2
         IF( GotCommDate )THEN
            WRITE(DEVRPT,5064) IWBAN_A1, iCommDate
C           Check for use of ISHD ASOS flag
            IF( ISHD_ASOS )THEN 
C----          User specified ASOS flag for ISHD data, but station
C              is included in the ASOS commission list - issue
C              additional warning.
               WRITE(DEVRPT,5069)
C              Also write message to screen
               WRITE(DEVIO,*) ' '
               WRITE(DEVIO,5069) 
            ENDIF
         ELSEIF( SrchCommDate )THEN
C----       ASOS commission date search was performed, but station not found;
C           don't issue message if no search was performed
            WRITE(DEVRPT,5065) IWBAN_A1
         ENDIF
      ENDIF


      RETURN

C-----------------------------------------------------------------------
C *** PROCESSING CONTINUE HERE IN CASE AN ERROR OCCURS IN A READ STMT

 6200 CONTINUE
      WRITE(DEVRPT,6020) NCNT, DEVERR, IOST60
      RETURN

 6300 CONTINUE
      WRITE(DEVRPT,6030) NCNT, IOST60
      RETURN

 6400 CONTINUE
      WRITE(DEVRPT,6040) NCNT, DEV70, IOST60
      RETURN

C-----------------------------------------------------------------------
C *** FORMAT STATEMENTS

 5001 FORMAT(/21X, 'EXTRACT AND/OR QA THE METEOROLOGICAL DATA')
 5003 FORMAT(/15X, 'PROCESSING METEOROLOGICAL DATA FOR DISPERSION ',
     &             'MODELING')
! 5005 FORMAT(//22X,'**** AERMET MESSAGE SUMMARY TABLE ****')
 5005 FORMAT(//22X,'**** METSCI MESSAGE SUMMARY TABLE ****')
 5010 FORMAT(/9X,8(I2,'-',I2,3X),'TOTAL')
 5020 FORMAT(7X,72('-'))
 5030 FORMAT(/2X,A10)
 5040 FORMAT(4X,A1,9(I7,1X),I7)
 5042 FORMAT(5X,8(I7,1X),I7)
 5050 FORMAT(/8X,'****   WARNING MESSAGES   ****')
 5055 FORMAT(/8X,'****    ERROR MESSAGES    ****')
 5062 FORMAT(/3X,' ASOS Commission Date for Surface Station ',A8,
     &                                         ' (YYYYMMDD): ',I8/)
 5063 FORMAT(/3X,' ASOS Commission Date for Surface Station ',A8,
     &                                         ' Not Found.'/)
 5064 FORMAT(/3X,' ASOS Commission Date for 1-min ASOS Station ',I8,
     &                                         ' (YYYYMMDD): ',I8/)
 5065 FORMAT(/3X,' ASOS Commission Date for 1-min ASOS Station ',I8,
     &                                         ' Not Found.'/)
 5069 FORMAT( 3X,' ASOS flag on ISHD DATA keyword should NOT be used! ',
     &           ' Station included in ASOS commission list.'/)
 5070 FORMAT(18X,' NO SUMMARY TABLE IS AVAILABLE BECAUSE THERE IS',/,
     &       18X,' NO MESSAGE AND/OR TEMPORARY FILE(S) OPEN')

 5100 FORMAT(//14X,56('*'),
     & /14X,'***     THIS RUN ONLY CHECKS THE RUNSTREAM SETUP     ***',
     & /14X,'********************************************************')

 5110 FORMAT( /14X,56('*'),
     & /14X,'***  METSCI Data Processing Finished UN-successfully ***',
     & /14X,'********************************************************')

 5120 FORMAT( /14X,56('*'),
     & /14X,'***   METSCI Data Processing Finished Successfully   ***',
     & /14X,'********************************************************')

 5130 FORMAT( /14X,56('*'),
     & /14X,'***   Data Processing Not Completed - Setup Errors   ***',
     & /14X,'********************************************************')

 6000 FORMAT(A132)
 6005 FORMAT(A132)
 6080 FORMAT(8X,A132)
 6088 FORMAT(A8,A132)
 6001 FORMAT(I2)
 6002 FORMAT(' ')
 6010 FORMAT(/15X,'---  NONE  ---'/)
 6020 FORMAT(5X,'Error reading record',I5,' on unit',I3,' with IOSTAT ',
     &     I8,/5X,'No further processing!')
 6030 FORMAT(5X,'Error reading 2-digit code from buffer at record',I5,
     &     ' with IOSTAT ',I8,/5X,'No further processing!')
 6040 FORMAT(5X,'Error reading informational message at record ',I5,
     &   ' on unit ',I3,' with IOSTAT ',I8,/5X,'No further processing!')
 6050 FORMAT(' Error reading scan report on DEV70, I/O STATUS= ',I8)
 6060 FORMAT(' END-OF-FILE ON DEV70, SCAN REPORT INCOMPLETE')
C
C---
      END

