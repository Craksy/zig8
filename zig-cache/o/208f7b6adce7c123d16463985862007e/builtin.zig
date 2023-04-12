const std = @import("std");
/// Zig version. When writing code that supports multiple versions of Zig, prefer
/// feature detection (i.e. with `@hasDecl` or `@hasField`) over version checks.
pub const zig_version = std.SemanticVersion.parse("0.10.1") catch unreachable;
pub const zig_backend = std.builtin.CompilerBackend.stage2_llvm;

pub const output_mode = std.builtin.OutputMode.Exe;
pub const link_mode = std.builtin.LinkMode.Static;
pub const is_test = true;
pub const single_threaded = false;
pub const abi = std.Target.Abi.gnu;
pub const cpu: std.Target.Cpu = .{
    .arch = .x86_64,
    .model = &std.Target.x86.cpu.bdver4,
    .features = std.Target.x86.featureSet(&[_]std.Target.x86.Feature{
        .@"64bit",
        .aes,
        .avx,
        .avx2,
        .bmi,
        .bmi2,
        .branchfusion,
        .cmov,
        .crc32,
        .cx16,
        .cx8,
        .f16c,
        .fast_11bytenop,
        .fast_bextr,
        .fast_movbe,
        .fast_scalar_shift_masks,
        .fma,
        .fma4,
        .fsgsbase,
        .fxsr,
        .lwp,
        .lzcnt,
        .mmx,
        .movbe,
        .mwaitx,
        .nopl,
        .pclmul,
        .popcnt,
        .prfchw,
        .sahf,
        .sbb_dep_breaking,
        .slow_shld,
        .sse,
        .sse2,
        .sse3,
        .sse4_1,
        .sse4_2,
        .sse4a,
        .ssse3,
        .tbm,
        .vzeroupper,
        .x87,
        .xop,
        .xsave,
        .xsaveopt,
    }),
};
pub const os = std.Target.Os{
    .tag = .linux,
    .version_range = .{ .linux = .{
        .range = .{
            .min = .{
                .major = 6,
                .minor = 2,
                .patch = 10,
            },
            .max = .{
                .major = 6,
                .minor = 2,
                .patch = 10,
            },
        },
        .glibc = .{
            .major = 2,
            .minor = 36,
            .patch = 0,
        },
    }},
};
pub const target = std.Target{
    .cpu = cpu,
    .os = os,
    .abi = abi,
    .ofmt = object_format,
};
pub const object_format = std.Target.ObjectFormat.elf;
pub const mode = std.builtin.Mode.Debug;
pub const link_libc = false;
pub const link_libcpp = false;
pub const have_error_return_tracing = true;
pub const valgrind_support = true;
pub const sanitize_thread = false;
pub const position_independent_code = false;
pub const position_independent_executable = false;
pub const strip_debug_info = false;
pub const code_model = std.builtin.CodeModel.default;
pub var test_functions: []std.builtin.TestFn = undefined; // overwritten later
pub const test_io_mode = .blocking;
