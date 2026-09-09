# Pandoc + XeLaTeX 中文 PDF 模板

这个目录用于把 Markdown 笔记导出成中文 PDF。

## 文件说明

- `template/pandoc.yaml`：Pandoc 默认配置，使用 XeLaTeX、A4、2cm 页边距、中文字体、目录、章节编号和代码高亮。
- `note.md`：示例笔记。
- `assets/`：图片目录。
- `Makefile`：一键导出 PDF。

## 导出

在 `notes/` 目录执行：

```bash
make
```

等价于：

```bash
pandoc note.md -d template/pandoc.yaml -o note.pdf
```

清理导出的 PDF：

```bash
make clean
```

## 字体

模板使用：

- 英文正文：TeX 默认字体。
- 中文字体：TeX Live 自带 `Fandol` 字体集，由 `ctexart` 的 `fontset=fandol` 接管。
- 代码字体：`JetBrainsMono Nerd Font`

这些字体由 `devices/nixos/fonts.nix` 管理。

## Eisvogel

如果以后要用 Eisvogel 高级模板，把 `eisvogel.latex` 放到 `template/`，然后在 `template/pandoc.yaml` 里增加：

```yaml
template: template/eisvogel.latex
```
