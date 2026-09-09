# MACHINE-SPECIFIC: the Windows EFI UUID below belongs to this computer.
{ ... }:

{
  # 引导加载器：EFI 模式下的 GRUB，并探测其它已安装系统
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      devices = [ "nodev" ];
      efiSupport = true;
      useOSProber = true;
      # 限制 GRUB 菜单中的内核数量，防止 /boot 空间耗尽
      configurationLimit = 5;

      # 手动添加 Windows 启动条目（os-prober 检测不稳定，直接指定更可靠）
      extraEntries = ''
        menuentry "Windows (via bootmgfw.efi)" {
          search --fs-uuid --set=root 13B5-B768
          chainloader /EFI/Microsoft/Boot/bootmgfw.efi
        }
      '';
    };
  };
}
