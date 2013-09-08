"=============================================================================
" FILE: file_include.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 08 Sep 2013.
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

" Global options definition. "{{{
let g:neocomplete#sources#file_include#exprs =
        \ get(g:, 'neocomplete#sources#file_include#exprs', {})
let g:neocomplete#sources#file_include#exts =
      \ get(g:, 'neocomplete#sources#file_include#exts', {})
"}}}

let s:source = {
      \ 'name' : 'file/include',
      \ 'kind' : 'manual',
      \ 'mark' : '[FI]',
      \ 'rank' : 10,
      \ 'hooks' : {},
      \ 'sorters' : 'sorter_filename',
      \}

function! neocomplete#sources#file_include#define() "{{{
  return s:source
endfunction"}}}

function! s:source.hooks.on_init(context) "{{{
  " Initialize.
  call neocomplete#sources#include#initialize()

  " Initialize filename include expr. "{{{
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#file_include#exprs',
        \ 'perl',
        \ 'fnamemodify(substitute(v:fname, "/", "::", "g"), ":r")')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#file_include#exprs',
        \ 'ruby,python,java,d',
        \ 'fnamemodify(substitute(v:fname, "/", ".", "g"), ":r")')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#file_include#exprs',
        \ 'python',
        \ "substitute(substitute(substitute(v:fname,
        \ '\\v.*egg%(-info|-link)?$', '', ''),
        \ '\\v\\.py$|%(\\.[^.]+)?\\.so$', '', ''), '/', '.', 'g')")
  "}}}

  " Initialize filename include extensions. "{{{
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#file_include#exts',
        \ 'c', ['h'])
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#file_include#exts',
        \ 'cpp', ['', 'h', 'hpp', 'hxx'])
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#file_include#exts',
        \ 'perl', ['pm'])
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#file_include#exts',
        \ 'java', ['java'])
  "}}}
endfunction"}}}

function! s:source.get_complete_position(context) "{{{
  let filetype = neocomplete#get_context_filetype()

  " Not Filename pattern.
  if exists('g:neocomplete#sources#include#patterns')
    let pattern = get(g:neocomplete#sources#include#patterns, filetype,
        \      &l:include)
  else
    let pattern = ''
  endif
  if neocomplete#is_auto_complete()
        \ && (pattern == '' || a:context.input !~ pattern)
        \ && a:context.input =~ '\*$\|\.\.\+$\|/c\%[ygdrive/]$'
    " Skip filename completion.
    return -1
  endif

  " Check include pattern.
  let pattern = get(g:neocomplete#sources#include#patterns,
        \ filetype, &l:include)
  if pattern == '' || a:context.input !~ pattern . '\s\+'
    return -1
  endif

  let match_end = matchend(a:context.input, pattern)
  let complete_str = matchstr(a:context.input[match_end :], '\f\+')

  let expr = get(g:neocomplete#sources#include#exprs,
        \ filetype, &l:includeexpr)
  if expr != ''
    let cur_text =
          \ substitute(eval(substitute(expr,
          \ 'v:fname', string(complete_str), 'g')),
          \  '\.\w*$', '', '')
  endif

  let complete_pos = len(a:context.input) - len(complete_str)
  if neocomplete#is_sources_complete() && complete_pos < 0
    let complete_pos = len(a:context.input)
  endif

  if complete_str =~ '/'
    let complete_pos += strridx(complete_str, '/') + 1
  endif

  return complete_pos
endfunction"}}}

function! s:source.gather_candidates(context) "{{{
  let pattern = neocomplete#get_keyword_pattern_end('filename')
  let [complete_pos, complete_str] =
        \ neocomplete#match_word(a:context.input, pattern)
  return s:get_include_files(complete_str)
endfunction"}}}

function! s:get_include_files(complete_str) "{{{
  let filetype = neocomplete#get_context_filetype()

  let path = neocomplete#util#substitute_path_separator(
        \ get(g:neocomplete#sources#include#paths, filetype,
        \   getbufvar('%', '&path')))
  let pattern = get(g:neocomplete#sources#include#patterns,
        \ filetype, getbufvar('%', '&include'))
  let expr = get(g:neocomplete#sources#include#exprs,
        \ filetype, getbufvar('%', '&includeexpr'))
  let reverse_expr = get(g:neocomplete#sources#file_include#exprs,
        \ filetype, '')
  let exts = get(g:neocomplete#sources#file_include#exts,
        \ filetype, [])

  let line = neocomplete#get_cur_text()
  if line =~ '^\s*\<require_relative\>' && &filetype =~# 'ruby'
    " For require_relative.
    let path = '.'
  endif

  let match_end = matchend(line, pattern)
  let complete_str = matchstr(line[match_end :], '\f\+')
  if expr != ''
    let complete_str =
          \ substitute(eval(substitute(expr,
          \ 'v:fname', string(complete_str), 'g')), '\.\w*$', '', '')
  endif
  let complete_str = substitute(complete_str, '[^/]\+$', '', '')

  " Path search.
  let glob = (complete_str !~ '\*$')?
        \ complete_str . '*' : complete_str
  let cwd = getcwd()
  let bufdirectory = neocomplete#util#substitute_path_separator(
        \ fnamemodify(expand('%'), ':p:h'))
  let candidates = s:get_default_include_files(filetype)
  for subpath in split(path, '[,;]')
    let dir = (subpath == '.') ? bufdirectory : subpath

    if (complete_str != '' && complete_str[0] == '.' && subpath[0] != '.')
        continue
    endif

    if !isdirectory(dir)
      continue
    endif

    execute 'lcd' fnameescape(dir)

    for word in split(
          \ neocomplete#util#substitute_path_separator(
          \   glob(glob)), '\n')
      let dict = {
            \ 'word' : word,
            \ 'action__is_directory' : isdirectory(word)
            \ }

      if reverse_expr != ''
        " Convert filename.
        let dict.word = eval(substitute(reverse_expr,
              \ 'v:fname', string(dict.word), 'g'))
      elseif !dict.action__is_directory
        let dict.word = fnamemodify(word, ':t')
        if &filetype !=# 'c' && &filetype !=# 'cpp'
          " Remove extension.
          let dict.word = fnamemodify(word, ':r')
        endif
      endif

      let abbr = dict.word
      if dict.action__is_directory
        let abbr .= '/'
        if g:neocomplete#enable_auto_delimiter
          let dict.word .= '/'
        endif
      elseif !empty(exts) &&
            \ index(exts, fnamemodify(word, ':e')) < 0
        " Skip.
        continue
      endif

      let dict.abbr = abbr

      " Escape word.
      let dict.word = escape(dict.word, ' ;*?[]"={}''')

      call add(candidates, dict)
    endfor
  endfor
  execute 'lcd' fnameescape(cwd)

  return candidates
endfunction"}}}

function! s:get_default_include_files(filetype) "{{{
  let files = []

  if a:filetype ==# 'python' || a:filetype ==# 'python3'
    let files = ['sys']
  endif

  return map(files, "{
        \ 'word' : v:val,
        \ 'action__is_directory' : isdirectory(v:val) }
        \")
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
