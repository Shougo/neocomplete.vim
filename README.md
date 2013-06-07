**neocomplete**
=================

Description
-----------

neocomplete is the abbreviation of "neo-completion with cache". It
provides keyword completion system by maintaining a cache of keywords in the
current buffer. neocomplete could be customized easily and has a lot more
features than the Vim's standard completion feature.

Installation
============

* Extract the file and put files in your Vim directory
   (usually ~/.vim/ or Program Files/Vim/vimfiles on Windows).
* Execute `|:NeoCompleteEnable|` command or
`let g:neocomplete#enable_at_startup = 1`
in your `.vimrc`. Not in `.gvimrc`(`_gvimrc`)!

Caution
-------

Snippets feature(snippets\_complete source) was split.
If you used it, please install neosnippet source manually.

https://github.com/Shougo/neosnippet

Migration guide from neocomplcache is available(incomplete).
[Migration guide](https://github.com/Shougo/neocomplete.vim/wiki/neocomplete-migration-guide)

Screen shots
============

Original filename completion.
-----------
![Original filename completion.](http://1.bp.blogspot.com/_ci2yBnqzJgM/TD1O5_bOQ2I/AAAAAAAAADE/vHf9Xg_mrTI/s1600/filename_complete.png)

Omni completion.
----------------
![Omni completion.](http://2.bp.blogspot.com/_ci2yBnqzJgM/TD1PTolkTBI/AAAAAAAAADU/knJ3eniuHWI/s1600/omni_complete.png)

Completion with vimshell(http://github.com/Shougo/vimshell).
------------------------------------------------------------
![Completion with vimshell(http://github.com/Shougo/vimshell).](http://1.bp.blogspot.com/_ci2yBnqzJgM/TD1PLfdQrwI/AAAAAAAAADM/2pSFRTHwYOY/s1600/neocomplete_with_vimshell.png)

Vim completion
------------------------------------------------------------
![Vim completion.](http://1.bp.blogspot.com/_ci2yBnqzJgM/TD1PfKTlwnI/AAAAAAAAADs/nOGWTRLuae8/s1600/vim_complete.png)

Setting examples

```vim
"Note: This option must set it in .vimrc(_vimrc).  NOT IN .gvimrc(_gvimrc)!
" Disable AutoComplPop.
let g:acp_enableAtStartup = 0
" Use neocomplete.
let g:neocomplete#enable_at_startup = 1
" Use smartcase.
let g:neocomplete#enable_smart_case = 1
" Set minimum syntax keyword length.
let g:neocomplete#sources#syntax#min_keyword_length = 3
let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'

" Define dictionary.
let g:neocomplete#sources#dictionary#dictionaries = {
    \ 'default' : '',
    \ 'vimshell' : $HOME.'/.vimshell_hist',
    \ 'scheme' : $HOME.'/.gosh_completions'
        \ }

" Define keyword.
if !exists('g:neocomplete#keyword_patterns')
    let g:neocomplete#keyword_patterns = {}
endif
let g:neocomplete#keyword_patterns['default'] = '\h\w*'

" Plugin key-mappings.
inoremap <expr><C-g>     neocomplete#undo_completion()
inoremap <expr><C-l>     neocomplete#complete_common_string()

" Recommended key-mappings.
" <CR>: close popup and save indent.
inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
function! s:my_cr_function()
  return neocomplete#smart_close_popup() . "\<CR>"
  " For no inserting <CR> key.
  "return pumvisible() ? neocomplete#close_popup() : "\<CR>"
endfunction
" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><C-y>  neocomplete#close_popup()
inoremap <expr><C-e>  neocomplete#cancel_popup()
" Close popup by <Space>.
"inoremap <expr><Space> pumvisible() ? neocomplete#close_popup() : "\<Space>"

" For cursor moving in insert mode(Not recommended)
"inoremap <expr><Left>  neocomplete#close_popup() . "\<Left>"
"inoremap <expr><Right> neocomplete#close_popup() . "\<Right>"
"inoremap <expr><Up>    neocomplete#close_popup() . "\<Up>"
"inoremap <expr><Down>  neocomplete#close_popup() . "\<Down>"
" Or set this.
"let g:neocomplete#enable_cursor_hold_i = 1
" Or set this.
"let g:neocomplete#enable_insert_char_pre = 1

" AutoComplPop like behavior.
"let g:neocomplete#enable_auto_select = 1

" Shell like behavior(not recommended).
"set completeopt+=longest
"let g:neocomplete#enable_auto_select = 1
"let g:neocomplete#disable_auto_complete = 1
"inoremap <expr><TAB>  pumvisible() ? "\<Down>" : "\<C-x>\<C-u>"

" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

" Enable heavy omni completion.
if !exists('g:neocomplete#sources#omni#input_patterns')
  let g:neocomplete#sources#omni#input_patterns = {}
endif
let g:neocomplete#sources#omni#input_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
let g:neocomplete#sources#omni#input_patterns.c = '[^.[:digit:] *\t]\%(\.\|->\)'
let g:neocomplete#sources#omni#input_patterns.cpp = '[^.[:digit:] *\t]\%(\.\|->\)\|\h\w*::'

" For perlomni.vim setting.
" https://github.com/c9s/perlomni.vim
let g:neocomplete#sources#omni#input_patterns.perl = '\h\w*->\h\w*\|\h\w*::'
```
