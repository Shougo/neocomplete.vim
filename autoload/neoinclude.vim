"=============================================================================
" FILE: neoinclude.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
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

function! neoinclude#initialize() abort "{{{
  let g:neocomplete#sources#file_include#exprs =
        \ get(g:, 'neocomplete#sources#file_include#exprs', {})
  let g:neocomplete#sources#file_include#exts =
        \ get(g:, 'neocomplete#sources#file_include#exts', {})
  let g:neocomplete#sources#file_include#delimiters =
        \ get(g:, 'neocomplete#sources#file_include#delimiters', {})
  let g:neocomplete#sources#include#patterns =
        \ get(g:, 'neocomplete#sources#include#patterns', {})
  let g:neocomplete#sources#include#exprs =
        \ get(g:, 'neocomplete#sources#include#exprs', {})
  let g:neocomplete#sources#include#paths =
        \ get(g:, 'neocomplete#sources#include#paths', {})
  let g:neocomplete#sources#include#suffixes =
        \ get(g:, 'neocomplete#sources#include#suffixes', {})
  let g:neocomplete#sources#include#functions =
        \ get(g:, 'neocomplete#sources#include#functions', {})

  " Initialize include pattern. "{{{
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#include#patterns',
        \ 'java,haskell', '^\s*\<import')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#include#patterns',
        \ 'c,cpp', '^\s*#\s*include')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#include#patterns',
        \ 'cs', '^\s*\<using')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#include#patterns',
        \ 'ruby', '^\s*\<\%(load\|require\|require_relative\)\>')
  "}}}
  " Initialize include suffixes. "{{{
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#include#suffixes',
        \ 'haskell', '.hs')
  "}}}
  " Initialize include functions. "{{{
  " call neocomplete#util#set_default_dictionary(
  "       \ 'g:neocomplete#sources#include#functions', 'vim',
  "       \ 'neoinclude#analyze_vim_include_files')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#include#functions', 'ruby',
        \ 'neoinclude#analyze_ruby_include_files')
  "}}}
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

function! neoinclude#set_filetype_paths(bufnr, filetype) abort "{{{
  if a:filetype ==# 'python' || a:filetype ==# 'python3'
    " Initialize python path pattern.
    if executable('python3')
      call s:set_python_paths('python3')
    endif
    if executable('python')
      call s:set_python_paths('python')
    endif
  elseif a:filetype ==# 'cpp'
        \ && !has_key(g:neocomplete#sources#include#paths, 'cpp')
        \ && isdirectory('/usr/include/c++')
    call s:set_cpp_paths(a:bufnr)
  endif
endfunction"}}}

function! neoinclude#get_path(bufnr, filetype) abort "{{{
  return neocomplete#util#substitute_path_separator(
        \ get(g:neocomplete#sources#include#paths, a:filetype,
        \   getbufvar(a:bufnr, '&path')))
endfunction"}}}
function! neoinclude#get_pattern(bufnr, filetype) abort "{{{
  return get(g:neocomplete#sources#include#patterns,
        \ a:filetype, getbufvar(a:bufnr, '&include'))
endfunction"}}}
function! neoinclude#get_expr(bufnr, filetype) abort "{{{
  return get(g:neocomplete#sources#include#exprs,
        \ a:filetype, getbufvar(a:bufnr, '&includeexpr'))
endfunction"}}}
function! neoinclude#get_reverse_expr(filetype) abort "{{{
  return get(g:neocomplete#sources#file_include#exprs,
        \ a:filetype, '')
endfunction"}}}
function! neoinclude#get_exts(filetype) abort "{{{
  return get(g:neocomplete#sources#file_include#exts,
        \ a:filetype, [])
endfunction"}}}
function! neoinclude#get_function(filetype) abort "{{{
  return get(g:neocomplete#sources#include#functions,
        \ a:filetype, '')
endfunction"}}}
function! neoinclude#get_delimiters(filetype) abort "{{{
  return get(g:neocomplete#sources#file_include#delimiters,
        \ a:filetype, '.')
endfunction"}}}

" Analyze include files functions.
function! neoinclude#analyze_vim_include_files(lines, path) "{{{
  let include_files = []
  let dup_check = {}
  for line in a:lines
    if line =~ '\<\h\w*#' && line !~ '\<function!\?\>'
      let filename = 'autoload/' . substitute(matchstr(line, '\<\%(\h\w*#\)*\h\w*\ze#'),
            \ '#', '/', 'g') . '.vim'
      if filename == '' || has_key(dup_check, filename)
        continue
      endif
      let dup_check[filename] = 1

      let filename = fnamemodify(findfile(filename, &runtimepath), ':p')
      if filereadable(filename)
        call add(include_files, filename)
      endif
    endif
  endfor

  return include_files
endfunction"}}}
function! neoinclude#analyze_ruby_include_files(lines, path) "{{{
  let include_files = []
  let dup_check = {}
  for line in a:lines
    if line =~ '\<autoload\>'
      let args = split(line, ',')
      if len(args) < 2
        continue
      endif
      let filename = substitute(matchstr(args[1], '["'']\zs\f\+\ze["'']'),
            \ '\.', '/', 'g') . '.rb'
      if filename == '' || has_key(dup_check, filename)
        continue
      endif
      let dup_check[filename] = 1

      let filename = fnamemodify(findfile(filename, a:path), ':p')
      if filereadable(filename)
        call add(include_files, filename)
      endif
    endif
  endfor

  return include_files
endfunction"}}}

function! s:set_python_paths(python_bin) "{{{
  let python_sys_path_cmd = a:python_bin .
        \ ' -c "import sys;sys.stdout.write(\",\".join(sys.path))"'
  let path = neocomplete#system(python_sys_path_cmd)
  let path = join(neocomplete#util#uniq(filter(
        \ split(path, ',', 1), "v:val != ''")), ',')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#include#paths', a:python_bin, path)
endfunction"}}}

function! s:set_cpp_paths(bufnr) "{{{
  if exists('*vimproc#readdir')
    let files = vimproc#readdir('/usr/include/')
          \ + vimproc#readdir('/usr/include/c++/')
    for directory in filter(split(glob(
          \ '/usr/include/*/c++'), '\n'), 'isdirectory(v:val)')
      let files += vimproc#readdir(directory)
    endfor
  else
    let files = split(glob('/usr/include/*'), '\n')
          \ + split(glob('/usr/include/c++/*'), '\n')
          \ + split(glob('/usr/include/*/c++/*'), '\n')
  endif
  call filter(files, 'isdirectory(v:val)')

  " Add cpp path.
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#include#paths', 'cpp',
        \ getbufvar(a:bufnr, '&path') .
        \ ','.join(files, ','))
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
