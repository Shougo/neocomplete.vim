"=============================================================================
" FILE: neocomplete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 29 Jul 2013.
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

function! unite#sources#neocomplete#define() "{{{
  return s:neocomplete_source
endfunction "}}}

" neocomplete unite source.
let s:neocomplete_source = {
      \ 'name': 'neocomplete',
      \ 'hooks' : {},
      \ }

function! s:neocomplete_source.hooks.on_init(args, context) "{{{
  if !neocomplete#is_enabled()
    let a:context.source__complete_pos = -1
    let a:context.source__candidates = []
    return
  endif

  " Save options.
  let max_list_save = g:neocomplete#max_list
  let max_keyword_width_save = g:neocomplete#max_keyword_width
  let manual_start_length = g:neocomplete#manual_completion_start_length

  try
    let g:neocomplete#max_list = -1
    let g:neocomplete#max_keyword_width = -1
    let g:neocomplete#manual_completion_start_length = 0

    let cur_text = neocomplete#get_cur_text(1)
    let complete_sources = neocomplete#complete#_get_results(cur_text)
    let a:context.source__complete_pos =
          \ neocomplete#complete#_get_complete_pos(complete_sources)
    let a:context.source__candidates = neocomplete#complete#_get_words(
          \ complete_sources, a:context.source__complete_pos,
          \ cur_text[a:context.source__complete_pos :])
  finally
    " Restore options.
    let g:neocomplete#max_list = max_list_save
    let g:neocomplete#max_keyword_width = max_keyword_width_save
    let &l:completefunc = 'neocomplete#complete#auto_complete'
    let g:neocomplete#manual_completion_start_length = manual_start_length
  endtry
endfunction"}}}

function! s:neocomplete_source.gather_candidates(args, context) "{{{
  let keyword_pos = a:context.source__complete_pos
  let list = []
  for keyword in a:context.source__candidates
    let dict = {
        \   'word' : keyword.word,
        \   'abbr' : printf('%-50s', get(keyword, 'abbr', keyword.word)),
        \   'kind': 'completion',
        \   'action__complete_word' : keyword.word,
        \   'action__complete_pos' : keyword_pos,
        \ }
    if has_key(keyword, 'kind')
      let dict.abbr .= ' ' . keyword.kind
    endif
    if has_key(keyword, 'menu')
      let dict.abbr .= ' ' . keyword.menu
    endif
    if has_key(keyword, 'description')
      if type(keyword.description) ==# type(function('tr'))
        let dict.action__complete_info_lazy = keyword.description
      else
        let dict.action__complete_info = keyword.description
      endif
    endif

    call add(list, dict)
  endfor

  return list
endfunction "}}}

function! unite#sources#neocomplete#start_complete() "{{{
  return s:start_complete(0)
endfunction "}}}

function! unite#sources#neocomplete#start_quick_match() "{{{
  return s:start_complete(1)
endfunction "}}}

function! s:start_complete(is_quick_match) "{{{
  if !neocomplete#is_enabled()
    return ''
  endif
  if !exists(':Unite')
    echoerr 'unite.vim is not installed.'
    return ''
  endif

  return unite#start_complete(['neocomplete'], {
        \ 'auto_preview' : 1, 'quick_match' : a:is_quick_match,
        \ 'input' : neocomplete#get_cur_text(1),
        \ })
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
