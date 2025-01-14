APP = linux-perf

CC = gcc

SRCS-y = main.c

CFLAGS ?=
CFLAGS += -march=pentiumpro
CFLAGS += -Wall
CFLAGS += -Werror

LDFLAGS ?=
LDFLAGS += -static

.PHONY: all

all: $(APP)

$(APP): $(SRCS-y) Makefile
	$(CC) $(CFLAGS) $(SRCS-y) -o $@ $(LDFLAGS)

clean:
	rm -f $(APP)
