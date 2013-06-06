"=============================================================================
" FILE: converter_remove_next_keyword.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 06 Jun 2013.
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

function! neocomplete#filters#converter_remove_next_keyword#define() "{{{
  return s:converter
endfunction"}}}

let s:converter = {
      \ 'name' : 'converter_remove_next_keyword',
      \ 'description' : 'remove next keyword converter',
      \}

function! s:converter.filter(context) "{{{
  " Remove next keyword.
  let next_keyword = neocomplete#filters#
        \converter_remove_next_keyword#get_next_keyword(a:context.source_name)
  if next_keyword == ''
    return a:context.candidates
  endif

  let next_keyword = substitute(
        \ substitute(escape(next_keyword,
        \ '~" \.^$*[]'), "'", "''", 'g'), ')$', '', '').'$'

  " No ignorecase.
  let ignorecase_save = &ignorecase
  let &ignorecase = 0
  try
    for r in a:context.candidates
      let pos = match(r.word, next_keyword)
      if pos >= 0
        if !has_key(r, 'abbr')
          let r.abbr = r.word
        endif

        let r.word = r.word[: pos-1]
      endif
    endfor
  finally
    let &ignorecase = ignorecase_save
  endtry

  return a:context.candidates
endfunction"}}}

function! neocomplete#filters#converter_remove_next_keyword#get_next_keyword(source_name) "{{{
  let pattern = '^\%(' .
        \ ((a:source_name ==# 'file' || a:source_name ==# 'file/include') ?
        \   neocomplete#get_next_keyword_pattern('filename') :
        \   neocomplete#get_next_keyword_pattern()) . '\m\)'

  let next_keyword = matchstr('a'.
        \ getline('.')[len(neocomplete#get_cur_text(1)) :], pattern)[1:]
  return next_keyword
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
