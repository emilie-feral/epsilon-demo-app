# Configuration
Q ?= @
PLATFORM ?= simulator

# Verbose
ifeq ("$(origin V)", "command line")
  ifeq ($(V),1)
    Q=
  endif
endif

# Host detection
ifeq ($(PLATFORM),simulator)
  ifeq ($(OS),Windows_NT)
    HOST = windows
  else
    uname_s := $(shell uname -s)
    ifeq ($(uname_s),Darwin)
      HOST = macos
    else ifeq ($(uname_s),Linux)
      HOST = linux
    else
      $(error Your OS wasn't recognized, please manually define HOST. For instance, 'make HOST=windows' 'make HOST=linux' 'make HOST=macos')
    endif
  endif
endif

ifeq ($(PLATFORM),device)
  CC = arm-none-eabi-gcc
  LINK_GC = 1
  LTO = 1
else
  SIMULATOR_PATH =
  ifeq ($(HOST),windows)
    ifeq ($(OS),Windows_NT)
      MINGW_TOOLCHAIN_PREFIX=
    else
      MINGW_TOOLCHAIN_PREFIX=x86_64-w64-mingw32-
    endif
    CC = $(MINGW_TOOLCHAIN_PREFIX)gcc
    GDB = $(MINGW_TOOLCHAIN_PREFIX)gdb --args
    EXE = exe
  else ifeq ($(HOST),linux)
    CC = gcc
    GDB = gdb --args
    EXE = bin
  else
    CC = clang
    GDB = lldb --
    EXE = app
    SIMULATOR_PATH = /Contents/MacOS/Epsilon
  endif
  LINK_GC = 0
  LTO = 0
  SIMULATOR ?= epsilon_simulators/$(HOST)/epsilon.$(EXE)$(SIMULATOR_PATH)
endif

NWLINK = npx --yes -- nwlink@0.0.17
BUILD_DIR = output/$(PLATFORM)

define object_for
$(addprefix $(BUILD_DIR)/,$(addsuffix .o,$(basename $(1))))
endef

src = $(addprefix src/,\
  main.c \
)

CFLAGS = -std=c99
CFLAGS += -Os -Wall
CFLAGS += -ggdb
ifeq ($(PLATFORM),device)
CFLAGS += $(shell $(NWLINK) eadk-cflags)
LDFLAGS = -Wl,--relocatable
LDFLAGS += -nostartfiles
LDFLAGS += --specs=nano.specs
CFLAGS += -DPLATFORM_DEVICE=1
# LDFLAGS += --specs=nosys.specs # Alternatively, use full-fledged newlib
else
# Only keep the header path from the eadk-cflags provided by nwlink
# CFLAGS = $(shell $(NWLINK) eadk-cflags | sed -n -e 's/.*\(-I[^ ]*\).*/\1/p')
CFLAGS = -Iinclude/
LDFLAGS += -shared -undefined dynamic_lookup
endif

ifeq ($(LINK_GC),1)
CFLAGS += -fdata-sections -ffunction-sections
LDFLAGS += -Wl,-e,main -Wl,-u,eadk_app_name -Wl,-u,eadk_app_icon -Wl,-u,eadk_api_level
LDFLAGS += -Wl,--gc-sections
endif

ifeq ($(LTO),1)
CFLAGS += -flto -fno-fat-lto-objects
CFLAGS += -fwhole-program
CFLAGS += -fvisibility=internal
LDFLAGS += -flinker-output=nolto-rel
endif

ifeq ($(PLATFORM),device)

.PHONY: build
build: $(BUILD_DIR)/app.nwa

.PHONY: check
check: $(BUILD_DIR)/app.bin

.PHONY: run
run: $(BUILD_DIR)/app.nwa src/input.txt
	@echo "INSTALL $<"
	$(Q) $(NWLINK) install-nwa --external-data src/input.txt $<

$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.nwa src/input.txt
	@echo "BIN     $@"
	$(Q) $(NWLINK) nwa-bin --external-data src/input.txt $< $@

$(BUILD_DIR)/%.elf: $(BUILD_DIR)/%.nwa src/input.txt
	@echo "ELF     $@"
	$(Q) $(NWLINK) nwa-elf --external-data src/input.txt $< $@

$(BUILD_DIR)/app.nwa: $(call object_for,$(src)) $(BUILD_DIR)/icon.o
	@echo "LD      $@"
	$(Q) $(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@

else

$(SIMULATOR):
	@echo "UNZIP   $<"
	$(Q) unzip epsilon_simulators.zip
.PHONY: build
build: $(BUILD_DIR)/app.nws

.PHONY: run
run: $(BUILD_DIR)/app.nws $(SIMULATOR) src/input.txt
	@echo "RUN     $<"
	$(Q) $(SIMULATOR) --nwb $< --nwb-external-data $(word 3,$^)

.PHONY: debug
debug: $(BUILD_DIR)/app.nws $(SIMULATOR) src/input.txt
	@echo "DEBUG   $<"
	$(Q) $(GDB) $(SIMULATOR) --nwb $< --nwb-external-data $(word 3,$^)

$(BUILD_DIR)/app.nws: $(call object_for,$(src))
	@echo "LD      $@"
	$(Q) $(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@

endif

$(addprefix $(BUILD_DIR)/,%.o): %.c | $(BUILD_DIR)
	@echo "CC      $^"
	$(Q) $(CC) $(CFLAGS) -c $^ -o $@

$(BUILD_DIR)/icon.o: src/icon.png
	@echo "ICON    $<"
	$(Q) $(NWLINK) png-icon-o $< $@

.PRECIOUS: $(BUILD_DIR)
$(BUILD_DIR):
	$(Q) mkdir -p $@/src

.PHONY: clean
clean:
	@echo "CLEAN"
	$(Q) rm -rf $(BUILD_DIR)
