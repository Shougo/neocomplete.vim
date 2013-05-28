"=============================================================================
" FILE: tags_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 28 May 2013.
"=============================================================================

if exists('g:loaded_neocomplete_tags_complete')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

" Add commands. "{{{
command! -nargs=0 -bar
      \ NeoCompleteCachingTags
      \ call neocomplete#sources#tags_complete#caching_tags(1)
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_neocomplete_tags_complete = 1

" vim: foldmethod=marker
