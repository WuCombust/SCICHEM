      SUBROUTINE TMGEOD(N,E,LAT,LON,EPS,CM,FE,SF,SO,R,V0,V2, &
                        V4,V6,FN,ER,ESQ,CONV,KP)

!**          TRANSVERSE MERCATOR PROJECTION               ***
!** CONVERSION OF GRID COORDS TO GEODETIC COORDS
!** REVISED SUBROUTINE OF T. VINCENTY  FEB. 25, 1985
!************* SYMBOLS AND DEFINITIONS ***********************
!** LATITUDE POSITIVE NORTH, LONGITUDE POSITIVE WEST.  ALL
!**          ANGLES ARE IN RADIAN MEASURE.
!** LAT,LON ARE LAT. AND LONG. RESPECTIVELY
!** N,E ARE NORTHING AND EASTING COORDINATES RESPECTIVELY
!** K IS POINT SCALE FACTOR
!** ER IS THE SEMI-MAJOR AXIS OF THE ELLIPSOID
!** ESQ IS THE SQUARE OF THE 1ST ECCENTRICITY
!** E IS THE 1ST ECCENTRICITY
!** CM IS THE CENTRAL MERIDIAN OF THE PROJECTION ZONE
!** FE IS THE FALSE EASTING VALUE AT THE CM
!** CONV IS CONVERGENCE
!** EPS IS THE SQUARE OF THE 2ND ECCENTRICITY
!** SF IS THE SCALE FACTOR AT THE CM
!** SO IS THE MERIDIONAL DISTANCE (TIMES THE SF) FROM THE
!**       EQUATOR TO SOUTHERNMOST PARALLEL OF LAT. FOR THE ZONE
!** R IS THE RADIUS OF THE RECTIFYING SPHERE
!** U0,U2,U4,U6,V0,V2,V4,V6 ARE PRECOMPUTED CONSTANTS FOR
!**   DETERMINATION OF MERIDIANAL DIST. FROM LATITUDE
!**
!** THE FORMULA USED IN THIS SUBROUTINE GIVES GEODETIC ACCURACY
!** WITHIN ZONES OF 7 DEGREES IN EAST-WEST EXTENT.  WITHIN STATE
!** TRANSVERSE MERCATOR PROJECTION ZONES, SEVERAL MINOR TERMS OF
!** THE EQUATIONS MAY BE OMITTED (SEE A SEPARATE NGS PUBLICATION).
!** IF PROGRAMMED IN FULL, THE SUBROUTINE CAN BE USED FOR
!** COMPUTATIONS IN SURVEYS EXTENDING OVER TWO ZONES.
!**********************************************************************

IMPLICIT DOUBLE PRECISION(A-H,K-Z)

om=(n-fn+so)/(r*sf)
cosom=DCOS(om)
foot=om+DSIN(om)*cosom*(v0+v2*cosom*cosom+v4*cosom**4+v6*cosom**6)
sinf=DSIN(foot)
cosf=DCOS(foot)
tn=sinf/cosf
ts=tn*tn
ets=eps*cosf*cosf
rn=er*sf/DSQRT(1.d0-esq*sinf*sinf)
q=(e-fe)/rn
qs=q*q
b2=-tn*(1.d0+ets)/2.d0
b4=-(5.d0+3.d0*ts+ets*(1.d0-9.d0*ts)-4.d0*ets*ets)/12.d0
b6=(61.d0+45.d0*ts*(2.d0+ts)+ets*(46.d0-252.d0*ts-60.d0*ts*ts))/360.d0
b1=1.d0
b3=-(1.d0+ts+ts+ets)/6.d0
b5=(5.d0+ts*(28.d0+24.d0*ts)+ets*(6.d0+8.d0*ts))/120.d0
b7=-(61.d0+662.d0*ts+1320.d0*ts*ts+720.d0*ts**3)/5040.d0
lat=foot+b2*qs*(1.d0+qs*(b4+b6*qs))
l=b1*q*(1.d0+qs*(b3+qs*(b5+b7*qs)))
lon=-l/cosf+cm

RETURN
END
