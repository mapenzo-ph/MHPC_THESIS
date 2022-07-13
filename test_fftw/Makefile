FC = ifort
FFLAGS = -O3 -qmkl -I${MKLROOT}/include/fftw

CC = icc
CFLAGS = -std=c11 -O3 -qmkl -I${MKLROOT}/include/fftw

SRC = fftw_F.f90
EXE = $(SRC:.f90=.x)

CSRC = fftw_C.c
CEXE = $(CSRC:.c=.x)

.PHONY:	default clean
default:	$(EXE) $(CEXE)

$(EXE):	$(SRC)
	$(FC) $< -o $@ $(FFLAGS)

$(CEXE):	$(CSRC)
	$(CC) $< -o $@ $(CFLAGS) -lm

clean:
	rm $(EXE) $(CEXE)