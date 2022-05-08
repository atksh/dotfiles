" setting
set fenc=utf-8

" visual
set number
set relativenumber
set cursorline
set visualbell
set showmatch
set laststatus=2
set showcmd
set statusline=[%n]
set statusline+=%{matchstr(hostname(),'\\w\\+')}@
set statusline+=%<%F
set statusline+=%m
set statusline+=%r
set statusline+=[%{&fileformat}]
set statusline+=[%{has('multi_byte')&&\&fileencoding!=''?&fileencoding:&encoding}]
set statusline+=%y


nnoremap j gj
nnoremap k gk
syntax enable
" カーソルが何行目の何列目に置かれているか
set ruler


" Tab系
" 不可視文字を可視化(タブが「▸-」と表示される)
set list listchars=tab:\▸\-
set smartindent
set tabstop=4
set autoindent
set expandtab
set shiftwidth=4
let python_highlight_all = 1
set clipboard=unnamed,autoselect


" 検索系
set ignorecase
set smartcase
set incsearch
set wrapscan
set hlsearch
nmap <Esc><Esc> :nohlsearch<CR><Esc>

" 戻るを永続化
if has('persistent_undo')
  set undodir=~/.vim/undo
  set undofile
endif

" 挿入モードでクリップボードからペーストする時に自動でインデントさせないようにする
if &term =~ "xterm"
    let &t_SI .= "\e[?2004h"
    let &t_EI .= "\e[?2004l"
    let &pastetoggle = "\e[201~"

    function XTermPasteBegin(ret)
        set paste
        return a:ret
    endfunction

    inoremap <special> <expr> <Esc>[200~ XTermPasteBegin("")
endif

" Others
"ハイフンを単語に含める
set isk+=-

"スペルチェック時に日本語を除外する
set spelllang=en,cjk

" インサートモードから抜けるときにペーストモードを解除する
autocmd InsertLeave * set nopaste


"syntax markdown
au BufRead,BufNewFile *.md set filetype=markdown

"------- Cursor -----"
"挿入モードでカーソル形状を変更する
let &t_SI.="\e[6 q"
let &t_EI.="\e[2 q"
"カーソル形状がすぐに元に戻らないのでタイムアウト時間を調整
set ttimeoutlen=10
"挿入モードを抜けた時にカーソルが見えなくなる現象対策(なぜかこれで治る)
inoremap <ESC> <ESC>
set mouse=a


" :W と :Q を :w と :q と認識させる
command W w
command Q q
command WQ wq
command Wq wq
