#!/bin/bash
#----------------------------------------------------------------------------------------
#
# Copyright (C) 2018-2021 ENVIRON (www.quantum-environ.org)
#
#----------------------------------------------------------------------------------------
#
#     This file is part of Environ version 2.0
#     
#     Environ 2.0 is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 2 of the License, or
#     (at your option) any later version.
#     
#     Environ 2.0 is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more detail, either the file
#     `License' in the root directory of the present distribution, or
#     online at <http://www.gnu.org/licenses/>.
#
#----------------------------------------------------------------------------------------
#
# Authors: Oliviero Andreussi (Department of Physics, UNT)
#          Francesco Nattino  (THEOS and NCCR-MARVEL, EPFL)
#          Ismaila Dabo       (DMSE, Penn State)
#          Edan Bainglass     (Department of Physics, UNT)
#
#----------------------------------------------------------------------------------------
#
# PATCH script for plugin files and Makefile in PW/src
#
#----------------------------------------------------------------------------------------

cd $PW_SRC

patch_makefile

check_src_patched
if test "$PATCHED" == 1; then 
   return
else
   message "Patching"
fi

echo "#Please do not remove or modify this file" >Environ_PATCH
echo "#It keeps track of patched versions of the Environ addson package" >>Environ_PATCH
echo "$ENVIRON_VERSION" >>Environ_PATCH

# plugin_int_forces

sed '/Environ MODULES BEGIN/ a\
!Environ patch\
  USE env_global_objects, ONLY : env\
  USE class_calculator,   ONLY : calc\
!Environ patch
' plugin_int_forces.f90 >tmp.1

sed '/Environ VARIABLES BEGIN/ a\
!Environ patch \
  REAL(DP), ALLOCATABLE :: force_environ(:,:)\
!Environ patch
' tmp.1 >tmp.2

sed '/Environ CALLS BEGIN/ a\
!Environ patch\
  IF (use_environ) THEN\
    !\
    ALLOCATE(force_environ(3,nat))\
    !\
    force_environ=0.0_dp\
    !\
    ! ... Add environment contributions\
    !\
    CALL calc%force( env, nat, force_environ )\
    !\
    IF ( iverbosity > 0 ) THEN\
      WRITE( stdout, 9001 )\
      DO na = 1, nat\
         WRITE( stdout, 9002 ) na, ityp(na), ( force_environ(ipol,na), ipol = 1, 3 )\
      END DO\
      WRITE( stdout, * )\
    ENDIF\
    !\
    force = force_environ\
    !\
    DEALLOCATE(force_environ)\
    !\
  END IF\
  !\
9001 FORMAT(5x,"The global environment contribution to forces")\
9002 FORMAT(5X,"atom ",I4," type ",I2,"   force = ",3F14.8)\
!Environ patch
' tmp.2 >tmp.1

mv tmp.1 plugin_int_forces.f90

# plugin_read_input

sed '/Environ MODULES BEGIN/ a\
!Environ patch\
  USE io_global,          ONLY : ionode, ionode_id, stdout\
  USE mp_images,          ONLY : intra_image_comm\
  USE martyna_tuckerman,  ONLY : do_comp_mt\
  USE class_io,           ONLY : io\
  USE env_global_objects, ONLY : setup\
  USE environ_input,      ONLY : read_environ_input\
!Environ patch
' plugin_read_input.f90 >tmp.1

sed '/Environ CALLS BEGIN/ a\
!Environ patch\
   IF (use_environ) THEN\
      !\
      CALL io%init(ionode, ionode_id, intra_image_comm, stdout, ionode)\
      !\
      CALL read_environ_input()\
      !\
      CALL setup%init(do_comp_mt)\
      !\
      IF (prog == "TD") CALL setup%set_tddfpt(.TRUE.)\
      !\
   ENDIF\
!Environ patch
' tmp.1 >tmp.2

mv tmp.2 plugin_read_input.f90

# plugin_clean

sed '/Environ MODULES BEGIN/ a\
!Environ patch\
USE class_destructor,   ONLY : clean\
USE env_global_objects, ONLY : setup\
!Environ patch
' plugin_clean.f90 >tmp.1

sed '/Environ CALLS BEGIN/ a\
!Environ patch\
   IF (use_environ) THEN\
      !\
      IF (prog(1:2) == "PW") THEN\
         !\
         ! When called by PW, but inside a TD calculation\
         ! do not clean environ variables, they have been\
         ! already cleaned by TD. The lflag input is used\
         ! to fully clean the variable or to only clean\
         ! variables initialized during the PW run and not the\
         ! ones initialized while processing the input:\
         ! this allows NEB simulations\
         !\
         IF (.NOT. setup%is_tddfpt()) CALL clean%all()\
         !\
      ELSE IF ( prog(1:2) == "TD" ) THEN\
         !\
         ! When called by TD, use the flag input variable to\
         ! specify whether to clean the PW variables or\
         ! the TD variables. In both cases, the variables are\
         ! fully cleaned (no NEB with TD).\
         !\
         IF (.NOT. lflag) THEN\
            CALL clean%first()\
         ELSE\
            CALL clean%second()\
         END IF\
         !\
      END IF\
      !\
   END IF\
!Environ patch
' tmp.1 >tmp.2

mv tmp.2 plugin_clean.f90

# plugin_summary

sed '/Environ MODULES BEGIN/ a\
!Environ patch \
USE io_global,          ONLY : stdout \
USE env_global_objects, ONLY : setup\
USE class_io,           ONLY : io\
!Environ patch
' plugin_summary.f90 >tmp.1

sed '/Environ CALLS BEGIN/ a\
!Environ patch \
   IF (use_environ) CALL io%update_unit( stdout )\
   IF (use_environ) CALL setup%print_summary()\
!Environ patch
' tmp.1 >tmp.2

mv tmp.2 plugin_summary.f90

# plugin_initbase

sed '/Environ MODULES BEGIN/ a\
!Environ patch \
USE kinds,              ONLY : DP\
USE mp_bands,           ONLY : intra_bgrp_comm, me_bgrp, root_bgrp\
USE cell_base,          ONLY : at, alat\
USE ions_base,          ONLY : nat, nsp, ityp, atm, zv\
USE gvect,              ONLY : gcutm\
USE class_io,           ONLY : io\
USE env_global_objects, ONLY : env, setup\
!Environ patch
' plugin_initbase.f90 >tmp.1

sed '/Environ VARIABLES BEGIN/ a\
!Environ patch\
REAL(DP), ALLOCATABLE :: at_scaled(:, :)\
REAL(DP) :: gcutm_scaled\
INTEGER :: nr(3)\
CHARACTER(LEN=80) :: sub_name = "plugin_initbase"\
!Environ patch
' tmp.1 >tmp.2

sed '/Environ CALLS BEGIN/ a\
!Environ patch \
  IF (use_environ) THEN\
      !\
      IF (alat < 1.D-8) CALL io%error(sub_name, "Wrong alat", 1)\
      !\
      IF (alat < 1.0_DP) CALL io%warning("strange lattice parameter", 1003)\
      !\
      CALL env_allocate_mp_buffers()\
      !\
      ALLOCATE (at_scaled(3, 3))\
      at_scaled = at * alat\
      !\
      gcutm_scaled = gcutm / alat**2\
      !\
      nr(1) = dfftp%nr1\
      nr(2) = dfftp%nr2\
      nr(3) = dfftp%nr3\
      !\
      CALL setup%init_cell(gcutm_scaled, intra_bgrp_comm, at_scaled, nr)\
      !\
      DEALLOCATE (at_scaled)\
      !\
      CALL setup%init_cores(gcutm_scaled)\
      !\
      CALL env%init(setup, 1, nat, nsp, atm, ityp, zv)\
      !\
  END IF\
!Environ patch
' tmp.2 >tmp.1

mv tmp.1 plugin_initbase.f90

# plugin_clock

sed '/Environ MODULES BEGIN/ a\
!Environ patch \
USE env_global_objects, ONLY : setup\
!Environ patch
' plugin_clock.f90 >tmp.1

sed '/Environ CALLS BEGIN/ a\
!Environ patch \
   if(use_environ) CALL setup%print_clocks() \
!Environ patch
' tmp.1 >tmp.2

mv tmp.2 plugin_clock.f90

# plugin_print_energies

sed '/Environ MODULES BEGIN/ a\
!Environ patch \
USE control_flags,      ONLY : conv_elec\
USE env_global_objects, ONLY : env, setup\
!Environ patch
' plugin_print_energies.f90 >tmp.1

sed '/Environ CALLS BEGIN/ a\
!Environ patch \
   if (use_environ) then \
     CALL env%print_energies("PW") \
     if (conv_elec) then \
       CALL setup%print_potential_warning() \
     end if \
   end if \
!Environ patch
' tmp.1 >tmp.2

mv tmp.2 plugin_print_energies.f90

# plugin_init_ions

sed '/Environ MODULES BEGIN/ a\
!Environ patch\
USE cell_base,          ONLY : alat\
USE ions_base,          ONLY : nat, tau\
USE env_global_objects, ONLY : env, setup\
!Environ patch
' plugin_init_ions.f90 >tmp.1

sed '/Environ VARIABLES BEGIN/ a\
!Environ patch\
REAL(DP), ALLOCATABLE :: tau_scaled(:, :)\
!Environ patch
' tmp.1 >tmp.2

sed '/Environ CALLS BEGIN/ a\
!Environ patch\
IF (use_environ) THEN\
   ALLOCATE (tau_scaled(3, nat))\
   tau_scaled = tau * alat\
   !\
   CALL env%update_ions(nat, tau_scaled)\
   !\
   DEALLOCATE (tau_scaled)\
END IF\
!Environ patch
' tmp.2 >tmp.1

mv tmp.1 plugin_init_ions.f90

# plugin_init_cell

sed '/Environ MODULES BEGIN/ a\
!Environ patch\
USE cell_base,          ONLY : at, alat\
USE env_global_objects, ONLY : env, setup\
!Environ patch
' plugin_init_cell.f90 >tmp.1

sed '/Environ VARIABLES BEGIN/ a\
!Environ patch\
REAL(DP), ALLOCATABLE :: at_scaled(:, :)\
!Environ patch
' tmp.1 >tmp.2

sed '/Environ CALLS BEGIN/ a\
!Environ patch\
IF ( use_environ ) THEN\
   ALLOCATE (at_scaled(3, 3))\
   at_scaled = at * alat\
   !\
   CALL setup%update_cell(at_scaled)\
   !\
   CALL env%update_cell_dependent_quantities()\
   !\
   CALL setup%end_cell_update()\
   !\
   DEALLOCATE (at_scaled)\
END IF\
!\
!Environ patch
' tmp.2 >tmp.1

mv tmp.1 plugin_init_cell.f90

# plugin_scf_energy

sed '/Environ MODULES BEGIN/ a\
!Environ patch \
USE env_global_objects, ONLY : env\
USE class_calculator,   ONLY : calc\
!Environ patch
' plugin_scf_energy.f90 >tmp.1

sed '/Environ CALLS BEGIN/ a\
!Environ patch \
IF(use_environ) THEN \
   ! \
   ! compute environ contributions to total energy\
   ! \
   ! Note: plugin_etot is set to 0.0_dp right before \
   !       this routine is called\
   ! \
   CALL calc%denergy(env, plugin_etot)\
   ! \
   CALL calc%energy(env, plugin_etot)\
   ! \
END IF \
!Environ patch
' tmp.1 >tmp.2

mv tmp.2 plugin_scf_energy.f90

# plugin_init_potential

sed '/Environ MODULES BEGIN/ a\
!Environ patch \
USE env_global_objects, ONLY : env\
!Environ patch
' plugin_init_potential.f90 >tmp.1

sed '/Environ CALLS BEGIN/ a\
!Environ patch \
  IF(use_environ) CALL env%update_potential( dfftp%nnr, vltot )\
!Environ patch
' tmp.1 >tmp.2

mv tmp.2 plugin_init_potential.f90

# plugin_scf_potential

sed '/Environ MODULES BEGIN/ a\
!Environ patch\
USE kinds,              ONLY : DP\
USE global_version,     ONLY : version_number\
USE klist,              ONLY : nelec\
USE control_flags,      ONLY : lscf\
USE lsda_mod,           ONLY : nspin\
USE env_global_objects, ONLY : env, setup\
USE class_calculator,   ONLY : calc\
!Environ patch
' plugin_scf_potential.f90 >tmp.1

sed '/Environ VARIABLES BEGIN/ a\
!Environ patch\
LOGICAL :: update_venviron\
INTEGER :: local_verbose\
REAL(DP), ALLOCATABLE :: rhoaux(:)\
!Environ patch
' tmp.1 >tmp.2

sed '/Environ CALLS BEGIN/ a\
!Environ patch\
     IF(use_environ) THEN\
        !\
        ! reduce output at each scf iteration\
        !\
        local_verbose = 0\
        IF ( .NOT. lscf .OR. conv_elec ) local_verbose = 1\
        !\
        ! update electrons-related quantities in environ\
        !\
        ALLOCATE ( rhoaux(dfftp%nnr) )\
        rhoaux(:) = rhoin%of_r(:, 1)\
        !\
        IF ( version_number == "6.3" ) THEN\
            IF ( nspin == 2 ) rhoaux(:) = rhoaux(:) + rhoin%of_r(:, 2)\
        END IF\
        !\
        CALL env%update_electrons( dfftp%nnr, rhoaux, nelec )\
        !\
        ! environ contribution to the local potential\
        !\
        IF ( dr2 .GT. 0.0_dp ) THEN\
           update_venviron = .NOT. conv_elec .AND. dr2 .LT. setup%get_threshold()\
        !\
        ELSE\
           update_venviron = setup%is_restart() .OR. setup%is_tddfpt()\
           ! for subsequent steps of optimization or dynamics, compute\
           ! environ contribution during initialization\
           CALL setup%set_restart(.TRUE.)\
        ENDIF\
        !\
        IF ( update_venviron ) WRITE( stdout, 9200 )\
        !\
        CALL calc%potential(env, update_venviron, local_verbose)\
        !\
        vltot = env%get_vzero(dfftp%nnr) + env%get_dvtot(dfftp%nnr)\
        !\
        IF ( .NOT. lscf .OR. conv_elec ) CALL env%print_potential_shift()\
        !\
9200 FORMAT(/"     add environment contribution to local potential")\
     ENDIF\
!Environ patch
' tmp.2 >tmp.1

mv tmp.1 plugin_scf_potential.f90

# plugin_check

sed '/Environ CALLS BEGIN/ a\
!Environ patch \
IF (use_environ) CALL errore( calling_subroutine, &\
   & "Calculation not compatible with Environ embedding", 1)\
!Environ patch
' plugin_check.f90 >tmp.1

mv tmp.1 plugin_check.f90

rm tmp.2

# plugin initialization
# Note, when I tried this from a fresh compilation, it didn't actually patch in
# may need a different spot to place this and plugin_ext_forces

sed '/Environ MODULES BEGIN/ a\
!Environ patch \
USE klist,            ONLY : tot_charge\
USE force_mod,        ONLY : lforce\
USE control_flags,    ONLY : lbfgs\
USE env_global_objects, ONLY : setup\
USE control_flags,    ONLY : nstep\
!Environ patch
' plugin_initialization.f90 > tmp.1

sed '/Environ CALLS BEGIN/ a\
!Environ patch \
!\
\
! *****************************************************************************\
!\
! This checks on whether semiconductor optimization is used and either starts \
! the initial calculation of flatband potential or reads flatband potential from \
! file according to user input \
! \
! ***************************************************************************** \
 \
IF (use_environ) THEN \
 \
IF (setup%lmsgcs) THEN \
CALL start_clock( "semiconductor" ) \
lforce = .TRUE. \
lbfgs = .FALSE. \
nstep = 100 \
tot_charge = 0.0 \
!WRITE( stdout, 1000) \
WRITE( stdout, 1002) tot_charge \
CALL stop_clock( "semiconductor" ) \
 \
END IF \
 \
END IF \
 \
1000 FORMAT(5X,//"*******************************************"//,& \
&"  Please cite                              "//,& \
&"  Q. Campbell, D. Fisher and I. Dabo, Phys. Rev. Mat. 3, 015404 (2019)."//,& \
&"  doi: 10.1103/PhysRevMaterials.3.015404   "//,& \
&"  In any publications resulting from this work.") \
 \
1002 FORMAT(5x,//"*******************************************"//, & \
&"     Running initial calculation for flatband."//& \
&   "     Using charge of: ",F14.8,//& \
&"*******************************************") \
 \
!Environ patch
' tmp.1 > tmp.2

mv tmp.2 plugin_initialization.f90

#plugin_ext_forces (where I'm hiding all the semiconductor shit)


sed '/Environ MODULES BEGIN/ a\
!Environ patch \
!------------------------------------------------ \
! \
!Note: I am using the forces plugin as a backdoor \
!for the semiconductor loop. Its kinda off, but it works \
!If youre actually interested in plugin forces, check \
!the plugin_int_forces module \
! \
!------------------------------------------------ \
 \
\
USE env_global_objects, ONLY : setup, env\
USE class_io,           ONLY : io\
 \
USE mp,             ONLY: mp_bcast, mp_barrier, mp_sum \
USE mp_world,       ONLY: world_comm \
USE mp_images,      ONLY: intra_image_comm \
USE mp_bands,       ONLY: intra_bgrp_comm \
USE klist,            ONLY : tot_charge, nelec \
USE cell_base,        ONLY : omega \
USE lsda_mod,         ONLY : nspin \
USE scf,              ONLY : rho \
USE control_flags,    ONLY : conv_ions, nstep, istep \
USE ener,             ONLY : ef \
USE constants,        ONLY : rytoev \
USE fft_base,         ONLY : dfftp \
USE ions_base,        ONLY : nat, ityp, zv \
USE extrapolation,    ONLY : update_pot \
USE qexsd_module,     ONLY:   qexsd_set_status \
!Environ patch
' plugin_ext_forces.f90 > tmp.1

sed '/Environ VARIABLES BEGIN/ a\
!Environ patch \
\
SAVE \
REAL(DP)                  ::   cur_chg \
REAL(DP)                  ::   prev_chg, prev_chg2 \
REAL(DP)                  ::   cur_dchg \
REAL(DP)                  ::   cur_fermi \
REAL(DP)                  ::   prev_dchg \
REAL(DP)                  ::   gamma_mult \
REAL(DP)                  ::   prev_step_size \
REAL(DP)                  ::   ss_chg, charge \
INTEGER                   ::   chg_step, na \
REAL(DP)                  ::   surf_area \
REAL(DP)                  :: chg_per_area \
REAL(DP)                  :: ss_chg_per_area \
REAL(DP)                  :: ss_potential, total_potential \
REAL(DP)                  :: dft_chg_max, dft_chg_min \
REAL(DP)                  :: change_vec \
REAL(DP)                  :: v_cut, bulk_potential \
REAL(DP)                  :: ionic_charge \
LOGICAL                   :: converge \
! !Environ patch
' tmp.1 > tmp.2

sed '/Environ CALLS BEGIN/ a\
!Environ patch \
 \
!************************************************* \
! \
! This section designed to run after a call to electrons. Basically, it checks \
! whether the semiconductor charge has converged and then updates the relevant \
! quantities (tot_charge) accordingly \
! \
!************************************************* \
 \
gamma_mult = 0.15 \
 \
 \
converge = .TRUE. \
ionic_charge = 0._DP \
DO na = 1, nat \
ionic_charge = ionic_charge + zv( ityp(na) ) \
END DO \
 \
 \
 \
IF (use_environ .AND. setup%lmsgcs) THEN \
CALL start_clock( "semiconductor" ) \
 \
chg_step = istep \
!! Initializing the constraints of possible DFT charges \
! Should probably be initialized at chg_step =1 but that seemed to be \
! creating some trouble possibly \
IF (chg_step == 1) THEN \
! this is an option that feels like it should be useful to edit in the future \
IF (env%semiconductor%electrode_charge > 0.0) THEN \
dft_chg_max = 2.0*env%semiconductor%electrode_charge \
dft_chg_min = 0.0 \
ELSE \
dft_chg_min = 2.0*env%semiconductor%electrode_charge \
dft_chg_max = 0.0 \
END IF \
 \
END IF \
 \
 \
IF (chg_step == 0) THEN \
tot_charge = 0.7*env%semiconductor%electrode_charge \
env%semiconductor%flatband_fermi = ef!*rytoev \
env%semiconductor%slab_charge = tot_charge\
conv_ions = .FALSE. \
! CALL qexsd_set_status(255) \
! CALL punch( "config" ) \
! CALL add_qexsd_step(istep) \
istep =  istep + 1 \
!CALL save_flatband_pot(dfftp%nnr) \
WRITE( stdout, 1001) env%semiconductor%flatband_fermi*rytoev,tot_charge \
! \
! ... re-initialize atomic position-dependent quantities \
! \
nelec = ionic_charge - tot_charge \
CALL update_pot() \
CALL hinit1() \
ELSE \
cur_fermi = ef!*rytoev \
! for now, will try to keep everything in Ry, should basically work the same \
 \
!CALL save_current_pot(dfftp%nnr,cur_fermi,cur_dchg,ss_chg,v_cut,chg_step) \
cur_dchg = env%semiconductor%bulk_sc_fermi - cur_fermi \
bulk_potential = (env%semiconductor%bulk_sc_fermi - env%semiconductor%flatband_fermi)*rytoev \
ss_chg = tot_charge \
!IF (ionode) THEN \
! making sure constraints are updated \
IF (env%semiconductor%electrode_charge > 0) THEN \
IF (ss_chg < 0.0) THEN \
dft_chg_min = tot_charge \
converge = .FALSE. \
ELSE \
prev_chg2 = tot_charge \
END IF \
ELSE \
IF (ss_chg > 0.0) THEN \
dft_chg_max = tot_charge \
converge = .FALSE. \
ELSE \
prev_chg2 = tot_charge \
END IF \
END IF \
CALL mp_bcast(dft_chg_min, ionode_id,intra_image_comm) \
CALL mp_bcast(dft_chg_max, ionode_id,intra_image_comm) \
IF (chg_step > 1 )THEN \
gamma_mult = (cur_chg - prev_chg)/(cur_dchg - prev_dchg) \
END IF \
WRITE(io%debug_unit,*)"cur_chg: ",cur_chg \
WRITE(io%debug_unit,*)"prev_chg: ",prev_chg \
WRITE(io%debug_unit,*)"cur_dchg: ",cur_dchg \
WRITE(io%debug_unit,*)"prev_dchg: ",prev_dchg \
WRITE(io%debug_unit,*)"Using gamma of ",gamma_mult \
change_vec = -gamma_mult*cur_dchg \
prev_chg = tot_charge \
! This is my way of trying to impose limited constraints with an \
! unknown constraining function. Theres almost certainly a more \
! efficient way to do this but I havent thought of it yet \
 \
IF ((tot_charge + change_vec) > dft_chg_max ) THEN \
IF (tot_charge >= dft_chg_max) THEN \
tot_charge = prev_chg2 + 0.7*(dft_chg_max-prev_chg2) \
ELSE \
tot_charge = tot_charge + 0.7*(dft_chg_max-tot_charge) \
END IF \
ELSE IF ((tot_charge + change_vec) < dft_chg_min) THEN \
IF (tot_charge <= dft_chg_min) THEN \
tot_charge = prev_chg2 - 0.7*(prev_chg2-dft_chg_min) \
ELSE \
tot_charge = tot_charge - 0.7*(tot_charge-dft_chg_min) \
END IF \
 \
ELSE \
tot_charge = tot_charge + change_vec \
 \
END IF \
WRITE(io%debug_unit,*)"DFT_min ",dft_chg_min \
WRITE(io%debug_unit,*)"DFT_max ",dft_chg_max \
CALL mp_bcast(tot_charge, ionode_id,intra_image_comm) \
!print *,"DFT_max",dft_chg_max \
cur_chg = tot_charge \
prev_step_size = ABS(cur_chg - prev_chg) \
prev_dchg = cur_dchg \
!WRITE(io%debug_unit,*)"Convergeable? ",converge \
CALL mp_bcast(converge,ionode_id, intra_image_comm) \
CALL mp_bcast(prev_step_size,ionode_id,intra_image_comm) \
IF (((prev_step_size > env%semiconductor%charge_threshold) .OR. (.NOT. converge)) & \
& .AND. (chg_step < nstep-1))  THEN \
conv_ions = .FALSE. \
WRITE( STDOUT, 1002)& \
&chg_step,cur_fermi*rytoev,ss_chg,prev_step_size,cur_dchg,tot_charge \
!CALL qexsd_set_status(255) \
!CALL punch( "config" ) \
!CALL add_qexsd_step(istep) \
istep =  istep + 1 \
nelec = ionic_charge - tot_charge \
env%semiconductor%slab_charge = tot_charge\
CALL mp_bcast(nelec, ionode_id,intra_image_comm) \
CALL update_pot() \
CALL hinit1() \
ELSE \
IF (chg_step == nstep -1) THEN \
WRITE(STDOUT,*)NEW_LINE("a")//"   Exceeded Max number steps!"//& \
&NEW_LINE("a")//"   Results probably out of accurate range"//& \
&NEW_LINE("a")//"   Smaller chg_thr recommended."//& \
&NEW_LINE("a")//"   Writing current step to q-v.dat." \
END IF \
WRITE(STDOUT, 1003)chg_step,prev_step_size,ss_chg,cur_dchg,& \
&bulk_potential \
OPEN(21,file = "q-v.dat", status = "unknown") \
WRITE(37, *)"Potential (V-V_fb)  Surface State Potential (V-V_cut)",& \
&"  Electrode Charge (e)",& \
&"  Surface States Charge (e)    ",& \
&"Electrode Charge per surface area (e/cm^2)     ",& \
&"Surface State Charge per surface area (e/cm^2)" \
surf_area = env%semiconductor%surf_area_per_sq_cm \
chg_per_area = env%semiconductor%electrode_charge/surf_area \
ss_chg_per_area = ss_chg/surf_area \
ss_potential = -bulk_potential \
CALL mp_bcast(ss_potential, ionode_id, intra_image_comm) \
!print *, bulk_potential,ss_potential \
WRITE(37, 1004)total_potential, ss_potential,& \
&env%semiconductor%electrode_charge, ss_chg,& \
&chg_per_area,ss_chg_per_area \
CLOSE(21) \
END IF \
END IF \
 \
CALL stop_clock( "semiconductor" ) \
END IF \
 \
 \
 \
1001 FORMAT(5x,//"***************************************************",//& \
&"     Flatband potential calculated as ",F14.8,// & \
&"     Now using initial charge of:  ",F14.8,// & \
"***************************************************") \
! \
1002 FORMAT(5x,//"***************************************************",//& \
&"     Finished Charge convergence step : ",I3,//& \
&"     DFT Fermi level calculated as ",F14.8,// & \
&"     Charge trapped in surface states: ",F14.8," e",//& \
&"     Charge Accuracy < ",F14.8,// & \
&"     Difference between bulk and DFT fermi: ",F14.8,//& \
&"     Now using DFT charge of:  ",F14.8,// & \
"***************************************************") \
1003 FORMAT(5x,//"***************************************************",//& \
&"     Finished charge convergence step : ",I3,//& \
&"     Convergence of charge with accuracy < ",F14.8," e",// & \
&"     Charge trapped in surface states: ",F14.8,//& \
&"     Difference between bulk and DFT fermi: ",F14.8,//& \
&"     Final Potential: ",F14.8," V", //& \
&"     Output written to q-v.dat       ",//& \
"***************************************************") \
1004 FORMAT(1x,4F14.8,2ES12.5) \
!Environ patch
' tmp.2 > tmp.1

mv tmp.1 plugin_ext_forces.f90


rm tmp.1

printf " done!\n"

cd $QE_DIR
