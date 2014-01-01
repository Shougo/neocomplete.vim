"=============================================================================
" FILE: vim.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 01 Jan 2014.
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
let g:neocomplete#sources#vim#complete_functions =
      \ get(g:, 'neocomplete#sources#vim#complete_functions', {})
"}}}

let s:source = {
      \ 'name' : 'vim',
      \ 'kind' : 'manual',
      \ 'filetypes' : { 'vim' : 1, 'vimconsole' : 1, },
      \ 'mark' : '[vim]',
      \ 'is_volatile' : 1,
      \ 'rank' : 300,
      \ 'hooks' : {},
      \}

function! s:source.hooks.on_init(context) "{{{
  " Initialize.

  autocmd neocomplete FileType *
        \ call neocomplete#sources#vim#helper#on_filetype()

  " Initialize check.
  call neocomplete#sources#vim#helper#on_filetype()

  " Add command.
  command! -nargs=? -complete=buffer NeoCompleteVimMakeCache
        \ call neocomplete#sources#vim#helper#make_cache(<q-args>)
endfunction"}}}

function! s:source.hooks.on_final(context) "{{{
  silent! delcommand NeoCompleteVimMakeCache
endfunction"}}}

function! s:source.get_complete_position(context) "{{{
  let cur_text = neocomplete#sources#vim#get_cur_text()

  if cur_text =~ '^\s*"'
    " Comment.
    return -1
  endif

  let pattern = '\.\%(\h\w*\)\?$\|' .
        \ neocomplete#get_keyword_pattern_end('vim', self.name)
  if cur_text != '' && cur_text !~
        \ '^[[:digit:],[:space:][:tab:]$''<>]*\h\w*$'
    let command_completion =
          \ neocomplete#sources#vim#helper#get_completion_name(
          \   neocomplete#sources#vim#get_command(cur_text))
    if command_completion =~ '\%(dir\|file\|shellcmd\)'
      let pattern = neocomplete#get_keyword_pattern_end('filename', self.name)
    endif
  endif

  let [complete_pos, complete_str] =
        \ neocomplete#helper#match_word(a:context.input, pattern)
  if complete_pos < 0
    " Use args pattern.
    let [complete_pos, complete_str] =
          \ neocomplete#helper#match_word(a:context.input, '\S\+$')
  endif

  if a:context.input !~ '\.\%(\h\w*\)\?$' && neocomplete#is_auto_complete()
        \ && len(complete_str) < g:neocomplete#auto_completion_start_length
    return -1
  endif

  return complete_pos
endfunction"}}}

function! s:source.gather_candidates(context) "{{{
  let cur_text = neocomplete#sources#vim#get_cur_text()
  if neocomplete#is_auto_complete() && cur_text !~ '\h\w*\.\%(\h\w*\)\?$'
        \ && len(a:context.complete_str) <
        \      g:neocomplete#auto_completion_start_length
        \ && bufname('%') !=# '[Command Line]'
    return []
  endif

  if cur_text =~ '\h\w*\.\%(\h\w*\)\?$'
    " Dictionary.
    let complete_str = matchstr(cur_text, '.\%(\h\w*\)\?$')
    return neocomplete#sources#vim#helper#var_dictionary(
          \ cur_text, complete_str)
  elseif a:context.complete_str =~# '^&\%([gl]:\)\?'
    " Options.
    let prefix = matchstr(a:context.complete_str, '^&\%([gl]:\)\?')
    let list = deepcopy(
          \ neocomplete#sources#vim#helper#option(
          \   cur_text, a:context.complete_str))
    for keyword in list
      let keyword.word =
            \ prefix . keyword.word
    endfor
  elseif a:context.complete_str =~? '^\c<sid>'
    " SID functions.
    let prefix = matchstr(a:context.complete_str, '^\c<sid>')
    let complete_str = substitute(
          \ a:context.complete_str, '^\c<sid>', 's:', '')
    let list = deepcopy(
          \ neocomplete#sources#vim#helper#function(
          \     cur_text, complete_str))
    for keyword in list
      let keyword.word = prefix . keyword.word[2:]
      let keyword.abbr = prefix .
            \ get(keyword, 'abbr', keyword.word)[2:]
    endfor
  elseif cur_text =~# '\<has([''"]\w*$'
    " Features.
    let list = neocomplete#sources#vim#helper#feature(
          \ cur_text, a:context.complete_str)
  elseif cur_text =~# '\<expand([''"][<>[:alnum:]]*$'
    " Expand.
    let list = neocomplete#sources#vim#helper#expand(
          \ cur_text, a:context.complete_str)
  elseif a:context.complete_str =~ '^\$'
    " Environment.
    let list = neocomplete#sources#vim#helper#environment(
          \ cur_text, a:context.complete_str)
  elseif cur_text =~ '^[[:digit:],[:space:][:tab:]$''<>]*!\s*\f\+$'
    " Shell commands.
    let list = neocomplete#sources#vim#helper#shellcmd(
          \ cur_text, a:context.complete_str)
  else
    " Commands.
    let list = neocomplete#sources#vim#helper#command(
          \ cur_text, a:context.complete_str)
  endif

  return list
endfunction"}}}

function! neocomplete#sources#vim#define() "{{{
  return s:source
endfunction"}}}

function! neocomplete#sources#vim#get_cur_text() "{{{
  let cur_text = neocomplete#get_cur_text(1)
  if &filetype == 'vimshell' && exists('*vimshell#get_secondary_prompt')
        \   && empty(b:vimshell.continuation)
    return cur_text[len(vimshell#get_secondary_prompt()) :]
  endif

  let line = line('.')
  let cnt = 0
  while cur_text =~ '^\s*\\' && line > 1 && cnt < 5
    let cur_text = getline(line - 1) .
          \ substitute(cur_text, '^\s*\\', '', '')
    let line -= 1
    let cnt += 1
  endwhile

  return split(cur_text, '\s\+|\s\+\|<bar>', 1)[-1]
endfunction"}}}
function! neocomplete#sources#vim#get_command(cur_text) "{{{
  return matchstr(a:cur_text, '\<\%(\d\+\)\?\zs\h\w*\ze!\?\|'.
        \ '\<\%([[:digit:],[:space:]$''<>]\+\)\?\zs\h\w*\ze/.*')
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
