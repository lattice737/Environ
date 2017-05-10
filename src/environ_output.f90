!
! Copyright (C) 2007-2008 Quantum-ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
! This module contains all the subroutines related to the printout
! of Environ informations and results.
!
! Original version by Oliviero Andreussi and Nicola Marzari
!
!--------------------------------------------------------------------
MODULE environ_output
!--------------------------------------------------------------------

  USE environ_types

  SAVE

  LOGICAL :: ionode = .TRUE.
  INTEGER :: ionode_id

  INTEGER :: comm

  INTEGER :: program_unit
  INTEGER :: environ_unit
  INTEGER :: verbose

  CHARACTER( LEN = 2 ) :: prog

  PRIVATE

  PUBLIC :: ionode, ionode_id, comm, program_unit, environ_unit, &
       & verbose, prog, set_environ_output, environ_print_energies, &
       & environ_summary, environ_clock, write_cube

CONTAINS
!--------------------------------------------------------------------
  SUBROUTINE set_environ_output( prog_, ionode_, ionode_id_, comm_, program_unit_ )
!--------------------------------------------------------------------

    IMPLICIT NONE

    CHARACTER( LEN=2 ), INTENT(IN) :: prog_
    LOGICAL, INTENT(IN) :: ionode_
    INTEGER, INTENT(IN) :: ionode_id_
    INTEGER, INTENT(IN) :: comm_
    INTEGER, INTENT(IN) :: program_unit_

    INTEGER, EXTERNAL :: find_free_unit

    ionode = ionode_
    ionode_id = ionode_id_
    comm = comm_

    program_unit = program_unit_
    environ_unit = find_free_unit()

    prog = prog_

    RETURN

!--------------------------------------------------------------------
  END SUBROUTINE set_environ_output
!--------------------------------------------------------------------
!--------------------------------------------------------------------
      SUBROUTINE environ_print_energies( )
!--------------------------------------------------------------------
      !
      ! Write out the different Environ contributions to the energy.
      ! Called by electrons.f90
      !
      USE environ_base, ONLY : e2
      USE environ_base, ONLY : lelectrostatic, eelectrostatic, &
                               lsurface, ecavity, &
                               lvolume, epressure
      !
      IF ( prog .EQ. 'PW' ) THEN
        IF ( lelectrostatic ) WRITE( program_unit, 9201 ) eelectrostatic
        IF ( lsurface ) WRITE( program_unit, 9202 ) ecavity
        IF ( lvolume ) WRITE( program_unit, 9203 ) epressure
      ELSE IF ( prog .EQ. 'CP' ) THEN
        IF ( lelectrostatic ) WRITE( program_unit, 9301 ) eelectrostatic
        IF ( lsurface ) WRITE( program_unit, 9302 ) ecavity
        IF ( lvolume ) WRITE( program_unit, 9303 ) epressure
      ELSE
        WRITE(program_unit,*)'ERROR: wrong value of e2 in Environ'
        STOP
      ENDIF
      !
      RETURN
      !
9201 FORMAT( '     electrostatic embedding   =',F17.8,' Ry')
9202 FORMAT( '     cavitation energy         =',F17.8,' Ry')
9203 FORMAT( '     PV energy                 =',F17.8,' Ry')
9301 FORMAT( '     electrostatic embedding = ',F14.5,' Hartree a.u.')
9302 FORMAT( '           cavitation energy = ',F14.5,' Hartree a.u.')
9303 FORMAT( '                   PV energy = ',F14.5,' Hartree a.u.')
      !
! ---------------------------------------------------------------------
      END SUBROUTINE environ_print_energies
! ---------------------------------------------------------------------
! ---------------------------------------------------------------------
      SUBROUTINE environ_summary( )
! ---------------------------------------------------------------------
      !
      ! Write out the main parameters of Environ calculations,
      ! summarizing the input keywords (some info also on internal
      ! vs input units). Called by summary.f90
      !
      USE constants,        ONLY : rydberg_si, bohr_radius_si
      USE environ_base,     ONLY : environ_thr, solvent,                &
                                   env_static_permittivity,             &
                                   env_optical_permittivity,            &
                                   env_surface_tension,                 &
                                   env_pressure
      USE control_flags,     ONLY : tddfpt
      !
      IMPLICIT NONE
      !
      !
      IF( ionode ) THEN
        !
        WRITE( program_unit, * )
        !
        WRITE( UNIT = program_unit,                                          &
               FMT = '(/,5x, "Environ Module",                         &
                      &/,5x, "==============")' )
        WRITE( program_unit, '(/5X,"Please cite",&
         &/9X,"""O. Andreussi, I. Dabo and N. Marzari, J. Chem. Phys. 136, ",&
         &    "064102 (2012);""", &
         &/5X,"in publications or presentations arising from this work.",&
         &/)' )
        !
        WRITE( UNIT = program_unit, FMT = 9001 ) environ_thr
        !
        IF ( solvent%type .EQ. 0 ) THEN
          WRITE( UNIT = program_unit, FMT = 9002 ) 'Fatteber-Gygi'
          WRITE( UNIT = program_unit, FMT = 9003 ) solvent%rhozero, solvent%tbeta
        ELSE IF ( solvent%type .EQ. 1 ) THEN
          WRITE( UNIT = program_unit, FMT = 9002 ) 'SCCS'
          WRITE( UNIT = program_unit, FMT = 9004 ) solvent%rhomax, solvent%rhomin
        ENDIF
        !
        IF ( env_static_permittivity .GT. 1.D0 ) THEN
           WRITE( UNIT = program_unit, FMT = 9005 ) env_static_permittivity
           IF (tddfpt) &
         & WRITE( UNIT = program_unit, FMT = 9006 ) env_optical_permittivity
           WRITE( UNIT = program_unit, FMT = 9007 ) TRIM( solvent%mode )
        END IF
        !
        IF ( env_surface_tension .GT. 0.D0 ) WRITE( UNIT = program_unit, FMT = 9010 )      &
           env_surface_tension/1.D-3/bohr_radius_si**2*rydberg_si, env_surface_tension, solvent%deltatheta
        !
        IF ( env_pressure .NE. 0.D0 ) WRITE( UNIT = program_unit, FMT = 9011 )&
           env_pressure*rydberg_si/bohr_radius_si**3*1.D-9, env_pressure
        !
        WRITE( program_unit, * )
        !
      END IF
      !
9001 FORMAT( '     compensation onset threshold      = ',  E24.4,' ' )
9002 FORMAT( '     switching function adopted        = ',  A24,' ' )
9003 FORMAT( '     solvation density threshold       = ',  E24.4,' ' &
            /'     smoothness exponent (2 x beta)    = ',  F24.2,' ')
9004 FORMAT( '     density limit for vacuum region   = ',  E24.4,' ' &
            /'     density limit for bulk solvent    = ',  E24.4,' ')
9005 FORMAT( '     static permittivity               = ',  F24.2,' ')
9006 FORMAT( '     optical permittivity              = ',  F24.4,' ')
9007 FORMAT( '     epsilon calculation mode          = ',  A24,' ' )
9008 FORMAT( '     type of numerical differentiator  = ',  A24,' ' &
            /'     number of points in num. diff.    = ',  I24,' ' )
9009 FORMAT( '     required accuracy                 = ',  E24.4,' ' &
            /'     linear mixing parameter           = ',  F24.2,' ' )
9010 FORMAT( '     surface tension in input (dyn/cm) = ',  F24.2,' ' &
            /'     surface tension in internal units = ',  E24.4,' ' &
            /'     delta parameter for surface depth = ',  E24.4,' ' )
9011 FORMAT( '     external pressure in input (GPa)  = ',  F24.2,' ' &
            /'     external pressure in inter. units = ',  E24.4,' ' )
9012 FORMAT( '     correction slab geom. along axis  = ',  I24,' ' )
9013 FORMAT( '     number of external charged items  = ',  I24,' ' )
9014 FORMAT( '     number of dielectric regions      = ',  I24,' ' )

!--------------------------------------------------------------------
      END SUBROUTINE environ_summary
!--------------------------------------------------------------------
!--------------------------------------------------------------------
      SUBROUTINE environ_clock( )
!--------------------------------------------------------------------
      !
      ! Write out the time informations of the Environ dependent
      ! calculations. Called by print_clock_pw.f90
      !
      USE environ_base,   ONLY : lelectrostatic, lsurface, lvolume
      USE control_flags,  ONLY : tddfpt
      !
      IMPLICIT NONE
      !
      WRITE( program_unit, * )
      WRITE( program_unit, '(5X,"Environ routines")' )
      ! dielectric subroutines
      IF ( lelectrostatic ) THEN
         CALL print_clock ('calc_eelect')
         CALL print_clock ('calc_velect')
         CALL print_clock ('dielectric')
         CALL print_clock ('calc_felect')
      END IF
      ! cavitation subroutines
      IF ( lsurface ) THEN
         CALL print_clock ('calc_ecav')
         CALL print_clock ('calc_vcav')
      END IF
      ! pressure subroutines
      IF ( lvolume ) THEN
         CALL print_clock ('calc_epre')
         CALL print_clock ('calc_vpre')
      END IF
      ! TDDFT
      IF (tddfpt) CALL print_clock ('calc_vsolvent_tddfpt')
      !
      RETURN
      !
!--------------------------------------------------------------------
      END SUBROUTINE environ_clock
!--------------------------------------------------------------------
!--------------------------------------------------------------------
      SUBROUTINE write_cube( f, ions )
!--------------------------------------------------------------------
      !
      USE kinds,          ONLY : DP
      USE mp,             ONLY : mp_sum
      USE fft_base,       ONLY : dfftp
! BACKWARD COMPATIBILITY
! Compatible with QE-5.1 QE-5.1.1 QE-5.1.2
!      USE fft_base,       ONLY : grid_gather
! Compatible with QE-5.2 QE-5.2.1
!      USE fft_base,       ONLY : gather_grid
! Compatible with QE-5.3 svn
      USE scatter_mod,    ONLY : gather_grid
! END BACKWARD COMPATIBILITY
      !
      IMPLICIT NONE
      !
      TYPE( environ_density ), TARGET, INTENT(IN) :: f
      TYPE( environ_ions ), TARGET, OPTIONAL, INTENT(IN) :: ions
      !
      INTEGER                  :: ir, ir1, ir2, ir3, num
      INTEGER                  :: ipol, iat, typ, count
      INTEGER                  :: nr1x, nr2x, nr3x
      INTEGER                  :: nr1, nr2, nr3
      !
      REAL( DP )               :: tmp, scale
      REAL( DP ), ALLOCATABLE  :: flocal( : )
      REAL( DP ), DIMENSION(3) :: origin
      !
      CHARACTER( LEN=80 ) :: filename
      REAL( DP ), POINTER :: alat
      REAL( DP ), DIMENSION(:,:), POINTER :: at
      !
      INTEGER :: nat
      INTEGER, DIMENSION(:), POINTER :: ityp
      REAL( DP ), DIMENSION(:,:), POINTER :: tau
      !
      nr1x = dfftp%nr1x
      nr2x = dfftp%nr2x
      nr3x = dfftp%nr3x
      !
      nr1 = dfftp%nr1
      nr2 = dfftp%nr2
      nr3 = dfftp%nr3
      !
      filename = f%label
      !
      alat => f%cell%alat
      at => f%cell%at
      !
      IF ( PRESENT( ions ) ) THEN
         nat = ions%number
         ityp => ions%ityp
         tau => ions%tau
      ELSE
         nat = 1
      ENDIF
      !
      ALLOCATE( flocal( nr1x*nr2x*nr3x ) )
#ifdef __MPI
      flocal = 0.D0
!Compatible with QE-5.1 QE-5.1.1 QE-5.1.2
!      CALL grid_gather( f, flocal )
!Compatible with QE-svn
      CALL gather_grid( dfftp, f%of_r, flocal )
      CALL mp_sum( flocal, comm )
#else
      flocal = f%of_r
#endif
      !
      IF( ionode ) THEN
        !
        OPEN( 300, file = TRIM( filename ), status = 'unknown' )
        !
        origin=0.d0
        scale=alat!*0.52917720859d0
        WRITE(300,*)'CUBE FILE GENERATED BY PW.X'
        WRITE(300,*)'OUTER LOOP: X, MIDDLE LOOP: Y, INNER LOOP: Z'
        WRITE(300,'(i5,3f12.6)')nat,origin(1),origin(2),origin(3)
        WRITE(300,'(i5,3f12.6)')nr1,(at(ipol,1)/DBLE(nr1)*scale,ipol=1,3)
        WRITE(300,'(i5,3f12.6)')nr2,(at(ipol,2)/DBLE(nr2)*scale,ipol=1,3)
        WRITE(300,'(i5,3f12.6)')nr3,(at(ipol,3)/DBLE(nr3)*scale,ipol=1,3)
        IF ( PRESENT( ions ) ) THEN
           DO iat=1,nat
              typ=ityp(iat)
              num=ions%iontype(typ)%atmnum
              WRITE(300,'(i5,4f12.6)')num,0.d0,tau(1,iat)*scale,&
                   tau(2,iat)*scale,tau(3,iat)*scale
           ENDDO
        ELSE
           WRITE(300,'(i5,4f12.6)')1,0.d0,0.d0,0.d0,0.d0
        ENDIF
        count=0
        DO ir1=1,nr1
          DO ir2=1,nr2
            DO ir3=1,nr3
              count=count+1
              ir = ir1 + ( ir2 -1 ) * nr1 + ( ir3 - 1 ) * nr1 * nr2
              tmp = DBLE( flocal( ir ) )
              IF (ABS(tmp).LT.1.D-99) tmp = 0.D0
              IF (MOD(count,6).EQ.0) THEN
                WRITE(300,'(e12.6,1x)')tmp
              ELSE
                WRITE(300,'(e12.6,1x)',advance='no')tmp
              ENDIF
            ENDDO
          ENDDO
        ENDDO
        !
        CLOSE( 300 )
        !
      END IF
      !
      DEALLOCATE( flocal )
      !
      RETURN
      !
!--------------------------------------------------------------------
      END SUBROUTINE write_cube
!--------------------------------------------------------------------
!--------------------------------------------------------------------
END MODULE environ_output
!--------------------------------------------------------------------
