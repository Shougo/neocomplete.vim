"=============================================================================
" FILE: cache.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 28 May 2013.
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditionneocomplete#cache#
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

let s:Cache = vital#of('neocomplete').import('System.Cache')

" Cache loader.
function! neocomplete#cache#check_cache_list(cache_dir, key, async_cache_dictionary, index_keyword_list, ...) "{{{
  if !has_key(a:async_cache_dictionary, a:key)
    return
  endif

  let is_string = get(a:000, 0, 0)

  let keyword_list = []
  let cache_list = a:async_cache_dictionary[a:key]
  for cache in cache_list
    if filereadable(cache.cachename)
      let keyword_list += neocomplete#cache#load_from_cache(
            \ a:cache_dir, cache.filename, is_string)
    endif
  endfor

  call neocomplete#cache#list2index(keyword_list, a:index_keyword_list, is_string)
  call filter(cache_list, '!filereadable(v:val.cachename)')

  if empty(cache_list)
    " Delete from dictionary.
    call remove(a:async_cache_dictionary, a:key)
  endif
endfunction"}}}
function! neocomplete#cache#check_cache(cache_dir, key, async_cache_dictionary, keyword_list_dictionary, ...) "{{{
  let is_string = get(a:000, 0, 0)

  " Caching.
  if !has_key(a:keyword_list_dictionary, a:key)
    let a:keyword_list_dictionary[a:key] = {}
  endif
  return neocomplete#cache#check_cache_list(
        \ a:cache_dir, a:key, a:async_cache_dictionary,
        \ a:keyword_list_dictionary[a:key], is_string)
endfunction"}}}
function! neocomplete#cache#load_from_cache(cache_dir, filename, ...) "{{{
  let is_string = get(a:000, 0, 0)

  try
    " Note: For neocomplete.
    let path = neocomplete#cache#encode_name(a:cache_dir, a:filename)
    let list = []
    lua << EOF
do
  local ret = vim.eval('list')
  local list = {}
  for line in io.lines(vim.eval('path')) do
    list = loadstring('return ' .. line)()
  end

  for i = 1, #list do
    ret:add(list[i])
  end
end
EOF
"     echomsg string(list)
    if !empty(list) && is_string && type(list[0]) != type('')
      " Type check.
      throw 'Type error'
    endif

    return list
  catch
    " Delete old cache file.
    let cache_name =
          \ neocomplete#cache#encode_name(a:cache_dir, a:filename)
    if filereadable(cache_name)
      call delete(cache_name)
    endif

    return []
  endtry
endfunction"}}}
function! neocomplete#cache#index_load_from_cache(cache_dir, filename, ...) "{{{
  let is_string = get(a:000, 0, 0)
  let keyword_lists = {}

  let completion_length = 2
  for keyword in neocomplete#cache#load_from_cache(
        \ a:cache_dir, a:filename, is_string)
    let key = tolower(
          \ (is_string ? keyword : keyword.word)[: completion_length-1])
    if !has_key(keyword_lists, key)
      let keyword_lists[key] = []
    endif
    call add(keyword_lists[key], keyword)
  endfor

  return keyword_lists
endfunction"}}}
function! neocomplete#cache#list2index(list, dictionary, is_string) "{{{
  let completion_length = 2
  for keyword in a:list
    let word = a:is_string ? keyword : keyword.word

    let key = tolower(word[: completion_length-1])
    if !has_key(a:dictionary, key)
      let a:dictionary[key] = {}
    endif
    let a:dictionary[key][word] = keyword
  endfor

  return a:dictionary
endfunction"}}}

" New cache loader.
function! neocomplete#cache#check_cache_noindex(cache_dir, key, async_cache_dictionary, keywords, is_string) "{{{
  if !has_key(a:async_cache_dictionary, a:key)
    return
  endif

  let cache_list = a:async_cache_dictionary[a:key]
  for cache in filter(copy(cache_list),
        \ 'filereadable(v:val.cachename)')
    let loaded_keywords = neocomplete#cache#load_from_cache(
              \ a:cache_dir, cache.filename, a:is_string)
    if type(a:keywords) == type({})
      if a:is_string
        for keyword in filter(loaded_keywords,
              \ '!has_key(a:keywords, v:val)')
          let a:keywords[keyword] = ''
        endfor
      else
        for keyword in filter(loaded_keywords,
              \ '!has_key(a:keyword_list, v:val.word)')
          let a:keywords[keyword.word] = keyword
        endfor
      endif
    else
      let a:keywords = loaded_keywords
    endif
  endfor

  call filter(cache_list, '!filereadable(v:val.cachename)')

  if empty(cache_list)
    " Delete from dictionary.
    call remove(a:async_cache_dictionary, a:key)
  endif
endfunction"}}}

function! neocomplete#cache#save_cache(cache_dir, filename, keyword_list) "{{{
  call neocomplete#cache#writefile(
        \ a:cache_dir, a:filename, [string(a:keyword_list)])
endfunction"}}}
function! neocomplete#cache#save_cache_old(cache_dir, filename, keyword_list) "{{{
  " Create dictionary key.
  for keyword in a:keyword_list
    if !has_key(keyword, 'abbr')
      let keyword.abbr = keyword.word
    endif
    if !has_key(keyword, 'kind')
      let keyword.kind = ''
    endif
    if !has_key(keyword, 'menu')
      let keyword.menu = ''
    endif
  endfor

  " Output cache.
  let word_list = []
  for keyword in a:keyword_list
    call add(word_list, printf('%s|||%s|||%s|||%s',
          \keyword.word, keyword.abbr, keyword.menu, keyword.kind))
  endfor

  call neocomplete#cache#writefile(
        \ a:cache_dir, a:filename, word_list)
endfunction"}}}

" Cache helper.
function! neocomplete#cache#getfilename(cache_dir, filename) "{{{
  let cache_dir = neocomplete#get_data_directory() . '/' . a:cache_dir
  return s:Cache.getfilename(cache_dir, a:filename)
endfunction"}}}
function! neocomplete#cache#filereadable(cache_dir, filename) "{{{
  let cache_dir = neocomplete#get_data_directory() . '/' . a:cache_dir
  return s:Cache.filereadable(cache_dir, a:filename)
endfunction"}}}
function! neocomplete#cache#readfile(cache_dir, filename) "{{{
  let cache_dir = neocomplete#get_data_directory() . '/' . a:cache_dir
  return s:Cache.readfile(cache_dir, a:filename)
endfunction"}}}
function! neocomplete#cache#writefile(cache_dir, filename, list) "{{{
  let cache_dir = neocomplete#get_data_directory() . '/' . a:cache_dir
  return s:Cache.writefile(cache_dir, a:filename, a:list)
endfunction"}}}
function! neocomplete#cache#encode_name(cache_dir, filename)
  " Check cache directory.
  let cache_dir = neocomplete#get_data_directory() . '/' . a:cache_dir
  return s:Cache.getfilename(cache_dir, a:filename)
endfunction
function! neocomplete#cache#check_old_cache(cache_dir, filename) "{{{
  let cache_dir = neocomplete#get_data_directory() . '/' . a:cache_dir
  return  s:Cache.check_old_cache(cache_dir, a:filename)
endfunction"}}}
function! neocomplete#cache#make_directory(directory) "{{{
  let directory =
        \ neocomplete#get_data_directory() .'/'.a:directory
  if !isdirectory(directory)
    call mkdir(directory, 'p')
  endif
endfunction"}}}

let s:sdir = neocomplete#util#substitute_path_separator(
      \ fnamemodify(expand('<sfile>'), ':p:h'))

" Async test.
function! neocomplete#cache#test_async() "{{{
  if !neocomplete#cache#check_old_cache(a:cache_dir, a:filename)
    return neocomplete#cache#encode_name(a:cache_dir, a:filename)
  endif

  let filename = neocomplete#util#substitute_path_separator(
        \ fnamemodify(expand('%'), ':p'))
  let pattern_file_name =
        \ neocomplete#cache#encode_name('keyword_patterns', 'vim')
  let cache_name =
        \ neocomplete#cache#encode_name('test_cache', filename)

  " Create pattern file.
  call neocomplete#cache#writefile(
        \ 'keyword_patterns', a:filename, [a:pattern])

  " args: funcname, outputname, filename pattern mark
  "       minlen maxlen encoding
  let fileencoding =
        \ &fileencoding == '' ? &encoding : &fileencoding
  let argv = [
        \  'load_from_file', cache_name, filename, pattern_file_name, '[B]',
        \  g:neocomplete_min_keyword_length, fileencoding
        \ ]
  return s:async_load(argv, 'test_cache', filename)
endfunction"}}}

function! neocomplete#cache#async_load_from_file(cache_dir, filename, pattern, mark) "{{{
  if !neocomplete#cache#check_old_cache(a:cache_dir, a:filename)
    return neocomplete#cache#encode_name(a:cache_dir, a:filename)
  endif

  let pattern_file_name =
        \ neocomplete#cache#encode_name('keyword_patterns', a:filename)
  let cache_name =
        \ neocomplete#cache#encode_name(a:cache_dir, a:filename)

  " Create pattern file.
  call neocomplete#cache#writefile(
        \ 'keyword_patterns', a:filename, [a:pattern])

  " args: funcname, outputname, filename pattern mark
  "       minlen maxlen encoding
  let fileencoding =
        \ &fileencoding == '' ? &encoding : &fileencoding
  let argv = [
        \  'load_from_file', cache_name, a:filename, pattern_file_name, a:mark,
        \  g:neocomplete_min_keyword_length, fileencoding
        \ ]
  return s:async_load(argv, a:cache_dir, a:filename)
endfunction"}}}
function! neocomplete#cache#async_load_from_tags(cache_dir, filename, filetype, mark, is_create_tags) "{{{
  if !neocomplete#cache#check_old_cache(a:cache_dir, a:filename)
    return neocomplete#cache#encode_name(a:cache_dir, a:filename)
  endif

  let cache_name =
        \ neocomplete#cache#encode_name(a:cache_dir, a:filename)
  let pattern_file_name =
        \ neocomplete#cache#encode_name('tags_pattens', a:filename)

  if a:is_create_tags
    if !executable(g:neocomplete_ctags_program)
      echoerr 'Create tags error! Please install '
            \ . g:neocomplete_ctags_program . '.'
      return neocomplete#cache#encode_name(a:cache_dir, a:filename)
    endif

    " Create tags file.
    let tags_file_name =
          \ neocomplete#cache#encode_name('tags_output', a:filename)

    let default = get(g:neocomplete_ctags_arguments_list, '_', '')
    let args = get(g:neocomplete_ctags_arguments_list, a:filetype, default)

    if has('win32') || has('win64')
      let filename =
            \ neocomplete#util#substitute_path_separator(a:filename)
      let command = printf('%s -f "%s" %s "%s" ',
            \ g:neocomplete_ctags_program, tags_file_name, args, filename)
    else
      let command = printf('%s -f ''%s'' 2>/dev/null %s ''%s''',
            \ g:neocomplete_ctags_program, tags_file_name, args, a:filename)
    endif

    if neocomplete#has_vimproc()
      call vimproc#system_bg(command)
    else
      call system(command)
    endif
  else
    let tags_file_name = '$dummy$'
  endif

  let filter_pattern =
        \ get(g:neocomplete_tags_filter_patterns, a:filetype, '')
  call neocomplete#cache#writefile('tags_pattens', a:filename,
        \ [neocomplete#get_keyword_pattern(),
        \  tags_file_name, filter_pattern, a:filetype])

  " args: funcname, outputname, filename
  "       pattern mark minlen encoding
  let fileencoding = &fileencoding == '' ? &encoding : &fileencoding
  let argv = [
        \  'load_from_tags', cache_name, a:filename, pattern_file_name, a:mark,
        \  g:neocomplete_min_keyword_length, fileencoding
        \ ]
  return s:async_load(argv, a:cache_dir, a:filename)
endfunction"}}}
function! s:async_load(argv, cache_dir, filename) "{{{
  " if 0
  if neocomplete#has_vimproc()
    let paths = vimproc#get_command_name(v:progname, $PATH, -1)
    if empty(paths)
      if has('gui_macvim')
        " MacVim check.
        if !executable('/Applications/MacVim.app/Contents/MacOS/Vim')
          call neocomplete#print_error(
                \ 'You installed MacVim in not default directory!'.
                \ ' You must add MacVim installed path in $PATH.')
          let g:neocomplete_use_vimproc = 0
          return
        endif

        let vim_path = '/Applications/MacVim.app/Contents/MacOS/Vim'
      else
        call neocomplete#print_error(
              \ printf('Vim path : "%s" is not found.'.
              \        ' You must add "%s" installed path in $PATH.',
              \        v:progname, v:progname))
        let g:neocomplete_use_vimproc = 0
        return
      endif
    else
      let base_path = neocomplete#util#substitute_path_separator(
            \ fnamemodify(paths[0], ':p:h'))

      let vim_path = base_path .
            \ (neocomplete#util#is_windows() ? '/vim.exe' : '/vim')
    endif

    if !executable(vim_path) && neocomplete#util#is_mac()
      " Note: Search "Vim" instead of vim.
      let vim_path = base_path. '/Vim'
    endif

    if !executable(vim_path)
      call neocomplete#print_error(
            \ printf('Vim path : "%s" is not executable.', vim_path))
      let g:neocomplete_use_vimproc = 0
      return
    endif

    let args = [vim_path, '-u', 'NONE', '-i', 'NONE', '-n',
          \       '-N', '-S', s:sdir.'/async_cache.vim']
          \ + a:argv
    call vimproc#system_bg(args)
    " call vimproc#system(args)
    " call system(join(args))
  else
    call neocomplete#async_cache#main(a:argv)
  endif

  return neocomplete#cache#encode_name(a:cache_dir, a:filename)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
