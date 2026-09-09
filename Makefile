.SUFFIXES:

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

TOPDIR ?= $(CURDIR)
include $(DEVKITARM)/3ds_rules

PLGINFO  := 3DSNuzlockeQOL.plgInfo
SOURCES  := Sources
INCLUDES :=

ARCH     := -march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft
ASFLAGS  := $(ARCH)
LDFLAGS  := -T $(TOPDIR)/3gx.ld $(ARCH) -Os -Wl,--gc-sections,--strip-discarded,--strip-debug
LIBS     := -lctru
LIBDIRS  := $(DEVKITPRO)/libctru

ARTIFACT_DIR := $(TOPDIR)/build
WORK_DIR     := $(ARTIFACT_DIR)/obj
BIN_DIR      := $(ARTIFACT_DIR)/bin
SDMC_DIR     := $(ARTIFACT_DIR)/sdmc
SDMC_PLUGINS := $(SDMC_DIR)/luma/plugins
PACKAGE      := $(ARTIFACT_DIR)/3DSNuzlockeQOL-Azahar.zip
GAMES_DIR    := $(TOPDIR)/Games

# -----------------------------------------------------------------------------
# Top-level build
#
# Every Games/*.mk file is automatically treated as one build target.
# Adding another supported game family only requires adding another .mk file.
# -----------------------------------------------------------------------------
ifeq ($(strip $(INTERNAL_BUILD)),)

GAME_CONFIGS := $(sort $(wildcard $(GAMES_DIR)/*.mk))
GAME_TARGETS := $(basename $(notdir $(GAME_CONFIGS)))

ifeq ($(strip $(GAME_TARGETS)),)
$(error "No game configs found in $(GAMES_DIR)")
endif

.PHONY: all games package clean re $(GAME_TARGETS)

all: games
games: $(GAME_TARGETS)

$(GAME_TARGETS):
	@echo "============================================================"
	@echo "Building $@"
	@echo "============================================================"
	@mkdir -p "$(WORK_DIR)/$@" "$(BIN_DIR)"
	@$(MAKE) --no-print-directory -j1 -C "$(WORK_DIR)/$@" -f "$(TOPDIR)/Makefile" TOPDIR="$(TOPDIR)" INTERNAL_BUILD=1 GAME_CONFIG="$(GAMES_DIR)/$@.mk"

package: games
	@echo "The binaries and sdmc tree are built. On Windows, build.bat creates build/$(notdir $(PACKAGE)) with PowerShell."

clean:
	@echo Cleaning ...
	@rm -rf "$(ARTIFACT_DIR)"

re: clean all

# -----------------------------------------------------------------------------
# One automatically-discovered game build
# -----------------------------------------------------------------------------
else

ifeq ($(strip $(GAME_CONFIG)),)
$(error "INTERNAL_BUILD requires GAME_CONFIG=<path to Games/*.mk>")
endif

include $(GAME_CONFIG)

# Required metadata / memory configuration.
REQUIRED_GAME_VARS := \
	GAME_KEY GAME_NAME GAME_TITLE_IDS \
	EXP_CALLSITE EXP_CODECAVE EXP_BRANCH \
	ITEM_QUANTITY BAG_QUANTITY_SHIFT REFRESH_INTERVAL_NS STARTUP_DELAY_NS \
	ITEM_RARE_CANDY_ID ITEM_RARE_CANDY_POCKET ITEM_RARE_CANDY_SLOTS \
	ITEM_FULL_RESTORE_ID ITEM_FULL_RESTORE_POCKET ITEM_FULL_RESTORE_SLOTS \
	ITEM_MAX_ELIXIR_ID ITEM_MAX_ELIXIR_POCKET ITEM_MAX_ELIXIR_SLOTS \
	ITEM_MAX_REPEL_ID ITEM_MAX_REPEL_POCKET ITEM_MAX_REPEL_SLOTS \
	ITEM_POKE_BALL_ID ITEM_POKE_BALL_POCKET ITEM_POKE_BALL_SLOTS

$(foreach v,$(REQUIRED_GAME_VARS),$(if $(strip $($(v))),,$(error "$(notdir $(GAME_CONFIG)): missing required variable $(v)")))

BUILD  := build/obj/$(GAME_KEY)
TARGET := build/bin/3DSNuzlockeQOL-$(GAME_KEY)

GAME_DEFINES := \
	-DEXP_CALLSITE=$(EXP_CALLSITE) \
	-DEXP_CODECAVE=$(EXP_CODECAVE) \
	-DEXP_BRANCH=$(EXP_BRANCH) \
	-DITEM_QUANTITY=$(ITEM_QUANTITY) \
	-DBAG_QUANTITY_SHIFT=$(BAG_QUANTITY_SHIFT) \
	-DREFRESH_INTERVAL_NS=$(REFRESH_INTERVAL_NS) \
	-DSTARTUP_DELAY_NS=$(STARTUP_DELAY_NS) \
	-DITEM_RARE_CANDY_ID=$(ITEM_RARE_CANDY_ID) \
	-DITEM_RARE_CANDY_POCKET=$(ITEM_RARE_CANDY_POCKET) \
	-DITEM_RARE_CANDY_SLOTS=$(ITEM_RARE_CANDY_SLOTS) \
	-DITEM_FULL_RESTORE_ID=$(ITEM_FULL_RESTORE_ID) \
	-DITEM_FULL_RESTORE_POCKET=$(ITEM_FULL_RESTORE_POCKET) \
	-DITEM_FULL_RESTORE_SLOTS=$(ITEM_FULL_RESTORE_SLOTS) \
	-DITEM_MAX_ELIXIR_ID=$(ITEM_MAX_ELIXIR_ID) \
	-DITEM_MAX_ELIXIR_POCKET=$(ITEM_MAX_ELIXIR_POCKET) \
	-DITEM_MAX_ELIXIR_SLOTS=$(ITEM_MAX_ELIXIR_SLOTS) \
	-DITEM_MAX_REPEL_ID=$(ITEM_MAX_REPEL_ID) \
	-DITEM_MAX_REPEL_POCKET=$(ITEM_MAX_REPEL_POCKET) \
	-DITEM_MAX_REPEL_SLOTS=$(ITEM_MAX_REPEL_SLOTS) \
	-DITEM_POKE_BALL_ID=$(ITEM_POKE_BALL_ID) \
	-DITEM_POKE_BALL_POCKET=$(ITEM_POKE_BALL_POCKET) \
	-DITEM_POKE_BALL_SLOTS=$(ITEM_POKE_BALL_SLOTS)

CFLAGS   = $(ARCH) -Os -mword-relocations -ffunction-sections -fdata-sections -fomit-frame-pointer -D__3DS__ $(GAME_DEFINES) $(GAME_EXTRA_DEFINES) $(INCLUDE)
CXXFLAGS = $(CFLAGS) -std=gnu++17 -fno-rtti -fno-exceptions -fno-threadsafe-statics

export OUTPUT   := $(TOPDIR)/$(TARGET)
export TOPDIR   := $(TOPDIR)
export VPATH    := $(foreach dir,$(SOURCES),$(TOPDIR)/$(dir))
export DEPSDIR  := $(TOPDIR)/$(BUILD)

CFILES          := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(TOPDIR)/$(dir)/*.c)))
CPPFILES        := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(TOPDIR)/$(dir)/*.cpp)))
SFILES          := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(TOPDIR)/$(dir)/*.s)))
export LD       := $(CXX)
export OFILES   := $(CFILES:.c=.o) $(CPPFILES:.cpp=.o) $(SFILES:.s=.o)
export INCLUDE  := $(foreach dir,$(LIBDIRS),-I $(dir)/include) -I $(TOPDIR)/$(BUILD)
export LIBPATHS := $(foreach dir,$(LIBDIRS),-L $(dir)/lib)

DEPENDS := $(OFILES:.o=.d)

.PHONY: build-game install-game

build-game: $(OUTPUT).3gx install-game

$(OUTPUT).3gx: $(OFILES)

install-game: $(OUTPUT).3gx
	@set -e; \
	for title in $(GAME_TITLE_IDS); do \
		mkdir -p "$(SDMC_PLUGINS)/$$title"; \
		cp "$(OUTPUT).3gx" "$(SDMC_PLUGINS)/$$title/3DSNuzlockeQOL-$(GAME_KEY).3gx"; \
	done
	@echo "$(GAME_KEY) - $(GAME_NAME)"
	@echo "  Title IDs: $(GAME_TITLE_IDS)"
	@echo "  Binary:    build/bin/3DSNuzlockeQOL-$(GAME_KEY).3gx"

ifeq ($(shell uname -s),Darwin)
TOOL := $(TOPDIR)/3gxtool
else
TOOL := $(TOPDIR)/3gxtool.exe
endif

%.3gx: %.elf
	@echo creating $(notdir $@)
	@$(TOOL) -s $(word 1,$^) $(TOPDIR)/$(PLGINFO) $@

-include $(DEPENDS)

endif
