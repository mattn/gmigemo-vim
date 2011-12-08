"=============================================================================
" File: gmigemo.vim
" Author: Yasuhiro Matsumoto <mattn.jp@gmail.com>
" Last Change:08-Dec-2011.
" Version: 0.1
" WebPage: http://github.com/mattn/gmigemo-vim
" Usage:
"
"   :GoogleMigemo ここではきものをぬぐ
"     match: "ココでは着物を脱ぐ"
"
"   :GoogleMigemo ここで はきものを ぬぐ
"     match: "此処で履物を脱ぐ"
"
" Require:
"   webapi-vim: http://github.com/mattn/webapi-vim

if exists("loaded_gmigemo") || v:version < 700
  finish
endif
let loaded_gmigemo = 1

function! s:nr2byte(nr)
  if a:nr < 0x80
    return nr2char(a:nr)
  elseif a:nr < 0x800
    return nr2char(a:nr/64+192).nr2char(a:nr%64+128)
  else
    return nr2char(a:nr/4096%16+224).nr2char(a:nr/64%64+128).nr2char(a:nr%64+128)
  endif
endfunction

function! s:nr2enc_char(charcode)
  if &encoding == 'utf-8'
    return nr2char(a:charcode)
  endif
  let char = s:nr2byte(a:charcode)
  if strlen(char) > 1
    let char = strtrans(iconv(char, 'utf-8', &encoding))
  endif
  return char
endfunction

function! g:GoogleMigemo(word)
  let word = substitute(a:word, '\s', ',', 'g')
  let url = "http://www.google.com/transliterate"
  let res = http#get(url, { "langpair": "ja-Hira|ja", "text": word }, {})
  let str = iconv(res.content, "utf-8", &encoding)
  let str = substitute(str, '\\u\(\x\x\x\x\)', '\=s:nr2enc_char("0x".submatch(1))', 'g')
  let str = substitute(str, "\n", "", "g")
  let g:hoge = str
  let arr = eval(str)
  let mx = ''
  for m in arr
    call map(m[1], 'substitute(v:val,"\\\\", "\\\\\\\\", "g")')
    let mx .= '\('.join(m[1], '\|').'\)'
  endfor
  return mx
endfunction

function! s:GoogleMigemo(word)
  if executable('curl') == ''
    echohl ErrorMsg
    echo 'GoogleMigemo: curl is not installed'
    echohl None
    return
  endif

  let word = a:word != '' ? a:word : input('GoogleMigemo:')
  if word == ''
    return
  endif
  let mx = g:GoogleMigemo(word)
  let @/ = mx
  let v:errmsg = ''
  silent! normal n
  if v:errmsg != ''
    echohl ErrorMsg
    echo v:errmsg
    echohl None
  endif
endfunction

command! -nargs=* GoogleMigemo :call <SID>GoogleMigemo(<q-args>)
nnoremap <silent> <leader>mg :call <SID>GoogleMigemo('')<cr>

" vi:set ts=8 sts=2 sw=2 tw=0:
