subroutine tconpc( v0,v2,v4,v6,er,esq,rf )

!**          TRANSVERSE MERCATOR PROJECTION               ***
!** CONVERSION OF GRID COORDS TO GEODETIC COORDS
!** REVISED SUBROUTINE OF T. VINCENTY  FEB. 25, 1985
!************* SYMBOLS AND DEFINITIONS ***********************
!** ER IS THE SEMI-MAJOR AXIS FOR GRS-80
!** SF IS THE SCALE FACTOR AT THE CM
!** SO IS THE MERIDIONAL DISTANCE (TIMES THE SF) FROM THE
!**       EQUATOR TO SOUTHERNMOST PARALLEL OF LAT. FOR THE ZONE
!** R IS THE RADIUS OF THE RECTIFYING SPHERE
!** U0,U2,U4,U6,V0,V2,V4,V6 ARE PRECOMPUTED CONSTANTS FOR
!**   DETERMINATION OF MERIDIONAL DIST. FROM LATITUDE
!** OR IS THE SOUTHERNMOST PARALLEL OF LATITUDE FOR WHICH THE
!**       NORTHING COORD IS ZERO AT THE CM
!*************************************************************

IMPLICIT DOUBLE PRECISION(A-H,O-Z)

F=1.D0/RF
PR=(1.D0-F)*ER
EN=(ER-PR)/(ER+PR)
EN2=EN*EN
EN3=EN*EN*EN
EN4=EN2*EN2

C2=-3.D0*EN/2.D0+9.D0*EN3/16.D0
C4=15.D0*EN2/16.D0-15.D0*EN4/32.D0
C6=-35.D0*EN3/48.D0
C8=315.D0*EN4/512.D0
U0=2.D0*(C2-2.D0*C4+3.D0*C6-4.D0*C8)
U2=8.D0*(C4-4.D0*C6+10.D0*C8)
U4=32.D0*(C6-6.D0*C8)
U6=128.D0*C8

C2=3.D0*EN/2.D0-27.D0*EN3/32.D0
C4=21.D0*EN2/16.D0-55.D0*EN4/32.D0
C6=151.D0*EN3/96.D0
C8=1097.D0*EN4/512.D0
V0=2.D0*(C2-2.D0*C4+3.D0*C6-4.D0*C8)
V2=8.D0*(C4-4.D0*C6+10.D0*C8)
V4=32.D0*(C6-6.D0*C8)
V6=128.D0*C8

!R=ER*(1.D0-EN)*(1.D0-EN*EN)*(1.D0+2.25D0*EN*EN+(225.D0/64.D0)*EN4) *** in tconst
!COSOR=DCOS(OR)
!OMO=OR+DSIN(OR)*COSOR*(U0+U2*COSOR*COSOR+U4*COSOR**4+U6*COSOR**6)
!SO=SF*R*OMO  *** Always =0 for OR=0

RETURN
END
