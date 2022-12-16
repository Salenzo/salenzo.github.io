// Convert <img alt> math tags to a form jsMath accepts.
// We convert them to <div class="math"> or <span class="math"> tags.
// While modifying the DOM, the live HTMLCollection updates itself.
// It would resulting in shifted indices and unprocessed images.
// Thus, it is necessary to make a copy first by calling Array.prototype.slice.
Array.prototype.slice.call(document.getElementsByTagName('img')).forEach(function (el) {
	if (/^ |^\\displaystyle /.test(el.alt)) {
		el.outerHTML = (el.alt.charAt(0) == '\\' ? '<div' : '<span') + ' class="math">' + el.alt.replace(/&/g, '&amp;').replace(/</g, '&lt;')
	}
})
jsMath.Process(document)
