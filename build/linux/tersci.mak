# Main program is tersci

PROG =	tersci

include ../make.${Compiler_Version}

BD =../${PSrcDir}/src

SRCS_f90 = bin/tersci/sub_utmgeo.f90 bin/tersci/sub_demchk.f90 \
	  bin/tersci/sub_initer_dem.f90 bin/tersci/tersci.f90 \
	  bin/tersci/sub_srccnv.f90 bin/tersci/sub_read_tifftags.f90 \
	  bin/tersci/mod_control.f90 bin/tersci/sub_initer_ned.f90 \
	  bin/tersci/sub_chkext.f90 bin/tersci/sub_chkadj.f90 \
	  bin/tersci/mod_tifftags.f90 bin/tersci/sub_reccnv.f90 \
	  bin/tersci/sub_cnrcnv.f90 bin/tersci/sub_nadcon.f90 \
	  bin/tersci/sub_demrec.f90 bin/tersci/mod_main1.f90 \
	  bin/tersci/sub_domcnv.f90 bin/tersci/sub_recelv.f90 \
	  bin/tersci/sub_calchc.f90 bin/tersci/sub_demsrc.f90 \
	  bin/tersci/sub_srcelv.f90 bin/tersci/sub_nedchk.f90

OBJS_f90 := $(notdir $(subst .f90,.o,$(SRCS_f90)))

OBJS :=  $(OBJS_f90) 

all: $(PROG) separator

separator:
	@echo ==========================================================================

$(PROG): $(OBJS) $(LIBDEPENDS)
	$(LNK) $(LNKFLAGS) $(PROG) $(OBJS) $(LIBS)

$(OBJS_f90): %.o:$(filter /\%.f90,$(SRCS_f90))
	$(FC) $(FCFLAGS) $< 


sub_utmgeo.o:$(BD)/bin/tersci/sub_utmgeo.f90 

mod_main1.o:$(BD)/bin/tersci/mod_main1.f90 

sub_demchk.o:$(BD)/bin/tersci/sub_demchk.f90  mod_main1.o

sub_initer_dem.o:$(BD)/bin/tersci/sub_initer_dem.f90  mod_main1.o

mod_control.o:$(BD)/bin/tersci/mod_control.f90  mod_main1.o

tersci.o:$(BD)/bin/tersci/tersci.f90  mod_control.o mod_main1.o

sub_srccnv.o:$(BD)/bin/tersci/sub_srccnv.f90  mod_main1.o

mod_tifftags.o:$(BD)/bin/tersci/mod_tifftags.f90 

sub_read_tifftags.o:$(BD)/bin/tersci/sub_read_tifftags.f90  mod_tifftags.o

sub_initer_ned.o:$(BD)/bin/tersci/sub_initer_ned.f90  mod_main1.o \
	  mod_tifftags.o

sub_chkext.o:$(BD)/bin/tersci/sub_chkext.f90  mod_main1.o

sub_chkadj.o:$(BD)/bin/tersci/sub_chkadj.f90  mod_main1.o

sub_reccnv.o:$(BD)/bin/tersci/sub_reccnv.f90  mod_main1.o

sub_cnrcnv.o:$(BD)/bin/tersci/sub_cnrcnv.f90  mod_main1.o

sub_nadcon.o:$(BD)/bin/tersci/sub_nadcon.f90 

sub_demrec.o:$(BD)/bin/tersci/sub_demrec.f90  mod_main1.o

sub_domcnv.o:$(BD)/bin/tersci/sub_domcnv.f90  mod_main1.o

sub_recelv.o:$(BD)/bin/tersci/sub_recelv.f90  mod_main1.o

sub_calchc.o:$(BD)/bin/tersci/sub_calchc.f90  mod_main1.o

sub_demsrc.o:$(BD)/bin/tersci/sub_demsrc.f90  mod_main1.o

sub_srcelv.o:$(BD)/bin/tersci/sub_srcelv.f90  mod_main1.o

sub_nedchk.o:$(BD)/bin/tersci/sub_nedchk.f90  mod_main1.o mod_tifftags.o


# Entry for " make clean " to get rid of all object and module files 
clean:
	rm -f $(OBJS) $(PROG)  control.mod tifftags.mod ter_main.mod