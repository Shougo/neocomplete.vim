"=============================================================================
" FILE: echodoc.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

" For echodoc. "{{{
let s:doc_dict = {
      \ 'name' : 'neocomplete',
      \ 'rank' : 10,
      \ }
" @vimlint(EVL102, 1, v:completed_item)
function! s:doc_dict.search(cur_text) "{{{
  if !exists('v:completed_item') || empty(v:completed_item)
    return []
  endif

  let item = v:completed_item

  let abbr = (item.abbr != '') ? item.abbr : item.word
  if len(item.menu) > 5
    " Combine menu.
    let abbr .= ' ' . item.menu
  endif

  if item.info != ''
    let abbr = split(item.info, '\n\|\\n')[0]
  endif

  " Skip
  if len(abbr) < len(item.word) + 2
    return []
  endif

  let ret = []

  let match = stridx(abbr, item.word)
  if match < 0
    call add(ret, { 'text' : abbr })
  else
    call add(ret, { 'text' : item.word, 'highlight' : 'Identifier' })
    call add(ret, { 'text' : abbr[match+len(item.word) :] })
  endif

  return ret
endfunction"}}}
" @vimlint(EVL102, 0, v:completed_item)
"}}}

function! neocomplete#echodoc#init() "{{{
  if neocomplete#exists_echodoc()
    call echodoc#register(s:doc_dict.name, s:doc_dict)
  endif
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
