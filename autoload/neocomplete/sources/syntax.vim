"=============================================================================
" FILE: syntax.vim
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

" Important variables.
if !exists('s:syntax_list')
  let s:syntax_list = {}
endif

let s:source = {
      \ 'name' : 'syntax',
      \ 'kind' : 'keyword',
      \ 'mark' : '[S]',
      \ 'rank' : 4,
      \ 'hooks' : {},
      \}

function! s:source.hooks.on_init(context) "{{{
  autocmd neocomplete Syntax * call s:make_cache()

  " Create cache directory.
  call neocomplete#cache#make_directory('syntax_cache')

  " Initialize check.
  call s:make_cache()
endfunction"}}}

function! s:source.hooks.on_final(context) "{{{
  silent! delcommand NeoCompleteSyntaxMakeCache
endfunction"}}}

function! s:source.gather_candidates(context) "{{{
  if &filetype == ''
    return []
  endif

  let list = []

  if !has_key(s:syntax_list, &filetype)
    call s:make_cache()
  endif

  for syntax in neocomplete#helper#ftdictionary2list(
        \ s:syntax_list, neocomplete#get_context_filetype())
    let list += syntax
  endfor

  return list
endfunction"}}}

function! neocomplete#sources#syntax#define() "{{{
  return s:source
endfunction"}}}

function! s:make_cache() "{{{
  if &filetype == '' || &filetype ==# 'vim'
    return
  endif

  for filetype in filter(neocomplete#get_source_filetypes(&filetype),
        \ '!has_key(s:syntax_list, v:val)')
    " Check old cache.
    let cache_name = neocomplete#cache#encode_name(
          \ 'syntax_cache', filetype)
    if getftime(cache_name) < 0
      if filetype ==# &filetype
        " Make cache from syntax list.
        let s:syntax_list[filetype] = s:make_cache_from_syntax(filetype)
      endif
    else
      let s:syntax_list[filetype] =
            \ neocomplete#cache#load_from_cache(
            \      'syntax_cache', filetype, 1)
    endif
  endfor
endfunction"}}}

function! neocomplete#sources#syntax#remake_cache(filetype) "{{{
  if !neocomplete#is_enabled()
    call neocomplete#initialize()
  endif

  if a:filetype == ''
    let filetype = &filetype
  else
    let filetype = a:filetype
  endif

  if filetype == ''
    let filetype = 'nothing'
  endif

  let s:syntax_list[filetype] = s:make_cache_from_syntax(filetype)
endfunction"}}}

function! s:make_cache_from_syntax(filetype) "{{{
  " Get current syntax list.
  let syntax_list = ''
  redir => syntax_list
  silent! syntax list
  redir END

  if syntax_list =~ '^E\d\+' || syntax_list =~ '^No Syntax items'
    return []
  endif

  let group_name = ''
  let keyword_pattern = neocomplete#get_keyword_pattern(a:filetype, s:source.name)

  let filetype_pattern = tolower(substitute(
        \ matchstr(a:filetype, '[^_]*'), '-', '_', 'g'))

  let keyword_list = []
  for line in split(syntax_list, '\n')
    if line =~ '^\h\w\+'
      " Change syntax group name.
      let group_name = matchstr(line, '^\S\+')
      let line = substitute(line, '^\S\+\s*xxx', '', '')
    endif

    if line =~ 'Syntax items' || line =~ '^\s*links to' ||
          \ line =~ '^\s*nextgroup=' ||
          \ stridx(tolower(group_name), filetype_pattern) != 0
      " Next line.
      continue
    endif

    let line = substitute(line,
          \ 'contained\|skipwhite\|skipnl\|oneline', '', 'g')
    let line = substitute(line,
          \ '^\s*nextgroup=.*\ze\s', '', '')

    if line =~ '^\s*match'
      let line = s:substitute_candidate(
            \ matchstr(line, '/\zs[^/]\+\ze/'))
    elseif line =~ '^\s*start='
      let line =
            \s:substitute_candidate(
            \   matchstr(line, 'start=/\zs[^/]\+\ze/')) . ' ' .
            \s:substitute_candidate(
            \   matchstr(line, 'end=/zs[^/]\+\ze/'))
    endif

    " Add keywords.
    let match_num = 0
    let match_str = matchstr(line, keyword_pattern, match_num)

    while match_str != ''
      " Ignore too short keyword.
      if len(match_str) >= g:neocomplete#sources#syntax#min_keyword_length
            \&& match_str =~ '^[[:print:]]\+$'
        call add(keyword_list, match_str)
      endif

      let match_num += len(match_str)

      let match_str = matchstr(line, keyword_pattern, match_num)
    endwhile
  endfor

  let keyword_list = neocomplete#util#uniq(keyword_list)

  " Save syntax cache.
  call neocomplete#cache#save_cache(
        \ 'syntax_cache', a:filetype, keyword_list)

  return keyword_list
endfunction"}}}

function! s:substitute_candidate(candidate) "{{{
  let candidate = a:candidate

  " Collection.
  let candidate = substitute(candidate,
        \'\\\@<!\[[^\]]*\]', ' ', 'g')

  " Delete.
  let candidate = substitute(candidate,
        \'\\\@<!\%(\\[=?+]\|\\%[\|\\s\*\)', '', 'g')
  " Space.
  let candidate = substitute(candidate,
        \'\\\@<!\%(\\[<>{}]\|[$^]\|\\z\?\a\)', ' ', 'g')

  if candidate =~ '\\%\?('
    let candidate = join(neocomplete#sources#syntax#_split_pattern(
          \ candidate, ''))
  endif

  " \
  let candidate = substitute(candidate, '\\\\', '\\', 'g')
  " *
  let candidate = substitute(candidate, '\\\*', '*', 'g')
  return candidate
endfunction"}}}

function! neocomplete#sources#syntax#_split_pattern(keyword_pattern, prefix) "{{{
  let original_pattern = a:keyword_pattern
  let result_patterns = []
  let analyzing_patterns = [ '' ]

  let i = 0
  let max = len(original_pattern)
  while i < max
    if match(original_pattern, '^\\%\?(', i) >= 0
      " Grouping.
      let end = s:match_pair(original_pattern, '\\%\?(', '\\)', i)
      if end < 0
        break
      endif

      let save_patterns = analyzing_patterns
      let analyzing_patterns = []
      for pattern in filter(save_patterns, "v:val !~ '.*\\s\\+.*\\s'")
        let analyzing_patterns += neocomplete#sources#syntax#_split_pattern(
              \ original_pattern[matchend(original_pattern,
              \                 '^\\%\?(', i) : end-1],
              \ pattern)
      endfor

      let i = end + 2
    elseif match(original_pattern, '^\\|', i) >= 0
      " Select.
      let result_patterns += analyzing_patterns
      let analyzing_patterns = [ '' ]
      let original_pattern = original_pattern[i+2 :]
      let max = len(original_pattern)

      let i = 0
    elseif original_pattern[i] == '\' && i+1 < max
      call map(analyzing_patterns, 'v:val . original_pattern[i+1]')

      " Escape.
      let i += 2
    else
      call map(analyzing_patterns, 'v:val . original_pattern[i]')

      let i += 1
    endif
  endwhile

  let result_patterns += analyzing_patterns
  return map(result_patterns, 'a:prefix . v:val')
endfunction"}}}

function! s:match_pair(string, start_pattern, end_pattern, start_cnt) "{{{
  let end = -1
  let start_pattern = '\%(' . a:start_pattern . '\)'
  let end_pattern = '\%(' . a:end_pattern . '\)'

  let i = a:start_cnt
  let max = len(a:string)
  let nest_level = 0
  while i < max
    let start = match(a:string, start_pattern, i)
    let end = match(a:string, end_pattern, i)

    if start >= 0 && (end < 0 || start < end)
      let i = matchend(a:string, start_pattern, i)
      let nest_level += 1
    elseif end >= 0 && (start < 0 || end < start)
      let nest_level -= 1

      if nest_level == 0
        return end
      endif

      let i = matchend(a:string, end_pattern, i)
    else
      break
    endif
  endwhile

  if nest_level != 0
    return -1
  else
    return end
  endif
endfunction"}}}

" Global options definition. "{{{
let g:neocomplete#sources#syntax#min_keyword_length =
 \ get(g:, 'neocomplete#sources#syntax#min_keyword_length', 4)
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
