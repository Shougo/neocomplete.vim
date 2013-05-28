"=============================================================================
" FILE: converter_delimiter.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 28 May 2013.
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

function! neocomplete#filters#converter_delimiter#define() "{{{
  return s:converter
endfunction"}}}

let s:converter = {
      \ 'name' : 'converter_delimiter',
      \ 'description' : 'delimiter converter',
      \}

function! s:converter.filter(context) "{{{
  " Delimiter check.
  let filetype = neocomplete#get_context_filetype()

  let next_keyword = neocomplete#filters#
        \converter_remove_next_keyword#get_next_keyword(a:context.source_name)
  for delimiter in ['/'] +
        \ get(g:neocomplete_delimiter_patterns, filetype, [])
    " Count match.
    let delim_cnt = 0
    let matchend = matchend(a:context.complete_str, delimiter)
    while matchend >= 0
      let matchend = matchend(a:context.complete_str,
            \ delimiter, matchend)
      let delim_cnt += 1
    endwhile

    for candidate in a:context.candidates
      let split_list = split(candidate.word, delimiter.'\ze.', 1)
      if len(split_list) > 1
        let delimiter_sub = substitute(
              \ delimiter, '\\\([.^$]\)', '\1', 'g')
        let candidate.word = join(split_list[ : delim_cnt], delimiter_sub)
        let candidate.abbr = join(
              \ split(get(candidate, 'abbr', candidate.word),
              \             delimiter.'\ze.', 1)[ : delim_cnt],
              \ delimiter_sub)

        if g:neocomplete_max_keyword_width >= 0
              \ && len(candidate.abbr) > g:neocomplete_max_keyword_width
          let candidate.abbr = substitute(candidate.abbr,
                \ '\(\h\)\w*'.delimiter, '\1'.delimiter_sub, 'g')
        endif
        if delim_cnt+1 < len(split_list)
          let candidate.abbr .= delimiter_sub . '~'
          let candidate.dup = 0

          if g:neocomplete_enable_auto_delimiter && next_keyword == ''
            let candidate.word .= delimiter_sub
          endif
        endif
      endif
    endfor
  endfor

  return a:context.candidates
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
