"=============================================================================
" FILE: include_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 29 May 2013.
"=============================================================================

if exists('g:loaded_neocomplete_include_complete')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

" Add commands. "{{{
command! -nargs=? -complete=buffer NeoCompleteIncludeMakeCache
      \ call neocomplete#sources#include_complete#make_cache(<q-args>)
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_neocomplete_include_complete = 1

" vim: foldmethod=marker
