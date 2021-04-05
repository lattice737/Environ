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
! Authors: Oliviero Andreussi (Department of Physics, UNT)
!          Francesco Nattino  (THEOS and NCCR-MARVEL, EPFL)
!          Ismaila Dabo       (DMSE, Penn State)
!          Nicola Marzari     (THEOS and NCCR-MARVEL, EPFL)
!
!----------------------------------------------------------------------------------------
!>
!! This module contains all variables in the environ.in input file
!! together with the routines performing initialization and broadcast
!!
!----------------------------------------------------------------------------------------
MODULE environ_input
    !------------------------------------------------------------------------------------
    !
    USE modules_constants, ONLY: DP, bohr_radius_angs, nsx
    USE modules_parser, ONLY: env_field_count, env_read_line, env_get_field, parse_unit
    USE mp, ONLY: mp_bcast
    !
    USE environ_output, ONLY: ionode, ionode_id, comm, program_unit, &
                              verbose_ => verbose, environ_unit
    !
    IMPLICIT NONE
    !
    SAVE
    !
    !=---------------------------------------------------------------------------------=!
!       ENVIRON Cards Parameters
    !=---------------------------------------------------------------------------------=!
    !
    ! Local parameters of external charges
    !
    LOGICAL :: taextchg = .FALSE.
    !
    INTEGER, ALLOCATABLE :: extcharge_dim(:) ! point/line/plane of charge
    INTEGER, ALLOCATABLE :: extcharge_axis(:) ! x/y/z direction of line/plane
    REAL(DP), ALLOCATABLE :: extcharge_charge(:) ! total charge of density
    REAL(DP), ALLOCATABLE :: extcharge_spread(:) ! gaussian density spread (bohr)
    REAL(DP), ALLOCATABLE :: extcharge_pos(:, :) ! cartesian position of density
    !
    CHARACTER(LEN=80) :: external_charges = 'bohr' ! atomic positions (bohr|angstrom)
    !
    !------------------------------------------------------------------------------------
    ! Local parameters of dielectric regions
    !
    LOGICAL :: taepsreg = .FALSE.
    !
    INTEGER, ALLOCATABLE :: epsregion_dim(:) ! point/line/plane region
    INTEGER, ALLOCATABLE :: epsregion_axis(:) ! x/y/z direction of line/plane
    REAL(DP), ALLOCATABLE :: epsregion_eps(:, :) ! permittivity inside region
    REAL(DP), ALLOCATABLE :: epsregion_width(:) ! region size (bohr)
    REAL(DP), ALLOCATABLE :: epsregion_spread(:) ! interface spread (bohr)
    REAL(DP), ALLOCATABLE :: epsregion_pos(:, :) ! cartesian center of region
    !
    CHARACTER(LEN=80) :: dielectric_regions = 'bohr' ! atomic positions (bohr|angstrom)
    !
    !=---------------------------------------------------------------------------------=!
!       ENVIRON Namelist Input Parameters
    !=---------------------------------------------------------------------------------=!
    !
    LOGICAL :: environ_restart = .FALSE.
    ! restart a previous calculation: environ contributions are computed during
    ! initialization
    !
    INTEGER :: verbose = 0 ! verbosity
    ! 0: only prints summary of polarization charge calculation;
    ! 1: prints an extra file with details of iterative convergence;
    ! 2: prints 3D cube files of physical properties
    !
    REAL(DP) :: environ_thr = 1.D-1 ! when in scf to start calculating corr. pot.
    !
    INTEGER :: environ_nskip = 1 ! # steps to skip before starting add. pot. computation
    !
    !------------------------------------------------------------------------------------
    ! Predefined environ types
    !
    CHARACTER(LEN=80) :: environ_type = 'input'
    CHARACTER(LEN=80) :: environ_type_allowed(5)
    !
    DATA environ_type_allowed/'vacuum', 'water', 'water-cation', 'water-anion', 'input'/
    !
    !   sets all the environment parameters at once to a specific set
    !
    ! vacuum = all the flags are off (perm=1.d0, surf=0.0, pres=0.0)
    !
    ! water = parameters optimized for water solutions in Andreussi et al.
    !         J. Chem. Phys. 136, 064102 (perm=78, surf=50, pres=-0.35)
    !
    ! water-cation = parameters optimized for aqueous solvation of cations
    !         Dupont et al. J. Chem. Phys. 139, 214110 (perm=78, surf=, pres=)
    !
    ! water-anion = parameters optimized for aqueous solvation of anions
    !         Dupont et al. J. Chem. Phys. 139, 214110 (perm=78, surf=, pres=)
    !
    ! input = do not use any predefined set, use parameters from input
    !
    !------------------------------------------------------------------------------------
    ! System specification
    !
    INTEGER :: system_ntyp = 0
    ! specify the atom types that are used to determine the origin and
    ! size of the system (types up to system_ntyp are used, all atoms are
    ! used by default or if system_ntyp == 0)
    !
    INTEGER :: system_dim = 0
    ! dimensionality of the system, used to determine size (only ortogonally to
    ! periodic dimensions) and position (0 = 0D, 1 = 1D, 2 = 2D)
    !
    INTEGER :: system_axis = 3 ! main axis of 1D or 2D systems (1 = x, 2 = y, 3 = z)
    !
    !------------------------------------------------------------------------------------
    ! Environment cell specifications
    !
    INTEGER :: env_nrep(3) = 0
    ! number of additional replicas of the system cell on each side along the three axis
    ! nrep = 1 means there is one more cell on the left and on the right of the cell
    ! the environment cell is (2*nrep+1) times the system cell along the three axis
    !
    !------------------------------------------------------------------------------------
    ! Modification of electrostatic embedding (e.g. PBC correction)
    !
    LOGICAL :: env_electrostatic = .FALSE. ! flag electrostatic namelist reading
    !
    REAL(DP) :: atomicspread(nsx) = -0.5D0 ! atomic charge density gaussian spread (a.u.)
    !
    !------------------------------------------------------------------------------------
    ! Dielectric solvent parameters
    !
    REAL(DP) :: env_static_permittivity = 1.D0
    ! static dielectric permittivity of the solvation model
    ! if set equal to one (=vacuum), no dielectric effects
    !
    REAL(DP) :: env_optical_permittivity = 1.D0
    ! optical dielectric permittivity of the solvation model
    ! if set equal to one (=vacuum), no dielectric effects
    ! needed only for the TDDFTPT
    !
    !------------------------------------------------------------------------------------
    ! Cavitation energy parameters
    !
    REAL(DP) :: env_surface_tension = 0.D0 ! solvent surface tension
    ! if equal to zero, no cavitation term
    !
    !------------------------------------------------------------------------------------
    ! PV energy parameters
    !
    REAL(DP) :: env_pressure = 0.D0 ! external pressure for PV energy
    ! if equal to zero no pressure term
    !
    !------------------------------------------------------------------------------------
    ! Confine energy parameters
    !
    REAL(DP) :: env_confine = 0.D0 ! confinement potential
    !
    !------------------------------------------------------------------------------------
    ! Ionic countercharge parameters
    !
    LOGICAL :: electrolyte_linearized = .FALSE.
    ! solve linear-regime poisson-boltzmann problem
    !
    INTEGER :: env_electrolyte_ntyp = 0
    ! number of countercharge species in the electrolyte
    ! if != 0, must be >= 2
    !
    CHARACTER(LEN=80) :: electrolyte_entropy = 'full'
    CHARACTER(LEN=80) :: electrolyte_entropy_allowed(2)
    !
    DATA electrolyte_entropy_allowed/'ions', 'full'/
    !
    !   sets the electrolyte entropy terms that are affected by
    !   the Stern-layer correction
    !
    ! ions = only ionic terms ( Ringe et al. J. Chem. Theory Comput. 12, 4052 )
    !
    ! full = all terms ( Dabo et al. arXiv 0901.0096 )
    !
    CHARACTER(LEN=80) :: ion_adsorption = 'none'
    CHARACTER(LEN=80) :: ion_adsorption_allowed(4)
    !
    DATA ion_adsorption_allowed/'none', 'anion', 'cation', 'repulsion'/
    ! include asymmetric adsorption of electrolyte
    ! ( Baskin and Prendergast J. Electrochem. Soc. 164, E3438 )
    !
    REAL(DP) :: cion(nsx) = 1.D0 ! molar concentration of ionic countercharge (M=mol/L)
    REAL(DP) :: cionmax = 1.D3 ! maximum molar concentration of ionic countercharge (M=mol/L)
    REAL(DP) :: rion = 0.D0 ! mean atomic radius of ionic countercharge (a.u.)
    REAL(DP) :: zion(nsx) = 1.D0 ! valence of ionic countercharge
    REAL(DP) :: temperature = 300.D0 ! temperature of the solution
    REAL(DP) :: ion_adsorption_energy = 0.D0 ! adsorption energy of electrolyte (Ry)
    !
    !------------------------------------------------------------------------------------
    ! Semiconductor parameters
    !
    REAL(DP) :: sc_permittivity = 1.D0 ! dielectric permittivity of the semiconductor
    !
    REAL(DP) :: sc_carrier_density = 0.D0
    ! concentration of charge carriers within the semiconductor (cm^-3)
    !
    REAL(DP) :: sc_electrode_chg = 0.D0 ! the total charge on the electrode (e)
    !
    REAL(DP) :: sc_chg_thr = 1.D-4
    ! threshold for an outer loop of chg optimization in qe
    !
    !------------------------------------------------------------------------------------
    ! External charges parameters not read from EXTERNAL_CHARGES card
    !
    INTEGER :: env_external_charges = 0
    ! number of fixed external gaussian points/lines/planes of charges to be used
    ! in the calculation
    !
    !------------------------------------------------------------------------------------
    ! Dielectric regions parameters not read from DIELECTRIC_REGIONS card
    !
    INTEGER :: env_dielectric_regions = 0
    ! number of fixed dielectric regions in the calculation
    !
    !------------------------------------------------------------------------------------
    !
    NAMELIST /environ/ &
        environ_restart, verbose, environ_thr, environ_nskip, environ_type, &
        system_ntyp, system_dim, system_axis, env_nrep, env_electrostatic, &
        atomicspread, env_static_permittivity, env_optical_permittivity, &
        env_surface_tension, env_pressure, env_confine, env_electrolyte_ntyp, &
        cion, cionmax, rion, zion, temperature, electrolyte_linearized, &
        electrolyte_entropy, ion_adsorption, ion_adsorption_energy, &
        sc_permittivity, sc_carrier_density, sc_electrode_chg, sc_chg_thr, &
        env_external_charges, env_dielectric_regions
    !
    !=---------------------------------------------------------------------------------=!
!       BOUNDARY Namelist Input Parameters
    !=---------------------------------------------------------------------------------=!
    !
    ! Soft boundary (electronic) parameters
    !
    INTEGER :: stype = 2 ! type of switching functions used in the solvation models
    ! 0: original Fattebert-Gygi
    ! 1: ultrasoft switching function (only exponential part used for non-electrostatic)
    ! 2: ultrasoft switching function as defined in Andreussi et al. JCP 2012
    !
    !------------------------------------------------------------------------------------
    ! Rigid boundary (ionic) parameters
    !
    CHARACTER(LEN=80) :: radius_mode = 'uff'
    CHARACTER(LEN=80) :: radius_mode_allowed(4)
    !
    DATA radius_mode_allowed/'pauling', 'bondi', 'uff', 'muff'/
    !
    !   type of hardcoded solvation radii to be used when solvent_mode = 'ionic'
    !
    ! pauling = R.C. Weast, ed., Handbook of chemistry and physics
    !           (CRC Press, Cleveland, 1981)
    !
    ! bondi   = A. Bondi, J. Phys. Chem. 68, 441 (1964)
    !
    ! uff     = A.K. Rapp/'{e} et al. J. Am. Chem. Soc. 114(25) pp.10024-10035 (1992)
    !
    ! muff    = uff with local modifications (Nitrogen, see Fisicaro JCTC (2017)
    !
    REAL(DP) :: solvationrad(nsx) = -3.D0
    ! solvationrad radius of the solvation shell for each species when the
    ! ionic dielectric function is adopted, in internal units (a.u.)
    !
    !------------------------------------------------------------------------------------
    ! Full boundary parameters
    !
    REAL(DP) :: corespread(nsx) = -0.5D0
    ! gaussian spreads of the core electrons, in internal units (a.u.), to
    ! be used when solvent_mode = 'full'
    !
    !------------------------------------------------------------------------------------
    ! Solvent-aware boundary parameters
    !
    REAL(DP) :: solvent_radius = 0.D0
    ! size of the solvent, used to decide whether to fill a continuum
    ! void or not. If set equal to 0.D0, use the standard algorithm
    !
    REAL(DP) :: radial_scale = 2.D0
    ! compute the filled fraction on a spherical volume scaled w.r.t solvent size
    !
    REAL(DP) :: radial_spread = 0.5D0
    ! spread of the step function used to evaluate occupied volume
    !
    REAL(DP) :: filling_threshold = 0.825D0
    ! threshold to decide whether to fill a continuum void or not, to be
    ! compared with the filled fraction: if filled fraction .GT. threshold
    ! THEN fill gridpoint
    !
    REAL(DP) :: filling_spread = 0.02D0
    ! spread of the switching function used to decide whether the continuum
    ! void should be filled or not
    !
    !------------------------------------------------------------------------------------
    ! Field-aware boundary parameters #TODO add documentation
    !
    REAL(DP) :: field_awareness = 0.D0
    REAL(DP) :: charge_asymmetry = -1.D0
    REAL(DP) :: field_max = 10.D0
    REAL(DP) :: field_min = 1.D0
    !
    !------------------------------------------------------------------------------------
    ! Numerical core's parameters
    !
    CHARACTER(LEN=80) :: derivatives = 'analytic'
    CHARACTER(LEN=80) :: derivatives_allowed(4)
    !
    DATA derivatives_allowed/'fft', 'fd', 'analytic', 'highmem'/
    !
    CHARACTER(LEN=80) :: boundary_core = 'analytic'
    CHARACTER(LEN=80) :: boundary_core_allowed(5)
    !
    DATA boundary_core_allowed/'fft', 'fd', 'analytic', 'highmem', 'lowmem'/
    !
    !   core numerical methods to be exploited for quantities
    !   derived from the dielectric
    !
    ! fft       = fast Fourier transforms
    !
    ! fd        = finite difference in real space
    !
    ! analytic  = analytic derivatives for as much as possible (FFTs for the rest)
    !
    ! highmem   = analytic derivatives for soft-sphere computed by storing all spherical
    !             functions and derivatives
    !
    ! lowmem    = more efficient analytic derivatives (testing) #TODO possibly already working. discuss with Oliviero
    !
    !------------------------------------------------------------------------------------
    ! Finite difference parameters
    !
    INTEGER :: ifdtype = 1 ! type of numerical differentiator
    ! 1 = central difference
    ! 2 = low-noise lanczos (m=2)
    ! 3 = low-noise lanczos (m=4)
    ! 4 = smooth noise-robust (n=2)
    ! 5 = smooth noise-robust (n=4)
    !
    INTEGER :: nfdpoint = 2 ! number of points used in the numerical differentiator
    ! N = 2 * nfdpoint + 1
    !
    !------------------------------------------------------------------------------------
    ! Solvent boundary parameters
    !
    CHARACTER(LEN=80) :: solvent_mode = 'electronic'
    CHARACTER(LEN=80) :: solvent_mode_allowed(8)
    !
    DATA solvent_mode_allowed/'electronic', 'ionic', 'full', 'external', 'system', &
        'fa-electronic', 'fa-ionic', 'fa-full'/
    !
    !   solvent_mode method for calculating the density that
    !   sets the dielectric constant
    !
    ! electronic = dielectric depends self-consist. on electronic density
    !
    ! ionic = dielectric defined on a fictitious ionic density, generated
    !         as the sum of spherical error functions centered on atomic
    !         positions of width specified in input by solvationrad(ityp)
    !
    ! full  = similar to electronic, but an extra density is added to
    !         represent the core electrons and the nuclei. This extra
    !         density is defined as the sum of gaussian functions centered
    !         on atomic positions of width equal to corespread(ityp)
    !
    ! system = simplified regular dielectric defined to be outside a distance
    !         solvent_distance from the specified system
    !
    ! fa-electrons = similar to electronic, but field-aware
    !
    ! fa-ionic = similar to ionic, but field-aware
    !
    ! fa-full = similar to full, but field-aware
    !
    !------------------------------------------------------------------------------------
    ! Soft solvent boundary (electronic) parameters
    !
    REAL(DP) :: rhomax = 0.005
    ! first parameter of the sw function, roughly corresponding to the density
    ! threshold of the solvation model
    !
    REAL(DP) :: rhomin = 0.0001 ! second parameter of the sw function when stype=1 or 2
    !
    REAL(DP) :: tbeta = 4.8 ! second parameter of the sw function when stype=0
    !
    !------------------------------------------------------------------------------------
    ! Rigid solvent boundary (ionic) parameters
    !
    REAL(DP) :: alpha = 1.D0 ! scaling factor for ionic radii when solvent_mode = 'ionic'
    REAL(DP) :: softness = 0.5D0 ! spread of the rigid interfaces
    !
    !------------------------------------------------------------------------------------
    ! Simplified solvent boundary (system) parameters
    !
    REAL(DP) :: solvent_distance = 1.D0
    ! distance from the system where the boundary starts if required from solvent_mode
    !
    REAL(DP) :: solvent_spread = 0.5D0
    ! spread of the boundary interface if defined on system position and width
    !
    !------------------------------------------------------------------------------------
    ! Stern boundary parameters
    !
    CHARACTER(LEN=80) :: electrolyte_mode = 'electronic'
    CHARACTER(LEN=80) :: electrolyte_mode_allowed(8)
    !
    DATA electrolyte_mode_allowed/'electronic', 'ionic', 'full', 'external', &
        'system', 'fa-electronic', 'fa-ionic', 'fa-full'/
    ! electrolyte_mode method for calculating the density that sets the onset of
    ! ionic countercharge ( see solvent_mode above )
    !
    !------------------------------------------------------------------------------------
    ! Soft Stern boundary (electronic) parameters
    !
    REAL(DP) :: electrolyte_rhomax = 0.005D0
    ! first parameter of the Stern sw function, roughly corresponding
    ! to the density threshold of the ionic countercharge.
    !
    REAL(DP) :: electrolyte_rhomin = 0.0001D0
    ! second parameter of the Stern sw function when stype=1 or 2
    !
    REAL(DP) :: electrolyte_tbeta = 4.8D0
    ! second parameter of the Stern sw function when stype=0
    !
    !------------------------------------------------------------------------------------
    ! Rigid Stern boundary (ionic) parameters
    !
    REAL(DP) :: electrolyte_alpha = 1.D0
    ! scaling factor for ionic radii when electrolyte_mode = 'ionic'
    !
    REAL(DP) :: electrolyte_softness = 0.5D0 ! spread of the rigid Stern interfaces
    !
    !------------------------------------------------------------------------------------
    ! Simplified Stern boundary (system) parameters
    !
    REAL(DP) :: electrolyte_distance = 0.D0
    ! distance from the system where the electrolyte boundary starts
    !
    REAL(DP) :: electrolyte_spread = 0.5D0
    ! spread of the interfaces for the electrolyte boundary
    !
    !------------------------------------------------------------------------------------
    ! Mott Schottky boundary (system parameters
    !
    REAL(DP) :: sc_distance = 0.D0
    ! distance from the system where the mott schottky boundary starts
    !
    REAL(DP) :: sc_spread = 0.5D0
    ! spread of the interfaces for the mott schottky boundary
    !
    !------------------------------------------------------------------------------------
    !
    NAMELIST /boundary/ &
        solvent_mode, radius_mode, alpha, softness, solvationrad, stype, rhomax, &
        rhomin, tbeta, corespread, solvent_distance, solvent_spread, solvent_radius, &
        radial_scale, radial_spread, filling_threshold, filling_spread, &
        field_awareness, charge_asymmetry, field_max, field_min, electrolyte_mode, &
        electrolyte_distance, electrolyte_spread, electrolyte_rhomax, &
        electrolyte_rhomin, electrolyte_tbeta, electrolyte_alpha, &
        electrolyte_softness, derivatives, ifdtype, nfdpoint, boundary_core, &
        sc_distance, sc_spread
    !
    !=---------------------------------------------------------------------------------=!
!       ELECTROSTATIC Namelist Input Parameters
    !=---------------------------------------------------------------------------------=!
    !
    CHARACTER(LEN=80) :: problem = 'none'
    CHARACTER(LEN=80) :: problem_allowed(6)
    !
    DATA problem_allowed/'poisson', 'generalized', 'pb', 'modpb', 'linpb', 'linmodpb'/
    !
    !   type of electrostatic problem
    !
    ! poisson     = standard poisson equation, with or without
    !               boundary conditions (default)
    !
    ! generalized = generalized poisson equation
    !
    ! pb          = poisson-boltzmann equation (non-linear)
    !
    ! modpb       = modified poisson-boltzmann equation (non-linear)
    !
    ! linpb       = linearized poisson-boltzmann equation (debye-huckel)
    !
    ! linmodpb    = linearized modified poisson-boltzmann equation
    !
    !------------------------------------------------------------------------------------
    !
    REAL(DP) :: tol = 1.D-5
    ! convergence threshold for electrostatic potential or auxiliary charge
    !
    REAL(DP) :: inner_tol = 1.D-5 ! same as tol for inner loop in nested algorithms
    !
    !------------------------------------------------------------------------------------
    ! Driver's parameters
    !
    CHARACTER(LEN=80) :: solver = 'none'
    CHARACTER(LEN=80) :: solver_allowed(7)
    !
    DATA solver_allowed/'cg', 'sd', 'iterative', 'lbfgs', 'newton', 'nested', 'direct'/
    !
    !   type of numerical solver
    !
    ! direct    = for simple problems with analytic or direct solution
    !
    ! cg        = conjugate gradient (default)
    !
    ! sd        = steepest descent
    !
    ! iterative = fixed-point search
    !
    ! lbfgs     = low-memory bfgs
    !
    ! newton    = newton's method (only for non-linear problem)
    !
    ! nested    = double iterations (only for non-linear problem)
    !
    CHARACTER(LEN=80) :: auxiliary = 'none'
    CHARACTER(LEN=80) :: auxiliary_allowed(4)
    !
    DATA auxiliary_allowed/'none', 'full', 'pol', 'ioncc'/
    !
    !   solve with respect to the potential or with respect to
    !   an auxiliary charge density
    !
    ! none  = solve for the potential (default)
    !
    ! full  = solve for the auxiliary charge density
    !
    ! pol   = in a nested scheme, solve the inner (pol) cycle in terms of
    !         the auxiliary charge
    !
    ! ioncc = in a nested scheme, solve the outer (ioncc) cycle in terms of
    !         the auxiliary charge
    !
    CHARACTER(LEN=80) :: step_type = 'optimal'
    CHARACTER(LEN=80) :: step_type_allowed(3)
    !
    DATA step_type_allowed/'optimal', 'input', 'random'/
    !
    !   how to choose the step size in gradient descent algorithms or iterative mixing
    !
    ! optimal = step size that minimize the cost function on the descent direction
    !
    ! input   = fixed step size as defined in input (step keyword)
    !
    ! random  = random step size within zero and twice the optima value
    !
    REAL(DP) :: step = 0.3
    ! step size to be used if step_type = 'input'
    ! (inherits the tasks of the old mixrhopol)
    !
    INTEGER :: maxstep = 200
    ! maximum number of steps to be performed by gradient or iterative solvers
    !
    CHARACTER(LEN=80) :: inner_solver = 'none'
    CHARACTER(LEN=80) :: inner_solver_allowed(5)
    !
    DATA inner_solver_allowed/'none', 'cg', 'sd', 'iterative', 'direct'/
    ! type of numerical solver for inner loop in nested algorithms
    !
    INTEGER :: inner_maxstep = 200
    ! same as maxstep for inner loop in nested algorithms
    !
    !------------------------------------------------------------------------------------
    ! Iterative driver's parameters (OBSOLETE)
    !
    CHARACTER(LEN=80) :: mix_type = 'linear'
    CHARACTER(LEN=80) :: mix_type_allowed(4)
    !
    DATA mix_type_allowed/'linear', 'anderson', 'diis', 'broyden'/
    ! mixing method for iterative calculations: linear | anderson | diis | broyden
    !
    INTEGER :: ndiis = 1 ! order of DIIS interpolation of iterative calculation
    REAL(DP) :: mix = 0.5 ! mixing parameter to be used in the iterative driver
    REAL(DP) :: inner_mix = 0.5 ! same as mix but for inner loop in nested algorithm
    !
    !------------------------------------------------------------------------------------
    ! Preconditioner's parameters
    !
    CHARACTER(LEN=80) :: preconditioner = 'sqrt'
    CHARACTER(LEN=80) :: preconditioner_allowed(3)
    !
    DATA preconditioner_allowed/'none', 'sqrt', 'left'/
    !
    !   type of preconditioner
    !
    ! none      = no preconditioner
    !
    ! left      = left linear preconditioner eps nabla v = r
    !
    ! sqrt      = sqrt preconditioner sqrt(eps) nabla ( sqrt(eps) * v ) = r
    !
    CHARACTER(LEN=80) :: screening_type = 'none'
    CHARACTER(LEN=80) :: screening_type_allowed(4)
    !
    DATA screening_type_allowed/'none', 'input', 'linear', 'optimal'/
    !
    !   use the screened coulomb Green's function instead of the vacuum one
    !
    ! none      = unscreened coulomb
    !
    ! input     = screened coulomb with screening lenght provided in input
    !
    ! linear    = screened coulomb with screening lenght from linear component
    !             of the problem
    !
    ! optimal   = screened coulomb with screening lenght optimized (to be defined)
    !
    REAL(DP) :: screening = 0.D0
    ! screening lenght to be used if screening_type = 'input'
    !
    !------------------------------------------------------------------------------------
    ! Numerical core's parameters
    !
    CHARACTER(LEN=80) :: core = 'fft'
    CHARACTER(LEN=80) :: core_allowed(1)
    !
    DATA core_allowed/'fft'/
    !
    !   choice of the core numerical methods to be exploited for
    !   the different operations
    !
    ! fft = fast Fourier transforms (default)
    !
    ! to be implemented : wavelets (from big-DFT) and multigrid #TODO future work
    !
    !------------------------------------------------------------------------------------
    ! Periodic correction keywords
    !
    INTEGER :: pbc_dim = -3 ! dimensionality of the simulation cell
    ! periodic boundary conditions on 3/2/1/0 sides of the cell
    !
    CHARACTER(LEN=80) :: pbc_correction = 'none'
    CHARACTER(LEN=80) :: pbc_correction_allowed(9)
    !
    DATA pbc_correction_allowed/'none', 'parabolic', 'gcs', 'gouy-chapman', &
        'gouy-chapman-stern', 'ms', 'mott-schottky', 'ms-gcs', &
        'mott-schottky-guoy-chapman-stern'/
    !
    !   type of periodic boundary condition correction to be used
    !
    ! parabolic = point-counter-charge type of correction
    !
    ! ms        = mott-schottky calculation for semiconductor
    !
    INTEGER :: pbc_axis = 3 ! choice of the sides with periodic boundary conditions
    ! 1 = x, 2 = y, 3 = z, where
    ! if pbc_dim = 2, cell_axis is orthogonal to 2D plane
    ! if pbc_dim = 1, cell_axis is along the 1D direction
    !
    !------------------------------------------------------------------------------------
    !
    NAMELIST /electrostatic/ &
        problem, tol, solver, auxiliary, step_type, step, maxstep, mix_type, mix, &
        ndiis, preconditioner, screening_type, screening, core, pbc_dim, &
        pbc_correction, pbc_axis, inner_tol, inner_solver, inner_maxstep, inner_mix
    !
    !------------------------------------------------------------------------------------
CONTAINS
    !------------------------------------------------------------------------------------
    !>
    !! Routine for reading Environ input files. Uses built-in Namelist functionality
    !! and derived routines for cards (external charges and dielectric regions)
    !!
    !------------------------------------------------------------------------------------
    ! BACKWARD COMPATIBILITY
    ! Compatible with QE-6.0 QE-6.1.X QE-6.2.X QE-6.3.X
    ! SUBROUTINE read_environ(prog, nelec, nspin, nat, ntyp, atom_label, &
    !                         use_internal_pbc_corr, ion_radius)
    ! Compatible with QE-6.4.X QE-GIT
    SUBROUTINE read_environ(prog, nelec, nat, ntyp, atom_label, use_internal_pbc_corr, &
                            ion_radius)
        ! END BACKWARD COMPATIBILITY
        !--------------------------------------------------------------------------------
        !
        USE environ_init, ONLY: set_environ_base
        USE electrostatic_init, ONLY: set_electrostatic_base
        USE core_init, ONLY: set_core_base
        !
        CHARACTER(LEN=*), INTENT(IN) :: prog
        LOGICAL, INTENT(IN) :: use_internal_pbc_corr
        INTEGER, INTENT(IN) :: nelec, nat, ntyp
        !
        ! BACKWARD COMPATIBILITY
        ! Compatible with QE-6.0 QE-6.1.X QE-6.2.X QE-6.3.X
        ! INTEGER, INTENT(IN) :: nspin
        ! Compatible with QE-6.4.X QE-GIT
        ! END BACKWARD COMPATIBILITY
        !
        CHARACTER(LEN=3), INTENT(IN) :: atom_label(:)
        REAL(DP), INTENT(IN), OPTIONAL :: ion_radius(:)
        !
        INTEGER, EXTERNAL :: find_free_unit
        !
        LOGICAL :: ext
        INTEGER :: environ_unit_input
        INTEGER :: is
        !
        !--------------------------------------------------------------------------------
        ! Open environ input file: environ.in
        !
        environ_unit_input = find_free_unit()
        INQUIRE (file="environ.in", exist=ext)
        !
        IF (.NOT. ext) CALL errore('read_environ', ' missing environ.in file ', 1)
        !
        OPEN (unit=environ_unit_input, file="environ.in", status="old")
        !
        !--------------------------------------------------------------------------------
        ! Read values into local variables
        !
        CALL environ_read_namelist(environ_unit_input)
        !
        CALL environ_read_cards(environ_unit_input)
        !
        CLOSE (environ_unit_input)
        !
        !--------------------------------------------------------------------------------
        ! If passed from input, overwrites atomic spread
        ! (USED IN CP TO HAVE CONSISTENT RADII FOR ELECTROSTATICS)
        !
        IF (PRESENT(ion_radius)) THEN
            !
            DO is = 1, ntyp
                atomicspread(is) = ion_radius(is)
            END DO
            !
        END IF
        !
        !--------------------------------------------------------------------------------
        ! Set verbosity and open debug file
        !
        verbose_ = verbose
        !
        IF (verbose_ .GE. 1) &
            OPEN (unit=environ_unit, file='environ.debug', status='unknown')
        !
        !=-----------------------------------------------------------------------------=!
        !  Set module variables according to input
        !=-----------------------------------------------------------------------------=!
        !
        ! Set electrostatic first as it does not depend on anything else
        !
        CALL set_electrostatic_base(problem, tol, solver, auxiliary, &
                                    step_type, step, maxstep, mix_type, &
                                    ndiis, mix, preconditioner, &
                                    screening_type, screening, core, &
                                    ! BACKWARD COMPATIBILITY
                                    ! Compatible with QE-6.0 QE-6.1.X QE-6.2.X QE-6.3.X
                                    ! pbc_correction, nspin, prog, &
                                    ! Compatible with QE-6.4.X QE-GIT
                                    pbc_correction, pbc_dim, pbc_axis, &
                                    ! END BACKWARD COMPATIBILITY
                                    prog, inner_tol, inner_solver, &
                                    inner_maxstep, inner_mix)
        !
        !--------------------------------------------------------------------------------
        ! Then set environ base
        !
        ! BACKWARD COMPATIBILITY
        ! Compatible with QE-6.0 QE-6.1.X QE-6.2.X QE-6.3.X
        ! CALL set_environ_base(prog, nelec, nspin, &
        ! Compatible with QE-6.4.X QE-GIT
        CALL set_environ_base(prog, nelec, &
                              ! END BACKWARD COMPATIBILITY
                              nat, ntyp, atom_label, atomicspread, &
                              corespread, solvationrad, &
                              environ_restart, environ_thr, &
                              environ_nskip, environ_type, &
                              system_ntyp, system_dim, system_axis, &
                              env_nrep, &
                              stype, rhomax, rhomin, tbeta, &
                              env_static_permittivity, &
                              env_optical_permittivity, &
                              solvent_mode, &
                              derivatives, &
                              radius_mode, alpha, softness, &
                              solvent_distance, solvent_spread, &
                              solvent_radius, radial_scale, &
                              radial_spread, filling_threshold, &
                              filling_spread, &
                              field_awareness, charge_asymmetry, &
                              field_max, field_min, &
                              env_surface_tension, &
                              env_pressure, &
                              env_confine, &
                              env_electrolyte_ntyp, &
                              electrolyte_linearized, electrolyte_entropy, &
                              electrolyte_mode, electrolyte_distance, &
                              electrolyte_spread, cion, cionmax, rion, &
                              zion, electrolyte_rhomax, &
                              electrolyte_rhomin, electrolyte_tbeta, &
                              electrolyte_alpha, electrolyte_softness, &
                              ion_adsorption, ion_adsorption_energy, &
                              temperature, &
                              sc_permittivity, sc_carrier_density, sc_electrode_chg, &
                              sc_distance, sc_spread, sc_chg_thr, &
                              env_external_charges, &
                              extcharge_charge, extcharge_dim, &
                              extcharge_axis, extcharge_pos, &
                              extcharge_spread, &
                              env_dielectric_regions, &
                              epsregion_eps, epsregion_dim, &
                              epsregion_axis, epsregion_pos, &
                              epsregion_spread, epsregion_width)
        !
        !--------------------------------------------------------------------------------
        ! Eventually set core base
        !
        CALL set_core_base(ifdtype, nfdpoint, use_internal_pbc_corr, pbc_dim, pbc_axis)
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE read_environ
    !------------------------------------------------------------------------------------
    !>
    !! Sets default values for all variables and overwrites with provided input
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE environ_read_namelist(environ_unit_input)
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        INTEGER, INTENT(IN) :: environ_unit_input
        !
        LOGICAL :: lboundary, lelectrostatic
        INTEGER :: ios
        !
        !--------------------------------------------------------------------------------
        ! Set defaults
        !
        CALL environ_defaults()
        !
        CALL boundary_defaults()
        !
        CALL electrostatic_defaults()
        !
        !--------------------------------------------------------------------------------
        ! &ENVIRON namelist
        !
        ios = 0
        !
        IF (ionode) READ (environ_unit_input, environ, iostat=ios)
        !
        CALL mp_bcast(ios, ionode_id, comm)
        !
        IF (ios /= 0) &
            CALL errore(' read_environ ', ' reading namelist environ ', ABS(ios))
        !
        CALL environ_bcast() ! broadcast &ENVIRON variables
        !
        CALL environ_checkin() ! check &ENVIRON variables
        !
        !--------------------------------------------------------------------------------
        ! &BOUNDARY namelist (only if needed)
        !
        CALL fix_boundary(lboundary) ! fix some &BOUNDARY defaults depending on &ENVIRON
        !
        ios = 0
        !
        IF (ionode) THEN
            !
            IF (lboundary) READ (environ_unit_input, boundary, iostat=ios)
            ! #TODO warn if &BOUNDARY is empty here?
        END IF
        !
        CALL mp_bcast(ios, ionode_id, comm)
        !
        IF (ios /= 0) &
            CALL errore(' read_environ ', ' reading namelist boundary ', ABS(ios))
        !
        CALL boundary_bcast() ! broadcast &BOUNDARY variables
        !
        CALL boundary_checkin() ! check &BOUNDARY variables
        !
        CALL set_environ_type() ! set predefined environ_types according to the boundary
        !
        !--------------------------------------------------------------------------------
        ! &ELECTROSTATIC namelist (only if needed)
        !
        CALL fix_electrostatic(lelectrostatic)
        ! fix some &ELECTROSTATIC defaults depending on &ENVIRON and &BOUNDARY
        !
        ios = 0
        !
        IF (ionode) THEN
            !
            IF (lelectrostatic) READ (environ_unit_input, electrostatic, iostat=ios)
            ! #TODO warn if &ELECTROSTATIC is empty here?
        END IF
        !
        CALL mp_bcast(ios, ionode_id, comm)
        !
        IF (ios /= 0) &
            CALL errore(' read_environ ', ' reading namelist electrostatic ', ABS(ios))
        !
        CALL electrostatic_bcast() ! broadcast &ELECTROSTATIC variables
        !
        CALL set_electrostatic_problem() ! set electrostatic problem #TODO: should this happen before checking?
        !
        CALL electrostatic_checkin() ! check &ELECTROSTATIC variables
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE environ_read_namelist
    !------------------------------------------------------------------------------------
    !>
    !! Variables initialization for Namelist ENVIRON
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE environ_defaults()
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        environ_restart = .FALSE.
        verbose = 0
        environ_thr = 1.D-1
        environ_nskip = 1
        environ_type = 'input'
        !
        system_ntyp = 0
        system_dim = 0
        system_axis = 3
        !
        env_nrep = 0
        !
        env_electrostatic = .FALSE.
        atomicspread(:) = -0.5D0
        !
        env_static_permittivity = 1.D0
        env_optical_permittivity = 1.D0
        !
        env_surface_tension = 0.D0
        !
        env_pressure = 0.D0
        !
        env_confine = 0.D0
        !
        env_electrolyte_ntyp = 0
        electrolyte_linearized = .FALSE.
        electrolyte_entropy = 'full'
        cion(:) = 1.0D0
        cionmax = 0.0D0 ! if remains zero, pb or linpb
        rion = 0.D0
        zion(:) = 0.D0
        temperature = 300.0D0
        !
        ion_adsorption = 'none'
        ion_adsorption_energy = 0.D0
        sc_permittivity = 1.D0
        sc_carrier_density = 0.D0
        !
        env_external_charges = 0
        env_dielectric_regions = 0
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE environ_defaults
    !------------------------------------------------------------------------------------
    !>
    !! Variables initialization for Namelist BOUNDARY
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE boundary_defaults()
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        solvent_mode = 'electronic'
        !
        radius_mode = 'uff'
        alpha = 1.D0
        softness = 0.5D0
        solvationrad(:) = -3.D0
        !
        stype = 2
        rhomax = 0.005
        rhomin = 0.0001
        tbeta = 4.8
        !
        corespread(:) = -0.5D0
        !
        solvent_distance = 1.D0
        solvent_spread = 0.5D0
        !
        solvent_radius = 0.D0
        radial_scale = 2.D0
        radial_spread = 0.5D0
        filling_threshold = 0.825D0
        filling_spread = 0.02D0
        !
        field_awareness = 0.D0
        charge_asymmetry = -1.D0
        field_max = 10.D0
        field_min = 1.D0
        !
        electrolyte_mode = 'electronic'
        !
        electrolyte_distance = 0.D0
        electrolyte_spread = 0.5D0
        !
        sc_distance = 0.D0
        sc_spread = 0.5D0
        !
        electrolyte_rhomax = 0.005D0
        electrolyte_rhomin = 0.0001D0
        electrolyte_tbeta = 4.8D0
        !
        electrolyte_alpha = 1.D0
        electrolyte_softness = 0.5D0
        !
        derivatives = 'analytic'
        ifdtype = 1
        nfdpoint = 2
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE boundary_defaults
    !------------------------------------------------------------------------------------
    !>
    !! Variables initialization for Namelist ELECTROSTATIC
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE electrostatic_defaults()
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        problem = 'none'
        tol = 1.D-5
        !
        solver = 'none'
        auxiliary = 'none'
        step_type = 'optimal'
        step = 0.3D0
        maxstep = 200
        inner_solver = 'none'
        inner_tol = 1.D-10
        inner_maxstep = 200
        inner_mix = 0.5D0
        !
        mix_type = 'linear'
        ndiis = 1
        mix = 0.5D0
        !
        preconditioner = 'sqrt'
        screening_type = 'none'
        screening = 0.D0
        !
        core = 'fft'
        !
        pbc_dim = -3
        pbc_correction = 'none'
        pbc_axis = 3
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE electrostatic_defaults
    !------------------------------------------------------------------------------------
    !>
    !! Broadcast variables values for Namelist ENVIRON
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE environ_bcast()
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        CALL mp_bcast(environ_restart, ionode_id, comm)
        !
        CALL mp_bcast(verbose, ionode_id, comm)
        !
        CALL mp_bcast(environ_thr, ionode_id, comm)
        !
        CALL mp_bcast(environ_nskip, ionode_id, comm)
        !
        CALL mp_bcast(environ_type, ionode_id, comm)
        !
        CALL mp_bcast(system_ntyp, ionode_id, comm)
        !
        CALL mp_bcast(system_dim, ionode_id, comm)
        !
        CALL mp_bcast(system_axis, ionode_id, comm)
        !
        CALL mp_bcast(env_nrep, ionode_id, comm)
        !
        CALL mp_bcast(env_electrostatic, ionode_id, comm)
        !
        CALL mp_bcast(atomicspread, ionode_id, comm)
        !
        CALL mp_bcast(env_static_permittivity, ionode_id, comm)
        !
        CALL mp_bcast(env_optical_permittivity, ionode_id, comm)
        !
        CALL mp_bcast(env_surface_tension, ionode_id, comm)
        !
        CALL mp_bcast(env_pressure, ionode_id, comm)
        !
        CALL mp_bcast(env_confine, ionode_id, comm)
        !
        CALL mp_bcast(env_electrolyte_ntyp, ionode_id, comm)
        !
        CALL mp_bcast(electrolyte_linearized, ionode_id, comm)
        !
        CALL mp_bcast(electrolyte_entropy, ionode_id, comm)
        !
        CALL mp_bcast(cion, ionode_id, comm)
        !
        CALL mp_bcast(cionmax, ionode_id, comm)
        !
        CALL mp_bcast(rion, ionode_id, comm)
        !
        CALL mp_bcast(zion, ionode_id, comm)
        !
        CALL mp_bcast(temperature, ionode_id, comm)
        !
        CALL mp_bcast(ion_adsorption, ionode_id, comm)
        !
        CALL mp_bcast(ion_adsorption_energy, ionode_id, comm)
        !
        CALL mp_bcast(sc_permittivity, ionode_id, comm)
        !
        CALL mp_bcast(sc_carrier_density, ionode_id, comm)
        !
        CALL mp_bcast(env_external_charges, ionode_id, comm)
        !
        CALL mp_bcast(env_dielectric_regions, ionode_id, comm)
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE environ_bcast
    !------------------------------------------------------------------------------------
    !>
    !! Broadcast variables values for Namelist BOUNDARY
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE boundary_bcast()
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        CALL mp_bcast(solvent_mode, ionode_id, comm)
        !
        CALL mp_bcast(stype, ionode_id, comm)
        !
        CALL mp_bcast(rhomax, ionode_id, comm)
        !
        CALL mp_bcast(rhomin, ionode_id, comm)
        !
        CALL mp_bcast(tbeta, ionode_id, comm)
        !
        CALL mp_bcast(radius_mode, ionode_id, comm)
        !
        CALL mp_bcast(alpha, ionode_id, comm)
        !
        CALL mp_bcast(softness, ionode_id, comm)
        !
        CALL mp_bcast(solvationrad, ionode_id, comm)
        !
        CALL mp_bcast(corespread, ionode_id, comm)
        !
        CALL mp_bcast(solvent_distance, ionode_id, comm)
        !
        CALL mp_bcast(solvent_spread, ionode_id, comm)
        !
        CALL mp_bcast(solvent_radius, ionode_id, comm)
        !
        CALL mp_bcast(radial_scale, ionode_id, comm)
        !
        CALL mp_bcast(radial_spread, ionode_id, comm)
        !
        CALL mp_bcast(filling_threshold, ionode_id, comm)
        !
        CALL mp_bcast(filling_spread, ionode_id, comm)
        !
        CALL mp_bcast(field_awareness, ionode_id, comm)
        !
        CALL mp_bcast(charge_asymmetry, ionode_id, comm)
        !
        CALL mp_bcast(field_max, ionode_id, comm)
        !
        CALL mp_bcast(field_min, ionode_id, comm)
        !
        CALL mp_bcast(electrolyte_mode, ionode_id, comm)
        !
        CALL mp_bcast(electrolyte_distance, ionode_id, comm)
        !
        CALL mp_bcast(electrolyte_spread, ionode_id, comm)
        !
        CALL mp_bcast(sc_distance, ionode_id, comm)
        !
        CALL mp_bcast(sc_spread, ionode_id, comm)
        !
        CALL mp_bcast(electrolyte_rhomax, ionode_id, comm)
        !
        CALL mp_bcast(electrolyte_rhomin, ionode_id, comm)
        !
        CALL mp_bcast(electrolyte_tbeta, ionode_id, comm)
        !
        CALL mp_bcast(electrolyte_alpha, ionode_id, comm)
        !
        CALL mp_bcast(electrolyte_softness, ionode_id, comm)
        !
        CALL mp_bcast(derivatives, ionode_id, comm)
        !
        CALL mp_bcast(ifdtype, ionode_id, comm)
        !
        CALL mp_bcast(nfdpoint, ionode_id, comm)
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE boundary_bcast
    !------------------------------------------------------------------------------------
    !>
    !! Broadcast variables values for Namelist ELECTROSTATIC
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE electrostatic_bcast()
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        CALL mp_bcast(problem, ionode_id, comm)
        !
        CALL mp_bcast(tol, ionode_id, comm)
        !
        CALL mp_bcast(solver, ionode_id, comm)
        !
        CALL mp_bcast(inner_solver, ionode_id, comm)
        !
        CALL mp_bcast(inner_tol, ionode_id, comm)
        !
        CALL mp_bcast(inner_maxstep, ionode_id, comm)
        !
        CALL mp_bcast(inner_mix, ionode_id, comm)
        !
        CALL mp_bcast(auxiliary, ionode_id, comm)
        !
        CALL mp_bcast(step_type, ionode_id, comm)
        !
        CALL mp_bcast(step, ionode_id, comm)
        !
        CALL mp_bcast(maxstep, ionode_id, comm)
        !
        CALL mp_bcast(mix_type, ionode_id, comm)
        !
        CALL mp_bcast(mix, ionode_id, comm)
        !
        CALL mp_bcast(ndiis, ionode_id, comm)
        !
        CALL mp_bcast(preconditioner, ionode_id, comm)
        !
        CALL mp_bcast(screening_type, ionode_id, comm)
        !
        CALL mp_bcast(screening, ionode_id, comm)
        !
        CALL mp_bcast(core, ionode_id, comm)
        !
        CALL mp_bcast(pbc_dim, ionode_id, comm)
        !
        CALL mp_bcast(pbc_correction, ionode_id, comm)
        !
        CALL mp_bcast(pbc_axis, ionode_id, comm)
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE electrostatic_bcast
    !------------------------------------------------------------------------------------
    !>
    !! Check input values for Namelist ENVIRON
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE environ_checkin()
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        INTEGER :: i
        LOGICAL :: allowed = .FALSE.
        !
        CHARACTER(LEN=20) :: sub_name = ' environ_checkin '
        !
        !--------------------------------------------------------------------------------
        !
        IF (environ_restart) CALL infomsg(sub_name, ' environ restarting')
        !
        IF (verbose < 0) CALL errore(sub_name, ' verbose out of range ', 1)
        !
        IF (environ_thr < 0.0_DP) CALL errore(sub_name, ' environ_thr out of range ', 1)
        !
        IF (environ_nskip < 0) CALL errore(sub_name, ' environ_nskip out of range ', 1)
        !
        allowed = .FALSE.
        !
        DO i = 1, SIZE(environ_type_allowed)
            IF (TRIM(environ_type) == environ_type_allowed(i)) allowed = .TRUE.
        END DO
        !
        IF (.NOT. allowed) &
            CALL errore(sub_name, ' environ_type '''// &
                        TRIM(environ_type)//''' not allowed ', 1)
        !
        IF (system_ntyp < 0) CALL errore(sub_name, ' system_ntype out of range ', 1)
        !
        IF (system_dim < 0 .OR. system_dim > 3) &
            CALL errore(sub_name, ' system_dim out of range ', 1)
        !
        IF (system_axis < 1 .OR. system_axis > 3) &
            CALL errore(sub_name, ' system_axis out of range ', 1)
        !
        IF (env_nrep(1) < 0 .OR. env_nrep(2) < 0 .OR. env_nrep(3) < 0) &
            CALL errore(sub_name, ' env_nrep cannot be smaller than 0', 1)
        !
        IF (env_static_permittivity < 1.0_DP) &
            CALL errore(sub_name, ' env_static_permittivity out of range ', 1)
        !
        IF (env_optical_permittivity < 1.0_DP) &
            CALL errore(sub_name, ' env_optical_permittivity out of range ', 1)
        !
        IF (env_surface_tension < 0.0_DP) &
            CALL errore(sub_name, ' env_surface_tension out of range ', 1)
        !
        IF (env_electrolyte_ntyp < 0 .OR. env_electrolyte_ntyp .EQ. 1) &
            CALL errore(sub_name, ' env_electrolyte_ntyp out of range ', 1)
        !
        allowed = .FALSE.
        !
        DO i = 1, SIZE(electrolyte_entropy_allowed)
            !
            IF (TRIM(electrolyte_entropy) == electrolyte_entropy_allowed(i)) &
                allowed = .TRUE.
            !
        END DO
        !
        IF (.NOT. allowed) &
            CALL errore(sub_name, ' electrolyte_entropy '''// &
                        TRIM(electrolyte_entropy)//''' not allowed ', 1)
        !
        IF (temperature < 0.0_DP) CALL errore(sub_name, ' temperature out of range ', 1)
        !
        DO i = 1, env_electrolyte_ntyp
            !
            IF (cion(i) .LT. 0.D0) &
                CALL errore(sub_name, ' cion cannot be negative ', 1)
            !
        END DO
        !
        IF (cionmax .LT. 0.D0 .OR. rion .LT. 0.D0) &
            CALL errore(sub_name, 'cionmax and rion cannot be negative ', 1)
        !
        IF (cionmax .GT. 0.D0 .AND. rion .GT. 0.D0) &
            CALL errore(sub_name, 'either cionmax or rion can be set ', 1)
        !
        allowed = .FALSE.
        !
        DO i = 1, SIZE(ion_adsorption_allowed)
            IF (TRIM(ion_adsorption) == ion_adsorption_allowed(i)) allowed = .TRUE.
        END DO
        !
        IF (.NOT. allowed) &
            CALL errore(sub_name, ' ion_adsorption '''// &
                        TRIM(ion_adsorption)//''' not allowed ', 1)
        !
        IF (ion_adsorption_energy .LT. 0D0) &
            CALL errore(sub_name, 'ion_adsorption_energy must be positive', 1)
        !
        IF (.NOT. TRIM(ion_adsorption) .EQ. 'none') &
            CALL errore(sub_name, 'ion_adsorption not implemented', 1)
        !
        IF (sc_permittivity < 1.D0) &
            CALL errore(sub_name, 'sc_permittivity out of range', 1)
        !
        IF (sc_carrier_density < 0.D0) &
            CALL errore(sub_name, 'sc_carrier_density cannot be negative', 1)
        !
        IF (env_external_charges < 0) &
            CALL errore(sub_name, ' env_external_charges out of range ', 1)
        !
        IF (env_dielectric_regions < 0) &
            CALL errore(sub_name, ' env_dielectric_regions out of range ', 1)
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE environ_checkin
    !------------------------------------------------------------------------------------
    !>
    !! Check input values for Namelist BOUNDARY
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE boundary_checkin()
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        INTEGER :: i
        LOGICAL :: allowed = .FALSE.
        !
        CHARACTER(LEN=20) :: sub_name = ' boundary_checkin '
        !
        !--------------------------------------------------------------------------------
        !
        allowed = .FALSE.
        !
        DO i = 1, SIZE(solvent_mode_allowed)
            IF (TRIM(solvent_mode) == solvent_mode_allowed(i)) allowed = .TRUE.
        END DO
        !
        IF (.NOT. allowed) &
            CALL errore(sub_name, ' solvent_mode '''// &
                        TRIM(solvent_mode)//''' not allowed ', 1)
        !
        IF (stype > 2) CALL errore(sub_name, ' stype out of range ', 1)
        !
        IF (rhomax < 0.0_DP) CALL errore(sub_name, ' rhomax out of range ', 1)
        !
        IF (rhomin < 0.0_DP) CALL errore(sub_name, ' rhomin out of range ', 1)
        !
        IF (rhomax < rhomin) CALL errore(sub_name, ' inconsistent rhomax and rhomin', 1)
        !
        IF (tbeta < 0.0_DP) CALL errore(sub_name, ' tbeta out of range ', 1)
        !
        allowed = .FALSE.
        !
        DO i = 1, SIZE(radius_mode_allowed)
            IF (TRIM(radius_mode) == radius_mode_allowed(i)) allowed = .TRUE.
        END DO
        !
        IF (.NOT. allowed) &
            CALL errore(sub_name, ' radius_mode '''// &
                        TRIM(radius_mode)//''' not allowed ', 1)
        !
        IF (alpha <= 0.0_DP) CALL errore(sub_name, ' alpha out of range ', 1)
        !
        IF (softness <= 0.0_DP) CALL errore(sub_name, ' softness out of range ', 1)
        !
        IF (solvent_spread <= 0.0_DP) &
            CALL errore(sub_name, ' solvent_spread out of range ', 1)
        !
        IF (solvent_radius < 0.0_DP) &
            CALL errore(sub_name, 'solvent_radius out of range ', 1)
        !
        IF (radial_scale < 1.0_DP) &
            CALL errore(sub_name, 'radial_scale out of range ', 1)
        !
        IF (radial_spread <= 0.0_DP) &
            CALL errore(sub_name, 'radial_spread out of range ', 1)
        !
        IF (filling_threshold <= 0.0_DP) &
            CALL errore(sub_name, 'filling_threshold out of range ', 1)
        !
        IF (filling_spread <= 0.0_DP) &
            CALL errore(sub_name, 'filling_spread out of range ', 1)
        !
        IF (field_awareness < 0.0_DP) &
            CALL errore(sub_name, 'field_awareness out of range ', 1)
        !
        IF (ABS(charge_asymmetry) > 1.0_DP) &
            CALL errore(sub_name, 'charge_asymmetry out of range ', 1)
        !
        IF (field_min < 0.0_DP) CALL errore(sub_name, 'field_min out of range ', 1)
        !
        IF (field_max <= field_min) CALL errore(sub_name, 'field_max out of range ', 1)
        !
        allowed = .FALSE.
        !
        DO i = 1, SIZE(electrolyte_mode_allowed)
            IF (TRIM(electrolyte_mode) == electrolyte_mode_allowed(i)) allowed = .TRUE.
        END DO
        !
        IF (.NOT. allowed) &
            CALL errore(sub_name, ' electrolyte_mode '''// &
                        TRIM(electrolyte_mode)//''' not allowed ', 1)
        !
        IF (electrolyte_distance < 0.0_DP) &
            CALL errore(sub_name, ' electrolyte_distance out of range ', 1)
        !
        IF (electrolyte_spread <= 0.0_DP) &
            CALL errore(sub_name, ' electrolyte_spread out of range ', 1)
        !
        IF (electrolyte_rhomax < 0.0_DP) &
            CALL errore(sub_name, ' electrolyte_rhomax out of range ', 1)
        !
        IF (electrolyte_rhomin < 0.0_DP) &
            CALL errore(sub_name, ' electrolyte_rhomin out of range ', 1)
        !
        IF (electrolyte_rhomax < electrolyte_rhomin) &
            CALL errore(sub_name, &
                        ' inconsistent electrolyte_rhomax and electrolyte_rhomin', 1)
        !
        IF (electrolyte_tbeta < 0.0_DP) &
            CALL errore(sub_name, ' electrolyte_tbeta out of range ', 1)
        !
        IF (electrolyte_alpha <= 0.0_DP) &
            CALL errore(sub_name, ' electrolyte_alpha out of range ', 1)
        !
        IF (electrolyte_softness <= 0.0_DP) &
            CALL errore(sub_name, ' electrolyte_softness out of range ', 1)
        !
        !--------------------------------------------------------------------------------
        ! semiconductor checks
        !
        IF (sc_distance < 0.0_DP) &
            CALL errore(sub_name, ' electrolyte_distance out of range ', 1)
        !
        IF (sc_spread <= 0.0_DP) &
            CALL errore(sub_name, ' electrolyte_spread out of range ', 1)
        !
        allowed = .FALSE.
        !
        DO i = 1, SIZE(derivatives_allowed)
            IF (TRIM(derivatives) == derivatives_allowed(i)) allowed = .TRUE.
        END DO
        !
        IF (.NOT. allowed) &
            CALL errore(sub_name, ' derivatives '''//TRIM(core)//''' not allowed ', 1)
        !
        IF (ifdtype < 1) CALL errore(sub_name, ' ifdtype out of range ', 1)
        !
        IF (nfdpoint < 1) CALL errore(sub_name, ' nfdpoint out of range ', 1)
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE boundary_checkin
    !------------------------------------------------------------------------------------
    !>
    !! Check input values for Namelist ELECTROSTATIC
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE electrostatic_checkin()
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        INTEGER :: i
        LOGICAL :: allowed = .FALSE.
        !
        CHARACTER(LEN=20) :: sub_name = ' electrostatic_checkin '
        !
        !--------------------------------------------------------------------------------
        !
        allowed = .FALSE.
        !
        DO i = 1, SIZE(problem_allowed)
            IF (TRIM(problem) == problem_allowed(i)) allowed = .TRUE.
        END DO
        !
        IF (.NOT. allowed) &
            CALL errore(sub_name, ' problem '''//TRIM(problem)//''' not allowed ', 1)
        !
        IF (tol <= 0.0_DP) CALL errore(sub_name, ' tolerance out of range ', 1)
        !
        allowed = .FALSE.
        !
        DO i = 1, SIZE(solver_allowed)
            IF (TRIM(solver) == solver_allowed(i)) allowed = .TRUE.
        END DO
        !
        IF (.NOT. allowed) &
            CALL errore(sub_name, ' solver '''//TRIM(solver)//''' not allowed ', 1)
        !
        allowed = .FALSE.
        !
        DO i = 1, SIZE(auxiliary_allowed)
            IF (TRIM(auxiliary) == auxiliary_allowed(i)) allowed = .TRUE.
        END DO
        !
        IF (.NOT. allowed) &
            CALL errore(sub_name, ' auxiliary '''// &
                        TRIM(auxiliary)//''' not allowed ', 1)
        !
        allowed = .FALSE.
        !
        DO i = 1, SIZE(step_type_allowed)
            IF (TRIM(step_type) == step_type_allowed(i)) allowed = .TRUE.
        END DO
        !
        IF (.NOT. allowed) &
            CALL errore(sub_name, ' step_type '''// &
                        TRIM(step_type)//''' not allowed ', 1)
        !
        IF (step <= 0.0_DP) CALL errore(sub_name, ' step out of range ', 1)
        !
        IF (maxstep <= 1) CALL errore(sub_name, ' maxstep out of range ', 1)
        !
        allowed = .FALSE.
        !
        DO i = 1, SIZE(mix_type_allowed)
            IF (TRIM(mix_type) == mix_type_allowed(i)) allowed = .TRUE.
        END DO
        !
        IF (.NOT. allowed) &
            CALL errore(sub_name, ' mix_type '''//TRIM(mix_type)//''' not allowed ', 1)
        !
        IF (ndiis <= 0) CALL errore(sub_name, ' ndiis out of range ', 1)
        !
        IF (mix <= 0.0_DP) CALL errore(sub_name, ' mix out of range ', 1)
        !
        allowed = .FALSE.
        !
        DO i = 1, SIZE(preconditioner_allowed)
            IF (TRIM(preconditioner) == preconditioner_allowed(i)) allowed = .TRUE.
        END DO
        !
        IF (.NOT. allowed) &
            CALL errore(sub_name, ' preconditioner '''// &
                        TRIM(preconditioner)//''' not allowed ', 1)
        !
        allowed = .FALSE.
        !
        DO i = 1, SIZE(screening_type_allowed)
            IF (TRIM(screening_type) == screening_type_allowed(i)) allowed = .TRUE.
        END DO
        !
        IF (.NOT. allowed) &
            CALL errore(sub_name, ' screening_type '''// &
                        TRIM(screening_type)//''' not allowed ', 1)
        !
        IF (screening < 0.0_DP) CALL errore(sub_name, ' screening out of range ', 1)
        !
        allowed = .FALSE.
        !
        DO i = 1, SIZE(core_allowed)
            IF (TRIM(core) == core_allowed(i)) allowed = .TRUE.
        END DO
        !
        IF (.NOT. allowed) &
            CALL errore(sub_name, ' core '''//TRIM(core)//''' not allowed ', 1)
        !
        IF (pbc_dim < -3 .OR. pbc_dim > 3) &
            CALL errore(sub_name, ' pbc_dim out of range ', 1)
        !
        IF (pbc_axis < 1 .OR. pbc_axis > 3) &
            CALL errore(sub_name, ' cell_axis out of range ', 1)
        !
        allowed = .FALSE.
        !
        DO i = 1, SIZE(pbc_correction_allowed)
            IF (TRIM(pbc_correction) == pbc_correction_allowed(i)) allowed = .TRUE.
        END DO
        !
        IF (.NOT. allowed) &
            CALL errore(sub_name, ' pbc_correction '''// &
                        TRIM(pbc_correction)//''' not allowed ', 1)
        !
        IF (TRIM(pbc_correction) .EQ. 'gcs' .AND. &
            TRIM(electrolyte_mode) .NE. 'system') &
            CALL errore(sub_name, 'Only system boundary for gcs correction', 1)
        !
        allowed = .FALSE.
        !
        DO i = 1, SIZE(inner_solver_allowed)
            IF (TRIM(inner_solver) == inner_solver_allowed(i)) allowed = .TRUE.
        END DO
        !
        IF (.NOT. allowed) &
            CALL errore(sub_name, ' inner solver '''// &
                        TRIM(inner_solver)//''' not allowed ', 1)
        !
        IF (inner_mix <= 0.0_DP) CALL errore(sub_name, ' inner_mix out of range ', 1)
        !
        IF (inner_tol <= 0.0_DP) CALL errore(sub_name, ' inner_tol out of range ', 1)
        !
        IF (inner_maxstep <= 1) CALL errore(sub_name, ' inner_maxstep out of range ', 1)
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE electrostatic_checkin
    !------------------------------------------------------------------------------------
    !>
    !! Check if BOUNDARY needs to be read and reset defaults
    !! according to the ENVIRON namelist
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE fix_boundary(lboundary)
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        LOGICAL, INTENT(OUT) :: lboundary
        !
        CHARACTER(LEN=20) :: sub_name = ' fix_boundary '
        !
        !--------------------------------------------------------------------------------
        !
        lboundary = .FALSE.
        !
        IF (environ_type .NE. 'input' .AND. environ_type .NE. 'vacuum') &
            lboundary = .TRUE.
        !
        IF (env_static_permittivity .GT. 1.D0 .OR. &
            env_optical_permittivity .GT. 1.D0) &
            lboundary = .TRUE.
        !
        IF (env_surface_tension .GT. 0.D0) lboundary = .TRUE.
        !
        IF (env_pressure .NE. 0.D0) lboundary = .TRUE.
        !
        IF (env_confine .NE. 0.D0) lboundary = .TRUE.
        !
        IF (env_electrolyte_ntyp .GT. 0) lboundary = .TRUE.
        !
        IF (env_dielectric_regions .GT. 0) lboundary = .TRUE.
        !
        IF (sc_permittivity .GT. 1.D0 .OR. sc_carrier_density .GT. 0) &
            lboundary = .TRUE.
        !
        ! Accepted both if statements. May only need one. #TODO ?
        !
        IF (solvent_mode .EQ. 'ionic' .AND. derivatives .NE. 'analytic') THEN
            !
            IF (ionode) &
                WRITE (program_unit, *) &
                'Only analytic derivatives for ionic solvent_mode'
            !
            derivatives = 'analytic'
        END IF
        !
        IF (solvent_mode .EQ. 'ionic') THEN !.OR. solvent_mode .EQ. 'fa-ionic') THEN ! #TODO field-aware
            !
            ! May want a switch statement here #TODO ?
            !
            IF (boundary_core .EQ. 'fft' .OR. boundary_core .EQ. 'fd') THEN
                !
                IF (ionode) &
                    WRITE (program_unit, *) &
                    'Only analytic boundary_core for ionic solvent_mode'
                !
                boundary_core = 'analytic'
            END IF
            !
        END IF
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE fix_boundary
    !------------------------------------------------------------------------------------
    !>
    !! Set values according to the environ_type keyword and boundary mode
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE set_environ_type()
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        CHARACTER(LEN=20) :: sub_name = ' set_environ_type '
        !
        !--------------------------------------------------------------------------------
        !
        IF (TRIM(ADJUSTL(environ_type)) .EQ. 'input') RETURN
        ! skip set up if read environ keywords from input
        !
        !--------------------------------------------------------------------------------
        ! Vacuum case is straightforward, all flags are off
        !
        IF (TRIM(ADJUSTL(environ_type)) .EQ. 'vacuum') THEN
            env_static_permittivity = 1.D0
            env_optical_permittivity = 1.D0
            env_surface_tension = 0.D0
            env_pressure = 0.D0
            !
            RETURN
            !
        END IF
        !
        !--------------------------------------------------------------------------------
        ! First set global physically meaningful parameters
        !
        SELECT CASE (TRIM(ADJUSTL(environ_type)))
            !
            !----------------------------------------------------------------------------
            ! water experimental permittivities
            !
        CASE ('water', 'water-cation', 'water-anion')
            env_static_permittivity = 78.3D0
            env_optical_permittivity = 1.D0 ! 1.776D0
        CASE DEFAULT
            CALL errore(sub_name, 'unrecognized value for environ_type', 1)
        END SELECT
        !
        !--------------------------------------------------------------------------------
        ! Depending on the boundary mode, set fitted parameters
        !
        IF (TRIM(ADJUSTL(solvent_mode)) .EQ. 'electronic' .OR. &
            TRIM(ADJUSTL(solvent_mode)) .EQ. 'full') THEN ! .OR. &
            ! TRIM(ADJUSTL(solvent_mode)) .EQ. 'fa-electronic' .OR. & ! #TODO field-aware
            !     TRIM(ADJUSTL(solvent_mode)) .EQ. 'fa-full') THEN
            !
            !----------------------------------------------------------------------------
            ! Self-consistent continuum solvation (SCCS)
            !
            SELECT CASE (TRIM(ADJUSTL(environ_type)))
            CASE ('water')
                !
                !------------------------------------------------------------------------
                ! SCCS for neutrals
                !
                env_surface_tension = 50.D0
                env_pressure = -0.35D0
                rhomax = 0.005
                rhomin = 0.0001
            CASE ('water-cation')
                !
                !------------------------------------------------------------------------
                ! SCCS for cations
                !
                env_surface_tension = 5.D0
                env_pressure = 0.125D0
                rhomax = 0.0035
                rhomin = 0.0002
            CASE ('water-anion')
                !
                !------------------------------------------------------------------------
                ! SCCS for cations
                !
                env_surface_tension = 0.D0
                env_pressure = 0.450D0
                rhomax = 0.0155
                rhomin = 0.0024
            END SELECT
            !
        ELSE IF (TRIM(ADJUSTL(solvent_mode)) .EQ. 'ionic' .OR. &
                 TRIM(ADJUSTL(solvent_mode)) .EQ. 'fa-ionic') THEN
            !
            !----------------------------------------------------------------------------
            ! Soft-sphere continuum solvation
            !
            radius_mode = 'uff'
            softness = 0.5D0
            env_surface_tension = 50.D0 !! NOTE THAT WE ARE USING THE
            env_pressure = -0.35D0      !! SET FOR CLUSTERS, AS IN SCCS
            !
            SELECT CASE (TRIM(ADJUSTL(environ_type)))
            CASE ('water')
                alpha = 1.12D0 ! SS for neutrals
            CASE ('water-cation')
                alpha = 1.10D0 ! SS for cations
            CASE ('water-anion')
                alpha = 0.98D0 ! SS for anions
            END SELECT
            !
        END IF
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE set_environ_type
    !------------------------------------------------------------------------------------
    !>
    !! Set values according to the &ENVIRON namelist
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE fix_electrostatic(lelectrostatic)
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        LOGICAL, INTENT(OUT) :: lelectrostatic
        !
        CHARACTER(LEN=20) :: sub_name = ' fix_electrostatic '
        !
        !--------------------------------------------------------------------------------
        !
        lelectrostatic = env_electrostatic
        !
        IF (env_static_permittivity .GT. 1.D0 .OR. env_optical_permittivity .GT. 1.D0) &
            lelectrostatic = .TRUE.
        !
        IF (env_external_charges .GT. 0) lelectrostatic = .TRUE.
        !
        IF (env_dielectric_regions .GT. 0) lelectrostatic = .TRUE.
        !
        IF (env_electrolyte_ntyp .GT. 0) lelectrostatic = .TRUE.
        !
        IF (sc_permittivity .GT. 1.D0 .OR. sc_carrier_density .GT. 0) &
            lelectrostatic = .TRUE.
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE fix_electrostatic
    !------------------------------------------------------------------------------------
    !>
    !! Set problem according to the ENVIRON and ELECTROSTATIC namelists
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE set_electrostatic_problem()
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        CHARACTER(LEN=80) :: sub_name = ' set_electrostatic_problem '
        !
        !--------------------------------------------------------------------------------
        !
        IF (env_electrolyte_ntyp .GT. 0) THEN
            !
            IF (.NOT. TRIM(pbc_correction) == 'gcs') THEN
                !
                IF (electrolyte_linearized) THEN
                    !
                    IF (problem == 'none') problem = 'linpb'
                    !
                    IF (solver == 'none') solver = 'cg'
                    !
                    IF (cionmax .GT. 0.D0 .OR. rion .GT. 0.D0) problem = 'linmodpb'
                    !
                ELSE
                    !
                    IF (problem == 'none') problem = 'pb'
                    !
                    IF (solver == 'none') solver = 'newton'
                    !
                    IF (inner_solver == 'none') inner_solver = 'cg'
                    !
                    IF (cionmax .GT. 0.D0 .OR. rion .GT. 0.D0) problem = 'modpb'
                    !
                END IF
                !
            END IF
            !
        END IF
        !
        IF (env_static_permittivity > 1.D0 .OR. env_dielectric_regions > 0) THEN
            !
            IF (problem == 'none') problem = 'generalized'
            !
            IF (.NOT. TRIM(pbc_correction) == 'gcs') THEN
                IF (solver == 'none') solver = 'cg'
            ELSE
                IF (solver == 'none') solver = 'iterative'
                IF (solver == 'iterative' .AND. auxiliary == 'none') auxiliary = 'full'
                !
                IF (solver .NE. 'iterative') &
                    CALL errore(sub_name, &
                                'GCS correction requires iterative solver', 1)
                !
            END IF
        ELSE
            IF (problem == 'none') problem = 'poisson'
            IF (solver == 'none') solver = 'direct'
        END IF
        !
        IF (.NOT. (problem == 'pb' .OR. &
                   problem == 'modpb' .OR. &
                   problem == 'generalized') &
            .AND. (inner_solver .NE. 'none')) &
            CALL errore(sub_name, 'Only pb or modpb problems allow inner solver', 1)
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE set_electrostatic_problem
    !------------------------------------------------------------------------------------
    !>
    !! Environ cards parsing routine
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE environ_read_cards(unit)
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        INTEGER, INTENT(IN), OPTIONAL :: unit
        !
        CHARACTER(LEN=256) :: input_line
        CHARACTER(LEN=80) :: card
        CHARACTER(LEN=1), EXTERNAL :: capital
        LOGICAL :: tend
        INTEGER :: i
        !
        !--------------------------------------------------------------------------------
        !
        parse_unit = unit ! #TODO FIX THIS !!!
        !
        !=-----------------------------------------------------------------------------=!
        !  START OF LOOP
        !=-----------------------------------------------------------------------------=!
        !
100     CALL env_read_line(input_line, end_of_file=tend)
        !
        !--------------------------------------------------------------------------------
        ! Skip blank/comment lines (REDUNDANT)
        !
        IF (tend) GOTO 120
        !
        ! #TODO redundant IF statement? add to env_read_line?
        IF (input_line == ' ' .OR. input_line(1:1) == '#' .OR. input_line(1:1) == '!') &
            GOTO 100
        !
        READ (input_line, *) card
        !
        !--------------------------------------------------------------------------------
        ! Force uppercase
        !
        DO i = 1, LEN_TRIM(input_line)
            input_line(i:i) = capital(input_line(i:i))
        END DO
        !
        !--------------------------------------------------------------------------------
        ! Read cards
        !
        IF (TRIM(card) == 'EXTERNAL_CHARGES') THEN
            CALL card_external_charges(input_line)
        ELSE IF (TRIM(card) == 'DIELECTRIC_REGIONS') THEN
            CALL card_dielectric_regions(input_line)
        ELSE
            !
            ! #TODO add more meaningful warnings
            !
            IF (ionode) &
                WRITE (program_unit, '(A)') &
                'Warning: card '//TRIM(input_line)//' ignored'
            !
        END IF
        !
        !=-----------------------------------------------------------------------------=!
        !  END OF LOOP
        !=-----------------------------------------------------------------------------=!
        !
        GOTO 100
        !
120     CONTINUE
        !
        !--------------------------------------------------------------------------------
        ! Final check
        !
        IF (env_external_charges .GT. 0 .AND. .NOT. taextchg) &
            CALL errore(' environ_read_cards  ', &
                        ' missing card external_charges', 0)
        !
        IF (env_dielectric_regions .GT. 0 .AND. .NOT. taepsreg) &
            CALL errore(' environ_read_cards  ', &
                        ' missing card dielectric_regions', 0)
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE environ_read_cards
    !------------------------------------------------------------------------------------
    !>
    !! Description of the allowed input CARDS
    !!
    !! EXTERNAL_CHARGES (unit_option)
    !!
    !!   set external fixed charge densities and their shape
    !!
    !! Syntax:
    !!
    !!    EXTERNAL_CHARGES (unit_option)
    !!      charge(1)  x(1) y(1) z(1)  spread(1) dim(1)  axis(1)
    !!       ...       ...        ...      ...        ...
    !!      charge(n)  x(n) y(n) z(n)  spread(n) dim(n)  axis(n)
    !!
    !! Example:
    !!
    !! EXTERNAL_CHARGES (bohr)
    !!  1.0  0.0  0.0  0.0  [0.5  2  1]
    !! -1.0  0.0  0.0  5.0  [0.5  2  1]
    !!
    !! Where:
    !!
    !!   unit_option == bohr       positions are given in Bohr (DEFAULT)
    !!   unit_option == angstrom   positions are given in Angstrom
    !!
    !!      charge(i) ( real )       total charge of the density
    !!      x/y/z(i)  ( real )       cartesian position of the density
    !!      spread(i) ( real )       gaussian spread of the density (in bohr, optional, default=0.5)
    !!      dim(i)    ( integer )    0/1/2 point/line/plane of charge (optional, default=0)
    !!      axis(i)   ( integer )    1/2/3 for x/y/z direction of line/plane (optional, default=3)
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE card_external_charges(input_line)
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        CHARACTER(LEN=256) :: input_line
        INTEGER :: ie, ix, ierr, nfield
        LOGICAL :: tend
        LOGICAL, EXTERNAL :: matches
        CHARACTER(LEN=4) :: lb_pos
        CHARACTER(LEN=256) :: field_str
        !
        !--------------------------------------------------------------------------------
        ! Validate input
        !
        IF (taextchg) &
            CALL errore(' card_external_charges  ', ' two occurrences', 2)
        !
        IF (env_external_charges > nsx) &
            CALL errore(' card_external_charges ', ' nsx out of range ', &
                        env_external_charges)
        !
        CALL allocate_input_extcharge(env_external_charges)
        !
        IF (matches("BOHR", input_line)) THEN
            external_charges = 'bohr'
        ELSE IF (matches("ANGSTROM", input_line)) THEN
            external_charges = 'angstrom'
        ELSE
            !
            IF (TRIM(ADJUSTL(input_line)) /= 'EXTERNAL_CHARGES') &
                CALL errore('read_cards ', &
                            'unknown option for EXTERNAL_CHARGES: '//input_line, 1)
            !
            CALL infomsg('read_cards ', 'No units specified in EXTERNAL_CHARGES card')
            !
            external_charges = 'bohr'
            !
            CALL infomsg('read_cards ', &
                         'EXTERNAL_CHARGES: units set to '//TRIM(external_charges))
            !
        END IF
        !
        !--------------------------------------------------------------------------------
        ! Parse card input
        !
        DO ie = 1, env_external_charges
            !
            CALL env_read_line(input_line, end_of_file=tend)
            !
            IF (tend) &
                CALL errore('environ_cards', 'end of file reading external charges', ie)
            !
            ! #TODO how about 'missing external charges'?
            !
            CALL env_field_count(nfield, input_line)
            !
            !----------------------------------------------------------------------------
            ! read field 1 (total charge of the external density)
            !
            CALL env_get_field(1, field_str, input_line)
            !
            READ (field_str, *) extcharge_charge(ie)
            !
            !----------------------------------------------------------------------------
            ! read fields 2-4 (x-y-z position of external density)
            !
            CALL env_get_field(2, field_str, input_line)
            !
            READ (field_str, *) extcharge_pos(1, ie)
            !
            CALL env_get_field(3, field_str, input_line)
            !
            READ (field_str, *) extcharge_pos(2, ie)
            !
            CALL env_get_field(4, field_str, input_line)
            !
            READ (field_str, *) extcharge_pos(3, ie)
            !
            !----------------------------------------------------------------------------
            ! optionally read field 5 (spread of the density)
            !
            IF (nfield >= 5) THEN
                !
                CALL env_get_field(5, field_str, input_line)
                !
                READ (field_str, *) extcharge_spread(ie)
                !
                IF (extcharge_spread(ie) .LT. 0.D0) &
                    CALL errore(' card_external_charges  ', &
                                ' spread must be positive', ie)
                !
            END IF
            !
            !----------------------------------------------------------------------------
            ! optionally read field 6 and 7 (dimensionality and direction)
            !
            IF (nfield >= 6) THEN
                !
                CALL env_get_field(6, field_str, input_line)
                !
                READ (field_str, *) extcharge_dim(ie)
                !
                IF (extcharge_dim(ie) .LT. 0 .OR. extcharge_dim(ie) .GT. 2) &
                    CALL errore(' card_external_charges  ', &
                                ' wrong excharge dimension ', ie)
                !
                IF (extcharge_dim(ie) .GT. 0) THEN
                    !
                    IF (nfield == 6) &
                        CALL errore('environ_cards', &
                                    'missing axis direction of partially periodic &
                                    &external charge', ie)
                    !
                    CALL env_get_field(7, field_str, input_line)
                    !
                    READ (field_str, *) extcharge_axis(ie)
                    !
                    IF (extcharge_axis(ie) .LT. 0 .OR. extcharge_axis(ie) .GT. 3) &
                        CALL errore(' card_external_charges  ', &
                                    ' wrong excharge axis ', ie)
                    !
                END IF
                !
            END IF
            !
        END DO
        !
        !----------------------------------------------------------------------------
        ! Convert to atomic units
        !
        taextchg = .TRUE.
        !
        DO ie = 1, env_external_charges
            !
            DO ix = 1, 3
                CALL convert_length(external_charges, extcharge_pos(ix, ie))
            END DO
            !
            CALL convert_length(external_charges, extcharge_spread(ie))
            !
        END DO
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE card_external_charges
    !------------------------------------------------------------------------------------
    !
    !>
    !------------------------------------------------------------------------------------
    SUBROUTINE allocate_input_extcharge(env_external_charges)
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        INTEGER, INTENT(IN) :: env_external_charges
        !
        !--------------------------------------------------------------------------------
        !
        IF (ALLOCATED(extcharge_dim)) DEALLOCATE (extcharge_dim)
        !
        IF (ALLOCATED(extcharge_axis)) DEALLOCATE (extcharge_axis)
        !
        IF (ALLOCATED(extcharge_charge)) DEALLOCATE (extcharge_charge)
        !
        IF (ALLOCATED(extcharge_spread)) DEALLOCATE (extcharge_spread)
        !
        IF (ALLOCATED(extcharge_pos)) DEALLOCATE (extcharge_pos)
        !
        ALLOCATE (extcharge_dim(env_external_charges))
        ALLOCATE (extcharge_axis(env_external_charges))
        ALLOCATE (extcharge_charge(env_external_charges))
        ALLOCATE (extcharge_spread(env_external_charges))
        ALLOCATE (extcharge_pos(3, env_external_charges))
        !
        extcharge_dim = 0
        extcharge_axis = 3
        extcharge_charge = 0.0_DP
        extcharge_spread = 0.5_DP
        extcharge_pos = 0.0_DP
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE allocate_input_extcharge
    !------------------------------------------------------------------------------------
    !>
    !! Description of the allowed input CARDS
    !!
    !! DIELECTRIC_REGIONS (unit_option)
    !!
    !!   set fixed dielectric regions and their shape
    !!
    !! Syntax:
    !!
    !!    DIELECTRIC_REGIONS (unit_option)
    !!      epsilon0(1) epsilonopt(1) x(1) y(1) z(1)  width(1) spread(1) dim(1)  axis(1)
    !!       ...       ...        ...      ...        ...
    !!      epsilon0(n) epsilonopt(n) x(n) y(n) z(n)  width(n) spread(n) dim(n)  axis(n)
    !!
    !! Example:
    !!
    !! DIELECTRIC_REGIONS (bohr)
    !!  80.0  2.0   0.0  0.0  10.0   5.0  1.0  2  3
    !!
    !! Where:
    !!
    !!   unit_option == bohr       positions are given in Bohr (DEFAULT)
    !!   unit_option == angstrom   positions are given in Angstrom
    !!
    !!      epsilon0(i)   ( real )    static permittivity inside the region
    !!      epsilonopt(i) ( real )    optical permittivity inside the region
    !!      x/y/z(i)      ( real )    cartesian center of the region
    !!      width(i)      ( real )    size of the region (in bohr)
    !!      spread(i)     ( real )    spread of the interface (in bohr, optional)
    !!      dim(i)     ( integer )    0/1/2 point/line/plane region (optional)
    !!      axis(i)    ( integer )    1/2/3 for x/y/z direction of line/plane (optional)
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE card_dielectric_regions(input_line)
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        CHARACTER(LEN=256) :: input_line
        INTEGER :: ie, ix, ierr, nfield
        LOGICAL :: tend
        LOGICAL, EXTERNAL :: matches
        CHARACTER(LEN=4) :: lb_pos
        CHARACTER(LEN=256) :: field_str
        !
        !--------------------------------------------------------------------------------
        !
        IF (taepsreg) CALL errore(' card_dielectric_regions  ', ' two occurrences', 2)
        !
        IF (env_dielectric_regions > nsx) &
            CALL errore(' card_dielectric_regions ', ' nsx out of range ', &
                        env_dielectric_regions)
        !
        CALL allocate_input_epsregion(env_dielectric_regions)
        !
        IF (matches("BOHR", input_line)) THEN
            dielectric_regions = 'bohr'
        ELSE IF (matches("ANGSTROM", input_line)) THEN
            dielectric_regions = 'angstrom'
        ELSE
            !
            IF (TRIM(ADJUSTL(input_line)) /= 'DIELECTRIC_REGIONS') &
                CALL errore('read_cards ', &
                            'unknown option for DIELECTRIC_REGIONS: '//input_line, 1)
            !
            CALL infomsg('read_cards ', 'No units specified in DIELECTRIC_REGIONS card')
            !
            dielectric_regions = 'bohr'
            !
            CALL infomsg('read_cards ', &
                         'DIELECTRIC_REGIONS: units set to '//TRIM(dielectric_regions))
            !
        END IF
        !
        !--------------------------------------------------------------------------------
        ! Parse card input
        !
        DO ie = 1, env_dielectric_regions
            !
            CALL env_read_line(input_line, end_of_file=tend)
            !
            IF (tend) CALL errore('environ_cards', &
                                  'end of file reading dielectric regions', ie)
            !
            CALL env_field_count(nfield, input_line)
            !
            !----------------------------------------------------------------------------
            ! read field 1-2 (static and optical permettivity inside dielectric region)
            !
            CALL env_get_field(1, field_str, input_line)
            !
            READ (field_str, *) epsregion_eps(1, ie)
            !
            IF (epsregion_eps(1, ie) .LT. 1.D0) &
                CALL errore(' card_dielectric_regions  ', &
                            ' static permittivity must be .gt. 1', ie)
            !
            CALL env_get_field(2, field_str, input_line)
            !
            READ (field_str, *) epsregion_eps(2, ie)
            !
            IF (epsregion_eps(2, ie) .LT. 1.D0) &
                CALL errore(' card_dielectric_regions  ', &
                            ' optical permittivity must be .gt. 1', ie)
            !
            !----------------------------------------------------------------------------
            ! read fields 3-5 (x-y-z position of dielectric region)
            !
            CALL env_get_field(3, field_str, input_line)
            !
            READ (field_str, *) epsregion_pos(1, ie)
            !
            CALL env_get_field(4, field_str, input_line)
            !
            READ (field_str, *) epsregion_pos(2, ie)
            !
            CALL env_get_field(5, field_str, input_line)
            !
            READ (field_str, *) epsregion_pos(3, ie)
            !
            !----------------------------------------------------------------------------
            ! read field 6 (size/width of the dielectric region)
            !
            CALL env_get_field(6, field_str, input_line)
            !
            READ (field_str, *) epsregion_width(ie)
            !
            IF (epsregion_width(ie) .LT. 0.D0) &
                CALL errore(' card_dielectric_regions  ', &
                            ' width must be positive', ie)
            !
            !----------------------------------------------------------------------------
            ! optionally read field 7 (spread of interface of the dielectric region)
            !
            IF (nfield >= 7) THEN
                !
                CALL env_get_field(7, field_str, input_line)
                !
                READ (field_str, *) epsregion_spread(ie)
                !
                IF (epsregion_spread(ie) .LT. 0.D0) &
                    CALL errore(' card_dielectric_regions ', &
                                ' spread must be positive', ie)
                !
            END IF
            !
            !----------------------------------------------------------------------------
            ! optionally read field 7 and 8 (dimensionality and direction)
            !
            IF (nfield >= 8) THEN
                !
                CALL env_get_field(8, field_str, input_line)
                !
                READ (field_str, *) epsregion_dim(ie)
                !
                IF (epsregion_dim(ie) .LT. 0 .OR. epsregion_dim(ie) .GT. 2) &
                    CALL errore(' card_dielectric_regions ', &
                                ' wrong epsregion dimension ', ie)
                !
                IF (epsregion_dim(ie) .GT. 0) THEN
                    !
                    IF (nfield == 8) &
                        CALL errore('environ_cards', &
                                    'missing axis direction of partially periodic &
                                    &dielectric region', ie)
                    !
                    CALL env_get_field(9, field_str, input_line)
                    !
                    READ (field_str, *) epsregion_axis(ie)
                    !
                    IF (epsregion_axis(ie) .LT. 1 .OR. epsregion_axis(ie) .GT. 3) &
                        CALL errore(' card_dielectric_regions ', &
                                    ' wrong epsregion axis ', ie)
                    !
                END IF
                !
            END IF
            !
        END DO
        !
        !--------------------------------------------------------------------------------
        ! Convert to atomic units
        !
        taepsreg = .TRUE.
        !
        DO ie = 1, env_dielectric_regions
            !
            DO ix = 1, 3
                CALL convert_length(dielectric_regions, epsregion_pos(ix, ie))
            END DO
            !
            CALL convert_length(dielectric_regions, epsregion_width(ie))
            !
            CALL convert_length(dielectric_regions, epsregion_spread(ie))
            !
        END DO
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE card_dielectric_regions
    !------------------------------------------------------------------------------------
    !>
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE allocate_input_epsregion(env_dielectric_regions)
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        INTEGER, INTENT(IN) :: env_dielectric_regions
        !
        !--------------------------------------------------------------------------------
        !
        IF (ALLOCATED(epsregion_dim)) DEALLOCATE (epsregion_dim)
        !
        IF (ALLOCATED(epsregion_axis)) DEALLOCATE (epsregion_axis)
        !
        IF (ALLOCATED(epsregion_eps)) DEALLOCATE (epsregion_eps)
        !
        IF (ALLOCATED(epsregion_width)) DEALLOCATE (epsregion_width)
        !
        IF (ALLOCATED(epsregion_spread)) DEALLOCATE (epsregion_spread)
        !
        IF (ALLOCATED(epsregion_pos)) DEALLOCATE (epsregion_pos)
        !
        ALLOCATE (epsregion_dim(env_dielectric_regions))
        ALLOCATE (epsregion_axis(env_dielectric_regions))
        ALLOCATE (epsregion_eps(2, env_dielectric_regions))
        ALLOCATE (epsregion_width(env_dielectric_regions))
        ALLOCATE (epsregion_spread(env_dielectric_regions))
        ALLOCATE (epsregion_pos(3, env_dielectric_regions))
        !
        epsregion_dim = 0
        epsregion_axis = 3
        epsregion_eps = 1.0_DP
        epsregion_width = 0.0_DP
        epsregion_spread = 0.5_DP
        epsregion_pos = 0.0_DP
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE allocate_input_epsregion
    !------------------------------------------------------------------------------------
    !>
    !! Convert input length to atomic units
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE convert_length(length_format, length)
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        CHARACTER(LEN=*), INTENT(IN) :: length_format
        !
        REAL(DP), INTENT(INOUT) :: length
        !
        !--------------------------------------------------------------------------------
        !
        SELECT CASE (length_format)
        CASE ('bohr')
            length = length ! input length are in a.u., do nothing
        CASE ('angstrom')
            length = length / bohr_radius_angs ! length in A: convert to a.u.
        CASE DEFAULT
            !
            CALL errore('iosys', 'length_format='// &
                        TRIM(length_format)//' not implemented', 1)
            !
        END SELECT
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE convert_length
    !------------------------------------------------------------------------------------
    !
    !------------------------------------------------------------------------------------
END MODULE environ_input
!----------------------------------------------------------------------------------------
