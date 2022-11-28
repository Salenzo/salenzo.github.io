import re
import subprocess
from latex2mathml.converter import convert as latex2mathml


def on_page_markdown(markdown: str, page, config, files):
    if not page.is_homepage and page.file.src_uri.endswith("/index.md"):
        items = sorted(
            "- [%s](%s)"
            % (
                path[path.index("/") + 1 : path.rindex(".")],
                path[path.index("/") + 1 :],
            )
            for path in files.src_uris
            if "/" in path
            and path[: path.index("/")] == page.file.src_uri[:-9]
            and path != page.file.src_uri
        )
        if page.file.src_uri == "post/index.md":
            items = reversed(items)
        markdown += "\n\n" + "\n".join(items)
    return markdown


def on_page_content(html: str, page, config, files):
    def replacer(match: re.Match):
        display = "block" if match.group(1) else "inline"
        mml = latex2mathml(match.group(2), display=display)
        mml = re.sub(
            r"<mi>(.)<\/mi>",
            '<mi mathvariant="italic">\\1</mi>',
            mml,
            flags=re.IGNORECASE,
        )
        mml = re.sub(
            r">(.)<\/mo>",
            ' data-content="\\1">\\1</mo>',
            mml,
            flags=re.IGNORECASE,
        )
        return mml

    return re.sub(
        r"""<script\s+type=['"]?math/tex(;\s*mode\s*=\s*display)?['"]?\s*>(.*?)</script>""",
        replacer,
        html,
        flags=re.IGNORECASE | re.DOTALL,
    )


def on_post_build(config):
    subprocess.run(
        ["npx", "sass", "--style=compressed", "--no-source-map", config.site_dir],
        check=True,
    )
