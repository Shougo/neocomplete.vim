"=============================================================================
" FILE: init.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

if !exists('s:is_enabled')
  let s:is_enabled = 0
endif

function! neocomplete#init#enable() "{{{
  if neocomplete#is_enabled()
    return
  endif

  if !exists('b:neocomplete')
    call neocomplete#init#_current_neocomplete()
  endif
  call neocomplete#init#_autocmds()
  call neocomplete#init#_others()

  call neocomplete#init#_sources(get(g:neocomplete#sources,
        \ neocomplete#get_context_filetype(), ['_']))

  doautocmd <nomodeline> neocomplete InsertEnter

  let s:is_enabled = 1
endfunction"}}}

function! neocomplete#init#disable() "{{{
  if !neocomplete#is_enabled()
    call neocomplete#init#enable()
  endif

  let s:is_enabled = 0

  augroup neocomplete
    autocmd!
  augroup END

  silent! delcommand NeoCompleteDisable

  call neocomplete#helper#call_hook(filter(values(
        \ neocomplete#variables#get_sources()), 'v:val.loaded'),
        \ 'on_final', {})
endfunction"}}}

function! neocomplete#init#is_enabled() "{{{
  return s:is_enabled
endfunction"}}}

function! neocomplete#init#_autocmds() "{{{
  augroup neocomplete
    autocmd!
    autocmd InsertEnter *
          \ call neocomplete#handler#_on_insert_enter()
    autocmd InsertLeave *
          \ call neocomplete#handler#_on_insert_leave()
    autocmd CursorMovedI *
          \ call neocomplete#handler#_on_moved_i()
    autocmd BufWritePost *
          \ call neocomplete#handler#_on_write_post()
    autocmd VimLeavePre *
          \ call neocomplete#init#disable()
    autocmd InsertCharPre *
          \ call neocomplete#handler#_on_insert_char_pre()
    autocmd TextChangedI *
          \ call neocomplete#handler#_on_text_changed()
  augroup END

  if g:neocomplete#enable_insert_char_pre
    autocmd neocomplete InsertCharPre *
          \ call neocomplete#handler#_do_auto_complete('InsertCharPre')
  elseif g:neocomplete#enable_cursor_hold_i
    augroup neocomplete
      autocmd CursorHoldI *
            \ call neocomplete#handler#_do_auto_complete('CursorHoldI')
      autocmd InsertEnter *
            \ call neocomplete#handler#_change_update_time()
      autocmd InsertLeave *
            \ call neocomplete#handler#_restore_update_time()
    augroup END
  else
    autocmd neocomplete CursorMovedI *
          \ call neocomplete#handler#_do_auto_complete('CursorMovedI')
  endif

  if !g:neocomplete#enable_cursor_hold_i
    autocmd neocomplete InsertEnter *
          \ call neocomplete#handler#_do_auto_complete('InsertEnter')
  endif

  autocmd neocomplete CompleteDone *
        \ call neocomplete#handler#_on_complete_done()
endfunction"}}}

function! neocomplete#init#_others() "{{{
  call neocomplete#init#_variables()

  call neocomplete#commands#_initialize()

  " For auto complete keymappings.
  call neocomplete#mappings#define_default_mappings()

  " Detect set paste.
  if &paste
    redir => output
    99verbose set paste
    redir END
    call neocomplete#print_error(output)
    call neocomplete#print_error(
          \ 'Detected set paste! Disabled neocomplete.')
  endif

  command! -nargs=0 -bar NeoCompleteDisable
        \ call neocomplete#init#disable()

  " Set for echodoc.
  call neocomplete#echodoc#init()
endfunction"}}}

function! neocomplete#init#_variables() "{{{
  " Initialize keyword patterns. "{{{
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'_',
        \'\h\w*')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#keyword_patterns',
        \'filename',
        \ neocomplete#util#is_windows() ?
        \'\%(\a\+:/\)\?\%([/[:alnum:]()$+_~.{}\x80-\xff-]\|[^[:print:]]\|\\.\)\+' :
        \'\%([/\[\][:alnum:]()$+_~.{}-]\|[^[:print:]]\|\\.\)\+')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'lisp,scheme,clojure,int-gosh,int-clisp,int-clj',
        \'[[:alpha:]!$%&*+/:<=>?@\^_~\-][[:alnum:]!$%&*./:<=>?@\^_~\-]*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'ruby,int-irb',
        \'^=\%(b\%[egin]\|e\%[nd]\)\|\%(@@\|[$@]\)\h\w*\|\h\w*\%(::\w*\)*[!?]\?')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'php,int-php',
        \'</\?\%(\h[[:alnum:]_-]*\s*\)\?\%(/\?>\)\?'.
        \'\|\$\h\w*\|\h\w*\%(\%(\\\|::\)\w*\)*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'perl,int-perlsh',
        \'<\h\w*>\?\|[$@%&*]\h\w*\|\h\w*\%(::\w*\)*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'perl6,int-perl6',
        \'<\h\w*>\?\|[$@%&][!.*?]\?\h[[:alnum:]_-]*'.
        \'\|\h[[:alnum:]_-]*\%(::[[:alnum:]_-]*\)*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'pir',
        \'[$@%.=]\?\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'pasm',
        \'[=]\?\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'vim,help',
        \'-\h[[:alnum:]-]*=\?\|\c\[:\%(\h\w*:\]\)\?\|&\h[[:alnum:]_:]*\|'.
        \'<SID>\%(\h\w*\)\?\|<Plug>([^)]*)\?'.
        \'\|<\h[[:alnum:]_-]*>\?\|\h[[:alnum:]_:#]*[!(]\?\|$\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'tex',
        \'\\\a{\a\{1,2}}\|\\[[:alpha:]@][[:alnum:]@]*'.
        \'\%({\%([[:alnum:]:_]\+\*\?}\?\)\?\)\?\|\a[[:alnum:]:_]*\*\?')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'sh,zsh,int-zsh,int-bash,int-sh',
        \'[[:alpha:]_.-][[:alnum:]_.-]*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'vimshell',
        \'\$\$\?\w*\|[[:alpha:]_.\\/~-][[:alnum:]_.\\/~-]*\|\d\+\%(\.\d\+\)\+')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'ps1,int-powershell',
        \'\[\h\%([[:alnum:]_.]*\]::\)\?\|[$%@.]\?[[:alpha:]_.:-][[:alnum:]_.:-]*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'c',
        \'^\s*#\s*\h\w*\|\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'cpp',
        \'^\s*#\s*\h\w*\|\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'objc',
        \'^\s*#\s*\h\w*\|\h\w*\|@\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'objcpp',
        \'^\s*#\s*\h\w*\|\h\w*\|@\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'objj',
        \'\h\w*\|@\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'d',
        \'\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'python,int-python,int-ipython',
        \'[@]\?\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'cs',
        \'\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'java',
        \'[@]\?\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'javascript,actionscript,int-js,int-kjs,int-rhino',
        \'\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'coffee,int-coffee',
        \'[@]\?\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'awk',
        \'\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'haskell,int-ghci',
        \'\%(\u\w*\.\)\+[[:alnum:]_'']*\|[[:alpha:]_''][[:alnum:]_'']*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'ml,ocaml,int-ocaml,int-sml,int-smlsharp',
        \'[''`#.]\?\h[[:alnum:]_'']*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'erlang,int-erl',
        \'^\s*-\h\w*\|\%(\h\w*:\)*\h\w*\|\h[[:alnum:]_@]*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'html,xhtml,xml,markdown,mkd,eruby',
        \'</\?\%([[:alnum:]_:-]\+\s*\)\?\%(/\?>\)\?\|&\h\%(\w*;\)\?'.
        \'\|\h[[:alnum:]_-]*="\%([^"]*"\?\)\?\|\h[[:alnum:]_:-]*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'css,stylus,scss,less',
        \'[@#.]\?[[:alpha:]_:-][[:alnum:]_:-]*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'tags',
        \'^[^!][^/[:blank:]]*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'pic',
        \'^\s*#\h\w*\|\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'arm',
        \'\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'asmh8300',
        \'[[:alpha:]_.][[:alnum:]_.]*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'masm',
        \'\.\h\w*\|[[:alpha:]_@?$][[:alnum:]_@?$]*\|\h\w*:\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'nasm',
        \'^\s*\[\h\w*\|[%.]\?\h\w*\|\%(\.\.@\?\|%[%$!]\)\%(\h\w*\)\?\|\h\w*:\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'asm',
        \'[%$.]\?\h\w*\%(\$\h\w*\)\?')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'gas',
        \'[$.]\?\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'gdb,int-gdb',
        \'$\h\w*\|[[:alnum:]:._-]\+')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'make',
        \'[[:alpha:]_.-][[:alnum:]_.-]*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'scala,int-scala',
        \'\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'int-termtter',
        \'\h[[:alnum:]_/-]*\|\$\a\+\|#\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'int-earthquake',
        \'[:#$]\h\w*\|\h[[:alnum:]_/-]*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'dosbatch,int-cmdproxy',
        \'\$\w+\|[[:alpha:]_./-][[:alnum:]_.-]*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'vb',
        \'\h\w*\|#\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'lua',
        \'\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \ 'zimbu',
        \'\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'konoha',
        \'[*$@%]\h\w*\|\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'cobol',
        \'\a[[:alnum:]-]*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'coq',
        \'\h[[:alnum:]_'']*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'tcl',
        \'[.-]\h\w*\|\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'nyaos,int-nyaos',
        \'\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'go',
        \'\h\w*')
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#keyword_patterns',
        \'toml',
        \'\h[[:alnum:]_.-]*')
  "}}}

  " Initialize same file types. "{{{
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'c', 'cpp')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'cpp', 'c')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'erb', 'ruby,html,xhtml')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'html,xml', 'xhtml')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'html,xhtml', 'css,stylus,less')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'css', 'scss')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'scss', 'css')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'stylus', 'css')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'less', 'css')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'xhtml', 'html,xml')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'help', 'vim')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'tex', 'bib,plaintex')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'plaintex', 'bib,tex')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'lingr-say', 'lingr-messages,lingr-members')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'J6uil_say', 'J6uil')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'vimconsole', 'vim')

  " Interactive filetypes.
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-irb', 'ruby')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-ghci,int-hugs', 'haskell')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-python,int-ipython', 'python')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-gosh', 'scheme')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-clisp', 'lisp')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-erl', 'erlang')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-zsh', 'zsh')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-bash', 'bash')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-sh', 'sh')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-cmdproxy', 'dosbatch')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-powershell', 'powershell')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-perlsh', 'perl')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-perl6', 'perl6')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-ocaml', 'ocaml')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-clj,int-lein', 'clojure')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-sml,int-smlsharp', 'sml')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-js,int-kjs,int-rhino', 'javascript')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-coffee', 'coffee')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-gdb', 'gdb')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-scala', 'scala')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-nyaos', 'nyaos')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#same_filetypes',
        \ 'int-php', 'php')
  "}}}

  " Initialize delimiter patterns. "{{{
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#delimiter_patterns',
        \ 'vim,help', ['#'])
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#delimiter_patterns',
        \ 'erlang,lisp,int-clisp', [':'])
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#delimiter_patterns',
        \ 'lisp,int-clisp', ['/', ':'])
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#delimiter_patterns',
        \ 'clojure,int-clj', ['/', '.'])
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#delimiter_patterns',
        \ 'perl,cpp', ['::'])
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#delimiter_patterns',
        \ 'php', ['\', '::'])
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#delimiter_patterns',
        \ 'java,d,javascript,actionscript,'.
        \ 'ruby,eruby,haskell,int-ghci,coffee,zimbu,konoha',
        \ ['.'])
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#delimiter_patterns',
        \ 'lua', ['.', ':'])
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#delimiter_patterns',
        \ 'perl6', ['.', '::'])
  "}}}

  " Initialize ctags arguments. "{{{
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#ctags_arguments',
        \ '_', '')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#ctags_arguments', 'vim',
        \ '--language-force=vim --extra=fq --fields=afmiKlnsStz ' .
        \ "--regex-vim='/function!? ([a-z#:_0-9A-Z]+)/\\1/function/'")
  if neocomplete#util#is_mac()
    call neocomplete#util#set_default_dictionary(
          \ 'g:neocomplete#ctags_arguments', 'c',
          \ '--c-kinds=+p --fields=+iaS --extra=+q
          \ -I__DARWIN_ALIAS,__DARWIN_ALIAS_C,__DARWIN_ALIAS_I,__DARWIN_INODE64
          \ -I__DARWIN_1050,__DARWIN_1050ALIAS,__DARWIN_1050ALIAS_C,__DARWIN_1050ALIAS_I,__DARWIN_1050INODE64
          \ -I__DARWIN_EXTSN,__DARWIN_EXTSN_C
          \ -I__DARWIN_LDBL_COMPAT,__DARWIN_LDBL_COMPAT2')
  else
    call neocomplete#util#set_default_dictionary(
          \ 'g:neocomplete#ctags_arguments', 'c',
          \ '-R --sort=1 --c-kinds=+p --fields=+iaS --extra=+q ' .
          \ '-I __wur,__THROW,__attribute_malloc__,__nonnull+,'.
          \   '__attribute_pure__,__attribute_warn_unused_result__,__attribute__+')
  endif
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#ctags_arguments', 'cpp',
        \ '--language-force=C++ -R --sort=1 --c++-kinds=+p --fields=+iaS --extra=+q '.
        \ '-I __wur,__THROW,__attribute_malloc__,__nonnull+,'.
        \   '__attribute_pure__,__attribute_warn_unused_result__,__attribute__+')
  "}}}

  " Initialize text mode filetypes. "{{{
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#text_mode_filetypes',
        \ 'hybrid,text,help,tex,gitcommit,gitrebase,vcs-commit,markdown,mkd,'.
        \ 'textile,creole,org,rdoc,mediawiki,rst,asciidoc,pod', 1)
  "}}}

  " Initialize tags filter patterns. "{{{
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#tags_filter_patterns', 'c,cpp',
        \'v:val.word !~ ''^[~_]''')
  "}}}

  " Initialize force omni completion patterns. "{{{
  call neocomplete#util#set_default_dictionary(
        \'g:neocomplete#force_omni_input_patterns', 'objc',
        \'\h\w\+\|[^.[:digit:] *\t]\%(\.\|->\)')
  "}}}

  " Must g:neocomplete#auto_completion_start_length > 1.
  if g:neocomplete#auto_completion_start_length < 1
    let g:neocomplete#auto_completion_start_length = 1
  endif

  " Must g:neocomplete#min_keyword_length > 1.
  if g:neocomplete#min_keyword_length < 1
    let g:neocomplete#min_keyword_length = 1
  endif
endfunction"}}}

function! neocomplete#init#_current_neocomplete() "{{{
  let b:neocomplete = {
        \ 'context' : {
        \      'input' : '',
        \      'complete_pos' : -1,
        \      'complete_str' : '',
        \      'candidates' : [],
        \ },
        \ 'lock' : 0,
        \ 'skip_next_complete' : 0,
        \ 'filetype' : '',
        \ 'context_filetype' : '',
        \ 'context_filetype_range' :
        \    [[1, 1], [line('$'), len(getline('$'))+1]],
        \ 'completion_length' : -1,
        \ 'update_time_save' : &updatetime,
        \ 'foldinfo' : [],
        \ 'skipped' : 0,
        \ 'event' : '',
        \ 'cur_text' : '',
        \ 'old_cur_text' : '',
        \ 'old_linenr' : line('.'),
        \ 'old_complete_pos' : -1,
        \ 'old_char' : '',
        \ 'complete_str' : '',
        \ 'complete_pos' : -1,
        \ 'candidates' : [],
        \ 'complete_sources' : [],
        \ 'manual_sources' : [],
        \ 'start_time' : reltime(),
        \ 'linenr' : 0,
        \ 'completeopt' : &completeopt,
        \ 'completed_item' : {},
        \ 'overlapped_items' : {},
        \ 'sources' : [],
        \ 'sources_filetype' : '',
        \ 'within_comment' : 0,
        \ 'is_auto_complete' : 0,
        \ 'indent_text' : '',
        \}
endfunction"}}}

function! neocomplete#init#_sources(names) "{{{
  if !exists('s:loaded_source_files')
    " Initialize.
    let s:loaded_source_files = {}
    let s:loaded_all_sources = 0
    let s:runtimepath_save = ''
  endif

  " Initialize sources table.
  if s:loaded_all_sources && &runtimepath ==# s:runtimepath_save
    return
  endif

  let runtimepath_save = neocomplete#util#split_rtp(s:runtimepath_save)
  let runtimepath = neocomplete#util#join_rtp(
        \ filter(neocomplete#util#split_rtp(),
        \ 'index(runtimepath_save, v:val) < 0'))
  let sources = neocomplete#variables#get_sources()

  for name in filter(copy(a:names), '!has_key(sources, v:val)')
    " Search autoload.
    for source_name in map(filter(split(globpath(runtimepath,
          \ 'autoload/neocomplete/sources/*.vim'), '\n'),
          \ "index(g:neocomplete#ignore_source_files,
          \        fnamemodify(v:val, ':t')) < 0"),
          \ "fnamemodify(v:val, ':t:r')")
      if has_key(s:loaded_source_files, source_name)
        continue
      endif

      let s:loaded_source_files[source_name] = 1

      let source = neocomplete#sources#{source_name}#define()
      if empty(source)
        " Ignore.
        continue
      endif

      call neocomplete#define_source(source)
    endfor

    if name == '_'
      let s:loaded_all_sources = 1
      let s:runtimepath_save = &runtimepath
    endif
  endfor
endfunction"}}}

function! neocomplete#init#_source(source) "{{{
  let default = {
        \ 'is_volatile' : 0,
        \ 'max_candidates' : 0,
        \ 'filetypes' : {},
        \ 'disabled' : 0,
        \ 'disabled_filetypes' : {},
        \ 'hooks' : {},
        \ 'mark' : '',
        \ 'matchers' :
        \        (g:neocomplete#enable_fuzzy_completion ?
        \          ['matcher_fuzzy'] : ['matcher_head'])
        \      + ['matcher_length'],
        \ 'sorters' : ['sorter_rank'],
        \ 'converters' : [
        \      'converter_remove_overlap',
        \      'converter_delimiter',
        \      'converter_abbr',
        \ ],
        \ 'keyword_patterns' : g:neocomplete#keyword_patterns,
        \ 'neocomplete__context' : neocomplete#init#_context({}),
        \ }

  let source = extend(copy(default), a:source)

  " Overwritten by user custom.
  let custom = neocomplete#custom#get().sources
  let source = extend(source, get(custom, source.name,
        \ get(custom, '_', {})))

  let source.loaded = 0
  " Source kind convertion.
  if !has_key(source, 'kind')
    let source.kind = 'manual'
  elseif source.kind ==# 'plugin'
    let source.kind = 'keyword'
  elseif source.kind ==# 'ftplugin' || source.kind ==# 'complfunc'
    " For compatibility.
    let source.kind = 'manual'
  endif

  if !has_key(source, 'rank')
    " Set default rank.
    let source.rank = (source.kind ==# 'keyword') ? 5 :
          \ empty(source.filetypes) ? 10 : 100
  endif

  if !has_key(source.keyword_patterns, '_')
    " Set default keyword pattern.
    let source.keyword_patterns['_'] =
          \ get(g:neocomplete#keyword_patterns, '_', '\h\w*')
  endif

  if !has_key(source, 'min_pattern_length')
    " Set min_pattern_length.
    let source.min_pattern_length = (source.kind ==# 'keyword') ?
          \ g:neocomplete#auto_completion_start_length : 0
  endif

  let source.neocomplete__matchers = neocomplete#init#_filters(
        \ neocomplete#util#convert2list(source.matchers))
  let source.neocomplete__sorters = neocomplete#init#_filters(
        \ neocomplete#util#convert2list(source.sorters))
  let source.neocomplete__converters = neocomplete#init#_filters(
        \ neocomplete#util#convert2list(source.converters))

  let source.neocomplete__context.source_name = source.name

  return source
endfunction"}}}

function! neocomplete#init#_filters(names) "{{{
  let _ = []
  let filters = neocomplete#variables#get_filters()

  for name in a:names
    if !has_key(filters, name)
      " Search autoload.
      for filter_name in map(split(globpath(&runtimepath,
            \ 'autoload/neocomplete/filters/'.
            \   substitute(name,
            \'^\%(matcher\|sorter\|converter\)_[^/_-]\+\zs[/_-].*$', '', '')
            \  .'*.vim'), '\n'), "fnamemodify(v:val, ':t:r')")
        let filter = neocomplete#filters#{filter_name}#define()
        if empty(filter)
          " Ignore.
          continue
        endif

        call neocomplete#define_filter(filter)
      endfor

      if !has_key(filters, name)
        " Not found.
        call neocomplete#print_error(
              \ printf('filter name : %s is not found.', string(name)))
        continue
      endif
    endif

    if has_key(filters, name)
      call add(_, filters[name])
    endif
  endfor

  return _
endfunction"}}}

function! neocomplete#init#_filter(filter) "{{{
  let default = {
        \ }

  let filter = extend(default, a:filter)
  if !has_key(filter, 'kind')
    let filter.kind =
          \ (filter.name =~# '^matcher_') ? 'matcher' :
          \ (filter.name =~# '^sorter_') ? 'sorter' : 'converter'
  endif

  return filter
endfunction"}}}

function! neocomplete#init#_context(context) "{{{
  return extend(a:context, {
        \ 'input' : '',
        \ 'prev_complete_pos' : -1,
        \ 'prev_candidates' : [],
        \ 'complete_pos' : -1,
        \ 'complete_str' : '',
        \ 'candidates' : []
        \ })
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
