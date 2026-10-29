# Repository guide

## Layout

- This repository packages the out-of-tree IT87/IT86 hardware-monitoring driver for fnOS on x86_64. Driver source is fetched from `fnnas/it87`; it is not maintained here.
- `.github/workflows/test_release.yml` owns the driver commit pin, application version, kernel-image matrix, artifact staging, packaging, and optional release.
- `.github/workflows/kernel-build.yml` is the shared container build workflow for both kernel groups; keep compilation, caching, and artifact upload behavior there.
- `package/cmd/main` selects and installs modules; `common` provides logging and cleanup; `build_module_chroot` implements the optional local-build fallback.
- `package/manifest` is a template; descriptions and changelogs reference `[manifest]` keys in `package/i18n/{zh,en,ja-JP}`. Keep build-time placeholders in both the manifest and translations for CI substitution. Keep all three catalogs aligned when changing wizard or runtime messages.
- `app/ui/.gitkep` preserves the UI directory required by packaging. Keep generated modules, source checkouts, and archives out of commits; `.idea/` and `tmp/` contain ignored local state.

## Adding kernel support

Update these locations together:

1. `.github/workflows/test_release.yml`: add the build matrix row and matching artifact download; increment `this_pack_manifest_version` using the existing patch-version sequence.
2. `package/cmd/main`: add the exact release-to-payload mapping in `module_payload_dir`.
3. `package/i18n/zh`, `package/i18n/en`, and `package/i18n/ja-JP`: extend the supported kernel/build list in `manifest.desc`, retaining its HTML formatting. Keep `package/manifest` references intact.
4. `scripts/validate-package.sh`: require the new module directory in `app.tgz`.
5. `readme.md`: extend the supported kernel list.

Use the supplied image and exact `uname -r` for `container_image` and `kernel_ver`. Preserve existing mappings, including historical `uname -v` build-number thresholds. Each new c-build gets an independent artifact; do not reuse another kernel's `.ko`. Keep artifact names, `module_dir`, download paths (`app/app/<module_dir>/`), and runtime payload paths (`${TRIM_APPDEST}/app/<module_dir>`) consistent. Preserve the driver commit pin unless an upstream update is requested.

Kernels without a `.c` build identifier belong to `build_old_kernels`, controlled by the dispatch input of the same name (default `false`). This group is retained for debugging only; omit its kernels and its switch from all three localization catalogs. Keep their artifact downloads and package validation conditional on that input. The `build` matrix contains `.c` kernels and always runs. Packaging must still run when the optional old-kernel job is skipped, and must stop if an enabled build fails.

## Validation

For routine kernel additions, run lightweight checks; do not compile, package, or dispatch CI unless requested. From the repository root with Bash and ShellCheck installed:

```sh
bash scripts/validate-workflows-and-scripts.sh
actionlint .github/workflows/test_release.yml .github/workflows/kernel-build.yml
git -c core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol diff --check
```

The shell validator runs Bash syntax checks, ShellCheck, and translation key/parameter/reference/kernel-list checks; Actionlint separately checks workflow semantics. Verify matrix rows, artifact downloads, validator entries, and runtime mappings agree. Test routing with mocked `uname` and system commands, without installing or loading modules. Report which checks actually ran.

Runtime messages use `[runtime]` catalogs and `i18n_message` / `report_error` helpers. CI copies the rendered catalogs into `app/app/i18n/`; scripts read `${TRIM_APPDEST}/app/i18n` with a repository-relative fallback. Select language using `TRIM_SYS_LANGUAGE`, then `LC_ALL`, `LC_MESSAGES`, or `LANG`; Chinese variants use `zh`, Japanese variants (`ja`, `ja-JP`, `ja_JP.UTF-8`) use `ja-JP`, with English as the fallback for unsupported languages or missing messages. Use ordered `%s` placeholders, and keep human-readable strings out of runtime call sites.

Preserve literal commands, paths, variables, and version identifiers. Include every catalog in CI substitution, runtime staging, translation validation, and package validation when adding a language.

For Japanese wording in `package/i18n/ja-JP`, prefer the [JIPDEC reference](docs/references/J0002146.pdf), especially printed pages 35–36 (PDF pages 49–50), together with its [source record](docs/references/SOURCES.txt). Use its terminology where suitable; other established, well-supported expressions are also acceptable. Keep terminology consistent and technically accurate, and distinguish documented terms from expressions composed for this repository. Keep explanations of these wording choices out of Markdown documentation.

Windows checkouts can contain CRLF or mixed endings; the workflow is committed with CRLF and shell scripts with LF. Inspect `git ls-files --eol`, preserve existing formats, and use temporary LF-normalized copies for shell checks when needed. Avoid repository-wide line-ending rewrites.

Run `bash scripts/validate-package.sh <staged-package-dir>` only when a staged package with `app.tgz` already exists. Set `BUILD_OLD_KERNELS=true` when validating a package built with old kernels; the default only requires `.c` kernel payloads. There is no separate automated test suite.

## Runtime and release conventions

- Pin CI jobs to `ubuntu-24.04` to avoid host OS migrations from `ubuntu-latest`. Use action releases that natively declare the Node 24 runtime or newer; kernel compilation still uses the matrix's fnOS container images.
- Match nearby Bash style: four-space function indentation, quoted paths, and shared helpers. Keep errors visible through `report_error` / `TRIM_TEMP_LOGFILE`.
- The installation wizard defaults to `allow_local_build`; compile locally only when the selected mode permits it and no prebuilt payload exists. Preserve the failed-build lock behavior. Lifecycle scripts modify `/lib/modules`, run `modprobe`/`depmod`, and may mount/chroot; do not execute them directly on a development host for validation.
- Keep `ignore_resource_conflict=1` on module loading, not on `modprobe -r`.
- Releases use manual `workflow_dispatch`; `make_release` defaults to false. Keep the short release-title format separate from archive/asset filenames.

## Commit messages

- Keep the existing title convention (`type(scope): 中文概述`); preserve a title already supplied by the user.
- Write the body in Chinese. Start with a short paragraph summarizing the overall change and its purpose.
- After a blank line, list each changed file using its repository-relative path on a standalone line, followed by bullets in the form `- 改动项 新增/修改/删除：具体改动。`. Choose the applicable action instead of writing all three.
- Separate file groups with blank lines. Describe the actual diff, including relevant versions, image tags, or behavior changes; omit unchanged files and generic claims.

Example body (following the existing title):

```text
新增目标内核的预构建模块支持，同步构建产物与运行时安装映射，并递增应用版本。

.github/workflows/test_release.yml
- 内核构建 修改：新增对应镜像的构建矩阵和产物下载步骤，同步升级应用版本。

package/cmd/main
- 模块映射 修改：为目标内核添加对应预构建模块目录的选择分支。
```
