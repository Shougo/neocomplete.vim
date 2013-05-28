"=============================================================================
" FILE: neocomplete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
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
" GetLatestVimScripts: 2620 1 :AutoInstall: neocomplete
"=============================================================================

if exists('g:loaded_neocomplete')
  finish
endif
let g:loaded_neocomplete = 1

let s:save_cpo = &cpo
set cpo&vim

if $SUDO_USER != '' && $USER !=# $SUDO_USER
      \ && $HOME !=# expand('~'.$USER)
      \ && $HOME ==# expand('~'.$SUDO_USER)
  echohl Error
  echomsg 'neocomplete disabled: "sudo vim" is detected and $HOME is set to '
        \.'your user''s home. '
        \.'You may want to use the sudo.vim plugin, the "-H" option '
        \.'with "sudo" or set always_set_home in /etc/sudoers instead.'
  echohl None
  finish
elseif !(has('lua') && (v:version > 703 || v:version == 703 && has('patch885')))
  echomsg 'neocomplete does not work this version of Vim.'
  echomsg 'It requires Vim 7.3.885 or above and "if_lua" enabled Vim.'
endif

command! -nargs=0 -bar NeoCompleteEnable
      \ call neocomplete#init#enable()
command! -nargs=0 -bar NeoCompleteDisable
      \ call neocomplete#init#disable()
command! -nargs=0 -bar NeoCompleteLock
      \ call neocomplete#commands#_lock()
command! -nargs=0 -bar NeoCompleteUnlock
      \ call neocomplete#commands#_unlock()
command! -nargs=0 -bar NeoCompleteToggle
      \ call neocomplete#commands#_toggle_lock()
command! -nargs=1 -bar NeoCompleteLockSource
      \ call neocomplete#commands#_lock_source(<q-args>)
command! -nargs=1 -bar NeoCompleteUnlockSource
      \ call neocomplete#commands#_unlock_source(<q-args>)
if v:version >= 703
  command! -nargs=1 -bar -complete=filetype NeoCompleteSetFileType
        \ call neocomplete#commands#_set_file_type(<q-args>)
else
  command! -nargs=1 -bar NeoCompleteSetFileType
        \ call neocomplete#commands#_set_file_type(<q-args>)
endif
command! -nargs=0 -bar NeoCompleteClean
      \ call neocomplete#commands#_clean()

" Warning if using obsolute mappings. "{{{
silent! inoremap <unique> <Plug>(neocomplete_snippets_expand)
      \ <C-o>:echoerr <SID>print_snippets_complete_error()<CR>
silent! snoremap <unique> <Plug>(neocomplete_snippets_expand)
      \ :<C-u>:echoerr <SID>print_snippets_complete_error()<CR>
silent! inoremap <unique> <Plug>(neocomplete_snippets_jump)
      \ <C-o>:echoerr <SID>print_snippets_complete_error()<CR>
silent! snoremap <unique> <Plug>(neocomplete_snippets_jump)
      \ :<C-u>:echoerr <SID>print_snippets_complete_error()<CR>
silent! inoremap <unique> <Plug>(neocomplete_snippets_force_expand)
      \ <C-o>:echoerr <SID>print_snippets_complete_error()<CR>
silent! snoremap <unique> <Plug>(neocomplete_snippets_force_expand)
      \ :<C-u>:echoerr <SID>print_snippets_complete_error()<CR>
silent! inoremap <unique> <Plug>(neocomplete_snippets_force_jump)
      \ <C-o>:echoerr <SID>print_snippets_complete_error()<CR>
silent! snoremap <unique> <Plug>(neocomplete_snippets_force_jump)
      \ :<C-u>:echoerr <SID>print_snippets_complete_error()<CR>
function! s:print_snippets_complete_error()
  return 'Warning: neocomplete snippets source was splitted!'
      \ .' You should install snippets_complete source from'
      \ .' "https://github.com/Shougo/neocomplete-snippets-complete"'
endfunction"}}}

" Global options definition. "{{{
let g:neocomplete_max_list =
      \ get(g:, 'neocomplete_max_list', 100)
let g:neocomplete_max_keyword_width =
      \ get(g:, 'neocomplete_max_keyword_width', 80)
let g:neocomplete_max_menu_width =
      \ get(g:, 'neocomplete_max_menu_width', 15)
let g:neocomplete_auto_completion_start_length =
      \ get(g:, 'neocomplete_auto_completion_start_length', 2)
let g:neocomplete_manual_completion_start_length =
      \ get(g:, 'neocomplete_manual_completion_start_length', 0)
let g:neocomplete_min_keyword_length =
      \ get(g:, 'neocomplete_min_keyword_length', 4)
let g:neocomplete_enable_ignore_case =
      \ get(g:, 'neocomplete_enable_ignore_case', &ignorecase)
let g:neocomplete_enable_smart_case =
      \ get(g:, 'neocomplete_enable_smart_case', &infercase)
let g:neocomplete_disable_auto_complete =
      \ get(g:, 'neocomplete_disable_auto_complete', 0)
let g:neocomplete_enable_wildcard =
      \ get(g:, 'neocomplete_enable_wildcard', 1)
let g:neocomplete_enable_camel_case_completion =
      \ get(g:, 'neocomplete_enable_camel_case_completion', 0)
let g:neocomplete_enable_underbar_completion =
      \ get(g:, 'neocomplete_enable_underbar_completion', 0)
let g:neocomplete_enable_fuzzy_completion =
      \ get(g:, 'neocomplete_enable_fuzzy_completion', 1)
let g:neocomplete_fuzzy_completion_start_length =
      \ get(g:, 'neocomplete_fuzzy_completion_start_length', 3)
let g:neocomplete_enable_caching_message =
      \ get(g:, 'neocomplete_enable_caching_message', 1)
let g:neocomplete_enable_insert_char_pre =
      \ get(g:, 'neocomplete_enable_insert_char_pre', 0)
let g:neocomplete_enable_cursor_hold_i =
      \ get(g:, 'neocomplete_enable_cursor_hold_i', 0)
let g:neocomplete_cursor_hold_i_time =
      \ get(g:, 'neocomplete_cursor_hold_i_time', 300)
let g:neocomplete_enable_auto_select =
      \ get(g:, 'neocomplete_enable_auto_select', 0)
let g:neocomplete_enable_auto_delimiter =
      \ get(g:, 'neocomplete_enable_auto_delimiter', 0)
let g:neocomplete_caching_limit_file_size =
      \ get(g:, 'neocomplete_caching_limit_file_size', 500000)
let g:neocomplete_disable_caching_file_path_pattern =
      \ get(g:, 'neocomplete_disable_caching_file_path_pattern', '')
let g:neocomplete_lock_buffer_name_pattern =
      \ get(g:, 'neocomplete_lock_buffer_name_pattern', '')
let g:neocomplete_ctags_program =
      \ get(g:, 'neocomplete_ctags_program', 'ctags')
let g:neocomplete_force_overwrite_completefunc =
      \ get(g:, 'neocomplete_force_overwrite_completefunc', 0)
let g:neocomplete_enable_prefetch =
      \ get(g:, 'neocomplete_enable_prefetch',
      \  has('gui_running') && has('xim'))
let g:neocomplete_lock_iminsert =
      \ get(g:, 'neocomplete_lock_iminsert', 0)
let g:neocomplete_release_cache_time =
      \ get(g:, 'neocomplete_release_cache_time', 900)
let g:neocomplete_wildcard_characters =
      \ get(g:, 'neocomplete_wildcard_characters', {
      \ '_' : '*' })
let g:neocomplete_skip_auto_completion_time =
      \ get(g:, 'neocomplete_skip_auto_completion_time', '0.3')
let g:neocomplete_enable_auto_close_preview =
      \ get(g:, 'neocomplete_enable_auto_close_preview', 1)

let g:neocomplete_sources_list =
      \ get(g:, 'neocomplete_sources_list', {})
let g:neocomplete_disabled_sources_list =
      \ get(g:, 'neocomplete_disabled_sources_list', {})
if exists('g:neocomplete_source_disable')
  let g:neocomplete_disabled_sources_list._ =
        \ keys(filter(copy(g:neocomplete_source_disable), 'v:val'))
endif

if exists('g:neocomplete_plugin_completion_length')
  let g:neocomplete_source_completion_length =
        \ g:neocomplete_plugin_completion_length
endif
let g:neocomplete_source_completion_length =
      \ get(g:, 'neocomplete_source_completion_length', {})
if exists('g:neocomplete_plugin_rank')
  let g:neocomplete_source_rank = g:neocomplete_plugin_rank
endif
let g:neocomplete_source_rank =
      \ get(g:, 'neocomplete_source_rank', {})

let g:neocomplete_temporary_dir =
      \ get(g:, 'neocomplete_temporary_dir', expand('~/.neocomplete'))
let g:neocomplete_enable_debug =
      \ get(g:, 'neocomplete_enable_debug', 0)
if get(g:, 'neocomplete_enable_at_startup', 0)
  augroup neocomplete
    " Enable startup.
    autocmd CursorHold,CursorMovedI
          \ * call neocomplete#init#lazy()
  augroup END
endif"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
