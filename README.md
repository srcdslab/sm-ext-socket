# SourceMod Socket Extension
This has been forked from [sfPlayer's origin Git repository][socket-git].
Get to the [AlliedModders forum thread][socket-am] for more information.

[socket-git]: http://player.to/gitweb/index.cgi?p=sm-ext-socket.git
[socket-am]: https://forums.alliedmods.net/showthread.php?t=67640

## Building

CI builds Linux and Windows packages (x86 and x86_64) against SourceMod master, 1.12-dev and
1.13.0.7427 with the shared [srcdslab CI][ci-workflows] and [sm-ext-common][].

[ci-workflows]: https://github.com/srcdslab/ci-workflows
[sm-ext-common]: https://github.com/srcdslab/sm-ext-common

To build locally:

1. Clone with submodules (`git clone --recursive`, or `git submodule update --init`).
2. Build the static [Boost][] `thread` and `system` libraries (see `.github/workflows/ci.yml`
   for the exact `b2` commands) and lay them out as `boost/boost-<platform>/include/boost` and
   `boost/boost-<platform>/lib/<arch>/`, with `<platform>` `linux` or `windows` and `<arch>`
   `x86` or `x86_64`.
3. Build with [AMBuild][]:
   ```sh
   mkdir build && cd build
   python ../sm-ext-common/configure.py --ext-root .. --sdks css --targets x86,x86_64 \
     --sm-path <sourcemod> --mms-path <metamod-source> --hl2sdk-root <hl2sdk folder> \
     --hl2sdk-manifests-path <hl2sdk-manifests> --enable-optimize
   ambuild
   ```
   The package is written to `build/package`.

[Boost]: https://www.boost.org/
[AMBuild]: https://github.com/alliedmodders/ambuild
