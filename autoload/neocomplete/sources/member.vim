"=============================================================================
" FILE: member.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 01 Jan 2014.
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

" Global options definition. "{{{
let g:neocomplete#sources#member#prefix_patterns =
      \ get(g:, 'neocomplete#sources#member#prefix_patterns', {})
let g:neocomplete#sources#member#input_patterns =
      \ get(g:, 'neocomplete#sources#member#input_patterns', {})
"}}}

" Important variables.
if !exists('s:member_sources')
  let s:member_sources = {}
endif

let s:source = {
      \ 'name' : 'member',
      \ 'kind' : 'manual',
      \ 'mark' : '[M]',
      \ 'rank' : 5,
      \ 'min_pattern_length' : 0,
      \ 'hooks' : {},
      \}

function! s:source.hooks.on_init(context) "{{{
  augroup neocomplete "{{{
    " Make cache events
    autocmd CursorHold * call s:make_cache_current_buffer(
          \ line('.')-10, line('.')+10)
    autocmd InsertEnter,InsertLeave *
          \ call neocomplete#sources#member#make_cache_current_line()
  augroup END"}}}

  " Initialize member prefix patterns. "{{{
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#member#prefix_patterns',
        \ 'c,objc', '\.\|->')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#member#prefix_patterns',
        \ 'cpp,objcpp', '\.\|->\|::')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#member#prefix_patterns',
        \ 'perl,php', '->')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#member#prefix_patterns',
        \ 'cs,java,javascript,d,vim,ruby,python,perl6,scala,vb', '\.')
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#member#prefix_patterns',
        \ 'lua', '\.\|:')
  "}}}

  " Initialize member patterns. "{{{
  call neocomplete#util#set_default_dictionary(
        \ 'g:neocomplete#sources#member#input_patterns',
        \ '_', '\h\w*\%(()\|\[\h\w*\]\)\?')
  "}}}

  " Initialize script variables. "{{{
  let s:member_sources = {}
  "}}}
endfunction
"}}}

function! s:source.get_complete_position(context) "{{{
  " Check member prefix pattern.
  let filetype = neocomplete#get_context_filetype()
  if !has_key(g:neocomplete#sources#member#prefix_patterns, filetype)
        \ || g:neocomplete#sources#member#prefix_patterns[filetype] == ''
    return -1
  endif

  let member = s:get_member_pattern(filetype)
  let prefix = g:neocomplete#sources#member#prefix_patterns[filetype]
  let complete_pos = matchend(a:context.input,
        \ '\%(' . member . '\%(' . prefix . '\m\)\)\+\ze\w*$')
  return complete_pos
endfunction"}}}

function! s:source.gather_candidates(context) "{{{
  " Check member prefix pattern.
  let filetype = neocomplete#get_context_filetype()
  if !has_key(g:neocomplete#sources#member#prefix_patterns, filetype)
        \ || g:neocomplete#sources#member#prefix_patterns[filetype] == ''
    return []
  endif

  let var_name = matchstr(a:context.input,
        \ '\%(' . s:get_member_pattern(filetype) . '\%(' .
        \ g:neocomplete#sources#member#prefix_patterns[filetype] . '\m\)\)\+\ze\w*$')
  if var_name == ''
    return []
  endif

  return s:get_member_list(a:context.input, var_name)
endfunction"}}}

function! neocomplete#sources#member#define() "{{{
  return s:source
endfunction"}}}

function! neocomplete#sources#member#make_cache_current_line() "{{{
  " Make cache from current line.
  return s:make_cache_current_buffer(line('.')-1, line('.')+1)
endfunction"}}}
function! neocomplete#sources#member#make_cache_current_buffer() "{{{
  " Make cache from current buffer.
  return s:make_cache_current_buffer(1, line('$'))
endfunction"}}}
function! s:make_cache_current_buffer(start, end) "{{{
  if !exists('g:neocomplete#sources#member#prefix_patterns')
    return
  endif

  if !has_key(s:member_sources, bufnr('%'))
    call s:initialize_source(bufnr('%'))
  endif

  let filetype = neocomplete#get_context_filetype(1)
  if !has_key(g:neocomplete#sources#member#prefix_patterns, filetype)
        \ || g:neocomplete#sources#member#prefix_patterns[filetype] == ''
    return
  endif

  let source = s:member_sources[bufnr('%')]
  let keyword_pattern =
        \ '\%(' . s:get_member_pattern(filetype) . '\%('
        \ . g:neocomplete#sources#member#prefix_patterns[filetype]
        \ . '\m\)\)\+' . s:get_member_pattern(filetype)
  let keyword_pattern2 = '^'.keyword_pattern
  let member_pattern = s:get_member_pattern(filetype) . '$'

  " Cache member pattern.
  for line in getline(a:start, a:end)
    let match = match(line, keyword_pattern)

    while match >= 0 "{{{
      let match_str = matchstr(line, keyword_pattern2, match)

      " Next match.
      let match = matchend(line, keyword_pattern, match + len(match_str))

      while match_str != ''
        let member_name = matchstr(match_str, member_pattern)
        if member_name == ''
          break
        endif
        let var_name = match_str[ : -len(member_name)-1]

        if !has_key(source.member_cache, var_name)
          let source.member_cache[var_name] = {}
        endif
        if !has_key(source.member_cache[var_name], member_name)
          let source.member_cache[var_name][member_name] = member_name
        endif

        let match_str = matchstr(var_name, keyword_pattern2)
      endwhile
    endwhile"}}}
  endfor
endfunction"}}}

function! s:get_member_list(cur_text, var_name) "{{{
  let keyword_list = []
  for [key, source] in filter(s:get_sources_list(),
        \ 'has_key(v:val[1].member_cache, a:var_name)')
    let keyword_list +=
          \ values(source.member_cache[a:var_name])
  endfor

  return keyword_list
endfunction"}}}

function! s:get_sources_list() "{{{
  let sources_list = []

  let filetypes_dict = {}
  for filetype in neocomplete#get_source_filetypes(
        \ neocomplete#get_context_filetype())
    let filetypes_dict[filetype] = 1
  endfor

  for [key, source] in items(s:member_sources)
    if has_key(filetypes_dict, source.filetype)
          \ || has_key(filetypes_dict, '_')
          \ || bufnr('%') == key
          \ || (bufname('%') ==# '[Command Line]' && bufnr('#') == key)
      call add(sources_list, [key, source])
    endif
  endfor

  return sources_list
endfunction"}}}

function! s:initialize_source(srcname) "{{{
  let path = fnamemodify(bufname(a:srcname), ':p')
  let filename = fnamemodify(path, ':t')
  if filename == ''
    let filename = '[No Name]'
    let path .= '/[No Name]'
  endif

  let ft = getbufvar(a:srcname, '&filetype')
  if ft == ''
    let ft = 'nothing'
  endif

  let s:member_sources[a:srcname] = {
        \ 'member_cache' : {}, 'filetype' : ft,
        \ 'keyword_pattern' : neocomplete#get_keyword_pattern(ft, s:source.name),
        \}
endfunction"}}}

function! s:get_member_pattern(filetype) "{{{
  return get(g:neocomplete#sources#member#input_patterns, a:filetype,
        \ get(g:neocomplete#sources#member#input_patterns, '_', ''))
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
