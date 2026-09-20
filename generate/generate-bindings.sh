#!/usr/bin/env bash
# LLM maintained.
# Generates C# P/Invoke bindings for the vendored sokol headers using
# ClangSharpPInvokeGenerator. Run from anywhere; paths are resolved relative
# to this script. Regenerate after touching sokol/ or when adding a new
# module to MODULES below - see generate/README.md.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SOKOL_DIR="../sokol"
OUT_DIR="../src/SharpSokol/Native"
NAMESPACE="SharpSokol.Native"
LIBRARY="sokol"

# locate the ClangSharpPInvokeGenerator dotnet tool shim (works whether or
# not ~/.dotnet/tools is resolvable via `which` under Git Bash on Windows)
if command -v ClangSharpPInvokeGenerator >/dev/null 2>&1; then
    GEN=ClangSharpPInvokeGenerator
elif [ -f "$HOME/.dotnet/tools/ClangSharpPInvokeGenerator.cmd" ]; then
    GEN="$HOME/.dotnet/tools/ClangSharpPInvokeGenerator.cmd"
else
    echo "error: ClangSharpPInvokeGenerator not found - run: dotnet tool install --global ClangSharpPInvokeGenerator" >&2
    exit 1
fi

mkdir -p "$OUT_DIR"

# columns: class-name | prefix | source-file (relative to this script) | traverse-file (optional, for headers parsed via a shims/*.h wrapper)
MODULES="
Log         slog_       $SOKOL_DIR/sokol_log.h
Gfx         sg_         $SOKOL_DIR/sokol_gfx.h
App         sapp_       $SOKOL_DIR/sokol_app.h
Time        stm_        $SOKOL_DIR/sokol_time.h
Audio       saudio_     $SOKOL_DIR/sokol_audio.h
Fetch       sfetch_     $SOKOL_DIR/sokol_fetch.h
Args        sargs_      $SOKOL_DIR/sokol_args.h
Glue        sglue_      shims/shim_glue.h        $SOKOL_DIR/sokol_glue.h
Color       sg_         shims/shim_color.h       $SOKOL_DIR/util/sokol_color.h
DebugText   sdtx_       shims/shim_debugtext.h   $SOKOL_DIR/util/sokol_debugtext.h
Gl          sgl_        shims/shim_gl.h          $SOKOL_DIR/util/sokol_gl.h
Shape       sshape_     shims/shim_shape.h       $SOKOL_DIR/util/sokol_shape.h
Framebuffer sfb_        shims/shim_framebuffer.h $SOKOL_DIR/util/sokol_framebuffer.h
Letterbox   slbx_       $SOKOL_DIR/util/sokol_letterbox.h
Memtrack    smemtrack_  $SOKOL_DIR/util/sokol_memtrack.h
Cmdbuf      scb_        shims/shim_cmdbuf.h      $SOKOL_DIR/util/sokol_cmdbuf.h
"

while read -r class prefix file traverse; do
    [ -z "$class" ] && continue
    args=(
        -f "$file"
        -x c -std c11
        -I "$SOKOL_DIR"
        -n "$NAMESPACE"
        -m "$class"
        -l "$LIBRARY"
        -p "$prefix"
        -i "${prefix}*"
        -e "_*"
        -o "$OUT_DIR/$class.cs"
        -c codegen=default
        --generate macro-bindings
    )
    if [ -n "$traverse" ]; then
        args+=(-t "$traverse")
    fi
    # helper types (NativeTypeNameAttribute etc.) are shared boilerplate
    # referenced from every module - emit them once, into Log.cs (first
    # and smallest module), instead of duplicating the class per file.
    if [ "$class" = "Log" ]; then
        args+=(--generate helper-types)
    fi
    echo ">> generating $class.cs"
    # the generator exits non-zero (commonly 3) when it only emitted
    # warnings (e.g. an unsupported function-like macro) - treat that as
    # success as long as the output file was actually written; anything
    # else (parse errors, missing output) is a hard failure.
    set +e
    "$GEN" "${args[@]}"
    status=$?
    set -e
    if [ ! -s "$OUT_DIR/$class.cs" ]; then
        echo "error: $class.cs was not generated (generator exit $status)" >&2
        exit 1
    fi
done <<< "$MODULES"

echo "done. Generated files in $OUT_DIR"
