!----------------------------------------------------------------------------------------
!
! Copyright (C) 2018-2021 ENVIRON (www.quantum-environ.org)
!
!----------------------------------------------------------------------------------------
!
!     This file is part of Environ version 2.0
!
!     Environ 2.0 is free software: you can redistribute it and/or modify
!     it under the terms of the GNU General Public License as published by
!     the Free Software Foundation, either version 2 of the License, or
!     (at your option) any later version.
!
!     Environ 2.0 is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!     GNU General Public License for more detail, either the file
!     `License' in the root directory of the present distribution, or
!     online at <http://www.gnu.org/licenses/>.
!
!----------------------------------------------------------------------------------------
!
! Authors: Oliviero Andreussi (Department of Physics, UNT)
!          Francesco Nattino  (THEOS and NCCR-MARVEL, EPFL)
!          Nicola Marzari     (THEOS and NCCR-MARVEL, EPFL)
!          Quinn Campbell     (Sandia National Laboratories)
!          Ismaila Dabo       (DMSE, Penn State)
!          Edan Bainglass     (Department of Physics, UNT)
!
!----------------------------------------------------------------------------------------
!>
!!
!----------------------------------------------------------------------------------------
MODULE class_core_1da
    !------------------------------------------------------------------------------------
    !
    USE environ_param, ONLY: DP
    !
    USE class_cell
    !
    USE class_core_numerical
    !
    USE generate_functions, ONLY: generate_axis, generate_distance
    !
    !------------------------------------------------------------------------------------
    !
    IMPLICIT NONE
    !
    PRIVATE
    !
    !------------------------------------------------------------------------------------
    !>
    !!
    !------------------------------------------------------------------------------------
    TYPE, EXTENDS(numerical_core), PUBLIC :: core_1da
        !--------------------------------------------------------------------------------
        !
        LOGICAL :: initialized = .FALSE.
        INTEGER :: n, d, p, axis
        REAL(DP) :: size, origin(3)
        REAL(DP), ALLOCATABLE :: x(:, :)
        !
        !--------------------------------------------------------------------------------
    CONTAINS
        !--------------------------------------------------------------------------------
        !
        PROCEDURE :: create => create_core_1da
        PROCEDURE :: init_first => init_core_1da_first
        PROCEDURE :: init_second => init_core_1da_second
        PROCEDURE :: update_cell => update_core_1da_cell
        PROCEDURE :: update_origin => update_core_1da_origin
        PROCEDURE :: destroy => destroy_core_1da
        !
        !--------------------------------------------------------------------------------
    END TYPE core_1da
    !------------------------------------------------------------------------------------
    !
    !------------------------------------------------------------------------------------
CONTAINS
    !------------------------------------------------------------------------------------
    !------------------------------------------------------------------------------------
    !
    !                                   ADMIN METHODS
    !
    !------------------------------------------------------------------------------------
    !------------------------------------------------------------------------------------
    !>
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE create_core_1da(this)
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        CLASS(core_1da), INTENT(INOUT) :: this
        !
        !--------------------------------------------------------------------------------
        !
        this%core_type = '1d-analytic'
        !
        NULLIFY (this%cell)
        this%initialized = .FALSE.
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE create_core_1da
    !------------------------------------------------------------------------------------
    !>
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE init_core_1da_first(this, dim, axis)
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        INTEGER, INTENT(IN) :: dim, axis
        !
        CLASS(core_1da), INTENT(INOUT) :: this
        !
        CHARACTER(LEN=80) :: sub_name = 'init_core_1da_first'
        !
        !--------------------------------------------------------------------------------
        !
        CALL this%create()
        !
        IF (dim == 3 .OR. dim < 0) &
            CALL env_errore(sub_name, &
                            'Wrong dimensions for analytic one dimensional core', 1)
        !
        this%d = dim
        this%p = 3 - dim
        !
        IF ((dim == 1 .OR. dim == 2) .AND. (axis > 3 .OR. axis < 1)) &
            CALL env_errore(sub_name, &
                            'Wrong choice of axis for analytic one dimensional core', 1)
        !
        this%axis = axis
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE init_core_1da_first
    !------------------------------------------------------------------------------------
    !>
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE init_core_1da_second(this, cell)
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        TYPE(environ_cell), INTENT(IN) :: cell
        !
        CLASS(core_1da), INTENT(INOUT) :: this
        !
        !--------------------------------------------------------------------------------
        !
        CALL this%update_cell(cell)
        !
        this%n = cell%nnr
        ALLOCATE (this%x(this%p, this%n))
        !
        CALL this%update_origin(cell%origin)
        !
        this%initialized = .TRUE.
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE init_core_1da_second
    !------------------------------------------------------------------------------------
    !>
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE update_core_1da_cell(this, cell)
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        TYPE(environ_cell), TARGET, INTENT(IN) :: cell
        !
        CLASS(core_1da), INTENT(INOUT) :: this
        !
        !--------------------------------------------------------------------------------
        !
        this%cell => cell
        !
        IF (this%d == 0) THEN
            this%size = cell%omega
        ELSE IF (this%d == 1) THEN
            this%size = cell%omega / cell%at(this%axis, this%axis) / cell%alat
        ELSE IF (this%d == 2) THEN
            this%size = cell%at(this%axis, this%axis) * cell%alat
        END IF
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE update_core_1da_cell
    !------------------------------------------------------------------------------------
    !>
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE update_core_1da_origin(this, origin)
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        REAL(DP), INTENT(IN) :: origin(3)
        !
        CLASS(core_1da), INTENT(INOUT) :: this
        !
        CHARACTER(LEN=80) :: sub_name = 'update_core_1da_origin'
        !
        !--------------------------------------------------------------------------------
        !
        this%origin = origin
        !
        IF (this%d == 0) THEN
            CALL generate_distance(this%cell, this%origin, this%x)
        ELSE IF (this%d == 1) THEN
            CALL env_errore(sub_name, 'Option not yet implemented', 1)
        ELSE IF (this%d == 2) THEN
            CALL generate_axis(this%cell, this%axis, this%origin, this%x(1, :))
        END IF
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE update_core_1da_origin
    !------------------------------------------------------------------------------------
    !>
    !!
    !------------------------------------------------------------------------------------
    SUBROUTINE destroy_core_1da(this, lflag)
        !--------------------------------------------------------------------------------
        !
        IMPLICIT NONE
        !
        LOGICAL, INTENT(IN) :: lflag
        !
        CLASS(core_1da), INTENT(INOUT) :: this
        !
        CHARACTER(LEN=80) :: sub_name = 'destroy_core_1da'
        !
        !--------------------------------------------------------------------------------
        !
        IF (this%initialized) THEN
            !
            IF (.NOT. ALLOCATED(this%x)) &
                CALL env_errore(sub_name, &
                                'Trying to destroy a non-allocated component', 1)
            !
            DEALLOCATE (this%x)
            !
            IF (.NOT. ASSOCIATED(this%cell)) &
                CALL env_errore(sub_name, &
                                'Trying to nullify a non-associated pointer', 1)
            !
            NULLIFY (this%cell)
            this%initialized = .FALSE.
        END IF
        !
        RETURN
        !
        !--------------------------------------------------------------------------------
    END SUBROUTINE destroy_core_1da
    !------------------------------------------------------------------------------------
    !
    !------------------------------------------------------------------------------------
END MODULE class_core_1da
!----------------------------------------------------------------------------------------
