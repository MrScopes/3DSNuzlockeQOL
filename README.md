# 3DSNuzlockeQOL

Vibe coded lightweight native 3GX plugin for the Nintendo 3DS Pokémon games:

- Pokémon X / Y
- Pokémon Omega Ruby / Alpha Sapphire
- Pokémon Sun / Moon
- Pokémon Ultra Sun / Ultra Moon

The plugin provides:

- Battle EXP reduced to the game's minimum of 1 EXP
- 999 Rare Candies
- 999 Max Repels
- 999 Full Restores
- 999 Max Elixirs

# Installation
Azahar:
- Make sure the 3GX plugin loader is enabled in Azahar.
- **(Emulation > Configure > System > Enable 3GX plugin loader)**
- Download the source, run azahar.bat. This will automatically place it in your AppData Azahar folder.

Luma:
- REAL 3DS HARDWARE HAS NOT BEEN TESTED YET!
- similar to Azahar since Azahar uses the same 3gx system. 
- use the matching game-family plugin from `build/bin`
- copy it to `SD:/luma/plugins/<TITLE_ID>/`

For example, Ultra Sun / Ultra Moon uses:

```text
SD:/luma/plugins/<TITLE_ID>/3DSNuzlockeQOL-USUM.3gx
```

## Compatibility

The plugin is intended for the latest game updates/patches.
It probably won't work on outdated versions.

It has been tested with Azahar using updated copies of the games:
- X
- Alpha Sapphire
- Sun
- Ultra Sun

NO TESTING has been done yet on an official 3DS, sorry

Each game family has its own compiled plugin because the executable and RAM addresses differ between generations:

```text
3DSNuzlockeQOL-XY.3gx
3DSNuzlockeQOL-ORAS.3gx
3DSNuzlockeQOL-SM.3gx
3DSNuzlockeQOL-USUM.3gx
```

The build system automatically places the correct variant into the appropriate title-ID folders and keeps the game-family tag in the filename (for example, `3DSNuzlockeQOL-USUM.3gx`).

## Requirements

Building requires devkitPro with the Nintendo 3DS development packages installed.

### Windows

Download the official devkitPro installer:

https://github.com/devkitPro/installer/releases

devkitPro's setup documentation is available here:

https://devkitpro.org/wiki/Getting_Started

During installation, make sure the Nintendo 3DS development tools are installed.

The relevant devkitPro package group is:

```text
3ds-dev
```

The project expects the default Windows installation location:

```text
C:\devkitPro
```

and uses:

```text
C:\devkitPro\devkitARM
C:\devkitPro\msys2
```

The build requires devkitARM, libctru, and the normal 3DS development tools supplied by devkitPro.

If using devkitPro's pacman environment manually, the 3DS package group can be installed with:

```bash
pacman -S 3ds-dev
```

devkitPro distributes its toolchains and console development packages through pacman. The official `3ds-dev` group provides the tools needed for Nintendo 3DS development. 

## Building

On Windows, simply run:

```text
build.bat
```

After a successful build, the important files are under:

```text
build\
├── bin\
│   ├── 3DSNuzlockeQOL-XY.3gx
│   ├── 3DSNuzlockeQOL-ORAS.3gx
│   ├── 3DSNuzlockeQOL-SM.3gx
│   └── 3DSNuzlockeQOL-USUM.3gx
│
├── sdmc\
│   └── luma\
│       └── plugins\
│
└── 3DSNuzlockeQOL-Azahar.zip
```

The plugin folders under `build\sdmc\luma\plugins` are generated automatically for all supported game title IDs.

## Project structure

```text
3DSNuzlockeQOL\
├── Games\
│   ├── XY.mk
│   ├── ORAS.mk
│   ├── SM.mk
│   └── USUM.mk
│
├── Sources\
│   ├── Main.cpp
│   └── 3gx_crt0.s
│
├── build.bat
├── azahar.bat
├── Makefile
├── 3gx.ld
├── 3gxtool.exe
└── 3DSNuzlockeQOL.plgInfo
```

The four files under `Games` contain the game-specific addresses and configuration.

`Sources/Main.cpp` contains the shared plugin implementation.

The build system compiles `Main.cpp` separately for each game family, producing four different binaries rather than detecting the game at runtime.

# Credits
https://github.com/biometrix76/AlolanCTRPluginFramework

https://github.com/biometrix76/Gen6CTRPluginFramework

https://github.com/samaBR85/Gen6CTRPFrameworkOverhauled

These were very useful in finding the memory addresses and offsets for bags, and finding out how EXP can be multiplied.

# AI Disclosure
The development of this program was heavily assisted by ChatGPT. My C experience is limited.