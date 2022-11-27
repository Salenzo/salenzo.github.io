import fs from 'fs'
import { micromark } from 'micromark'
import { frontmatter, frontmatterHtml } from 'micromark-extension-frontmatter'
import { gfm, gfmHtml } from 'micromark-extension-gfm'
import { math, mathHtml } from 'micromark-extension-math'
import Link from 'next/link'
import path from 'path'
import markdownStyles from '../markdown-styles.module.css'

const postsDirectory = path.join(process.cwd(), 'src/post')

export function getPostSlugs() {
  return fs.readdirSync(postsDirectory).map(slug => slug.replace(/\.md$/, '')).sort()
}

export function getPostBySlug(slug: string) {
  return fs.readFileSync(`${postsDirectory}/${slug}.md`, 'utf-8')
}

type Props = {
  params: { path: string[] },
}

function markdownToHtml(markdown: string) {
  return micromark(markdown, {
    allowDangerousHtml: true,
    allowDangerousProtocol: true,
    extensions: [
      frontmatter(),
      gfm(),
      math(),
    ],
    htmlExtensions: [
      frontmatterHtml(),
      gfmHtml(),
      mathHtml({
        throwOnError: false,
        errorColor: '#ff0000',
        macros: {
          '\\iiiint': '\\iint\\!\\!\\!\\iint',
        },
        trust: true,
      }),
    ],
  })
}

export default function Index({ params: { path } }: Props) {
  if (!path) {
    return (
      <div>
        hello world
      </div>
    )
  }
  return (
    <div className="container mx-auto px-5">
      <h2 className="text-2xl md:text-4xl font-bold tracking-tight md:tracking-tighter leading-tight mb-20 mt-8">
        <Link href="/" className="hover:underline">
          Blog
        </Link>
        .
      </h2>
      <article className="mb-32">
        <h1 className="text-5xl md:text-7xl lg:text-8xl font-bold tracking-tighter leading-tight md:leading-none mb-12 text-center md:text-left">
          title
        </h1>
        <div className="max-w-2xl mx-auto">
          author
          <div className="mb-6 text-lg">date</div>
        </div>
        <div className="max-w-2xl mx-auto">
          <div
            className={markdownStyles['markdown']}
            dangerouslySetInnerHTML={{ __html: markdownToHtml(getPostBySlug(path[0])) }}
          />
        </div>
      </article>
    </div>
  )
}

export async function generateStaticParams() {
  return getPostSlugs().map(slug => ({ path: [slug] }))
}
