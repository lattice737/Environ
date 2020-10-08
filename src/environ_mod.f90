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
!> This module contains all control variables and stored variables
!! needed for the Environ calculation
!
! Authors: Oliviero Andreussi (Department of Physics, UNT)
!          Francesco Nattino  (THEOS and NCCR-MARVEL, EPFL)
!          Ismaila Dabo       (DMSE, Penn State)
!          Nicola Marzari     (THEOS and NCCR-MARVEL, EPFL)
!
!----------------------------------------------------------------------------
MODULE environ_base
!----------------------------------------------------------------------------
  !
  ! ... this module contains all the main variables needed for the
  ! ... environ module. This include the control and debug variables,
  ! ... all physical and numerical parameters, and
  ! ... the contributions to the energy and to the potential.
  !
  USE environ_types
  !
  SAVE
  !
  ! Global parameters
  !
  LOGICAL ::                        &
       environ_restart
  LOGICAL ::                        &
       update_venviron
  REAL (KIND=DP) ::                 &
       environ_thr
  INTEGER ::                        &
       environ_nskip
  !
  ! Control flags
  !
  LOGICAL ::                          &
       ltddfpt
  LOGICAL ::                          &
       lsolvent
  LOGICAL ::                          &
       lelectrostatic
  LOGICAL ::                          &
       lsoftsolvent
  LOGICAL ::                          &
       lsoftelectrolyte
  LOGICAL ::                          &
       lsoftcavity
  LOGICAL ::                          &
       lrigidsolvent
  LOGICAL ::                          &
       lrigidelectrolyte
  LOGICAL ::                          &
       lrigidcavity
  LOGICAL ::                          &
       lcoredensity
  LOGICAL ::                          &
       lsmearedions
  LOGICAL ::                          &
       lgradient
  !
  ! Mapping between environment and system cell
  !
  LOGICAL ::                 &
       ldoublecell
  TYPE( environ_mapping ) :: &
       mapping
  !
  ! Internal system cell parameters
  !
  TYPE( environ_cell ), TARGET :: &
       system_cell
  !
  ! Internal environment cell parameters
  !
  TYPE( environ_cell ), POINTER :: &
       environment_cell
  !
  ! Internal parameters of ions
  !
  TYPE( environ_ions ), TARGET :: &
       system_ions,               &
       environment_ions
  !
  ! Internal parameters of electrons
  !
  TYPE( environ_electrons ), TARGET :: &
       system_electrons,               &
       environment_electrons
  !
  ! Internal parameters of external charges
  !
  LOGICAL ::                           &
       lexternals
  TYPE( environ_externals ), TARGET :: &
       externals
  !
  ! Internal paramters of system charges
  !
  TYPE( environ_charges ), TARGET :: &
       system_charges
  !
  ! Internal paramters of environment charges
  !
  TYPE( environ_charges ), TARGET :: &
       environment_charges
  !
  ! Details of the selected system
  !
  TYPE( environ_system ), TARGET :: &
       system_system,               &
       environment_system
  !
  ! Details of the continuum interface
  !
  LOGICAL ::                       &
       lboundary
  TYPE( boundary_core ), TARGET :: &
       derivatives
  !
  ! Details of the continuum interface
  !
  TYPE( environ_boundary ), TARGET :: &
       solvent
  !
  ! Dielectric parameters (solvent)
  !
  LOGICAL ::                        &
       lstatic
  LOGICAL ::                        &
       loptical
  LOGICAL ::                        &
       ldielectric
  REAL (KIND=DP) ::                 &
       env_static_permittivity,     &
       env_optical_permittivity
  TYPE( environ_dielectric ) ::     &
       static,                      &
       optical
  !
  ! Ionic countercharge parameters
  !
  LOGICAL ::                        &
       lelectrolyte
  INTEGER ::                        &
       env_electrolyte_ntyp
  TYPE( environ_electrolyte ) ::    &
       electrolyte
  !
  ! Semiconductor parameters
  !
  LOGICAL ::                        &
       lsemiconductor
  LOGICAL ::                        &
       louterloop
  TYPE( environ_semiconductor ) ::  &
       semiconductor

  !
  ! Cavitation energy parameters
  !
  LOGICAL ::                        &
       lsurface
  REAL (KIND=DP) ::                 &
       env_surface_tension
  !
  ! PV term parameters
  !
  LOGICAL ::                        &
       lvolume
  REAL (KIND=DP) ::                 &
       env_pressure
  !
  ! Confinement potential parameters
  !
  LOGICAL ::                        &
       lconfine
  REAL (KIND=DP) ::                 &
       env_confine
  !
  ! Periodicity correction parameters
  !
  LOGICAL ::                        &
       lperiodic
  !
  ! Temporary parameters
  !
  INTEGER ::                        &
       nrep
  INTEGER ::                        &
       niter ! stores the iteration of environ for debugging purposes
  !
  ! Computed physical variables
  !
  REAL (KIND=DP) ::                 &
       deenviron,                   &
       eelectrostatic,              &
       esurface,                    &
       evolume,                     &
       eelectrolyte,                &
       econfine,                    &
       potential_shift
  TYPE ( environ_density ) ::       &
       vzero,                       &
       velectrostatic,              &
       vreference,                  &
       dvtot,                       &
       vconfine,                    &
       vsoftcavity
!----------------------------------------------------------------------------
END MODULE environ_base
!----------------------------------------------------------------------------
