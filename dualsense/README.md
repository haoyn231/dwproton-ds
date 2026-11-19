# DWProton DS 构建记录

## 版本和来源

此分支针对 USB DualSense 的设备标识、设备容器、音频端点、FAudio / XAudio2 路由及音频设备热插拔行为移植补丁。它不向没有原生适配的游戏添加手柄音效，也不保证蓝牙功能。

| 内容 | 来源 |
| --- | --- |
| DWProton 11.0-14 基础 | [`8b178c8870a68f5012ee4a1d82078fa5a7b3a814`](https://github.com/dawn-winery/dwproton-mirror/commit/8b178c8870a68f5012ee4a1d82078fa5a7b3a814) |
| 未修改的发行包 | [DWProton 11.0-14 Release](https://github.com/dawn-winery/dwproton-mirror/releases/tag/dwproton-11.0-14) |
| Wine 基础 | `b585905ec92032840e924e4e2a88382523e92ed3` |
| 移植后的 Wine | [`a8efbde13edc226e02866b9c20cea90f29bad136`](https://github.com/haoyn231/wine-dwproton-ds/commit/a8efbde13edc226e02866b9c20cea90f29bad136) |
| DualSense 补丁集 | [`xzn/proton-ds5-haptic@5d8b4951c919d67d157645ae44ba3c2f45dbabaf`](https://github.com/xzn/proton-ds5-haptic/tree/5d8b4951c919d67d157645ae44ba3c2f45dbabaf) |
| 构建 SDK | `registry.gitlab.steamos.cloud/proton/steamrt4/sdk/x86_64:4.0.20260714.251823-0` |

原始补丁保存在 [`upstream-patches/`](upstream-patches/)，保留邮件格式中的作者署名（JS Deck 等）。编号 0001–0012 均参与了移植，部分冲突经过手工合并；最终结果以 Wine 提交为准。感谢 Wine、FAudio、Valve、Dawn Winery、CachyOS、Proton-EM、xzn 和所有原始贡献者。

## 发布包的实际组成

首次发布是**模块替换构建**：保留原版发行包的其余文件，对两个架构分别替换 `hidclass.sys`、`winebus.sys`、`mmdevapi.dll`、`setupapi.dll`、`winepulse.drv`、`xaudio2_7.dll` 和 Unix `winepulse.so`，共 14 个文件。FAudio 修改静态编入 XAudio2。没有替换 `winebus.so`；Winebus 源码不在本次补丁修改范围内。

打包时修改 runner 名称与 `version`，清除 `__pycache__`，保留原始许可证和默认 Wine 前缀模板。不会包含本机游戏前缀、用户配置或诊断日志。Release 中 `BUILD-MANIFEST.json` 记录原始和替换模块的 SHA-256。

完整 `make redist` 尚未成功：遇到过第三方补丁重复、可选 DXVK 扩展 / Meson 配置问题、Kaldi / OpenFST 错误和 GCC 14 编译 FFmpeg 时的内部错误。因此本项目没有声称已有可复现的干净全量构建或自动构建流水线。

## 获取源码

```sh
git clone --branch feat https://github.com/haoyn231/dwproton-ds.git
cd dwproton-ds
git submodule update --init --recursive
```

GitHub 自动生成的主仓库源码压缩包不包含子模块。修改后的完整 Wine 保存在单独的公开仓库。Release 另附 `dwproton-11.0-14-ds-wine-source.tar.xz`，保存本次编译实际使用的 `build/src-wine`，包括生成的源码和发行构建阶段的附加变化；同时提供 `wine-build-tree.patch`，记录它与已提交 Wine 源码之间的差异。

未重编译组件的来源由上游 DWProton 11.0-14 标签、其 `.gitmodules`、各子模块固定提交及上游发行包说明确定。`upstream-submodules.txt` 保存该基础提交的子模块清单，不能把当前工作目录中可能用于构建试验的其他子模块版本当作原始发行包的版本。

## 已成功的增量构建路径

在已经完成源码生成和两套 Wine `configure` 的 Proton 构建目录中：

```sh
./dualsense/rebuild-modules.sh /absolute/path/to/build
```

脚本在上述 SDK 内对 `obj-wine-i386` 和 `obj-wine-x86_64` 顺序编译六个模块目录，不运行全量 redist，也不安装到用户 runner。它需要现成的配置目录、依赖和编译工具；不能把它当作从空目录开始的一键构建脚本。`configure-i386.json` 和 `configure-x86_64.json` 保存实际 configure 参数，使用 `$BUILD` / `$SOURCE` 代替本机路径。

上游的准备入口是 `configure.sh --build-name=dwproton-ds --container-engine=podman --enable-ccache --without-tts`；本次构建的 `HOST_CFLAGS` 为 `-O1 -march=nocona -mtune=core-avx2`。构建目录的生成 Makefile 和依赖安装目录仍需正确准备；具体规则见根目录 `Makefile.in`。源码快照、实际配置和补丁用于后续继续修复干净构建。

## 验证范围与限制

- 两个架构的目标模块编译成功，替换文件的哈希和架构已检查。
- 发行 runner 的 `wine --version` 可执行，返回 `wine-11.0 (CachyOS)`。
- 未完成本次 runner 的游戏内功能回归或长时间稳定性验证。初次发布标记为 prerelease。
- [补丁集作者的已知问题](https://github.com/xzn/proton-ds5-haptic/blob/5d8b4951c919d67d157645ae44ba3c2f45dbabaf/readme.md)：同一 Wine 前缀 / wineserver 下多个进程同时使用音频时，音频设备热插拔可能异常。
- 不承诺修复 GE-Proton 的崩溃，也不承诺特定游戏、手柄固件或音频配置必然可用。

## 许可

保留上游 [`LICENSE`](../LICENSE)、[`LICENSE.proton`](../LICENSE.proton)、[`dist.LICENSE`](../dist.LICENSE) 及发行包内许可证；Wine 的 LGPL 文本位于 Wine 源码的 `COPYING.LIB`，FAudio 等组件遵循各自源码文件和许可证。本仓库新增的说明与构建辅助脚本按 `LICENSE.proton` 中的 BSD 3-Clause 条款提供，不改变任何上游组件的许可。
