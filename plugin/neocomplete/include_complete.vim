"=============================================================================
" FILE: include_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 28 May 2013.
"=============================================================================

if exists('g:loaded_neocomplete_include_complete')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

" Add commands. "{{{
command! -nargs=? -complete=buffer NeoCompleteCachingInclude
      \ call neocomplete#sources#include_complete#caching_include(<q-args>)
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_neocomplete_include_complete = 1

" vim: foldmethod=marker
