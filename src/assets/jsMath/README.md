jsMath v3.6e
============

本文件夹中的文件（除了本文件）均来自jsMath，文件内容未作改动，仅删除了不需要的文件。

作出的更改
----------

- 添加了TrueType网络字体。用户无需自行安装字体，便能享受到最佳体验。
  - 因此强制jsMath字体检测程序认为jsMath字体已正确安装。
  - 使用的字体来自[`TeX-fonts-linux.tgz`](https://www.math.union.edu/~dpvc/jsMath/download/jsMath-fonts.html)和[附加字体](https://www.math.union.edu/~dpvc/jsMath/download/extra-fonts/welcome.html)（粗版）
- 没有图片和精灵字体，因此控制面板中对应选项不可用。
- 删除了对老旧浏览器的检测。
- 覆盖了对平台的检测，现在所有平台上的Unicode渲染都会像Unix一样，不再指定字体。
- 删除了全局模式。
- 删除了所有内置插件，因为它们要么可以通过配置来获得同等效果（`mimeTeX`、`smallFonts`、`noImageFonts`），要么不适用于当前站点的配置（`tex2math`、`autoload`、`global`、`noGlobal`、`noCache`、`CHMmode`、`spriteImageFonts`）。
