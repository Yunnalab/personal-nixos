# nixos 主机配置

此目录只描述当前这台电脑，不是可直接复制到其他机器的通用模块。

## 迁移检查清单

- 运行 `nixos-generate-config --show-hardware-config`，用新机器生成的内容替换 `hardware-configuration.nix`。
- 检查 `boot.nix` 中的 Windows EFI 分区 UUID；没有 Windows 时删除 `extraEntries`。
- 检查 `nvidia.nix` 的 `intelBusId` 和 `nvidiaBusId`；没有 NVIDIA 时不要导入该文件。
- 检查 `hardware-tweaks.nix` 的 ASUS 键盘 LED 路径；非 ASUS 设备应删除键盘背光规则。
- 检查 `power.nix` 的 CPU 和电源策略；非 Intel 设备应删除或重写 Intel 专属调优。
- 检查 `networking.nix` 中的主机名、SSH 和开放端口，再决定是否启用。

通用系统功能放在仓库顶层 `modules/`；迁移时优先复用这些模块，而不是复制本目录的硬件配置。
