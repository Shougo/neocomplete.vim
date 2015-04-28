"=============================================================================
" FILE: file_include.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
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
let g:neocomplete#sources#file_include#delimiters =
      \ get(g:, 'neocomplete#sources#file_include#delimiters', {})
"}}}

let s:source = {
      \ 'name' : 'file/include',
      \ 'kind' : 'manual',
      \ 'mark' : '[FI]',
      \ 'rank' : 150,
      \ 'hooks' : {},
      \ 'sorters' : 'sorter_filename',
      \ 'converters' : ['converter_remove_overlap', 'converter_abbr'],
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
        \ 'substitute(v:fname, "/", "::", "g")')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#file_include#exprs',
        \ 'java,d',
        \ 'substitute(v:fname, "/", ".", "g")')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#file_include#exprs',
        \ 'ruby',
        \ 'substitute(v:fname, "\.rb$", "", "")')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#file_include#exprs',
        \ 'python',
        \ "substitute(substitute(v:fname,
        \ '\\v.*egg%(-info|-link)?$', '', ''), '/', '.', 'g')")
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
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#file_include#exts',
        \ 'ruby', ['rb'])
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#file_include#exts',
        \ 'python', ['py', 'py3'])
  "}}}

  " Initialize filename include delimiter. "{{{
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#file_include#delimiters',
        \ 'c,cpp,ruby', '/')
  "}}}
endfunction"}}}

function! s:source.get_complete_position(context) "{{{
  let filetype = neocomplete#get_context_filetype()
  if filetype ==# 'java' || filetype ==# 'haskell'
    " Cannot complete include path.
    " You should use omnifunc plugins..
    return -1
  endif

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
  if pattern != ''
    let pattern .= '\m\s\+'
  endif
  if pattern == '' || a:context.input !~ pattern
    return -1
  endif

  let match_end = matchend(a:context.input, pattern)
  let complete_str = matchstr(a:context.input[match_end :], '\f\+')

  let complete_pos = len(a:context.input) - len(complete_str)

  let delimiter = get(g:neocomplete#sources#file_include#delimiters,
        \ &filetype, '.')
  if strridx(complete_str, delimiter) >= 0
    let complete_pos += strridx(complete_str, delimiter) + 1
  endif

  return complete_pos
endfunction"}}}

function! s:source.gather_candidates(context) "{{{
  return s:get_include_files()
endfunction"}}}

function! s:get_include_files() "{{{
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

  let match_end = matchend(line, pattern)
  let complete_str = matchstr(line[match_end :], '\f\+')
  if expr != ''
    let complete_str =
          \ substitute(eval(substitute(expr,
          \ 'v:fname', string(complete_str), 'g')), '\.\w*$', '', '')
  endif
  let delimiter = get(g:neocomplete#sources#file_include#delimiters,
        \ &filetype, '.')

  if (line =~ '^\s*\<require_relative\>' && &filetype =~# 'ruby')
        \ || stridx(complete_str, '.') == 0
    " For include relative.
    let path = '.'
  endif

  " Path search.
  let glob = (complete_str !~ '\*$')?
        \ complete_str . '*' : complete_str
  let bufdirectory = neocomplete#util#substitute_path_separator(
        \ fnamemodify(expand('%'), ':p:h'))
  let candidates = s:get_default_include_files(filetype)
  let path = join(map(split(path, ',\+'),
        \ "v:val == '.' ? bufdirectory : v:val"), ',')
  for word in filter(split(
        \ neocomplete#util#substitute_path_separator(
        \   globpath(path, glob, 1)), '\n'),"
        \  isdirectory(v:val) || empty(exts) ||
        \  index(exts, fnamemodify(v:val, ':e')) >= 0")

    let dict = {
          \ 'word' : word,
          \ 'action__is_directory' : isdirectory(word),
          \ 'kind' : (isdirectory(word) ? 'dir' : 'file'),
          \ }

    if reverse_expr != ''
      " Convert filename.
      let dict.word = eval(substitute(reverse_expr,
            \ 'v:fname', string(dict.word), 'g'))
    endif

    if !dict.action__is_directory && delimiter != '/'
      " Remove extension.
      let dict.word = fnamemodify(dict.word, ':r')
    endif

    " Remove before delimiter.
    if strridx(dict.word, delimiter) >= 0
      let dict.word = dict.word[strridx(dict.word, delimiter)+1: ]
    endif

    let dict.abbr = dict.word
    if dict.action__is_directory
      let dict.abbr .= delimiter
      if g:neocomplete#enable_auto_delimiter
        let dict.word .= delimiter
      endif
    endif

    call add(candidates, dict)
  endfor

  return candidates
endfunction"}}}

function! s:get_default_include_files(filetype) "{{{
  let files = []

  if a:filetype ==# 'python' || a:filetype ==# 'python3'
    let files = ['sys']
  endif

  return map(files, "{
        \ 'word' : v:val,
        \ 'action__is_directory' : isdirectory(v:val),
        \ 'kind' : (isdirectory(v:val) ? 'dir' : 'file'),
        \}")
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
