program fftw_example
    implicit none 
    include 'fftw3.f'
    include 'fftw3_mkl.f'

    ! set precision to double
    integer, parameter :: r8 = selected_real_kind(15,307)

    ! interval length and number of points
    integer, parameter  :: N = 1024
    real(r8), parameter :: L = 4.0

    ! declare arrays to store data
    real(r8), allocatable :: myfun(:)
    real(r8), allocatable :: myder(:)
    real(r8), allocatable :: exact(:)

    ! declare array to keep data to be transformed
    complex(r8), allocatable :: fft_data(:)

    ! creating plans for fw/bw transforms (in place on arr)
    integer*8 :: plan_fw = 0, plan_bw = 0

    ! other variables
    character(40) :: fmt = "(F16.10,A1,F16.10,A1,F16.10,A1,F16.10)"
    integer  :: i, k = 0
    real(r8) :: G, x, err 
    real(r8) :: maxerr = 0.d0, cumerr = 0.d0
    G = 8.d0*atan(1.d0)/L/N  ! == 2*pi/L

    ! allocate space in memory
    allocate(myfun(N))
    allocate(myder(N))
    allocate(exact(N))
    allocate(fft_data(N))

    ! init plans for transforms
    call dfftw_plan_dft_r2c_1d(plan_fw, N, myfun, fft_data, FFTW_ESTIMATE)
    if (plan_fw == 0) stop
    call dfftw_plan_dft_c2r_1d(plan_bw, N, fft_data, myder,  FFTW_ESTIMATE)
    if (plan_bw == 0) stop

    ! initialize vectors
    do i=1,N
        x = -L/2 + (i-1)*L/(N-1)
        myfun(i) = exp(-0.5*x*x)
        exact(i) = -x*myfun(i)
    end do

    ! compute forward transform
    call dfftw_execute(plan_fw)

    ! multiply by wave number to obtain derivative
    do i=1,N
        k = i-1
        k = merge(k-N, k, k>(N/2))
        k = merge(0, k, (modulo(N,2).ne.0) .and. (k.eq.(N/2)))
        fft_data(i) = cmplx(0.d0, G*k, kind=r8)*fft_data(i)
    end do

    ! compute inverse transform
    call dfftw_execute(plan_bw)

    ! print out arrays for plotting and check error
    open(1, file='arrays.txt', status='replace')
    do i=1,N
        x = -L/2 + (i-1)*L/(N-1)
        write(1,fmt) x, char(9), myfun(i), char(9), exact(i), char(9), myder(i)

        err = dabs(exact(i) - myder(i))
        if (err > maxerr) maxerr = err
        cumerr = cumerr + err
    end do

    write(*,"(A18,F16.10)") "Cumulative error: ", cumerr
    write(*,"(A18,F16.10)") "Maximum error: ", maxerr

    ! destroy plans
    call dfftw_destroy_plan(plan_fw)
    call dfftw_destroy_plan(plan_bw)

    ! free resources
    deallocate(fft_data)
    deallocate(myfun)
    deallocate(myder)
    deallocate(exact)

end program 