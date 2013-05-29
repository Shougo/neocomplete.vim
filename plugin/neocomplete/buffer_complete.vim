"=============================================================================
" FILE: buffer_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 29 May 2013.
"=============================================================================

if exists('g:loaded_neocomplete_buffer_complete')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

" Add commands. "{{{
command! -nargs=? -complete=file -bar
      \ NeoCompleteBufferMakeCache
      \ call neocomplete#sources#buffer_complete#make_cache(<q-args>)
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_neocomplete_buffer_complete = 1

" vim: foldmethod=marker
