jsMath = {
  Setup: {
    Source: function () {
      jsMath.root = jsMath.document.location.protocol + '//' + jsMath.document.location.host + '/assets/jsMath/'
      jsMath.Img.root = jsMath.root + "fonts/"
      jsMath.blank = jsMath.root + "blank.gif"
    },
  },
  Font: {
    CheckTeX: function () {
      jsMath.nofonts = false
    },
  },
  Controls: {
    cookie: {
      scale: 100,
      global: 'never',
    },
    CheckVersion: function () {
      jsMath.Script.delayedLoad('http://www.math.union.edu/locate/jsMath/jsMath/jsMath-version-check.js');
    },
  },
  Parser: {
    prototype: {
      macros: {
        warning: ["Macro", "\\color{##00CC00}{\\rm jsMath\\ appears\\ to\\ be\\  working!}", 1],
      },
    },
  },
  noGoGlobal: 1,
  noChangeGlobal: 1,
  noShowGlobal: 1,
  noImgFonts: 1,
  safeHBoxes: 0,
  platform: 'unix',
  Browser: {
    // Disable browser checks.
    MSIE: isFinite,
    Mozilla: Math.max,
    Opera: Object,
    OmniWeb: Math.min,
    Safari: String,
    Konqueror: parseFloat,
  },
}
