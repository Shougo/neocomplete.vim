"=============================================================================
" FILE: async_cache.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 15 Jan 2014.
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following condition
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

function! s:main(argv) "{{{
  " args: funcname, outputname filename pattern_file_name mark minlen fileencoding
  let [funcname, outputname, filename, pattern_file_name, mark, minlen, fileencoding]
        \ = a:argv

  if funcname ==# 'load_from_file'
    let keyword_list = s:load_from_file(
          \ filename, pattern_file_name, mark, minlen, fileencoding, 1)

    let string = '{' . escape(string(keyword_list)[1 : -2], '\\') . '}'
  else
    let keyword_list = s:load_from_tags(
          \ filename, pattern_file_name, mark, minlen, fileencoding)
    let string = string(keyword_list)
  endif

  if empty(keyword_list)
    return
  endif

  " For neocomplete.
  " Output cache.
  call writefile([string], outputname)
endfunction"}}}

function! s:load_from_file(filename, pattern_file_name, mark, minlen, fileencoding, is_string) "{{{
  if !filereadable(a:filename)
    " File not found.
    return []
  endif

  let lines = map(readfile(a:filename),
        \ 's:iconv(v:val, a:fileencoding, &encoding)')

  let pattern = get(readfile(a:pattern_file_name), 0, '\h\w*')

  let keyword_list = []
  let dup_check = {}
  let keyword_pattern2 = '^\%('.pattern.'\m\)'

  for line in lines "{{{
    let match = match(line, pattern)
    while match >= 0 "{{{
      let match_str = matchstr(line, keyword_pattern2, match)

      if !has_key(dup_check, match_str) && len(match_str) >= a:minlen
        " Append list.
        call add(keyword_list, (a:is_string ?
              \ match_str : { 'word' : match_str }))

        let dup_check[match_str] = 1
      endif

      let match += len(match_str)

      let match = match(line, pattern, match)
    endwhile"}}}
  endfor"}}}

  return keyword_list
endfunction"}}}

function! s:load_from_tags(filename, pattern_file_name, mark, minlen, fileencoding) "{{{
  let keyword_lists = []
  let dup_check = {}

  let [pattern, tags_file_name, filter_pattern, filetype] =
        \ readfile(a:pattern_file_name)[: 4]
  if tags_file_name !=# '$dummy$'
    " Check output.
    let tags_list = []

    let i = 0
    while i < 2
      if filereadable(tags_file_name)
        " Use filename.
        let tags_list = map(readfile(tags_file_name),
              \ 's:iconv(v:val, a:fileencoding, &encoding)')
        break
      endif

      sleep 500m
      let i += 1
    endwhile
  else
    if !filereadable(a:filename)
      return []
    endif

    " Use filename.
    let tags_list = map(readfile(a:filename),
          \ 's:iconv(v:val, a:fileencoding, &encoding)')
  endif

  if empty(tags_list)
    return s:load_from_file(a:filename, a:pattern_file_name,
          \ a:mark, a:minlen, a:fileencoding, 0)
  endif

  for line in tags_list "{{{
    let tag = split(substitute(line, "\<CR>", '', 'g'), '\t', 1)

    " Add keywords.
    if line =~ '^!' || len(tag) < 3 || len(tag[0]) < a:minlen
          \ || has_key(dup_check, tag[0])
      continue
    endif

    let opt = join(tag[2:], "\<TAB>")
    let cmd = matchstr(opt, '.*/;"')

    let option = {
          \ 'cmd' : substitute(substitute(substitute(cmd,
          \'^\%([/?]\^\?\)\?\s*\|\%(\$\?[/?]\)\?;"$', '', 'g'),
          \ '\\\\', '\\', 'g'), '\\/', '/', 'g'),
          \ 'kind' : ''
          \}
    if option.cmd =~ '\d\+'
      let option.cmd = tag[0]
    endif

    for opt in split(opt[len(cmd):], '\t', 1)
      let key = matchstr(opt, '^\h\w*\ze:')
      if key == ''
        let option['kind'] = opt
      else
        let option[key] = matchstr(opt, '^\h\w*:\zs.*')
      endif
    endfor

    if has_key(option, 'file')
          \ || (has_key(option, 'access') && option.access != 'public')
      continue
    endif

    let abbr = has_key(option, 'signature')? tag[0] . option.signature :
          \ (option['kind'] == 'd' || option['cmd'] == '') ?
          \ tag[0] : option['cmd']
    let abbr = substitute(abbr, '\s\+', ' ', 'g')
    " Substitute "namespace foobar" to "foobar <namespace>".
    let abbr = substitute(abbr,
          \'^\(namespace\|class\|struct\|enum\|union\)\s\+\(.*\)$',
          \'\2 <\1>', '')
    " Substitute typedef.
    let abbr = substitute(abbr,
          \'^typedef\s\+\(.*\)\s\+\(\h\w*\%(::\w*\)*\);\?$',
          \'\2 <typedef \1>', 'g')
    " Substitute extends and implements.
    let abbr = substitute(abbr,
          \'\<\%(extends\|implements\)\s\+\S\+\>', '', '')
    " Substitute marker.
    let abbr = substitute(abbr, '"\s*{{{', '', '')

    let keyword = {
          \ 'word' : tag[0], 'abbr' : abbr, 'menu' : a:mark,
          \ 'kind' : option['kind'],
          \ }
    if has_key(option, 'struct')
      let keyword.menu = option.struct
    elseif has_key(option, 'class')
      let keyword.menu = option.class
    elseif has_key(option, 'enum')
      let keyword.menu = option.enum
    elseif has_key(option, 'union')
      let keyword.menu = option.union
    endif

    call add(keyword_lists, keyword)
    let dup_check[tag[0]] = 1
  endfor"}}}

  if filter_pattern != ''
    call filter(keyword_lists, filter_pattern)
  endif

  return keyword_lists
endfunction"}}}

function! s:truncate(str, width) "{{{
  " Original function is from mattn.
  " http://github.com/mattn/googlereader-vim/tree/master

  if a:str =~# '^[\x00-\x7f]*$'
    return len(a:str) < a:width ?
          \ printf('%-'.a:width.'s', a:str) : strpart(a:str, 0, a:width)
  endif

  let ret = a:str
  let width = s:wcswidth(a:str)
  if width > a:width
    let ret = s:strwidthpart(ret, a:width)
    let width = s:wcswidth(ret)
  endif

  if width < a:width
    let ret .= repeat(' ', a:width - width)
  endif

  return ret
endfunction"}}}

function! s:strwidthpart(str, width) "{{{
  let ret = a:str
  let width = s:wcswidth(a:str)
  while width > a:width
    let char = matchstr(ret, '.$')
    let ret = ret[: -1 - len(char)]
    let width -= s:wcwidth(char)
  endwhile

  return ret
endfunction"}}}

function! s:iconv(expr, from, to)
  if a:from == '' || a:to == '' || a:from ==? a:to
    return a:expr
  endif
  let result = iconv(a:expr, a:from, a:to)
  return result != '' ? result : a:expr
endfunction

" Use builtin function.
function! s:wcswidth(str) "{{{
  return strdisplaywidth(a:str)
endfunction"}}}
function! s:wcwidth(str) "{{{
  return strwidth(a:str)
endfunction"}}}

if argc() == 7 &&
      \ (argv(0) ==# 'load_from_file' || argv(0) ==# 'load_from_tags')
  try
    call s:main(argv())
  catch
    call writefile([v:throwpoint, v:exception],
          \     fnamemodify(argv(1), ':h:h').'/async_error_log')
  endtry

  qall!
else
  function! neocomplete#async_cache#main(argv) "{{{
    call s:main(a:argv)
  endfunction"}}}
endif

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
