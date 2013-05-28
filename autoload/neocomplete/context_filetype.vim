"=============================================================================
" FILE: context_filetype.vim
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

let s:stopline = 100
let s:timeout = 10

function! neocomplete#context_filetype#initialize() "{{{
  " Initialize context filetype lists.
  call neocomplete#util#set_default(
        \ 'g:neocomplete_context_filetype_lists', {})
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete_context_filetype_lists',
        \ 'c,cpp', [
        \ {'filetype' : 'masm',
        \  'start' : '_*asm_*\s\+\h\w*', 'end' : '$'},
        \ {'filetype' : 'masm',
        \  'start' : '_*asm_*\s*\%(\n\s*\)\?{', 'end' : '}'},
        \ {'filetype' : 'gas',
        \  'start' : '_*asm_*\s*\%(_*volatile_*\s*\)\?(', 'end' : ');'},
        \])
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete_context_filetype_lists',
        \ 'd', [
        \ {'filetype' : 'masm',
        \  'start' : 'asm\s*\%(\n\s*\)\?{', 'end' : '}'},
        \])
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete_context_filetype_lists',
        \ 'perl6', [
        \ {'filetype' : 'pir', 'start' : 'Q:PIR\s*{', 'end' : '}'},
        \])
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete_context_filetype_lists',
        \ 'vimshell', [
        \ {'filetype' : 'vim',
        \  'start' : 'vexe \([''"]\)', 'end' : '\\\@<!\1'},
        \ {'filetype' : 'vim', 'start' : ' :\w*', 'end' : '\n'},
        \ {'filetype' : 'vim', 'start' : ' vexe\s\+', 'end' : '\n'},
        \])
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete_context_filetype_lists',
        \ 'eruby', [
        \ {'filetype' : 'ruby', 'start' : '<%[=#]\?', 'end' : '%>'},
        \])
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete_context_filetype_lists',
        \ 'vim', [
        \ {'filetype' : 'python',
        \  'start' : '^\s*py\%[thon\]3\? <<\s*\(\h\w*\)', 'end' : '^\1'},
        \ {'filetype' : 'ruby',
        \  'start' : '^\s*rub\%[y\] <<\s*\(\h\w*\)', 'end' : '^\1'},
        \ {'filetype' : 'lua',
        \  'start' : '^\s*lua <<\s*\(\h\w*\)', 'end' : '^\1'},
        \])
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete_context_filetype_lists',
        \ 'html,xhtml', [
        \ {'filetype' : 'javascript', 'start' :
        \'<script\%( [^>]*\)\? type="text/javascript"\%( [^>]*\)\?>',
        \  'end' : '</script>'},
        \ {'filetype' : 'coffee', 'start' :
        \'<script\%( [^>]*\)\? type="text/coffeescript"\%( [^>]*\)\?>',
        \  'end' : '</script>'},
        \ {'filetype' : 'css', 'start' :
        \'<script\%( [^>]*\)\? type="text/css"\%( [^>]*\)\?>',
        \  'end' : '</style>'},
        \])
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete_context_filetype_lists',
        \ 'python', [
        \ {'filetype' : 'vim',
        \  'start' : 'vim.command\s*(\([''"]\)', 'end' : '\\\@<!\1\s*)'},
        \ {'filetype' : 'vim',
        \  'start' : 'vim.eval\s*(\([''"]\)', 'end' : '\\\@<!\1\s*)'},
        \])
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete_context_filetype_lists',
        \ 'help', [
        \ {'filetype' : 'vim', 'start' : '^>', 'end' : '^<'},
        \])
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete_context_filetype_lists',
        \ 'nyaos,int-nyaos', [
        \ {'filetype' : 'lua',
        \  'start' : '\<lua_e\s\+\(["'']\)', 'end' : '^\1'},
        \])
endfunction"}}}

function! neocomplete#context_filetype#set() "{{{
  let old_filetype = neocomplete#get_current_neocomplete().filetype
  if old_filetype == ''
    let old_filetype = &filetype
  endif
  if old_filetype == ''
    let old_filetype = 'nothing'
  endif

  let neocomplete = neocomplete#get_current_neocomplete()

  let dup_check = {}
  while 1
    let new_filetype = neocomplete#context_filetype#get(old_filetype)

    " Check filetype root.
    if get(dup_check, old_filetype, '') ==# new_filetype
      let neocomplete.context_filetype = old_filetype
      break
    endif

    " Save old -> new filetype graph.
    let dup_check[old_filetype] = new_filetype
    let old_filetype = new_filetype
  endwhile

  return neocomplete.context_filetype
endfunction"}}}
function! neocomplete#context_filetype#get(filetype) "{{{
  " Default.
  let filetype = a:filetype
  if filetype == ''
    let filetype = 'nothing'
  endif

  " Default range.
  let neocomplete = neocomplete#get_current_neocomplete()

  let pos = [line('.'), col('.')]
  for include in get(g:neocomplete_context_filetype_lists, filetype, [])
    let start_backward = searchpos(include.start,
      \ 'bneW', line('.')-s:stopline, s:timeout)

    " Check pos > start.
    if start_backward[0] == 0 || s:compare_pos(start_backward, pos) > 0
      continue
    endif

    let end_pattern = include.end
    if end_pattern =~ '\\1'
      let match_list = matchlist(getline(start_backward[0]), include.start)
      let end_pattern = substitute(end_pattern, '\\1', '\=match_list[1]', 'g')
    endif
    let end_forward = searchpos(end_pattern, 'nW',
          \ line('.')+s:stopline, s:timeout)
    if end_forward[0] == 0
      let end_forward = [line('$'), len(getline('$'))+1]
    endif

    " Check end > pos.
    if s:compare_pos(pos, end_forward) > 0
      continue
    endif

    let end_backward = searchpos(end_pattern, 'bnW',
          \ line('.')+s:stopline, s:timeout)

    " Check start <= end.
    if s:compare_pos(start_backward, end_backward) < 0
      continue
    endif

    if start_backward[1] == len(getline(start_backward[0]))
      " Next line.
      let start_backward[0] += 1
      let start_backward[1] = 1
    endif
    if end_forward[1] == 1
      " Previous line.
      let end_forward[0] -= 1
      let end_forward[1] = len(getline(end_forward[0]))
    endif

    let neocomplete.context_filetype_range =
          \ [ start_backward, end_forward ]
    return include.filetype
  endfor

  return filetype
endfunction"}}}

function! s:compare_pos(i1, i2)
  return a:i1[0] == a:i2[0] ? a:i1[1] - a:i2[1] : a:i1[0] - a:i2[0]
endfunction"

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
