"=============================================================================
" FILE: filters.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 28 May 2013.
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

function! neocomplete#filters#keyword_filter(list, complete_str) "{{{
  let complete_str = a:complete_str

  if g:neocomplete_enable_debug
    echomsg len(a:list)
  endif

  " Delimiter check.
  let filetype = neocomplete#get_context_filetype()
  for delimiter in get(g:neocomplete_delimiter_patterns, filetype, [])
    let complete_str = substitute(complete_str,
          \ delimiter, '*' . delimiter, 'g')
  endfor

  if complete_str == '' ||
        \ &l:completefunc ==# 'neocomplete#complete#unite_complete' ||
        \ empty(a:list)
    return a:list
  elseif neocomplete#check_match_filter(complete_str)
    " Match filter.
    let word = type(a:list[0]) == type('') ? 'v:val' : 'v:val.word'

    let expr = printf('%s =~ %s',
          \ word, string('^' .
          \ neocomplete#keyword_escape(complete_str)))
    if neocomplete#is_auto_complete()
      " Don't complete cursor word.
      let expr .= printf(' && %s !=? a:complete_str', word)
    endif

    " Check head character.
    if complete_str[0] != '\' && complete_str[0] != '.'
      let expr = word.'[0] == ' .
            \ string(complete_str[0]) .' && ' . expr
    endif

    call neocomplete#print_debug(expr)

    return filter(a:list, expr)
  elseif neocomplete#util#has_lua()
    return s:lua_filter(a:list, complete_str)
  else
    " Use fast filter.
    return s:head_filter(a:list, complete_str)
  endif
endfunction"}}}

function! s:head_filter(list, complete_str) "{{{
  let word = type(a:list[0]) == type('') ? 'v:val' : 'v:val.word'

  if &ignorecase
   let expr = printf('!stridx(tolower(%s), %s)',
          \ word, string(tolower(a:complete_str)))
  else
    let expr = printf('!stridx(%s, %s)',
          \ word, string(a:complete_str))
  endif

  if neocomplete#is_auto_complete()
    " Don't complete cursor word.
    let expr .= printf(' && %s !=? a:complete_str', word)
  endif

  return filter(a:list, expr)
endfunction"}}}
function! s:lua_filter(list, complete_str) "{{{
  lua << EOF
  do
    local input = vim.eval('a:complete_str')
    local candidates = vim.eval('a:list')
    if (vim.eval('&ignorecase') ~= 0) then
      input = string.lower(input)
      for i = #candidates-1, 0, -1 do
        local word = vim.type(candidates[i]) == 'dict' and
          string.lower(candidates[i].word) or string.lower(candidates[i])
        if (string.find(word, input, 1, true) == nil) and word ~= input then
          candidates[i] = nil
        end
      end
    else
      for i = #candidates-1, 0, -1 do
        local word = vim.type(candidates[i]) == 'dict' and
          candidates[i].word or candidates[i]
        if (string.find(word, input, 1, true) == nil) and word ~= input then
          candidates[i] = nil
        end
      end
    end
  end
EOF

  return a:list
endfunction"}}}

function! neocomplete#filters#dictionary_filter(dictionary, complete_str) "{{{
  if empty(a:dictionary)
    return []
  endif

  let completion_length = 2
  if len(a:complete_str) < completion_length ||
        \ neocomplete#check_completion_length_match(
        \         a:complete_str, completion_length) ||
        \ &l:completefunc ==# 'neocomplete#cunite_complete'
    return neocomplete#keyword_filter(
          \ neocomplete#unpack_dictionary(a:dictionary), a:complete_str)
  endif

  let key = tolower(a:complete_str[: completion_length-1])

  if !has_key(a:dictionary, key)
    return []
  endif

  let list = a:dictionary[key]
  if type(list) == type({})
    " Convert dictionary dictionary.
    unlet list
    let list = values(a:dictionary[key])
  else
    let list = copy(list)
  endif

  return (len(a:complete_str) == completion_length && &ignorecase
        \ && !neocomplete#check_completion_length_match(
        \   a:complete_str, completion_length)) ?
        \ list : neocomplete#keyword_filter(list, a:complete_str)
endfunction"}}}

function! neocomplete#filters#fuzzy_escape(string) "{{{
  " Escape string for lua regexp.
  return substitute(neocomplete#filters#escape(a:string),
        \ '\w', '\0.*', 'g')
endfunction"}}}

function! neocomplete#filters#escape(string) "{{{
  " Escape string for lua regexp.
  return substitute(a:string,
        \ '[%\[\]().*+?^$-]', '%\0', 'g')
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
