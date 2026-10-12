** Benchmark in System RPL for the HP50g - by JMC
**
** This .m file accompanies "benchmark.hp50.s". It contains directions for the linker (sload)
** to generate "benchmark.bin".
** Unfortunately these directions cannot be passed as command line arguments, and this extra file is required.
** See "SLOAD.DOC" inside "HP Tools Source Code 3.0.8" for its syntax.
** NOTE: make sure to pass -H to sload:
**       sload -H benchmark.hp50.m
**
TITLE Benchmark for HP50g in SysRPL
OUTPUT benchmark.bin
** Uncomment LLIST to supress printed output of SLOAD and have it written to the timeeval.lr file:
**   LLIST benchmark.hp50.lr
SUPPRESS XREF
** Put here the correct path to your entries.o:
SEARCH /opt/hptools/entries49.o
** SEARCH c:\hptools\entries49.o
REL benchmark.hp50.o
END
