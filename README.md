Ŝalenzo Website
===============

0. 共通部分 ![GitHub Actions workflow](https://github.com/Salenzo/salenzo.github.io/actions/workflows/deploy.yml/badge.svg)
    - 模板导航条、预处理Markdown（含链接）和CSS、子页面目录
    - 精巧而易碎的结构，不锁定依赖项版本。不必哀叹不锁版本不能复现，刻舟求剑逆流而上自取灭亡
1. [salenzo.github.io ![GitHub deployments](https://img.shields.io/github/deployments/Salenzo/salenzo.github.io/github-pages?logo=github)](https://salenzo.github.io/)
    - 特色：写得一派混乱的样式表，宽为*π*个空格的制表符轻而易举地得罪所有人
    - Jekyll (kramdown) + MathJax 2
    - `bundle install; bundle exec jekyll serve`
2. [salenzo.readthedocs.io ![Documentation Status](https://readthedocs.org/projects/salenzo/badge/?version=latest)](https://salenzo.readthedocs.io/)
    - 特色：MathML的CSS实现；自定义主题避免Read the Docs注入导航浮动条
    - MkDocs (Python-Markdown) + [latex2mathml](https://pypi.org/project/latex2mathml/) + [Prism](https://prismjs.com/)
    - `pip install -r requirements.txt; npm install; mkdocs serve --watch-theme`
3. [salenzo.neocities.org（在建） ![GitHub Actions workflow](https://github.com/Salenzo/salenzo.github.io/actions/workflows/deploy.yml/badge.svg)](https://salenzo.neocities.org/)
    - 特色：超古老的静态网站生成器工具链
    - [GTML](https://ext.boulgour.com/lifl/beaufils/gtml/) + [Markdown.pl](https://daringfireball.net/projects/markdown/) + [jsMath](https://www.math.union.edu/~dpvc/jsMath/)
4. [salenzo.vercel.app（在建） ![Vercel](https://therealsujitk-vercel-badge.vercel.app/?app=salenzo)](https://salenzo.vercel.app/)
    - 特色：
    - Next.js + micromark (KaTeX (SSR))
    - `npm install; npx next dev`
5. [salenzo.gitlab.io（在建） ![Pipeline Status](https://gitlab.com/salenzo/salenzo.gitlab.io/badges/main/pipeline.svg)](https://salenzo.gitlab.io/)
    - 特色：基于GitHub Actions的GitLab CI/CD运行器，不绑定银行卡也能将白嫖贯彻到底；PHP也想作为静态网站生成器
    - PHP + [Michelf\\MarkdownExtra](https://michelf.ca/projects/php-markdown/) + MathJax 2 + [`highlight_string`](https://www.php.net/manual/en/function.highlight-string.php)
    - `composer update; php index.php`
