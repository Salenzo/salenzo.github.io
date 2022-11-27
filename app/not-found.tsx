import Page from './[...path]/page'

export default function NotFound() {
  return Page({ params: { path: ['404'] } })
}
