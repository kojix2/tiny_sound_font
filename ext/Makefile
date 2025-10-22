CC ?= gcc
AR ?= ar
RANLIB ?= ranlib
CFLAGS ?= -O3 -std=c11 -fPIC -I. -ITinySoundFont
SRC ?= tsf.c tml.c
OBJ := $(SRC:.c=.o)
STATIC := libtsf.a

.PHONY: all clean

all: $(STATIC)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(STATIC): $(OBJ)
	$(AR) rcs $@ $^
	$(RANLIB) $@ || true

clean:
	rm -f $(OBJ) $(STATIC)