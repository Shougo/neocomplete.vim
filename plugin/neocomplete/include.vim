"=============================================================================
" FILE: include.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
"=============================================================================

if exists('g:loaded_neocomplete_include')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

" Add commands. "{{{
command! -nargs=? -complete=buffer NeoCompleteIncludeMakeCache
      \ call neocomplete#sources#include#make_cache(<q-args>)
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_neocomplete_include = 1

" vim: foldmethod=marker
