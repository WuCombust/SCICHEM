# Main program is libfdatums.a

PROG =	libfdatums.a

include ../make.${Compiler_Version}

BD =../${PSrcDir}/src

SRCS_f90 = lib/util/DATUMSlib/tmgeod.f90 lib/util/DATUMSlib/fdatums_mod.f90 \
	  lib/util/DATUMSlib/tconpc.f90 lib/util/DATUMSlib/tmgrid.f90 \
	  lib/util/DATUMSlib/tconst.f90 lib/util/DATUMSlib/fdatums.f90

OBJS_f90 := $(notdir $(subst .f90,.o,$(SRCS_f90)))

OBJS :=  $(OBJS_f90) 

all: $(PROG) separator

separator:
	@echo ==========================================================================

$(PROG): $(OBJS) $(LIBDEPENDS)
	$(LB) $(LBFLAGS) $(PROG) $(OBJS)

$(OBJS_f90): %.o:$(filter /\%.f90,$(SRCS_f90))
	$(FC) $(FCFLAGS) $< 


tmgeod.o:$(BD)/lib/util/DATUMSlib/tmgeod.f90 

fdatums_mod.o:$(BD)/lib/util/DATUMSlib/fdatums_mod.f90 

tconpc.o:$(BD)/lib/util/DATUMSlib/tconpc.f90 

tmgrid.o:$(BD)/lib/util/DATUMSlib/tmgrid.f90 

tconst.o:$(BD)/lib/util/DATUMSlib/tconst.f90 

fdatums.o:$(BD)/lib/util/DATUMSlib/fdatums.f90  fdatums_mod.o


# Entry for " make clean " to get rid of all object and module files 
clean:
	rm -f $(OBJS) $(PROG)  fdatums_fi.mod