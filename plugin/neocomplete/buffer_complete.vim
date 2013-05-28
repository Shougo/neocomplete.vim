"=============================================================================
" FILE: buffer_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 28 May 2013.
"=============================================================================

if exists('g:loaded_neocomplete_buffer_complete')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

" Add commands. "{{{
command! -nargs=? -complete=file -bar
      \ NeoCompleteCachingBuffer
      \ call neocomplete#sources#buffer_complete#caching_buffer(<q-args>)
command! -nargs=? -complete=buffer -bar
      \ NeoCompletePrintSource
      \ call neocomplete#sources#buffer_complete#print_source(<q-args>)
command! -nargs=? -complete=buffer -bar
      \ NeoCompleteDisableCaching
      \ call neocomplete#sources#buffer_complete#disable_caching(<q-args>)
command! -nargs=? -complete=buffer -bar
      \ NeoCompleteEnableCaching
      \ call neocomplete#sources#buffer_complete#enable_caching(<q-args>)
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_neocomplete_buffer_complete = 1

" vim: foldmethod=marker
