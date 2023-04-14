CFLAGS := -std=c99 -Wall -O2
# Set SSE2 to 'yes' if compiling for an arch that supports it (i.e. x86)
SSE2   := 

TARGET ?= $(shell uname -s 2>/dev/null || echo unknown)
override TARGET := $(shell echo $(TARGET) | tr A-Z a-z)

# Do make a favour and just hard code your JVM home dir here
JAVA_HOME := /Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home

ifeq ($(TARGET), darwin)
	DYLIB     := dylib
	LDFLAGS	  := -dynamiclib -Wl,-undefined -Wl,dynamic_lookup -Wl,-single_module
#	The include paths below _should_ 
	CFLAGS    += -I $(JAVA_HOME)/include -I $(JAVA_HOME)/include/$(TARGET)
else
	DYLIB     := so
	LDFLAGS   := -shared
ifneq ($(TARGET), android)
	CFLAGS    += -fPIC -I $(JAVA_HOME)/include -I $(JAVA_HOME)/include/$(TARGET)
endif
endif

CFLAGS += -DHAVE_CONFIG_H -I src/main/include

SRC := $(wildcard src/main/c/*.c)
OBJ  = $(patsubst src/main/c/%.c,$(OBJ_DIR)/%.o,$(SRC))

ifeq ($(TARGET), android)
	CC      := arm-linux-androideabi-gcc
	SYSROOT := $(NDK_ROOT)/platforms/android-9/arch-arm/
	CFLAGS  += --sysroot=$(SYSROOT)
	LDFLAGS += -lc -Wl,--fix-cortex-a8 --sysroot=$(SYSROOT)
	SSE2    :=
endif

SRC     := $(filter-out $(if $(SSE2),%-nosse.c,%-sse.c),$(SRC))
OBJ_DIR := target/obj
LIB     := target/libscrypt.$(DYLIB)

all: $(LIB)

clean:
	$(RM) $(LIB) $(OBJ)

$(LIB): $(OBJ)
	$(CC) $(LDFLAGS) -o $@ $^

$(OBJ): | $(OBJ_DIR)

$(OBJ_DIR):
	@mkdir -p $@

$(OBJ_DIR)/%.o : src/main/c/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: all clean
