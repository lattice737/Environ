! Copyright (C) 2018 ENVIRON (www.quantum-environment.org)
!
!    This file is part of Environ version 1.1
!
!    Environ 1.1 is free software: you can redistribute it and/or modify
!    it under the terms of the GNU General Public License as published by
!    the Free Software Foundation, either version 2 of the License, or
!    (at your option) any later version.
!
!    Environ 1.1 is distributed in the hope that it will be useful,
!    but WITHOUT ANY WARRANTY; without even the implied warranty of
!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!    GNU General Public License for more detail, either the file
!    `License' in the root directory of the present distribution, or
!    online at <http://www.gnu.org/licenses/>.
!
!> Module containing the definition of electrostatic derived data types
!! of the basic routines to handle them
!
! Authors: Oliviero Andreussi (Department of Physics, UNT)
!          Francesco Nattino  (THEOS and NCCR-MARVEL, EPFL)
!          Nicola Marzari     (THEOS and NCCR-MARVEL, EPFL)
!
!----------------------------------------------------------------------------
MODULE electrostatic_types
!----------------------------------------------------------------------------
  !
  USE environ_types
  !
  USE core_types
  USE core_base
  !
  TYPE gradient_solver
     !
     LOGICAL :: lconjugate
     !
     CHARACTER( LEN = 80 ) :: step_type
     REAL( DP ) :: step
     INTEGER :: maxstep
     !
     CHARACTER( LEN = 80 ) :: preconditioner
     !
     CHARACTER( LEN = 80 ) :: screening_type
     REAL( DP ) :: screening
     !
     REAL( DP ) :: tol
     !
  END TYPE gradient_solver
  !
  TYPE iterative_solver
     !
     CHARACTER( LEN = 80 ) :: mix_type
     REAL( DP ) :: mix
     INTEGER :: maxiter
     !
     INTEGER :: ndiis
     !
     REAL( DP ) :: tol
     !
  END TYPE iterative_solver
  !
  TYPE newton_solver
     !
     INTEGER :: maxiter
     REAL( DP ) :: tol
     !
  END TYPE newton_solver
  !
  TYPE electrostatic_solver
     !
     CHARACTER( LEN = 80 ) :: type
     !
     CHARACTER( LEN = 80 ) :: auxiliary
     !
     LOGICAL :: use_direct
     !
     LOGICAL :: use_gradient
     TYPE( gradient_solver ), POINTER :: gradient => NULL()
     !
     LOGICAL :: use_iterative
     TYPE( iterative_solver ), POINTER :: iterative => NULL()
     !
     LOGICAL :: use_newton
     TYPE( newton_solver ), POINTER :: newton => NULL()
     !
!     LOGICAL :: use_lbfgs
!     TYPE( lbfgs_solver ) :: lbfgs
!
     !
  END TYPE electrostatic_solver
  !
  TYPE electrostatic_core
     !
     CHARACTER( LEN = 80 ) :: type
     !
     LOGICAL :: use_fft
     TYPE( fft_core ), POINTER :: fft => NULL()
     !
     LOGICAL :: use_oned_analytic
     TYPE( oned_analytic_core ), POINTER :: oned_analytic => NULL()
     !
!     LOGICAL :: use_oned_numeric
!     TYPE( oned_numeric_core ), POINTER :: oned_numeric => NULL()
!
!     LOGICAL :: use_multigrid
!     TYPE( multigrid_core ), POINTER :: multigrid => NULL()
!
!     LOGICAL :: use_bigdft
!     TYPE( bigdft_core ), POINTER :: bigdft => NULL()
     !
     LOGICAL :: need_correction
     TYPE( electrostatic_core ), POINTER :: correction => NULL()
     !
  END TYPE electrostatic_core
  !
  TYPE electrostatic_setup
     !
     CHARACTER( LEN = 80 ) :: problem
     !
     TYPE( electrostatic_solver ), POINTER :: solver => NULL()
     !
     TYPE( electrostatic_core ), POINTER :: core => NULL()
     !
     LOGICAL :: nested_problem
     TYPE( electrostatic_setup ), POINTER :: inner => NULL()
     !
  END TYPE electrostatic_setup
  !
CONTAINS
  !
!--------------------------------------------------------------------
  SUBROUTINE init_gradient_solver( lconjugate, tol, step_type, step, maxstep, preconditioner, &
       & screening_type, screening, gradient )
!--------------------------------------------------------------------
    !
    IMPLICIT NONE
    !
    LOGICAL, INTENT(IN) :: lconjugate
    INTEGER, INTENT(IN) :: maxstep
    REAL( DP ), INTENT(IN) :: tol, step, screening
    CHARACTER( LEN = 80 ), INTENT(IN) :: step_type, preconditioner, screening_type
    TYPE( gradient_solver ), INTENT(INOUT) :: gradient
    !
    gradient % lconjugate = lconjugate
    gradient % tol = tol
    gradient % step_type = step_type
    gradient % step = step
    gradient % maxstep = maxstep
    gradient % preconditioner = preconditioner
    gradient % screening_type = screening_type
    gradient % screening = screening
    !
    RETURN
    !
!--------------------------------------------------------------------
  END SUBROUTINE init_gradient_solver
!--------------------------------------------------------------------
!--------------------------------------------------------------------
  SUBROUTINE init_iterative_solver( tol, mix_type, mix, maxiter, ndiis, iterative )
!--------------------------------------------------------------------
    !
    IMPLICIT NONE
    !
    INTEGER, INTENT(IN) :: maxiter, ndiis
    REAL( DP ), INTENT(IN) :: tol, mix
    CHARACTER( LEN = 80 ), INTENT(IN) :: mix_type
    TYPE( iterative_solver ), INTENT(INOUT) :: iterative
    !
    iterative % tol = tol
    iterative % mix_type = mix_type
    iterative % mix = mix
    iterative % maxiter = maxiter
    iterative % ndiis = ndiis
    !
    RETURN
    !
!--------------------------------------------------------------------
  END SUBROUTINE init_iterative_solver
!--------------------------------------------------------------------
!--------------------------------------------------------------------
  SUBROUTINE init_newton_solver( tol, maxiter, newton )
!--------------------------------------------------------------------
    !
    IMPLICIT NONE
    !
    INTEGER, INTENT(IN) :: maxiter
    REAL( DP ), INTENT(IN) :: tol
    TYPE( newton_solver ), INTENT(INOUT) :: newton
    !
    newton % tol = tol
    newton % maxiter = maxiter
    !
    RETURN
    !
!--------------------------------------------------------------------
  END SUBROUTINE init_newton_solver
!--------------------------------------------------------------------
!--------------------------------------------------------------------
  SUBROUTINE create_electrostatic_solver( solver )
!--------------------------------------------------------------------
    !
    IMPLICIT NONE
    !
    TYPE( electrostatic_solver ), INTENT(INOUT) :: solver
    !
    solver % type = 'default'
    solver % auxiliary = 'none'
    solver % use_direct = .FALSE.
    !
    solver % use_gradient = .FALSE.
    NULLIFY( solver % gradient )
    !
    solver % use_iterative = .FALSE.
    NULLIFY( solver % iterative )
    !
    RETURN
    !
!--------------------------------------------------------------------
  END SUBROUTINE create_electrostatic_solver
!--------------------------------------------------------------------
!--------------------------------------------------------------------
  SUBROUTINE init_electrostatic_solver( type, solver, gradient, iterative, newton, auxiliary )
!--------------------------------------------------------------------
    !
    IMPLICIT NONE
    !
    CHARACTER( LEN = 80 ), INTENT(IN) :: type
    TYPE( electrostatic_solver ), INTENT(INOUT) :: solver
    TYPE( gradient_solver ), TARGET, INTENT(IN), OPTIONAL :: gradient
    TYPE( iterative_solver ), TARGET, INTENT(IN), OPTIONAL :: iterative
    TYPE( newton_solver ), TARGET, INTENT(IN), OPTIONAL :: newton
    CHARACTER( LEN = 80 ), INTENT(IN), OPTIONAL :: auxiliary
    !
    INTEGER :: number
    CHARACTER( LEN = 80 ) :: sub_name = 'init_electrostatic_solver'
    !
    solver % type = type
    IF ( PRESENT( auxiliary ) ) solver % auxiliary = auxiliary
    !
    SELECT CASE ( TRIM( ADJUSTL( solver % type ) ) )
       !
    CASE ( 'direct', 'default' )
       !
       solver % use_direct = .TRUE.
       !
    CASE ( 'cg', 'sd', 'gradient' )
       !
       IF ( .NOT. PRESENT( gradient ) ) &
            & CALL errore( sub_name, 'Missing specified solver type', 1 )
       solver % use_gradient = .TRUE.
       solver % gradient => gradient
       !
    CASE ( 'iterative' )
       !
       IF ( .NOT. PRESENT( iterative ) ) &
            & CALL errore( sub_name, 'Missing specified solver type', 1 )
       solver % use_iterative = .TRUE.
       solver % iterative => iterative
    CASE( 'newton' )
       !
       IF ( .NOT. PRESENT( newton ) ) &
            & CALL errore( sub_name, 'Missing specified solver type', 1 )
       solver % use_newton = .TRUE.
       solver % newton => newton
       !
    CASE DEFAULT
       !
       CALL errore( sub_name, 'Unexpected option for electrostatic solver type', 1 )
       !
    END SELECT
    !
    ! double check that one and only one solver is specified
    !
    number = 0
    IF ( solver % use_direct ) number = number + 1
    IF ( solver % use_gradient ) number = number + 1
    IF ( solver % use_iterative ) number = number + 1
    IF ( solver % use_newton ) number = number + 1
    IF ( number .NE. 1 ) CALL errore( sub_name, 'Too few or too many solvers are active', 1 )
    !
    RETURN
    !
!--------------------------------------------------------------------
  END SUBROUTINE init_electrostatic_solver
!--------------------------------------------------------------------
!--------------------------------------------------------------------
  SUBROUTINE destroy_electrostatic_solver( lflag, solver )
!--------------------------------------------------------------------
    !
    IMPLICIT NONE
    !
    LOGICAL, INTENT(IN) :: lflag
    TYPE( electrostatic_solver ), INTENT(INOUT) :: solver
    !
    IF ( lflag ) THEN
       solver % use_direct = .FALSE.
       solver % use_gradient = .FALSE.
       NULLIFY( solver % gradient )
       solver % use_iterative = .FALSE.
       NULLIFY( solver % iterative )
    END IF
    !
    RETURN
    !
!--------------------------------------------------------------------
  END SUBROUTINE destroy_electrostatic_solver
!--------------------------------------------------------------------
!--------------------------------------------------------------------
  SUBROUTINE create_electrostatic_core( core )
!--------------------------------------------------------------------
    !
    IMPLICIT NONE
    !
    TYPE( electrostatic_core ), INTENT(INOUT) :: core
    !
    core % type = 'default'
    core % use_fft = .FALSE.
    NULLIFY( core % fft )
    core % use_oned_analytic = .FALSE.
    NULLIFY( core % oned_analytic )
    !
    core % need_correction = .FALSE.
    NULLIFY( core % correction )
    !
    RETURN
    !
!--------------------------------------------------------------------
  END SUBROUTINE create_electrostatic_core
!--------------------------------------------------------------------
!--------------------------------------------------------------------
  SUBROUTINE init_electrostatic_core( type, core, fft, oned_analytic )
!--------------------------------------------------------------------
    !
    IMPLICIT NONE
    !
    CHARACTER( LEN = 80 ), INTENT(IN) :: type
    TYPE( electrostatic_core ), INTENT(INOUT) :: core
    TYPE( fft_core ), INTENT(IN), TARGET, OPTIONAL :: fft
    TYPE( oned_analytic_core ), INTENT(IN), TARGET, OPTIONAL :: oned_analytic
    !
    INTEGER :: number
    CHARACTER( LEN = 80 ) :: sub_name = 'init_electrostatic_core'
    !
    core % type = type
    !
    ! Assign the selected numerical core
    !
    SELECT CASE ( TRIM( ADJUSTL( type ) ) )
       !
    CASE ( 'fft', 'default' )
       !
       IF ( .NOT. PRESENT( fft ) ) CALL errore(sub_name,'Missing specified core type',1)
       core % use_fft = .TRUE.
       core % fft => fft
       !
    CASE ( '1da', '1d-analytic', 'oned_analytic', 'gcs' ,'gouy-chapman', 'gouy-chapman-stern',&
           & 'ms','mott-schottky','ms-gcs','mott-schottky-gouy-chapman-stern')
       !
       IF ( .NOT. PRESENT( oned_analytic ) ) CALL errore(sub_name,'Missing specified core type',1)
       core % use_oned_analytic = .TRUE.
       core % oned_analytic => oned_analytic
       !
    CASE DEFAULT
       !
       CALL errore(sub_name,'Unexpected keyword for electrostatic core type',1)
       !
    END SELECT
    !
    ! double check number of active cores
    !
    number = 0
    IF ( core % use_fft ) number = number + 1
    IF ( core % use_oned_analytic ) number = number + 1
    IF ( number .NE. 1 ) &
         & CALL errore(sub_name,'Too few or too many cores are active',1)
    !
    RETURN
    !
!--------------------------------------------------------------------
  END SUBROUTINE init_electrostatic_core
!--------------------------------------------------------------------
!--------------------------------------------------------------------
  SUBROUTINE add_correction( correction, core )
!--------------------------------------------------------------------
    !
    IMPLICIT NONE
    !
    TYPE( electrostatic_core ), TARGET, INTENT(IN) :: correction
    TYPE( electrostatic_core ), INTENT(INOUT) :: core
    !
    core % need_correction = .TRUE.
    core % correction => correction
    !
    RETURN
    !
!--------------------------------------------------------------------
  END SUBROUTINE add_correction
!--------------------------------------------------------------------
!--------------------------------------------------------------------
  SUBROUTINE destroy_electrostatic_core( lflag, core )
!--------------------------------------------------------------------
    !
    IMPLICIT NONE
    !
    LOGICAL, INTENT(IN) :: lflag
    TYPE( electrostatic_core ), INTENT(INOUT) :: core
    !
    IF ( lflag ) THEN
       core % use_fft = .FALSE.
       NULLIFY( core % fft )
       core % use_oned_analytic = .FALSE.
       NULLIFY( core % oned_analytic )
       core % need_correction = .FALSE.
       NULLIFY( core % correction )
    END IF
    !
    RETURN
    !
!--------------------------------------------------------------------
  END SUBROUTINE destroy_electrostatic_core
!--------------------------------------------------------------------
!--------------------------------------------------------------------
  SUBROUTINE create_electrostatic_setup( setup )
!--------------------------------------------------------------------
    !
    IMPLICIT NONE
    !
    TYPE( electrostatic_setup ), INTENT(INOUT) :: setup
    !
    setup % problem = 'poisson'
    NULLIFY( setup % solver )
    NULLIFY( setup % core )
    !
    setup % nested_problem = .FALSE.
    NULLIFY( setup % inner )
    !
    RETURN
    !
!--------------------------------------------------------------------
  END SUBROUTINE create_electrostatic_setup
!--------------------------------------------------------------------
!--------------------------------------------------------------------
  SUBROUTINE init_electrostatic_setup( problem, solver, core, setup )
!--------------------------------------------------------------------
    !
    IMPLICIT NONE
    !
    CHARACTER( LEN = 80 ), INTENT(IN) :: problem
    TYPE( electrostatic_solver ), TARGET, INTENT(IN) :: solver
    TYPE( electrostatic_core ), TARGET, INTENT(IN) :: core
    TYPE( electrostatic_setup ), INTENT(INOUT) :: setup
    !
    CHARACTER( LEN = 80 ) :: sub_name = 'init_electrostatic_setup'
    !
    setup % problem = problem
    !
    ! Sanity check on the global setup
    !
    SELECT CASE ( TRIM( ADJUSTL( setup % problem ) ) )
       !
    CASE ( 'poisson', 'default' )
       !
    CASE ( 'generalized', 'gpe' )
       !
       IF ( solver % use_direct ) &
            & CALL errore(sub_name,'Cannot use a direct solver for the Generalized Poisson eq.',1)
       !
    CASE ( 'linpb', 'linmodpb', 'linearized-pb' )
       !
       IF ( solver % use_direct .OR. solver % use_iterative ) &
            & CALL errore(sub_name,'Only gradient-based solver for the linearized Poisson-Boltzmann eq.',1)
       !
       IF ( core % need_correction ) THEN
          IF (.NOT. core % correction % type .EQ. '1da' ) &
            & CALL errore(sub_name,'linearized-PB problem requires parabolic pbc correction.',1)
       ELSE
          CALL errore(sub_name,'linearized-PB problem requires parabolic pbc correction.',1)
       END IF
       !
    CASE ( 'pb', 'modpb', 'poisson-boltzmann' )
       !
       IF ( solver % use_direct .OR. solver % use_gradient ) &
          & CALL errore(sub_name,'No direct or gradient-based solver for the full Poisson-Boltzmann eq.',1)
       !
       IF ( core % need_correction ) THEN
          IF (.NOT. core % correction % type .EQ. '1da' ) &
            & CALL errore(sub_name,'full-PB problem requires parabolic pbc correction.',1)
       ELSE
          CALL errore(sub_name,'full-PB problem requires parabolic pbc correction.',1)
       END IF
       !
    CASE DEFAULT
       !
       CALL errore(sub_name,'Unexpected keyword for electrostatic problem',1)
       !
    END SELECT
    !
    setup % solver => solver
    setup % core => core
    !
    RETURN
    !
!--------------------------------------------------------------------
  END SUBROUTINE init_electrostatic_setup
!--------------------------------------------------------------------
!--------------------------------------------------------------------
  SUBROUTINE add_inner_setup( inner, outer )
!--------------------------------------------------------------------
    !
    IMPLICIT NONE
    !
    TYPE( electrostatic_setup ), TARGET, INTENT(IN) :: inner
    TYPE( electrostatic_setup ), INTENT(INOUT) :: outer
    !
    outer % nested_problem = .TRUE.
    outer % inner => inner
    !
    RETURN
    !
!--------------------------------------------------------------------
  END SUBROUTINE add_inner_setup
!--------------------------------------------------------------------
!--------------------------------------------------------------------
  SUBROUTINE destroy_electrostatic_setup( lflag, setup )
!--------------------------------------------------------------------
    !
    IMPLICIT NONE
    !
    LOGICAL, INTENT(IN) :: lflag
    TYPE( electrostatic_setup ), INTENT(INOUT) :: setup
    !
    IF ( lflag ) THEN
       NULLIFY( setup % solver )
       NULLIFY( setup % core )
       setup % nested_problem = .FALSE.
       NULLIFY( setup % inner )
    END IF
    !
    RETURN
    !
!--------------------------------------------------------------------
  END SUBROUTINE destroy_electrostatic_setup
!--------------------------------------------------------------------
!--------------------------------------------------------------------
  SUBROUTINE set_electrostatic_flags( setup, need_auxiliary, need_gradient, need_factsqrt )
!--------------------------------------------------------------------
    !
    IMPLICIT NONE
    !
    TYPE( electrostatic_setup ), INTENT(IN) :: setup
    LOGICAL, INTENT(INOUT) :: need_auxiliary, need_gradient, need_factsqrt
    !
    SELECT CASE ( setup % problem )
       !
    CASE ( 'generalized', 'linpb', 'linmodpb', 'pb', 'modpb' )
       !
       IF ( setup % solver % use_gradient ) THEN
          !
          SELECT CASE ( setup % solver % gradient % preconditioner )
             !
          CASE ( 'sqrt' )
             !
             need_factsqrt = .TRUE.
             !
          CASE ( 'left', 'none' )
             !
             need_gradient = .TRUE.
             !
          END SELECT
          !
       END IF
       !
       IF ( setup % solver % auxiliary .NE. 'none' ) need_auxiliary = .TRUE.
       !
    END SELECT
    !
    RETURN
    !
!--------------------------------------------------------------------
  END SUBROUTINE set_electrostatic_flags
!--------------------------------------------------------------------
!----------------------------------------------------------------------------
END MODULE electrostatic_types
!----------------------------------------------------------------------------
