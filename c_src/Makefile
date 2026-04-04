ERL ?= erl
BASEDIR=$(CURDIR)
PRIVDIR=./priv

NIF_DIR=c_src
NIF_ENV=c_src/env.mk

NIF_SOURCES=$(NIF_DIR)/localize_phone_number_nif.cpp
NIF_OBJS=$(NIF_DIR)/localize_phone_number_nif.o
NIF_SO=$(PRIVDIR)/localize_phone_number_nif.so

UNAME_SYS := $(shell uname -s)
UNAME_ARCH := $(shell uname -p)

ifeq ($(UNAME_SYS), Darwin)
	ifeq ($(UNAME_ARCH), arm)
		CXX ?= c++
		CXXFLAGS = -O3 -std=c++17 -arch arm64 -Wall
		LDFLAGS = -arch arm64 -flat_namespace -undefined dynamic_lookup
	else
		CXX ?= c++
		CXXFLAGS = -O3 -std=c++17 -arch x86_64 -Wall
		LDFLAGS = -arch x86_64 -flat_namespace -undefined dynamic_lookup
	endif
else ifeq ($(UNAME_SYS), FreeBSD)
	CXX ?= c++
	CXXFLAGS ?= -O3 -std=c++17 -finline-functions -Wall
else ifeq ($(UNAME_SYS), Linux)
	CXX ?= g++
	CXXFLAGS ?= -O3 -std=c++17 -finline-functions -Wall
endif

CXXFLAGS += -fPIC -I$(ERTS_INCLUDE_DIR) -I$(ERL_INTERFACE_INCLUDE_DIR)

# On OTP 23 and later, liberl_interface.a doesn't exist and
# isn't required
ifneq ("$(wildcard $(ERL_INTERFACE_LIB_DIR)/liberl_interface.a)","")
    LDLIBS += -L$(ERL_INTERFACE_LIB_DIR) -lerl_interface -lei
else
    LDLIBS += -L$(ERL_INTERFACE_LIB_DIR) -lei
endif

LDFLAGS += -shared

# ── libphonenumber detection ────────────────────────────────────
# libphonenumber does not ship a .pc file so we detect via Homebrew
# or system paths.

ifeq ($(UNAME_SYS), Darwin)
  HOMEBREW_PN := $(shell [ -d /opt/homebrew/opt/libphonenumber ] && echo /opt/homebrew/opt/libphonenumber || \
                         ([ -d /usr/local/opt/libphonenumber ] && echo /usr/local/opt/libphonenumber || echo ""))
  ifneq ($(HOMEBREW_PN),)
    PHONENUMBER_CFLAGS = -I$(HOMEBREW_PN)/include
    PHONENUMBER_LIBS = -L$(HOMEBREW_PN)/lib -lphonenumber
  endif
endif

# Fallback: try pkg-config (some Linux distros provide it)
ifeq ($(PHONENUMBER_LIBS),)
  PHONENUMBER_CFLAGS = $(shell pkg-config --cflags libphonenumber 2>/dev/null)
  PHONENUMBER_LIBS = $(shell pkg-config --libs libphonenumber 2>/dev/null)
endif

# Last resort: assume system paths
ifeq ($(PHONENUMBER_LIBS),)
  PHONENUMBER_CFLAGS =
  PHONENUMBER_LIBS = -lphonenumber
endif

# ── protobuf detection (required by libphonenumber) ─────────────
PROTOBUF_CFLAGS = $(shell pkg-config --cflags protobuf 2>/dev/null)
PROTOBUF_LIBS = $(shell pkg-config --libs protobuf 2>/dev/null)

ifeq ($(PROTOBUF_LIBS),)
  ifeq ($(UNAME_SYS), Darwin)
    HOMEBREW_PB := $(shell [ -d /opt/homebrew/opt/protobuf ] && echo /opt/homebrew/opt/protobuf || \
                           ([ -d /usr/local/opt/protobuf ] && echo /usr/local/opt/protobuf || echo ""))
    ifneq ($(HOMEBREW_PB),)
      PROTOBUF_CFLAGS = -I$(HOMEBREW_PB)/include
      PROTOBUF_LIBS = -L$(HOMEBREW_PB)/lib -lprotobuf
    endif
  endif
endif

ifeq ($(PROTOBUF_LIBS),)
  PROTOBUF_LIBS = -lprotobuf
endif

# ── abseil detection (required by protobuf 22+) ─────────────────
ABSEIL_CFLAGS = $(shell pkg-config --cflags absl_strings 2>/dev/null)
ABSEIL_LIBS = $(shell pkg-config --libs absl_strings 2>/dev/null)

ifeq ($(ABSEIL_LIBS),)
  ifeq ($(UNAME_SYS), Darwin)
    HOMEBREW_ABSL := $(shell [ -d /opt/homebrew/opt/abseil ] && echo /opt/homebrew/opt/abseil || \
                             ([ -d /usr/local/opt/abseil ] && echo /usr/local/opt/abseil || echo ""))
    ifneq ($(HOMEBREW_ABSL),)
      ABSEIL_CFLAGS = -I$(HOMEBREW_ABSL)/include
      ABSEIL_LIBS = -L$(HOMEBREW_ABSL)/lib -labsl_strings -labsl_strings_internal \
                    -labsl_int128 -labsl_base -labsl_spinlock_wait \
                    -labsl_throw_delegate -labsl_raw_logging_internal -labsl_log_severity
    endif
  endif
endif

# ── Aggregate flags ─────────────────────────────────────────────
ALL_CFLAGS = $(PHONENUMBER_CFLAGS) $(PROTOBUF_CFLAGS) $(ABSEIL_CFLAGS)
ALL_LIBS = $(PHONENUMBER_LIBS) $(PROTOBUF_LIBS) $(ABSEIL_LIBS) -lstdc++

all: $(NIF_ENV) $(NIF_SO)

clean:
	@rm -rf $(NIF_SO) $(NIF_OBJS)

distclean: clean
	@rm -rf $(NIF_ENV)

$(NIF_SO): $(NIF_OBJS)
	@mkdir -p $(PRIVDIR)
	$(CXX) $(NIF_OBJS) $(LDFLAGS) $(LDLIBS) $(ALL_LIBS) -o $(NIF_SO)

%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $(ALL_CFLAGS) $< -o $@

$(NIF_ENV):
	@$(ERL) -eval "file:write_file(\"$(NIF_ENV)\", \
		io_lib:format( \
		\"ERTS_INCLUDE_DIR ?= ~s/erts-~s/include/~n\" \
		\"ERL_INTERFACE_INCLUDE_DIR ?= ~s~n\" \
		\"ERL_INTERFACE_LIB_DIR ?= ~s~n\", \
		[code:root_dir(), erlang:system_info(version), \
		code:lib_dir(erl_interface, include), \
		code:lib_dir(erl_interface, lib)])), \
		halt()."

-include $(NIF_ENV)
