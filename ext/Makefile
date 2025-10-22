CC ?= gcc
AR ?= ar
RANLIB ?= ranlib
SRC ?= tsf.c tml.c

# Detect MSVC (cl). A simple heuristic: CC contains 'cl' (case-sensitive as typical on Windows).
IS_MSVC := $(findstring cl,$(CC))

ifeq ($(IS_MSVC),cl)
# ---- MSVC toolchain settings ----
OBJEXT := obj
LIBEXT := lib
STATIC := libtsf.$(LIBEXT)

# Override flags for MSVC
override CFLAGS := /nologo /O2 /I. /ITinySoundFont /D_CRT_SECURE_NO_WARNINGS

# Use Microsoft LIB to create the static library
AR := lib
RANLIB := echo

# Compile rule for MSVC: /c to compile, /Fo to set output object filename
COMPILE.c = $(CC) $(CFLAGS) /c $< /Fo$@

else
# ---- GCC/Clang toolchain settings ----
OBJEXT := o
LIBEXT := a
STATIC := libtsf.$(LIBEXT)

CFLAGS ?= -O3 -std=c11 -fPIC -I. -ITinySoundFont

# Compile rule for GCC/Clang
COMPILE.c = $(CC) $(CFLAGS) -c $< -o $@

endif

OBJ := $(SRC:.c=.$(OBJEXT))

.PHONY: all clean

all: $(STATIC)

%.$(OBJEXT): %.c
	$(COMPILE.c)

ifeq ($(IS_MSVC),cl)
$(STATIC): $(OBJ)
	$(AR) /nologo /out:$@ $^
	$(AR) /nologo /out:tsf.lib $^
else
$(STATIC): $(OBJ)
	$(AR) rcs $@ $^
	$(RANLIB) $@ || true
endif

clean:
	rm -f $(OBJ) $(STATIC)