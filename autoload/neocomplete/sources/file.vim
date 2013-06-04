"=============================================================================
" FILE: file.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 04 Jun 2013.
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

let s:source = {
      \ 'name' : 'file',
      \ 'kind' : 'manual',
      \ 'mark' : '[F]',
      \ 'rank' : 3,
      \ 'min_pattern_length' :
      \        g:neocomplete#auto_completion_start_length,
      \ 'sorters' : 'sorter_filename',
      \ 'is_volatile' : 1,
      \}

function! s:source.get_complete_position(context) "{{{
  let filetype = neocomplete#get_context_filetype()
  if filetype ==# 'vimshell' || filetype ==# 'unite'
    return -1
  endif

  " Filename pattern.
  let pattern = neocomplete#get_keyword_pattern_end('filename')
  let [complete_pos, complete_str] =
        \ neocomplete#match_word(a:context.input, pattern)
  if complete_str =~ '//' ||
        \ (neocomplete#is_auto_complete() &&
        \    (complete_str !~ '/' ||
        \     complete_str =~#
        \          '\\[^ ;*?[]"={}'']\|\.\.\+$\|/c\%[ygdrive/]$'))
    " Not filename pattern.
    return -1
  endif

  if neocomplete#is_sources_complete() && complete_pos < 0
    let complete_pos = len(a:context.input)
  endif

  return complete_pos
endfunction"}}}

function! s:source.gather_candidates(context) "{{{
  return s:get_glob_files(a:context.complete_str, '')
endfunction"}}}

let s:cached_files = {}

function! s:get_glob_files(complete_str, path) "{{{
  let path = ',,' . substitute(a:path, '\.\%(,\|$\)\|,,', '', 'g')

  let complete_str = neocomplete#util#substitute_path_separator(
        \ substitute(a:complete_str, '\\\(.\)', '\1', 'g'))

  let glob = (complete_str !~ '\*$')?
        \ complete_str . '*' : complete_str

  let ftype = getftype(glob)
  if ftype != '' && ftype !=# 'dir'
    " Note: If glob() device files, Vim may freeze!
    return []
  endif

  if a:path == ''
    let files = neocomplete#util#glob(glob)
  else
    try
      let globs = globpath(path, glob)
    catch
      return []
    endtry
    let files = split(substitute(globs, '\\', '/', 'g'), '\n')
  endif

  let files = filter(files, "v:val !~ '/.$'")

  let files = map(
        \ files, "{
        \    'word' : v:val,
        \    'orig' : v:val,
        \    'action__is_directory' : isdirectory(v:val),
        \ }")

  if a:complete_str =~ '^\$\h\w*'
    let env = matchstr(a:complete_str, '^\$\h\w*')
    let env_ev = eval(env)
    if neocomplete#is_windows()
      let env_ev = substitute(env_ev, '\\', '/', 'g')
    endif
    let len_env = len(env_ev)
  else
    let len_env = 0
  endif

  let home_pattern = '^'.
        \ neocomplete#util#substitute_path_separator(
        \ expand('~')).'/'
  let exts = escape(substitute($PATHEXT, ';', '\\|', 'g'), '.')

  let candidates = []
  for dict in files
    let dict.orig = dict.word

    if len_env != 0 && dict.word[: len_env-1] == env_ev
      let dict.word = env . dict.word[len_env :]
    endif

    let abbr = dict.word
    if dict.action__is_directory && dict.word !~ '/$'
      let abbr .= '/'
      if g:neocomplete#enable_auto_delimiter
        let dict.word .= '/'
      endif
    elseif neocomplete#is_windows()
      if '.'.fnamemodify(dict.word, ':e') =~ exts
        let abbr .= '*'
      endif
    elseif executable(dict.word)
      let abbr .= '*'
    endif
    let dict.abbr = abbr

    if a:complete_str =~ '^\~/'
      let dict.word = substitute(dict.word, home_pattern, '\~/', '')
      let dict.abbr = substitute(dict.abbr, home_pattern, '\~/', '')
    endif

    " Escape word.
    let dict.word = escape(dict.word, ' ;*?[]"={}''')

    call add(candidates, dict)
  endfor

  return candidates
endfunction"}}}

function! neocomplete#sources#file#define() "{{{
  return s:source
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
