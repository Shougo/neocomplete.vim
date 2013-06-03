"=============================================================================
" FILE: neocomplete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 03 Jun 2013.
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

if !exists('g:loaded_neocomplete')
  runtime! plugin/neocomplete.vim
endif

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

function! neocomplete#initialize() "{{{
  return neocomplete#init#enable()
endfunction"}}}

function! neocomplete#get_current_neocomplete() "{{{
  if !exists('b:neocomplete')
    call neocomplete#init#_current_neocomplete()
  endif

  return b:neocomplete
endfunction"}}}
function! neocomplete#get_context() "{{{
  return neocomplete#get_current_neocomplete().context
endfunction"}}}

" Source helper. "{{{
function! neocomplete#define_source(source) "{{{
  let sources = neocomplete#variables#get_sources()
  for source in neocomplete#util#convert2list(a:source)
    let sources[source.name] = neocomplete#init#_source(source)
  endfor
endfunction"}}}
function! neocomplete#define_filter(filter) "{{{
  let filters = neocomplete#variables#get_filters()
  for filter in neocomplete#util#convert2list(a:filter)
    let filters[filter.name] = neocomplete#init#_filter(filter)
  endfor
endfunction"}}}
function! neocomplete#available_sources() "{{{
  return copy(neocomplete#variables#get_sources())
endfunction"}}}
function! neocomplete#custom_source(source_name, option_name, value) "{{{
  let custom_sources = neocomplete#variables#get_custom().sources

  for key in split(a:source_name, '\s*,\s*')
    if !has_key(custom_sources, key)
      let custom_sources[key] = {}
    endif

    let custom_sources[key][a:option_name] = a:value
  endfor
endfunction"}}}

function! neocomplete#is_enabled_source(source_name) "{{{
  return neocomplete#helper#is_enabled_source(a:source_name)
endfunction"}}}
function! neocomplete#dup_filter(list) "{{{
  return neocomplete#util#dup_filter(a:list)
endfunction"}}}

function! neocomplete#system(...) "{{{
  let V = vital#of('neocomplete')
  return call(V.system, a:000)
endfunction"}}}
function! neocomplete#has_vimproc() "{{{
  return neocomplete#util#has_vimproc()
endfunction"}}}

function! neocomplete#get_cur_text(...) "{{{
  " Return cached text.
  let neocomplete = neocomplete#get_current_neocomplete()
  return (a:0 == 0 && mode() ==# 'i' &&
        \  neocomplete.cur_text != '') ?
        \ neocomplete.cur_text : neocomplete#helper#get_cur_text()
endfunction"}}}
function! neocomplete#get_next_keyword() "{{{
  " Get next keyword.
  let pattern = '^\%(' . neocomplete#get_next_keyword_pattern() . '\m\)'

  return matchstr('a'.getline('.')[len(neocomplete#get_cur_text()) :], pattern)[1:]
endfunction"}}}
function! neocomplete#get_keyword_pattern(...) "{{{
  let filetype = a:0 != 0? a:000[0] : neocomplete#get_context_filetype()

  return neocomplete#helper#unite_patterns(
        \ g:neocomplete#keyword_patterns, filetype)
endfunction"}}}
function! neocomplete#get_next_keyword_pattern(...) "{{{
  let filetype = a:0 != 0? a:000[0] : neocomplete#get_context_filetype()
  let next_pattern = neocomplete#helper#unite_patterns(
        \ g:neocomplete#next_keyword_patterns, filetype)

  return (next_pattern == '' ? '' : next_pattern.'\m\|')
        \ . neocomplete#get_keyword_pattern(filetype)
endfunction"}}}
function! neocomplete#get_keyword_pattern_end(...) "{{{
  let filetype = a:0 != 0? a:000[0] : neocomplete#get_context_filetype()

  return '\%('.neocomplete#get_keyword_pattern(filetype).'\m\)$'
endfunction"}}}
function! neocomplete#match_word(...) "{{{
  return call('neocomplete#helper#match_word', a:000)
endfunction"}}}
function! neocomplete#is_enabled() "{{{
  return neocomplete#init#is_enabled()
endfunction"}}}
function! neocomplete#is_locked(...) "{{{
  let bufnr = a:0 > 0 ? a:1 : bufnr('%')
  return !neocomplete#is_enabled() || &paste
        \ || g:neocomplete#disable_auto_complete
        \ || &l:completefunc == ''
        \ || neocomplete#get_current_neocomplete().lock
        \ || (g:neocomplete#lock_buffer_name_pattern != '' &&
        \   bufname(bufnr) =~ g:neocomplete#lock_buffer_name_pattern)
        \ || &l:omnifunc ==# 'fuf#onComplete'
endfunction"}}}
function! neocomplete#is_auto_select() "{{{
  return g:neocomplete#enable_auto_select && !neocomplete#is_eskk_enabled()
endfunction"}}}
function! neocomplete#is_auto_complete() "{{{
  return &l:completefunc == 'neocomplete#complete#auto_complete'
endfunction"}}}
function! neocomplete#is_sources_complete() "{{{
  return &l:completefunc == 'neocomplete#complete#sources_manual_complete'
endfunction"}}}
function! neocomplete#is_eskk_enabled() "{{{
  return exists('*eskk#is_enabled') && eskk#is_enabled()
endfunction"}}}
function! neocomplete#is_eskk_convertion(cur_text) "{{{
  return neocomplete#is_eskk_enabled()
        \   && eskk#get_preedit().get_henkan_phase() !=#
        \             g:eskk#preedit#PHASE_NORMAL
endfunction"}}}
function! neocomplete#is_multibyte_input(cur_text) "{{{
  return (exists('b:skk_on') && b:skk_on)
        \     || char2nr(split(a:cur_text, '\zs')[-1]) > 0x80
endfunction"}}}
function! neocomplete#is_text_mode() "{{{
  let neocomplete = neocomplete#get_current_neocomplete()
  return get(g:neocomplete#text_mode_filetypes,
        \ neocomplete.context_filetype, 0)
endfunction"}}}
function! neocomplete#is_windows() "{{{
  return neocomplete#util#is_windows()
endfunction"}}}
function! neocomplete#is_prefetch() "{{{
  return !neocomplete#is_locked() &&
        \ (g:neocomplete#enable_prefetch || &l:formatoptions =~# 'a')
endfunction"}}}
function! neocomplete#exists_echodoc() "{{{
  return exists('g:loaded_echodoc') && g:loaded_echodoc
endfunction"}}}
function! neocomplete#within_comment() "{{{
  return neocomplete#helper#get_syn_name(1) ==# 'Comment'
endfunction"}}}
function! neocomplete#print_error(string) "{{{
  echohl Error | echomsg a:string | echohl None
endfunction"}}}
function! neocomplete#print_warning(string) "{{{
  echohl WarningMsg | echomsg a:string | echohl None
endfunction"}}}
function! neocomplete#head_match(checkstr, headstr) "{{{
  let checkstr = &ignorecase ?
        \ tolower(a:checkstr) : a:checkstr
  let headstr = &ignorecase ?
        \ tolower(a:headstr) : a:headstr
  return stridx(checkstr, headstr) == 0
endfunction"}}}
function! neocomplete#get_source_filetypes(filetype) "{{{
  return neocomplete#helper#get_source_filetypes(a:filetype)
endfunction"}}}
function! neocomplete#get_sources_list(dictionary, filetype) "{{{
  return neocomplete#helper#ftdictionary2list(a:dictionary, a:filetype)
endfunction"}}}
function! neocomplete#escape_match(str) "{{{
  return escape(a:str, '~"*\.^$[]')
endfunction"}}}
function! neocomplete#get_context_filetype(...) "{{{
  if !neocomplete#is_enabled()
    return &filetype
  endif

  let neocomplete = neocomplete#get_current_neocomplete()

  if a:0 != 0 || mode() !=# 'i' ||
        \ neocomplete.context_filetype == ''
    call neocomplete#context_filetype#set()
  endif

  return neocomplete.context_filetype
endfunction"}}}
function! neocomplete#get_context_filetype_range(...) "{{{
  if !neocomplete#is_enabled()
    return [[1, 1], [line('$'), len(getline('$'))+1]]
  endif

  let neocomplete = neocomplete#get_current_neocomplete()

  if a:0 != 0 || mode() !=# 'i' ||
        \ neocomplete.context_filetype == ''
    call neocomplete#context_filetype#set()
  endif

  if neocomplete.context_filetype ==# &filetype
    return [[1, 1], [line('$'), len(getline('$'))+1]]
  endif

  return neocomplete.context_filetype_range
endfunction"}}}
function! neocomplete#print_debug(expr) "{{{
  if g:neocomplete#enable_debug
    echomsg string(a:expr)
  endif
endfunction"}}}
function! neocomplete#get_data_directory() "{{{
  let directory = neocomplete#util#substitute_path_separator(
        \ neocomplete#util#expand(g:neocomplete#data_directory))
  if !isdirectory(directory)
    call mkdir(directory, 'p')
  endif

  return directory
endfunction"}}}
function! neocomplete#complete_check() "{{{
  return neocomplete#helper#complete_check()
endfunction"}}}

function! neocomplete#set_dictionary_helper(variable, keys, value) "{{{
  return neocomplete#util#set_dictionary_helper(
        \ a:variable, a:keys, a:value)
endfunction"}}}
function! neocomplete#disable_default_dictionary(variable) "{{{
  return neocomplete#util#disable_default_dictionary(a:variable)
endfunction"}}}
function! neocomplete#filetype_complete(arglead, cmdline, cursorpos) "{{{
  return neocomplete#helper#filetype_complete(a:arglead, a:cmdline, a:cursorpos)
endfunction"}}}
"}}}

" Key mapping functions. "{{{
function! neocomplete#smart_close_popup()
  return neocomplete#mappings#smart_close_popup()
endfunction
function! neocomplete#close_popup()
  return neocomplete#mappings#close_popup()
endfunction
function! neocomplete#cancel_popup()
  return neocomplete#mappings#cancel_popup()
endfunction
function! neocomplete#undo_completion()
  return neocomplete#mappings#undo_completion()
endfunction
function! neocomplete#complete_common_string()
  return neocomplete#mappings#complete_common_string()
endfunction
function! neocomplete#start_manual_complete(...)
  return call('neocomplete#mappings#start_manual_complete', a:000)
endfunction
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
