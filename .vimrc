"""""""""""""""""""""""""""""
"        Behaviour          "
"""""""""""""""""""""""""""""
set nocompatible                " Don't behave like Vi

set backspace=indent,eol,start  " Allow backspacing over more stuff
set ignorecase                  " Case insensitive search
set smartcase                   " Case sensitive if search term contains capitals
set linebreak                   " Allow linebreaks between words
set scrolloff=2                 " Start scrolling a few lines from the border
set encoding=utf8               " Use utf8 as internal encoding
"set whichwrap+=<,>,h,l          " Allow cursor to wrap lines
set hidden                      " Allow opening new buffers without saving changes
set mouse=a                     " Allow mouse control in all modes
set undofile                    " Persistent undo history
set undodir=~/.vim/undo         " Undo data location
"set directory=~/.vim/swap       " Swap file location
"set backupdir=~/.vim/backup     " Backup file location
"set shell=zsh                   " Tell vim about zsh
set clipboard=unnamedplus       " copy/paste like regular

" Save cursor position "
augroup resCur
  autocmd!
  autocmd BufReadPost * call setpos(".", getpos("'\""))

"""""""""""""""""""""""""""""
"        Formatting         "
"""""""""""""""""""""""""""""
set tabstop=4                   " Width of the tab character
set softtabstop=4               " How many columns the tab key inserts
set shiftwidth=4                " Width of 1 indentation level
set expandtab                   " Expand tabs into spaces
set smartindent                 " Smart C-like autoindenting
set autoindent                  " automatically intend lines
set copyindent                  " copy intend from previous line

" Determine indentation rules by filetype
filetype plugin indent on


"""""""""""""""""""""""""""""
"        Interface          "
"""""""""""""""""""""""""""""
set number                      " Show line numbers
"set showmatch                   " When inserting brackets, highlight the matching one
"set hlsearch                    " Highlight search results
"set incsearch                   " Highlight search results as the search is typed
"set showcmd                     " Show command on the bottom
"set ruler                       " Show line and cursor position
"set listchars=tab:>-,trail:·    " Show tabs and trailing space
"set list                        " Enable the above settings
"set laststatus=2                " Wider status line, needed for powerline
syntax on                       " Enable syntax highlighting
"""""""""""""""""""""""""""""
"        Colours and GUI    "
"""""""""""""""""""""""""""""
set background=dark     " Use dark background
