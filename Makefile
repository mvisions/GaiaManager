CELL_MK_DIR = $(CELL_SDK)/samples/mk
include $(CELL_MK_DIR)/sdk.makedef.mk

PPU_SRCS = main.c at3plus.c graphics.c waveout.c syscall8.c $(VPSHADER_PPU_OBJS) $(FPSHADER_PPU_OBJS)
PPU_TARGET = open_manager.elf

PPU_LDLIBS = -lfont_stub -lfontFT_stub -lfreetype_stub -lpthread -latrac3plus_stub -lmixer -laudio_stub -lftp  -lnet_stub -lnetctl_stub -lpngdec_stub -lm -ldbgfont_gcm -lgcm_cmd -lgcm_sys_stub -lio_stub -lsysmodule_stub -lsysutil_stub -lfs_stub
PPU_CPPFLAGS += -D'FOLDER_NAME="$(FOLDER_NAME)"'

PPU_INCDIRS += -I$(CELL_SDK)/target/ppu/include/sysutil

VPSHADER_SRCS = vpshader.cg vpshader2.cg
FPSHADER_SRCS = fpshader.cg fpshader2.cg

VPSHADER_PPU_OBJS = $(patsubst %.cg, $(OBJS_DIR)/%.ppu.o, $(VPSHADER_SRCS))
FPSHADER_PPU_OBJS = $(patsubst %.cg, $(OBJS_DIR)/%.ppu.o, $(FPSHADER_SRCS))

PACKAGE_NAME = $(shell sed -n 's/^Product_ID[[:space:]]*=[[:space:]]*//p' openmanager.conf)
FOLDER_NAME = $(shell echo $(PACKAGE_NAME) | sed -n 's/^[[:alnum:]]*-\([[:alnum:]]*\)_.*/\1/p')

PKG_TARGET = $(PACKAGE_NAME).pkg

CLEANFILES = PS3_GAME/USRDIR/EBOOT.BIN $(OBJS_DIR)/$(PPU_TARGET) readme.aux readme.log readme.out readme.tex

ifneq (exists, $(shell [ -f at3plus.c -a -f at3plus.h -a -f waveout.c -a -f waveout.h ] && echo exists) )
PPU_INCDIRS += -I$(CELL_SDK)/samples/sdk/codec/atrac3plus_simple

at3plus.c: $(CELL_SDK)/samples/sdk/codec/atrac3plus_simple/at3plus.c
	cp $< $@
waveout.c: $(CELL_SDK)/samples/sdk/codec/atrac3plus_simple/waveout.c
	cp $< $@
endif

include $(CELL_MK_DIR)/sdk.target.mk

PPU_OBJS += $(VPSHADER_PPU_OBJS) $(FPSHADER_PPU_OBJS)

all : EBOOT.BIN $(PKG_TARGET) docs
docs : readme.html readme.pdf

$(VPSHADER_PPU_OBJS): $(OBJS_DIR)/%.ppu.o : %.vpo
	@mkdir -p $(dir $(@))
	$(PPU_OBJCOPY)  -I binary -O elf64-powerpc-celloslv2 -B powerpc $< $@

$(FPSHADER_PPU_OBJS): $(OBJS_DIR)/%.ppu.o : %.fpo
	@mkdir -p $(dir $(@))
	$(PPU_OBJCOPY)  -I binary -O elf64-powerpc-celloslv2 -B powerpc $< $@

$(OBJS_DIR)/$(PPU_TARGET): $(PPU_TARGET)
	@mkdir -p $(dir $(@))
	$(PPU_STRIP) -s $< -o $@
	@echo setting ftp home path to /
	sed -i 's:\x00/dev_hdd0/game/%s\x00:\x00/\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00:' $@

PS3_GAME/USRDIR/EBOOT.BIN: $(OBJS_DIR)/$(PPU_TARGET)
	@mkdir -p $(dir $(@))
	$(MAKE_FSELF_NPDRM) $< $@

$(PKG_TARGET): openmanager.conf PS3_GAME/USRDIR/EBOOT.BIN
	@echo generating package.
	$(MAKE_PACKAGE_NPDRM) openmanager.conf PS3_GAME/

EBOOT.BIN: $(OBJS_DIR)/$(PPU_TARGET)	# to use in /app_home/PS3_GAME
	@echo generating EBOOT.BIN to use in /app_home/PS3_GAME
	$(MAKE_FSELF) $< $@

readme.html: readme.mkd
	maruku -o $@ $<

readme.pdf: readme.mkd
	maruku --pdf -o $@ $<
