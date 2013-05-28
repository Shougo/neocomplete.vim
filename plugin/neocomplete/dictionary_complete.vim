"=============================================================================
" FILE: dictionary_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 28 May 2013.
"=============================================================================

if exists('g:loaded_neocomplete_dictionary_complete')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

" Add commands. "{{{
command! -nargs=? -complete=customlist,neocomplete#filetype_complete
      \ NeoCompleteCachingDictionary
      \ call neocomplete#sources#dictionary_complete#recaching(<q-args>)
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_neocomplete_dictionary_complete = 1

" vim: foldmethod=marker
