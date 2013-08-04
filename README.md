[![Stories in Ready](http://badge.waffle.io/Shougo/neocomplete.vim.png)](http://waffle.io/Shougo/neocomplete.vim)  
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

To use neocomplete, you must use Vim 7.3.885 or above with if\_lua feature.
---------------------------------------------------------------------------

In Windows:

[for 32bit Windows](http://files.kaoriya.net/goto/vim73w32) / [for 64bit Windows](http://files.kaoriya.net/goto/vim73w64)

In Mac:

[if\_lua enabled MacVim](https://github.com/zhaocai/macvim)

In MacVim with homebrew:

`brew install macvim --with-cscope --with-lua --HEAD`


In Linux:

You should make Vim and enable if\_lua manually. Distributed package is almost
old.

* Extract the file and put files in your Vim directory
   (usually ~/.vim/ or Program Files/Vim/vimfiles on Windows).
* Execute `|:NeoCompleteEnable|` command or
`let g:neocomplete#enable_at_startup = 1`
in your `.vimrc`. Not in `.gvimrc`(`_gvimrc`)!

Caution
-------

Snippets feature was split.
If you used it, please install neosnippet source manually.

https://github.com/Shougo/neosnippet

Migration guide from neocomplcache is available.
[Migration guide](https://github.com/Shougo/neocomplete.vim/wiki/neocomplete-migration-guide)

Screen shots
============

Original filename completion.
-----------
![Original filename completion.](https://f.cloud.github.com/assets/41495/622454/f519f6b8-cf42-11e2-921e-6e34dba148a6.png)
![Include filename completion.](https://f.cloud.github.com/assets/214488/623151/284ad86e-cf5b-11e2-828e-257d31bf0572.png)

Omni completion.
----------------
![Omni completion.](https://f.cloud.github.com/assets/41495/622456/fb2cc0bc-cf42-11e2-94e8-403cdcf5427e.png)

Completion with vimshell(http://github.com/Shougo/vimshell).
------------------------------------------------------------
![Completion with vimshell(http://github.com/Shougo/vimshell).](https://f.cloud.github.com/assets/41495/622458/01dbc660-cf43-11e2-85f1-326e7432b0a1.png)

Vim completion
------------------------------------------------------------
![Vim completion.](https://f.cloud.github.com/assets/41495/622457/fe90ad5e-cf42-11e2-8e03-8f189b5e26e5.png)
![Vim completion with animation.](https://f.cloud.github.com/assets/214488/623496/94ed19a2-cf68-11e2-8d33-3aad8a39d7c1.gif)

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
