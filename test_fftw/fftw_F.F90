include "mkl_omp_offload.f90"
include "fftw3.f"

program fftw_example

    use libomp
    implicit none

    integer, parameter            :: size = 100
    double precision, allocatable :: direct_data(:)
    double precision, allocatable :: transf_data(:)

    

    ! allocate space in memory
    allocate(direct_data(N, N, N))
    allocate(transf_data(N, N, N))



end program