"=============================================================================
" FILE: neocomplete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
"          manga_osyo (Original)
" Last Modified: 14 Jun 2013.
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

function! unite#sources#file_include#define()
  return s:source
endfunction

let s:source = {
      \ 'name' : 'file_include',
      \ 'description' : 'candidates from include files',
      \ 'hooks' : {},
      \}
function! s:source.hooks.on_init(args, context) "{{{
  " From neocomplete include files.
  let a:context.source__include_files =
        \ neocomplete#sources#include#get_include_files(bufnr('%'))
  let a:context.source__path = &path
endfunction"}}}

function! s:source.gather_candidates(args, context) "{{{
  let files = map(copy(a:context.source__include_files), '{
        \ "word" : neocomplete#util#substitute_path_separator(v:val),
        \ "abbr" : neocomplete#util#substitute_path_separator(v:val),
        \ "source" : "file_include",
        \ "kind" : "file",
        \ "action__path" : v:val
        \ }')

  for word in files
    " Path search.
    for path in map(split(a:context.source__path, ','),
          \ 'neocomplete#util#substitute_path_separator(v:val)')
      if path != '' && neocomplete#head_match(word.word, path . '/')
        let word.abbr = word.abbr[len(path)+1 : ]
        break
      endif
    endfor
  endfor

  return files
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
