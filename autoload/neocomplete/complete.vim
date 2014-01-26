"=============================================================================
" FILE: complete.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 26 Jan 2014.
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

function! neocomplete#complete#manual_complete(findstart, base) "{{{
  let neocomplete = neocomplete#get_current_neocomplete()
  let neocomplete.event = ''

  if a:findstart
    let cur_text = neocomplete#get_cur_text()
    if !neocomplete#is_enabled()
          \ || neocomplete#helper#is_omni(cur_text)
      let &l:completefunc = 'neocomplete#complete#manual_complete'

      return (neocomplete#is_prefetch()
            \ || !neocomplete#is_auto_complete()
            \ || g:neocomplete#enable_insert_char_pre) ?
            \ -1 : -3
    endif

    " Get complete_pos.
    if neocomplete#is_prefetch() &&
          \ !empty(neocomplete.complete_sources)
      " Use prefetch results.
    else
      let neocomplete.complete_sources =
            \ neocomplete#complete#_get_results(cur_text)
    endif
    let complete_pos =
          \ neocomplete#complete#_get_complete_pos(
          \ neocomplete.complete_sources)

    if complete_pos >= 0
      " Pre gather candidates for skip completion.
      let base = cur_text[complete_pos :]

      let neocomplete.candidates = neocomplete#complete#_get_words(
            \ neocomplete.complete_sources, complete_pos, base)
      let neocomplete.complete_str = base

      if empty(neocomplete.candidates)
        " Nothing candidates.
        let complete_pos = -1
      endif
    endif

    if complete_pos < 0
      let neocomplete = neocomplete#get_current_neocomplete()
      let complete_pos = (neocomplete#is_prefetch() ||
            \ g:neocomplete#enable_insert_char_pre ||
            \ !neocomplete#is_auto_complete() ||
            \ neocomplete#get_current_neocomplete().skipped) ?  -1 : -3
      let neocomplete.skipped = 0
      let neocomplete.overlapped_items = {}
    endif

    return complete_pos
  else
    if neocomplete.completeopt !=# &completeopt
      " Restore completeopt.
      let &completeopt = neocomplete.completeopt
    endif

    let dict = { 'words' : neocomplete.candidates }

    if len(a:base) < g:neocomplete#auto_completion_start_length
          \ || g:neocomplete#enable_refresh_always
          \ || g:neocomplete#enable_cursor_hold_i
      let dict.refresh = 'always'
    endif

    return dict
  endif
endfunction"}}}

function! neocomplete#complete#sources_manual_complete(findstart, base) "{{{
  let neocomplete = neocomplete#get_current_neocomplete()
  let neocomplete.event = ''

  if a:findstart
    if !neocomplete#is_enabled()
      return -2
    endif

    " Get complete_pos.
    let complete_sources = neocomplete#complete#_get_results(
          \ neocomplete#get_cur_text(1), neocomplete.manual_sources)
    let neocomplete.complete_pos =
          \ neocomplete#complete#_get_complete_pos(complete_sources)

    if neocomplete.complete_pos < 0
      return -2
    endif

    let neocomplete.complete_sources = complete_sources

    return neocomplete.complete_pos
  endif

  let neocomplete.complete_pos =
        \ neocomplete#complete#_get_complete_pos(
        \     neocomplete.complete_sources)
  let candidates = neocomplete#complete#_get_words(
        \ neocomplete.complete_sources,
        \ neocomplete.complete_pos, a:base)

  let neocomplete.candidates = candidates
  let neocomplete.complete_str = a:base

  return candidates
endfunction"}}}

function! neocomplete#complete#auto_complete(findstart, base) "{{{
  return neocomplete#complete#manual_complete(a:findstart, a:base)
endfunction"}}}

function! neocomplete#complete#_get_results(cur_text, ...) "{{{
  if g:neocomplete#enable_debug
    echomsg 'start get_complete_sources'
  endif

  let neocomplete = neocomplete#get_current_neocomplete()
  let neocomplete.start_time = reltime()

  " Comment check.
  let neocomplete.within_comment =
        \ neocomplete#helper#get_syn_name(1) ==# 'Comment'

  let complete_sources = call(
        \ 'neocomplete#complete#_set_results_pos', [a:cur_text] + a:000)
  call neocomplete#complete#_set_results_words(complete_sources)

  return filter(copy(complete_sources),
        \ '!empty(v:val.neocomplete__context.candidates)')
endfunction"}}}

function! neocomplete#complete#_get_complete_pos(sources) "{{{
  if empty(a:sources)
    return -1
  endif

  return min([col('.')] + map(copy(a:sources),
        \ 'v:val.neocomplete__context.complete_pos'))
endfunction"}}}

function! neocomplete#complete#_get_words(sources, complete_pos, complete_str) "{{{
  let frequencies = neocomplete#variables#get_frequencies()
  if exists('*neocomplete#sources#buffer#get_frequencies')
    let frequencies = extend(copy(
          \ neocomplete#sources#buffer#get_frequencies()),
          \ frequencies)
  endif

  " Append prefix.
  let candidates = []
  let len_words = 0
  for source in sort(filter(copy(a:sources),
        \ '!empty(v:val.neocomplete__context.candidates)'),
        \  's:compare_source_rank')
    let mark = source.mark
    let context = source.neocomplete__context
    let words =
          \ type(context.candidates[0]) == type('') ?
          \ map(copy(context.candidates), "{'word': v:val, 'menu' : mark}") :
          \ deepcopy(context.candidates)
    let context.candidates = words

    call neocomplete#helper#call_hook(
          \ source, 'on_post_filter', {})

    if context.complete_pos > a:complete_pos
      let prefix = a:complete_str[: context.complete_pos
            \                            - a:complete_pos - 1]

      " Fix complete position.
      let context.complete_pos = a:complete_pos
      let context.complete_str = prefix

      for candidate in words
        let candidate.word = prefix . candidate.word
      endfor
    endif

    lua << EOF
    do
      local frequencies = vim.eval('frequencies')
      local candidates = vim.eval('words')
      for i = 0, #candidates-1 do
        if frequencies[candidates[i].word] ~= nil then
          candidates[i].rank = frequencies[candidates[i].word]
        end
      end
    end
EOF

    let words = neocomplete#helper#call_filters(
          \ source.neocomplete__sorters, source, {})

    if source.max_candidates > 0
      let words = words[: len(source.max_candidates)-1]
    endif

    " Set default menu.
    lua << EOF
    do
      local candidates = vim.eval('words')
      local mark = vim.eval('mark')
      for i = 0, #candidates-1 do
        if candidates[i].menu == nil then
          candidates[i].menu = mark
        end
      end
    end
EOF

    let words = neocomplete#helper#call_filters(
          \ source.neocomplete__converters, source, {})

    let candidates += words
    let len_words += len(words)

    if g:neocomplete#max_list > 0
          \ && len_words > g:neocomplete#max_list
      break
    endif

    if neocomplete#complete_check()
      return []
    endif
  endfor

  if g:neocomplete#max_list > 0
    let candidates = candidates[: g:neocomplete#max_list]
  endif

  " Check dup and set icase.
  let icase = !neocomplete#is_text_mode() && !neocomplete#within_comment() &&
        \ g:neocomplete#enable_ignore_case &&
        \!((g:neocomplete#enable_smart_case
        \  || g:neocomplete#enable_camel_case) && a:complete_str =~ '\u')
  if icase
    for candidate in candidates
      let candidate.icase = 1
    endfor
  endif

  if neocomplete#complete_check()
    return []
  endif

  return candidates
endfunction"}}}
function! neocomplete#complete#_set_results_pos(cur_text, ...) "{{{
  " Initialize sources.
  let neocomplete = neocomplete#get_current_neocomplete()

  let filetype = neocomplete#get_context_filetype()
  let sources = (a:0 > 0) ? a:1 :
        \ (filetype ==# neocomplete.sources_filetype) ?
        \ neocomplete.sources : neocomplete#helper#get_sources_list()

  let pos = winsaveview()

  " Try source completion. "{{{
  let complete_sources = []
  for source in filter(values(sources),
        \ 'neocomplete#helper#is_enabled_source(v:val, filetype)')
    if !source.loaded
      call neocomplete#helper#call_hook(source, 'on_init', {})
      let source.loaded = 1
    endif

    let context = source.neocomplete__context
    let context.input = a:cur_text

    try
      let complete_pos =
            \ has_key(source, 'get_complete_position') ?
            \ source.get_complete_position(context) :
            \ neocomplete#helper#match_word(context.input,
            \    neocomplete#get_keyword_pattern_end(filetype, source.name))[0]
    catch
      call neocomplete#print_error(v:throwpoint)
      call neocomplete#print_error(v:exception)
      call neocomplete#print_error(
            \ 'Error occured in source''s get_complete_position()!')
      call neocomplete#print_error(
            \ 'Source name is ' . source.name)
      return complete_sources
    finally
      if winsaveview() != pos
        call winrestview(pos)
      endif
    endtry

    if complete_pos < 0
      let context.complete_pos = -1
      let context.complete_str = ''
      continue
    endif

    let complete_str = context.input[complete_pos :]
    if neocomplete#is_auto_complete() &&
          \ len(complete_str) < source.min_pattern_length
      " Skip.
      let context.complete_pos = -1
      let context.complete_str = ''
      continue
    endif

    let context.complete_pos = complete_pos
    let context.complete_str = complete_str
    call add(complete_sources, source)
  endfor
  "}}}

  return complete_sources
endfunction"}}}
function! neocomplete#complete#_set_results_words(sources) "{{{
  " Try source completion.

  " Save options.
  let ignorecase_save = &ignorecase
  let pos = winsaveview()

  for source in a:sources
    if neocomplete#complete_check()
      return
    endif

    let context = source.neocomplete__context

    let &ignorecase = (g:neocomplete#enable_smart_case
          \ || g:neocomplete#enable_camel_case) ?
          \   context.complete_str !~ '\u' : g:neocomplete#enable_ignore_case

    if !source.is_volatile
          \ && context.prev_complete_pos == context.complete_pos
          \ && !empty(context.prev_candidates)
      " Use previous candidates.
      let context.candidates = context.prev_candidates
    else
      try
        let context.candidates = source.gather_candidates(context)
      catch
        call neocomplete#print_error(v:throwpoint)
        call neocomplete#print_error(v:exception)
        call neocomplete#print_error(
              \ 'Source name is ' . source.name)
        call neocomplete#print_error(
              \ 'Error occured in source''s gather_candidates()!')

        let &ignorecase = ignorecase_save
        return
      finally
        if winsaveview() != pos
          call winrestview(pos)
        endif
      endtry
    endif

    let context.prev_candidates = copy(context.candidates)
    let context.prev_complete_pos = context.complete_pos

    if !empty(context.candidates)
      let context.candidates = neocomplete#helper#call_filters(
            \ source.neocomplete__matchers, source, {})
    endif

    if g:neocomplete#enable_debug
      echomsg source.name
    endif
  endfor

  let &ignorecase = ignorecase_save
endfunction"}}}

" Source rank order. "{{{
function! s:compare_source_rank(i1, i2)
  return a:i2.rank - a:i1.rank
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
