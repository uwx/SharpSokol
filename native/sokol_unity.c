// LLM maintained.
// Single translation unit building the implementation of every bound sokol
// header (core + safe utils, see generate/generate-bindings.sh for the list).
// Produces a linkable native library, not a standalone app: SOKOL_NO_ENTRY
// means sokol_app.h doesn't hijack main() - consumers call sokol_main()
// themselves.
//
// The active sokol_gfx.h backend is selected purely via a compiler -D flag
// (SOKOL_D3D11, SOKOL_GLCORE, SOKOL_METAL, SOKOL_GLES3, SOKOL_VULKAN or
// SOKOL_WGPU) passed in by .github/workflows/build-native.yml - this file
// never hardcodes a backend, so one source file produces every variant.
//
// On Windows, also pass -DSOKOL_DLL when building a .dll so the public API
// gets dllexport'd; omit it for the wasm static-lib build.

#if !defined(__ANDROID__)
#define SOKOL_NO_ENTRY
#endif
#if defined(_WIN32)
#define SOKOL_WIN32_FORCE_MAIN
#endif

#define SOKOL_IMPL

#include "sokol_log.h"
#include "sokol_gfx.h"
#include "sokol_app.h"
#include "sokol_time.h"
#include "sokol_audio.h"
#include "sokol_fetch.h"
#include "sokol_args.h"
#include "sokol_glue.h"

#include "util/sokol_color.h"
#include "util/sokol_debugtext.h"
#include "util/sokol_gl.h"
#include "util/sokol_shape.h"
#include "util/sokol_framebuffer.h"
#include "util/sokol_letterbox.h"
#include "util/sokol_memtrack.h"
#include "util/sokol_cmdbuf.h"
