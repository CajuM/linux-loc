CC = gcc

CFLAGS ?=
CFLAGS += -march=pentiumpro
CFLAGS += -Wall
CFLAGS += -Werror

LDFLAGS ?=
LDFLAGS += -static

.PHONY: all

all: linux-perf-tx linux-perf-rx

linux-perf-tx: linux-perf-tx.c common.c Makefile
	$(CC) $(CFLAGS) linux-perf-tx.c common.c -o $@ $(LDFLAGS)

linux-perf-rx: linux-perf-rx.c Makefile
	$(CC) $(CFLAGS) linux-perf-rx.c common.c -o $@ $(LDFLAGS)

clean:
	rm -f $(APP)
