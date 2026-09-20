# generate/

Regenerates the C# P/Invoke bindings in `../src/SharpSokol/Native/` from the
vendored headers in `../sokol/`.

## Prerequisites

- `dotnet tool install --global ClangSharpPInvokeGenerator`
- Bash (Git Bash on Windows)

## Usage

```
./generate-bindings.sh
```

Run from anywhere; paths are resolved relative to the script. It loops over
the `MODULES` table in `generate-bindings.sh` and runs one
`ClangSharpPInvokeGenerator` invocation per sokol module, writing
`../src/SharpSokol/Native/<Class>.cs`.

## Adding a new module

Add a row to `MODULES` in `generate-bindings.sh`: class name, C prefix,
source header (relative to the script), and an optional shim header (see
`shims/`) if the target header requires `sokol_gfx.h` types to be declared
first.

Type names are **not** prefix-stripped (only method names are, via `-p`) -
this is intentional. Several sokol modules reuse the same suffix (e.g.
`allocator_t`, `range`, `logger_t`) which would otherwise collide once
flattened into the shared `SharpSokol.Native` namespace, and cross-module
references (e.g. `sdtx_context_desc_t.color_format: sg_pixel_format`) need
the referenced type's own module to spell it the same way it's declared
there.

After regenerating, `dotnet build ../src/SharpSokol` must succeed.
