** Benchmark in System RPL for the HP48GX - by JMC
**
** This .m file accompanies "benchmark.hp48.s". It contains directions for the linker (sload)
** to generate "benchmark.bin".
** Unfortunately these directions cannot be passed as command line arguments, and this extra file is required.
** See "SLOAD.DOC" inside "HP Tools Source Code 3.0.8" for its syntax.
** NOTE: make sure to pass -H to sload:
**       sload -H benchmark.hp48.m
**
TITLE Benchmark for HP48 in SysRPL
OUTPUT benchmark.bin
** Uncomment LLIST to supress printed output of SLOAD and have it written to the timeeval.lr file:
**   LLIST benchmark.hp48.lr
SUPPRESS XREF
** Put here the correct path to your entries.o:
**   SEARCH /opt/hptools/entries.o
SEARCH c:\hptools\entries.o
REL benchmark.hp48.o
END
