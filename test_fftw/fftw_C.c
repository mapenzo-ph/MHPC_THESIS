#include <stdio.h>
#include <stdlib.h>
#include <complex.h>
#include <fftw3.h>
#include <fftw3_mkl.h>
#include <math.h>

#define PI 3.14159265358979323846

int main()
{
    int N = 1024;      // points
    double L = 4.0;    // interval length
    
    // allocate memory
    double *myfun = (double*)malloc(N*sizeof(double));
    double *myder = (double*)malloc(N*sizeof(double));
    double *exact = (double*)malloc(N*sizeof(double));

    // allocate work array
    fftw_complex *fft_data = (fftw_complex*)fftw_malloc(N*sizeof(fftw_complex));

    // init plans
    fftw_plan fwplan = fftw_plan_dft_r2c_1d(N, myfun, fft_data, FFTW_ESTIMATE);
    fftw_plan bwplan = fftw_plan_dft_c2r_1d(N, fft_data, myder, FFTW_ESTIMATE);

    // init matrices
    double x;
    for (int i=0; i<N; ++i)
    {
        x = -L/2 + i*L/(N-1);           // symmetric interval (-5.0, 5.0)
        myfun[i] = exp(-0.5*x*x);       // e^{-x^2/2}
        exact[i] = -x*myfun[i];         // -xe^{-X^2/2} 
    }

    // transform
    fftw_execute(fwplan);

    // multiply by wave number to obtain derivative
    int k = 0;
    double G = 2*PI/L/N;
    for (int i=0; i<N; ++i)
    {
        k = (i > N/2) ? i - N : i;
        k = ((N%2 != 0) && (i == N/2)) ? 0 : i;
        fft_data[i] *= (0.0 + I*G*k);
    }

    // inverse transform
    fftw_execute(bwplan);

    // print out for plotting and check errors
    FILE *fp = fopen("arrays.txt", "w");
    double maxerr = 0.0, cumerr = 0.0, err;
    for (int i=0; i<N; ++i)
    {
        x = -L/2 + i*L/(N-1);
        fprintf(fp, "%13.10lf\t%13.10lf\t%13.10lf\t%13.10lf\n", x, myfun[i], exact[i], myder[i]);
        
        err = fabs(exact[i] - myder[i]);
        cumerr += err;
        if (err > maxerr) maxerr = err;
    }
    printf("Cumulative error: %lf\n", cumerr);
    printf("Maximum error   : %lf\n", maxerr);

    // destroy plans
    fftw_destroy_plan(fwplan);
    fftw_destroy_plan(bwplan);

    // free memory
    fftw_free(fft_data);
    free(myfun);
    free(myder);
    free(exact);

    return 0;
}