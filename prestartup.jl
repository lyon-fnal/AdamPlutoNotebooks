using Pkg
@info "Instantiate"
Pkg.instantiate()


Pkg.add("PackageCompiler")
using PackageCompiler

@info "Compiling"
proj = Pkg.API.project()
pkgs = Symbol.(keys(proj.dependencies))
@info "Using packages $pkgs"
# See https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html for cpu_target options.
#         core2 is very generic
create_sysimage(pkgs, precompile_statements_file="./precompile.jl", cpu_target="core2", replace_default=true)