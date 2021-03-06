#==============================================================#
#               .zshrc                                         #
#==============================================================#

#--------------------------------------------------------------#
##          Base Configuration                                ##
#--------------------------------------------------------------#
export ZDOTDIR=$HOME
HOSTNAME=`hostname`
HISTFILE=~/.zsh/.zsh_history      # ヒストリ保存ファイル
HISTSIZE=10000                    # メモリ内の履歴の数
SAVEHIST=100000                   # 保存される履歴の数
LISTMAX=1000                      # 補完リストを尋ねる数 (1=黙って表示, 0=ウィンドウから溢れるときは尋ねる)

# root のコマンドはヒストリに追加しない
if [ $UID = 0 ]; then
  unset HISTFILE
  SAVEHIST=0
fi

# ls /usr/local/etc などと打っている際に、C-w で単語ごとに削除
# default  : ls /usr/local → ls /usr/ → ls /usr → ls /
# この設定 : ls /usr/local → ls /usr/ → ls /
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# core抑制
#unlimit
#limit core 0
#limit -s
limit   coredumpsize    10000

# ファイル作成時のパーミッション
umask 022


#--------------------------------------------------------------#
##          Environment Variables                             ##
#--------------------------------------------------------------#
export PATH=$PATH:$HOME/.bin
export EDITOR=vim

###     LANG     ###
if [ "$LANG" = "ja_JP.eucJP" ];then
  export LANG="ja_JP.eucJP"
else
  export LANG="ja_JP.UTF-8"
fi
export SUPPORTED="ja_JP.UTF-8:ja_JP:ja"

if [ -f $ZDOTDIR/.dircolors ];then
  eval $(dircolors $ZDOTDIR/.dircolors)
else
  export LS_COLORS='no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:'
fi
export LESS='-R'


#--------------------------------------------------------------#
##          Plugin                                            ##
#--------------------------------------------------------------#
export BIND_OPTION="emacs"
plugin_rc="$HOME/.zshrc.zplug"
if [ -f $plugin_rc ]; then
  source $plugin_rc
fi


#--------------------------------------------------------------#
##          Function                                          ##
#--------------------------------------------------------------#

###     git      ###
autoload -Uz VCS_INFO_get_data_git; VCS_INFO_get_data_git 2> /dev/null

function rprompt-git-current-branch {
local name st color gitdir action
if [[ "$PWD" =~ '/\.git(/.*)?$' ]]; then
  return
fi
name=`git symbolic-ref HEAD 2> /dev/null`
name=${name##refs/heads/}
if [[ -z $name ]]; then
  return
fi

gitdir=`git rev-parse --git-dir 2> /dev/null`
action=`VCS_INFO_git_getaction "$gitdir"` && action="($action)"

st=`git status 2> /dev/null`
if [[ -n `echo "$st" | grep "^nothing to"` ]]; then
  color=%F{green}
elif [[ -n `echo "$st" | grep "^nothing added"` ]]; then
  color=%F{yellow}
elif [[ -n `echo "$st" | grep "^# Untracked"` ]]; then
  color=%B%F{red}
else
  color=%F{red}
fi
echo "($color$name$action%f%b)"
}

###     cd      ###
function cd() {
builtin cd "$@" && ls -F --show-control-char --color=auto
}

###     history     ###
function history-all {
history -E 1  # 全履歴の一覧を出力する
}

###     rm      ###
# ~/.trashの作成は~/.bin/InstallMyHome.shに記載
function rm-trash() {
if [ -d ~/.trash ]; then
  local DATE=`date "+%y%m%d-%H%M%S"`
  mkdir ~/.trash/$DATE
  for j in $@; do
    # skip -
    if [ $j[1,1] != "-" ]; then
      # 対象が ~/.trash/ 以下なファイルならば /bin/rm を呼び出したいな
      if [ -e $j ]; then
        echo "mv $j ~/.trash/$DATE/"
        mv $j ~/.trash/$DATE/
      else
        echo "$j : not found"
      fi
    fi
  done
else
  command rm $@
fi
}

###     copy buffer     ###
function pbcopy-buffer(){
print -rn $BUFFER | pbcopy
zle -M "pbcopy: ${BUFFER}"
}

###     stack command     ###
function show_buffer_stack() {
POSTDISPLAY="
stack: $LBUFFER"
zle push-line-or-edit
}


#--------------------------------------------------------------#
##          Window Title                                      ##
#--------------------------------------------------------------#
# ターミナルのウィンドウ・タイトルを動的に変更
precmd() {
  [[ -t 1 ]] || return
  case $TERM in
    *xterm*|rxvt|(dt|k|E)term)
      print -Pn "\e]2;%n%%${ZSH_NAME}@%m:%~ [%l]\a"
      print -Pn "\e]2;[%n@%m %~] [%l]\a"
      print -Pn "\e]2;[%n@%m %~]\a"      # %l ← pts/1 等の表示を削除
      #            echo -ne "\033]0;${USER}@${HOST%%.*}:${PWD}\007"
      ;;
    screen*)
      #print -Pn "\e]0;[%n@%m %~] [%l]\a"
      print -Pn "\e]0;[%n@%m %~]\a"
      ;;
  esac
}

preexec () { # コマンドが実行される直前に実行
  [[ -t 1 ]] || return
  case $TERM in
    *xterm*|rxvt|(dt|k|E)term|screen*)
      print -Pn "\e]0;$1\a"
      ;;
  esac
}


#--------------------------------------------------------------#
##          Special Configuration                             ##
#--------------------------------------------------------------#
# カレントディレクトリ中にサブディレクトリが無い場合に cd が検索するディレクトリのリスト
cdpath=($HOME)
# zsh関数のサーチパス
#fpath=($fpath ~/.zfunc )

# run-help が呼ばれた時、zsh の内部コマンドの場合は該当する zsh のマニュアル表示
[ -n "`alias run-help`" ] && unalias run-help
autoload run-help


#--------------------------------------------------------------#
##          Prompt Configuration                              ##
#--------------------------------------------------------------#
# 左プロンプト
if `type git_super_status > /dev/null 2>&1`;then
  PROMPT='[%n@%m:%.`git_super_status`]${WINDOW:+"[$WINDOW]"}%# '
else
  PROMPT='[%n@%m:%.`rprompt-git-current-branch`]${WINDOW:+"[$WINDOW]"}%# '
fi

## <エスケープシーケンス>
## prompt_bang が有効な場合、!=現在の履歴イベント番号, !!='!' (リテラル)
# ${WINDOW:+"[$WINDOW]"} = screen 実行時にスクリーン番号を表示 (prompt_subst が必要)
# %B = underline
# %/ or %d = ディレクトリ (0=全て, -1=前方からの数)
# %~ = ディレクトリ
# %h or %! = 現在の履歴イベント番号
# %L = 現在の $SHLVL の値
# %M = マシンのフルホスト名
#  %m = ホスト名の最初の `.' までの部分
# %S (%s) = 突出モードの開始 (終了)
# %U (%u) = 下線モードの開始 (終了)
# %B (%b) = 太字モードの開始 (終了)
# %t or %@ = 12 時間制, am/pm 形式での現在時刻
# %n or $USERNAME = ユーザー ($USERNAME は環境変数なので setopt prompt_subst が必要)
# %N = シェル名
# %i = %N によって与えられるスクリプト, ソース, シェル関数で, 現在実行されている行の番号 (debug用)
# %T = 24 時間制での現在時刻
# %* = 24 時間制での現在時刻, 秒付き
# %w = `曜日-日' の形式での日付
# %W = `月/日/年' の形式での日付
# %D = `年-月-日' の形式での日付
# %D{string} = strftime 関数を用いて整形された文字列 (man 3 strftime でフォーマット指定が分かる)
# %l = ユーザがログインしている端末から, /dev/ プレフィックスを取り除いたもの
# %y = ユーザがログインしている端末から, /dev/ プレフィックスを取り除いたもの (/dev/tty* はソノママ)
# %? = プロンプトの直前に実行されたコマンドのリターンコード
# %_ = パーサの状態
# %E = 行末までクリア
# %# = 特権付きでシェルが実行されているならば `#', そうでないならば `%' == %(!.#.%%)
# %v = psvar 配列パラメータの最初の要素の値
# %{...%} = リテラルのエスケープシーケンスとして文字列をインクルード
# %(x.true-text.false-text) = 三つ組の式
# %<string<, %>string>, %[xstring] = プロンプトの残りの部分に対する, 切り詰めの振る舞い
#         `<' の形式は文字列の左側を切り詰め, `>' の形式は文字列の右側を切り詰めます
# %c, %., %C = $PWD の後ろ側の構成要素

#PROMPT=ubst が必要
# 右プロンプト


#--------------------------------------------------------------#
##          Completion                                        ##
#--------------------------------------------------------------#
# cd の後はディレクトリ名のみがマッチする
# su の後はユーザ名のみマッチする
# ssh の直後はユーザ名 or ホスト名、ユーザ名@に続いてはホスト名のみがマッチ(候補ホスト名の登録はまた後々)
# make の後は Makefile に記述されたターゲット名(install など)
# make --PREFIX= などの = の後のフルパス名マッチ
# jobs, fg, bg でのジョブ名マッチ
# kill の後のプロセス ID マッチ
# scp のリモートホスト側で、相手のファイルパスをマッチさせる
# 第1要素が大文字から始まる場合は環境変数にマッチ
# 代表的なコマンドでは 「-」 や 「--」 の後に使用可能なオプションがマッチ
# $の後はシェル変数／環境変数がマッチ(compinit しなくてもできますが)
# - 動的補完 : w3m, gcc 等に応じたファイルのみが補完される
autoload -U compinit
#compinit -u
compinit

# オプション補完で解説部分を表示
zstyle ':completion:*' verbose yes
# 補完方法の設定。指定した順番に実行する。
## _oldlist 前回の補完結果を再利用する。
## _complete: 普通の補完関数
## _ignored: 補完候補にださないと指定したものも補完候補とする。
## _match: *などのグロブによってコマンドを補完できる
## _prefix: カーソル以降を無視してカーソル位置までで補完する。
## _approximate: 似ている補完候補も補完候補とする。
## _expand: グロブや変数の展開を行う。もともとあった展開と比べて、細かい制御が可能
## _history: 履歴から補完を行う。_history_complete_wordから使われる
## _correct: ミススペルを訂正した上で補完を行う。
zstyle ':completion:*' completer _oldlist _complete _ignored
zstyle ':completion:*:messages' format '%F{yellow}%d'
zstyle ':completion:*:warnings' format '%B%F{red}No matches for:''%F{white}%d%b'
zstyle ':completion:*:descriptions' format '%B%F{white}--- %d ---%f%b'
zstyle ':completion::corrections' format ' %F{green}%d (errors: %e) %f'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' keep-prefix
zstyle ':completion:*' recent-dirs-insert both
zstyle ':completion:*' list-colors ${LS_COLORS} # 補完候補を色分け (GNU ls の色定義を流用)
zstyle ':completion:*' special-dirs true
# 補完の時に大文字小文字を区別しない (但し、大文字を打った場合は小文字に変換しない)
#zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
# 一部のコマンドライン定義は、展開時に時間のかかる処理を行う -- apt-get, dpkg (Debian), rpm (Redhat), urpmi (Mandrake), perlの-Mオプション, bogofilter (zsh 4.2.1以降), fink, mac_apps (MacOS X)(zsh 4.2.2以降)
#zstyle ':completion:*' use-cache true
# 補完候補を ←↓↑→ で選択 (補完候補が色分け表示される)
# zstyle show completion menu if 1 or more items to select
zstyle ':completion:*:default' menu select=1
# カレントディレクトリに候補がない場合のみ cdpath 上のディレクトリを候補
zstyle ':completion:*:cd:*' tag-order local-directories path-directories
# 補完リストの順番指定
zstyle ':completion:*:cd:*' group-order local-directories path-directories
# psコマンドを補完する
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'
# sudoコマンドを補完する
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin
# 変数の添字を補完する
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters
# manの補完をセクション番号別に表示させる
zstyle ':completion:*:manuals' separate-sections true
# 更新日順に表示する
zstyle ':completion:*' file-sort 'modification'

# 特定のコマンドの補完を無効にする
#compdef -d w3m
# あるコマンドの補完を他のコマンドのように補完する (platex も latex と同じ)
#compdef _tex platex


#--------------------------------------------------------------#
##          Key Bindings                                      ##
#--------------------------------------------------------------#
# 端末設定
stty    intr    '^C'        # Ctrl+C に割り込み
stty    susp    '^Z'        # Ctrl+Z にサスペンド

# zsh のキーバインド (EDITOR=vi かでも判断)
bindkey -e    # emacs 風
#bindkey -v     # vi 風

## delete ##
bindkey -M $BIND_OPTION '^?'    backward-delete-char
bindkey -M $BIND_OPTION '^H'    backward-delete-char
bindkey -M $BIND_OPTION '^[[3~' delete-char
bindkey -M $BIND_OPTION '^[[3;5~' delete-word
bindkey -M $BIND_OPTION '^[[1~' beginning-of-line
bindkey -M $BIND_OPTION '^[[4~' end-of-line
bindkey -M $BIND_OPTION '^U' backward-kill-line
bindkey -M $BIND_OPTION '^[^?' delete-char-or-list

## move ##
bindkey -M $BIND_OPTION '^[h' backward-char
bindkey -M $BIND_OPTION '^[j' down-line-or-history
bindkey -M $BIND_OPTION '^[k' up-line-or-history
bindkey -M $BIND_OPTION '^[l' forward-char
bindkey -M $BIND_OPTION '^[[1;5C' forward-word
bindkey -M $BIND_OPTION '^[[1;5D' backward-word

## history ##
autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey -M $BIND_OPTION '^P' history-beginning-search-backward-end
bindkey -M $BIND_OPTION '^N' history-beginning-search-forward-end
bindkey -M $BIND_OPTION '^[[A' history-beginning-search-backward-end
bindkey -M $BIND_OPTION '^[[B' history-beginning-search-forward-end
# history incremental search
#bindkey -M $BIND_OPTION "^R" history-incremental-search-backward
#bindkey -M $BIND_OPTION "^S" history-incremental-search-forward
bindkey -M $BIND_OPTION '^R' history-incremental-pattern-search-backward
bindkey -M $BIND_OPTION '^S' history-incremental-pattern-search-forward
autoload -Uz smart-insert-last-word
# [a-zA-Z], /, \ のうち少なくとも1文字を含む長さ2以上の単語
zstyle :insert-last-word match '*([[:alpha:]/\\]?|?[[:alpha:]/\\])*'
zle -N insert-last-word smart-insert-last-word
bindkey -M $BIND_OPTION '^]' insert-last-word
# anyframe
bindkey -M $BIND_OPTION '^xb' anyframe-widget-cdr
bindkey -M $BIND_OPTION '^x^b' anyframe-widget-checkout-git-branch
bindkey -M $BIND_OPTION '^xr' anyframe-widget-execute-history
bindkey -M $BIND_OPTION '^x^r' anyframe-widget-execute-history
bindkey -M $BIND_OPTION '^xp' anyframe-widget-put-history
bindkey -M $BIND_OPTION '^x^p' anyframe-widget-put-history
bindkey -M $BIND_OPTION '^xg' anyframe-widget-cd-ghq-repository
bindkey -M $BIND_OPTION '^x^g' anyframe-widget-cd-ghq-repository
bindkey -M $BIND_OPTION '^xk' anyframe-widget-kill
bindkey -M $BIND_OPTION '^x^k' anyframe-widget-kill
bindkey -M $BIND_OPTION '^xi' anyframe-widget-insert-git-branch
bindkey -M $BIND_OPTION '^x^i' anyframe-widget-insert-git-branch
bindkey -M $BIND_OPTION '^xf' anyframe-widget-insert-filename
bindkey -M $BIND_OPTION '^x^f' anyframe-widget-insert-filename

## completion ##
# shift-tabで補完を逆走
zmodload zsh/complist
bindkey -M $BIND_OPTION '^[[Z' reverse-menu-complete
bindkey -M menuselect '^[[Z' reverse-menu-complete

## edit ##
# copy command
zle -N pbcopy-buffer
bindkey -M $BIND_OPTION '^x^p' pbcopy-buffer
bindkey -M $BIND_OPTION '^[u' undo
bindkey -M $BIND_OPTION '^[r' redo

## etc ##
# ワイルドカードの展開を確認
bindkey -M $BIND_OPTION '^X' expand-word
# stack command
zle -N show_buffer_stack
bindkey -M $BIND_OPTION '^Q' show_buffer_stack

## zaw ##
bindkey -M $BIND_OPTION '^@' zaw-cdr
bindkey -M $BIND_OPTION '^X^F' zaw-git-files
bindkey -M $BIND_OPTION '^X^B' zaw-git-branches
bindkey -M $BIND_OPTION '^X^P' zaw-process
bindkey -M $BIND_OPTION '^X^A' zaw-tmux

## auto-fu ##
if type afu+cancel-and-accept-line 1>/dev/null 2>&1; then
  bindkey -M $BIND_OPTION "^M" afu+cancel-and-accept-line
fi


#--------------------------------------------------------------#
##          Options                                           ##
#--------------------------------------------------------------#
setopt prompt_subst          # プロンプトに escape sequence (環境変数) を通す
unsetopt promptcr            # 改行のない出力をプロンプトで上書きするのを防ぐ
#  autoload -U colors        # プロンプトのカラー表示を有効
#  colors                    # → 色指定  $fg[色名]/$bg[色名]/$reset_color (${, $} で囲む必要がある)
#                            #            30黒 31赤 32緑 33黄 34青 35紫 36水 37白
setopt nonomatch # wild card extended
#setopt extended_history      # 履歴ファイルに開始時刻と経過時間を記録
unsetopt extended_history
setopt append_history        # 履歴を追加 (毎回 .zhistory を作るのではなく)
setopt inc_append_history    # 履歴をインクリメンタルに追加
setopt share_history         # 履歴の共有
setopt hist_ignore_all_dups  # 重複するコマンド行は古い方を削除
setopt hist_ignore_dups      # 直前と同じコマンドラインはヒストリに追加しない
setopt hist_ignore_space     # スペースで始まるコマンド行はヒストリリストから削除
# (→ 先頭にスペースを入れておけば、ヒストリに保存されない)
unsetopt hist_verify         # ヒストリを呼び出してから実行する間に一旦編集可能を止める
setopt hist_reduce_blanks    # 余分な空白は詰めて記録<-teratermで履歴かおかしくなる
setopt hist_save_no_dups     # ヒストリファイルに書き出すときに、古いコマンドと同じものは無視する。
setopt hist_no_store         # historyコマンドは履歴に登録しない

setopt hist_expand           # 補完時にヒストリを自動的に展開
setopt list_packed           # コンパクトに補完リストを表示
setopt auto_remove_slash     # 補完で末尾に補われた / を自動的に削除
setopt auto_param_slash      # ディレクトリ名の補完で末尾の / を自動的に付加し、次の補完に備える
setopt mark_dirs             # ファイル名の展開でディレクトリにマッチした場合 末尾に / を付加
setopt list_types            # 補完候補一覧でファイルの種別を識別マーク表示 (訳注:ls -F の記号)
unsetopt menu_complete       # 補完の際に、可能なリストを表示してビープを鳴らすのではなく、
# 最初にマッチしたものをいきなり挿入、はしない
setopt auto_list             # ^Iで補完可能な一覧を表示する(補完候補が複数ある時に、一覧表示)
setopt auto_menu             # 補完キー連打で順に補完候補を自動で補完
setopt auto_param_keys       # カッコの対応などを自動的に補完
setopt auto_resume           # サスペンド中のプロセスと同じコマンド名を実行した場合はリジューム

#setopt auto_correct          # 補完時にスペルチェック
#setopt correct               # スペルミスを補完
#setopt correct_all           # コマンドライン全てのスペルチェックをする

setopt auto_cd               # ディレクトリのみで移動
setopt no_beep               # コマンド入力エラーでBeepを鳴らさない
#setopt beep
#setopt brace_ccl             # ブレース展開機能を有効にする -> HEAD@{1}とかが展開されてしまう
#setopt bsd_echo
setopt complete_in_word
setopt equals                # =COMMAND を COMMAND のパス名に展開
setopt nonomatch             # グロブ展開でnomatchにならないようにする
setopt glob
setopt extended_glob         # 拡張グロブを有効にする
unsetopt flow_control        # (shell editor 内で) C-s, C-q を無効にする
setopt no_flow_control       # C-s/C-q によるフロー制御を使わない
setopt hash_cmds             # 各コマンドが実行されるときにパスをハッシュに入れる
setopt no_hup                # ログアウト時にバックグラウンドジョブをkillしない
setopt ignore_eof            # C-dでログアウトしない
#setopt no_checkjobs          # ログアウト時にバックグラウンドジョブを確認しない

setopt long_list_jobs        # 内部コマンド jobs の出力をデフォルトで jobs -L にする
setopt magic_equal_subst     # コマンドラインの引数で --PREFIX=/USR などの = 以降でも補完できる
setopt mail_warning
setopt multios               # 複数のリダイレクトやパイプなど、必要に応じて TEE や CAT の機能が使われる
setopt numeric_glob_sort     # 数字を数値と解釈してソートする
setopt path_dirs             # コマンド名に / が含まれているとき PATH 中のサブディレクトリを探す
setopt print_eight_bit       # 補完候補リストの日本語を適正表示
setopt short_loops           # FOR, REPEAT, SELECT, IF, FUNCTION などで簡略文法が使えるようになる

setopt auto_name_dirs
#setopt sun_keyboard_hack     # SUNキーボードでの頻出 typo ` をカバーする
setopt always_last_prompt    # カーソル位置は保持したままファイル名一覧を順次その場で表示
setopt cdable_vars
unsetopt sh_word_split

setopt auto_pushd            # 普通に cd するときにもディレクトリスタックにそのディレクトリを入れる
setopt pushd_ignore_dups     # ディレクトリスタックに重複する物は古い方を削除
setopt pushd_to_home         # pushd 引数ナシ == pushd $HOME
setopt pushd_silent          # pushd,popdの度にディレクトリスタックの中身を表示しない

setopt rm_star_wait          # rm * を実行する前に確認
#setopt rm_star_silent        # rm * を実行する前に確認しない
setopt notify                # バックグラウンドジョブが終了したら(プロンプトの表示を待たずに)すぐに知らせる

#setopt no_clobber            # リダイレクトで上書きを禁止
unsetopt no_clobber
#setopt no_unset              # 未定義変数の使用禁止
setopt interactive_comments  # コマンド入力中のコメントを認める
setopt chase_links           # シンボリックリンクはリンク先のパスに変換してから実行
#setopt print_exit_value      # 戻り値が 0 以外の場合終了コードを表示
#setopt single_line_zle       # デフォルトの複数行コマンドライン編集ではなく、１行編集モードになる
#setopt xtrace                # コマンドラインがどのように展開され実行されたかを表示する
setopt noflowcontrol


#--------------------------------------------------------------#
##          Aliases                                           ##
#--------------------------------------------------------------#
## common ##
alias rm='rm-trash'
alias del='rm -rf'
alias cp='cp -irf'
alias mv='mv -i'
alias ..='cd ..'
alias zcompile='zcompile ~/.zshrc'
alias rez='exec zsh'
alias sc='screen'
alias l='less'
alias sudo='sudo -E '
alias cl='clear'
alias dircolor='eval `dircolors -b ~/.dir_colors`'   ## for Debian
alias quit='exit';

# グローバルエイリアス
alias -g G='| grep '  # e.x. dmesg lG CPU
alias -g L='| $PAGER '
alias -g W='| wc'
alias -g H='| head'
alias -g T='| tail'

# ls
alias la='ls -aF --show-control-char --color=auto'
alias lla='ls -alF --show-control-char --color=auto'
alias lal='ls -alF --show-control-char --color=auto'
alias ls='ls --show-control-char --color=auto'
alias ll='ls -l --show-control-char --color=auto'
alias l.='ls -d .[a-zA-Z]* --color=auto'

# chmod
alias 644='chmod 644'
alias 755='chmod 755'
alias 777='chmod 777'

# grep 行数, 再帰的, ファイル名表示, 行数表示, バイナリファイルは処理しない
alias grep='grep -i -H -n -I --color=auto'

## application ##
# vi
alias vi='vim'
alias v='vim'
alias sv='sudo vi'

## development ##
alias py='python'
alias gdb='gdb -silent'

# 今迄の履歴を簡単に辿る
alias gd='dirs -v; echo -n "select number: "; read newdir; cd +"$newdir"' # AUTO_PUSHD が必要
# dirs -v  --  ディレクトリスタックを表示

# tmux
alias tmux_powerline_disable='export ENABLE_TMUX_POWERLINE=false'
alias tmux_powerline_enable='export ENABLE_TMUX_POWERLINE=true'
alias tmux='TERM=xterm-256color tmux'


#--------------------------------------------------------------#
##          Execute Script                                    ##
#--------------------------------------------------------------#
if [ -f "$ZDOTDIR/.zshrc.local" ];then
  source "$ZDOTDIR/.zshrc.local"
fi

if [ -f "$ZDOTDIR/.tmuxinator/tmuxinator.zsh" ];then
  source $ZDOTDIR/.tmuxinator/tmuxinator.zsh
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


