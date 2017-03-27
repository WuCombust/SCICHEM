# Main program is libxpp.a

PROG =	libxpp.a

include ../make.${Compiler_Version}

BD =../${PSrcDir}/src

SRCS_f90 = bin/PostProcess/xpplib.f90

OBJS_f90 := $(notdir $(subst .f90,.o,$(SRCS_f90)))

OBJS :=  $(OBJS_f90) 

all: $(PROG) separator

separator:
	@echo ==========================================================================

$(PROG): $(OBJS) $(LIBDEPENDS)
	$(LB) $(LBFLAGS) $(PROG) $(OBJS)

$(OBJS_f90): %.o:$(filter /\%.f90,$(SRCS_f90))
	$(FC) $(FCFLAGS) $< 


xpplib.o:$(BD)/bin/PostProcess/xpplib.f90 


# Entry for " make clean " to get rid of all object and module files 
clean:
	rm -f $(OBJS) $(PROG) 