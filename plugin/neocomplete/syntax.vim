"=============================================================================
" FILE: syntax.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
"=============================================================================

if exists('g:loaded_neocomplete_syntax')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

" Add commands. "{{{
command! -nargs=? -complete=customlist,neocomplete#filetype_complete
      \ NeoCompleteSyntaxMakeCache
      \ call neocomplete#sources#syntax#remake_cache(<q-args>)
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_neocomplete_syntax = 1

" vim: foldmethod=marker
