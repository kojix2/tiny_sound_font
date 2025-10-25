CC ?= gcc
AR ?= ar
RANLIB ?= ranlib

# TinySoundFont headers (fetch on demand with curl)
TSF_REF  ?= master
TSF_HEADERS := tsf.h tml.h

# Sources implementing TinySoundFont single-header libs
SRC := tsf.c tml.c

# Detect MSVC by checking 'cl' in CC
IS_MSVC := $(findstring cl,$(CC))

# Output names by toolchain
ifeq ($(IS_MSVC),cl)
  OBJEXT := obj
  LIBEXT := lib
else
  OBJEXT := o
  LIBEXT := a
endif

STATIC := libtsf.$(LIBEXT)
OBJ := $(SRC:.c=.$(OBJEXT))

# Keep flags simple and cross-env friendly
CPPFLAGS ?=
CFLAGS   ?=

ifeq ($(IS_MSVC),cl)
	CPPFLAGS += /I. /D_CRT_SECURE_NO_WARNINGS
  CFLAGS   += /nologo /O2
  COMPILE.c = $(CC) $(CPPFLAGS) $(CFLAGS) /c $< /Fo$@
else
	CPPFLAGS += -I.
  CFLAGS   += -O2 -fPIC -std=c11
  COMPILE.c = $(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@
endif

.PHONY: all clean check-tsf check-assets

# Default target
all: check-tsf check-assets $(STATIC)

# Fetch TinySoundFont headers (curl only; simple and cross-platform)
check-tsf:
	@if [ ! -f "tsf.h" ] || [ ! -f "tml.h" ]; then \
		echo "Downloading TinySoundFont headers ($(TSF_REF)) via curl..."; \
		if ! command -v curl >/dev/null 2>&1; then \
			echo "Error: curl is required to fetch TinySoundFont headers."; \
			exit 1; \
		fi; \
		curl -fsSL -o tsf.h "https://raw.githubusercontent.com/schellingb/TinySoundFont/$(TSF_REF)/tsf.h"; \
		curl -fsSL -o tml.h "https://raw.githubusercontent.com/schellingb/TinySoundFont/$(TSF_REF)/tml.h"; \
	fi

# Fetch example assets used by Crystal examples (minimal)
check-assets:
	@if ! command -v curl >/dev/null 2>&1; then \
		echo "Error: curl is required to fetch TinySoundFont example assets."; \
		exit 1; \
	fi
	@if [ ! -f "florestan-subset.sf2" ]; then \
		echo "Downloading florestan-subset.sf2 ($(TSF_REF)) to ext/..."; \
		curl -fsSL -o florestan-subset.sf2 "https://raw.githubusercontent.com/schellingb/TinySoundFont/$(TSF_REF)/examples/florestan-subset.sf2"; \
	fi
	@if [ ! -f "venture.mid" ]; then \
		echo "Downloading venture.mid ($(TSF_REF)) to ext/..."; \
		curl -fsSL -o venture.mid "https://raw.githubusercontent.com/schellingb/TinySoundFont/$(TSF_REF)/examples/venture.mid"; \
	fi

# Compile rules
%.$(OBJEXT): %.c $(TSF_HEADERS)
	$(COMPILE.c)

# Archive rules
ifeq ($(IS_MSVC),cl)
$(STATIC): $(OBJ)
	lib /nologo /OUT:$@ $(OBJ)
else
$(STATIC): $(OBJ)
	$(AR) rcs $@ $^
	-@$(RANLIB) $@ >/dev/null 2>&1 || true
endif

clean:
	rm -f $(OBJ) $(STATIC)