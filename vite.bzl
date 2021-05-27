"vite_project rule"

load("@build_bazel_rules_nodejs//:providers.bzl", "DeclarationInfo", "ExternalNpmPackageInfo", "run_node")
load("@build_bazel_rules_nodejs//internal/linker:link_node_modules.bzl", "module_mappings_aspect")

_DEFAULT_VITE = "@npm//vite/bin:vite"

def _vite_project_impl(ctx):
    arguments = ctx.actions.args()
    execution_requirements = {}
    progress_prefix = "Compiling Vite project"

    arguments.add_all(["build"])

    deps_depsets = []
    inputs = ctx.files.srcs[:]
    for dep in ctx.attr.deps:
        # if TsConfigInfo in dep:
        #     deps_depsets.append(dep[TsConfigInfo].deps)
        if ExternalNpmPackageInfo in dep:
            deps_depsets.append(dep[ExternalNpmPackageInfo].sources)
        if DeclarationInfo in dep:
            deps_depsets.append(dep[DeclarationInfo].transitive_declarations)
    inputs.extend(depset(transitive = deps_depsets).to_list())

    outputs = []
    dist_dir = ctx.actions.declare_directory("dist")
    outputs.extend([dist_dir])
    arguments.add_all(["--outDir", dist_dir.path])

    run_node(
        ctx,
        inputs = inputs,
        arguments = [arguments],
        outputs = outputs,
        mnemonic = "ViteProject",
        executable = "vite",
        execution_requirements = execution_requirements,
        progress_message = "%s" % (
            progress_prefix,
        ),
    )

    providers = [
        DefaultInfo(
            files = depset(outputs),
        ),
    ]

    return providers

vite_project = rule(
    implementation = _vite_project_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
        ),
        "deps": attr.label_list(
            providers = [
                [DeclarationInfo],
            ],
            aspects = [module_mappings_aspect],
        ),
        "vite": attr.label(
            default = Label(_DEFAULT_VITE),
            executable = True,
            cfg = "host",
        ),
    },
)
