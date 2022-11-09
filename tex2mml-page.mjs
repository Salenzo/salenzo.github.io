import * as fs from 'node:fs'
import { TeX } from 'mathjax-full/js/input/tex.js'
import { STATE } from 'mathjax-full/js/core/MathItem.js'
import { liteAdaptor } from 'mathjax-full/js/adaptors/liteAdaptor.js'
import { SerializedMmlVisitor } from 'mathjax-full/js/core/MmlTree/SerializedMmlVisitor.js'
import { HTMLDocument } from 'mathjax-full/js/handlers/html/HTMLDocument.js'
import 'mathjax-full/js/input/tex/AllPackages.js'

const document = new HTMLDocument('', liteAdaptor(), { InputJax: new TeX({
  packages: [
    'base',
    'ams', 'cases', 'centernot', 'gensymb', 'mathtools', 'textcomp', 'upgreek',
    'autoload', 'configmacros', 'newcommand', 'noundefined', 'setoptions', 'require'
  ],
  macros: {
    dd: '\\mathop{}\\mathopen{}d',
  },
}) })
const visitor = new SerializedMmlVisitor()
fs.writeSync(process.stdout.fd, fs.readFileSync(process.stdin.fd, 'utf-8').replace(/<script\s+type=['"]?math\/tex(;\s*mode\s*=\s*display)?['"]?\s*>(.*?)<\/script>/isg, (tag, display, tex) => {
  let mml = visitor.visitTree(document.convert(tex, { display: !!display, end: STATE.CONVERT }), document)
  mml = mml.replace(/<mi>(.)<\/mi>/ig, '<mi mathvariant="italic">$1</mi>')
  mml = mml.replace(/>(.)<\/mo>/ig, ' data-content="$1">$1</mo>')
  return mml
}))
