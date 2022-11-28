<?php if (isset($contents)): ?>
<!DOCTYPE html>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<title><?= empty($title) ? htmlspecialchars($title) . " — " : "" ?>Ŝalenzo</title>
<link rel="shortcut icon" href="/assets/favicon.ico">

<nav>
  <a href="/">Ŝalenzo</a>
  <?php foreach (array(
		"Home" => "/",
	) as $name => $url): ?>
  	<a href="<?= htmlspecialchars($url) ?>"><?= htmlspecialchars($name) ?></a>
  <?php endforeach; ?>
</nav>

<main>
  <?php if ($metadata): ?>
		<dl class="meta">
			<?php foreach ($metadata as $key => $value): ?>
				<dt><?= htmlspecialchars($key) ?></dt>
				<dd><?= htmlspecialchars($value) ?></dd>
			<?php endforeach; ?>
		</dl>
		<hr>
  <?php endif; ?>
	<?= $contents ?>
</main>

<aside>
  <h1>About us</h1>
  <a href="https://github.com/akhialomgir">シュサイ Akhia</a>
  <a href="https://github.com/satgo1546">シュサイ satgo1546</a>
  <a href="https://github.com/Ezioxk">シュサイ Ezioxk</a>
  <a href="https://mochanaigai363.lofter.com">アート Flora</a>
  <a href="https://github.com/Salenzo" class="more">more »</a>
  <img src="/assets/img/MMPD.svg" alt="Ŝalenzo Logo" style="opacity: .3;">
</aside>

<footer>
  Copyright © Ŝalenzo<br>
  Powered by Ŝanity & <a href="https://www.php.net/"><img src="/assets/img/php-power-black.png" alt="Powered by PHP"></a> <?= phpversion() ?>
</footer>

<?php return;
endif;

require "vendor/autoload.php";
use Michelf\MarkdownExtra;
use Symfony\Component\Yaml\Yaml;

// Clear the contents of the destination folder.
if (!file_exists("_site")) mkdir("_site");
foreach (
	new RecursiveIteratorIterator(
		new RecursiveDirectoryIterator("_site", RecursiveDirectoryIterator::SKIP_DOTS),
		RecursiveIteratorIterator::CHILD_FIRST,
	) as $file
) {
	if ($file->isDir()) {
		rmdir($file->getPathname());
	} else {
		unlink($file->getPathname());
	}
}

$markdown = new MarkdownExtra;
$markdown->hard_wrap = true;
$markdown->url_filter_func = function ($url) {
	return strtolower($url);
};
$markdown->header_id_func = function ($text) {
	return preg_replace('/[^a-z0-9]/', '-', strtolower($text));
};
ini_set("highlight.comment", "#008000");
ini_set("highlight.default", "#000000");
ini_set("highlight.html", "#808080");
ini_set("highlight.keyword", "#0000BB; font-weight: bold");
ini_set("highlight.string", "#DD0000");
$markdown->code_block_content_func = function ($code, $language) {
	if (!$language) return htmlspecialchars($code);
	if (str_contains($code, "<?php ")) {
		$code = highlight_string($code, true);
	} else {
		$code = highlight_string("<?php " . $code, true);
		$code = str_replace("&lt;?php&nbsp;", "", $code);
	}
	$code = str_replace("<code>", "", $code);
	$code = str_replace("</code>", "", $code);
	return trim($code);
};
$markdown->hashtag_protection = true;

foreach (
	new RecursiveIteratorIterator(
		new RecursiveDirectoryIterator("src", RecursiveDirectoryIterator::SKIP_DOTS),
	) as $src
) {
	echo $src->getPathname();
	$dest = preg_replace("/^" . preg_quote("src", "/") . "/", "_site", $src->getPathname(), 1);
	$contents = file_get_contents($src->getPathname());
	$title = "";
	$metadata = array();
	if ($src->getExtension() === "md") {
		$dest = preg_replace('/\.md$/', ".html", $dest);
		// Parse the front matter and populate $metadata.
		if (str_starts_with($contents, "---\n")) {
			$metadata = Yaml::parse(strstr($contents, "\n---\n", true));
		}
		// Find the title of the document.
		if (!array_key_exists("title", $metadata)) {
			// Find the first <h1>, <h2>, or <h3> in the Markdown source.
			preg_match('/^\s*(?:#{1,3}\s+(.*)(?:\s+\#{1,3})?|(.*)\r?\n[-=]+\s*)$/m', $contents, $title);
			$contents = $markdown->transform($contents);
			$metadata["title"] = array_key_exists(1, $title) ? $title[1] : "";
		}
		$title = $metadata["title"];
		// Use this program as a HTML template and PHP as a powerful templating engine.
		ob_start();
		include __FILE__;
		$contents = ob_get_contents();
		ob_end_clean();
	}
	echo " → " . $dest . "\n";
	if (!file_exists(dirname($dest))) mkdir(dirname($dest), 0777, true);
	file_put_contents($dest, $contents);
}
