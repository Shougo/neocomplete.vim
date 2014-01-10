"=============================================================================
" FILE: mappings.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 11 Jan 2014.
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

function! neocomplete#mappings#define_default_mappings() "{{{
  inoremap <expr><silent> <Plug>(neocomplete_start_unite_complete)
        \ unite#sources#neocomplete#start_complete()
  inoremap <expr><silent> <Plug>(neocomplete_start_unite_quick_match)
        \ unite#sources#neocomplete#start_quick_match()
  inoremap <silent> <Plug>(neocomplete_start_omni_complete)
        \ <C-x><C-o><C-p>
  if neocomplete#util#is_complete_select()
    inoremap <silent> <Plug>(neocomplete_start_auto_complete)
          \ <C-x><C-u>
  else
    inoremap <silent> <Plug>(neocomplete_start_auto_complete)
          \ <C-x><C-u><C-r>=neocomplete#mappings#popup_post()<CR>
  endif
endfunction"}}}

function! neocomplete#mappings#smart_close_popup() "{{{
  let key = g:neocomplete#enable_auto_select ?
        \ neocomplete#mappings#cancel_popup() :
        \ neocomplete#mappings#close_popup()

  " Don't skip next complete.
  let neocomplete = neocomplete#get_current_neocomplete()
  let neocomplete.skip_next_complete = 0
  let neocomplete.old_linenr = 0

  return key
endfunction
"}}}
function! neocomplete#mappings#close_popup() "{{{
  let neocomplete = neocomplete#get_current_neocomplete()
  let neocomplete.complete_str = ''
  let neocomplete.skip_next_complete = 2

  return pumvisible() ? "\<C-y>" : ''
endfunction
"}}}
function! neocomplete#mappings#cancel_popup() "{{{
  let neocomplete = neocomplete#get_current_neocomplete()
  let neocomplete.skip_next_complete = 1

  return pumvisible() ? "\<C-e>" : ''
endfunction
"}}}

function! neocomplete#mappings#popup_post() "{{{
  return  !pumvisible() ? "" :
        \ g:neocomplete#enable_auto_select ? "\<C-p>\<Down>" :
        \ "\<C-p>"
endfunction"}}}

function! neocomplete#mappings#undo_completion() "{{{
  if !neocomplete#is_enabled()
    return ''
  endif

  let neocomplete = neocomplete#get_current_neocomplete()

  " Get cursor word.
  let [complete_pos, complete_str] =
        \ neocomplete#helper#match_word(neocomplete#get_cur_text(1))
  let old_keyword_str = neocomplete.complete_str
  let neocomplete.complete_str = complete_str

  return (!pumvisible() ? '' :
        \ complete_str ==# old_keyword_str ? "\<C-e>" : "\<C-y>")
        \. repeat("\<BS>", len(complete_str)) . old_keyword_str
endfunction"}}}

function! neocomplete#mappings#complete_common_string() "{{{
  if !neocomplete#is_enabled()
    return ''
  endif

  " Save options.
  let ignorecase_save = &ignorecase

  " Get cursor word.
  let [complete_pos, complete_str] =
        \ neocomplete#helper#match_word(neocomplete#get_cur_text(1))

  if neocomplete#is_text_mode()
    let &ignorecase = 1
  elseif g:neocomplete#enable_smart_case || g:neocomplete#enable_camel_case
    let &ignorecase = complete_str !~ '\u'
  else
    let &ignorecase = g:neocomplete#enable_ignore_case
  endif

  let neocomplete = neocomplete#get_current_neocomplete()
  let candidates = neocomplete#filters#matcher_head#define().filter(
        \ { 'candidates' : copy(neocomplete.candidates),
        \   'complete_str' : complete_str})

  if empty(candidates)
    return ''
  endif

  let common_str = candidates[0].word
  try
    for keyword in candidates[1:]
      while !neocomplete#head_match(keyword.word, common_str)
        let common_str = common_str[: -2]
      endwhile
    endfor

    if &ignorecase
      let common_str = tolower(common_str)
    endif
  finally
    let &ignorecase = ignorecase_save
  endtry

  if common_str == ''
    return ''
  endif

  return (pumvisible() ? "\<C-e>" : '')
        \ . repeat("\<BS>", len(complete_str)) . common_str
endfunction"}}}

" Manual complete wrapper.
function! neocomplete#mappings#start_manual_complete(...) "{{{
  if !neocomplete#is_enabled()
    return ''
  endif

  " Set context filetype.
  call neocomplete#context_filetype#set()

  let neocomplete = neocomplete#get_current_neocomplete()

  let sources = get(a:000, 0,
        \ keys(neocomplete#available_sources()))
  let neocomplete.manual_sources = neocomplete#helper#get_sources_list(
        \ neocomplete#util#convert2list(sources))

  " Set function.
  let &l:completefunc = 'neocomplete#complete#sources_manual_complete'

  " Start complete.
  return "\<C-x>\<C-u>\<C-p>"
        \ . (g:neocomplete#enable_auto_select ? "\<Down>" : "")
endfunction"}}}

function! neocomplete#mappings#start_manual_complete_list(complete_pos, complete_str, candidates) "{{{
  let neocomplete = neocomplete#get_current_neocomplete()
  let [neocomplete.complete_pos,
        \ neocomplete.complete_str, neocomplete.candidates] =
        \ [a:complete_pos, a:complete_str, a:candidates]

  " Set function.
  let &l:completefunc = 'neocomplete#complete#auto_complete'

  " Start complete.
  return "\<C-x>\<C-u>\<C-p>"
        \ . (g:neocomplete#enable_auto_select ? "\<Down>" : "")
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
