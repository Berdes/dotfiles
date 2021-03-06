alias ls="ls --color"
alias ll="ls -lh"
alias l="ls -lAh"
alias gg="g++ --std=c++14 -Wall -Wextra -O2"

alias reboot="sudo reboot"
alias halt="sudo halt -p"
alias new="vim (date +\"%F.txt\")"
set BROWSER chromium
set PATH /home/berdes/.cabal/bin/ $PATH

set fish_git_dirty_color red
set fish_git_not_dirty_color green

function parse_git_branch
  set -l branch (git branch 2> /dev/null | grep -e '\* ' | sed 's/^..\(.*\)/\1/')
  set -l git_diff (git diff)

  if test -n "$git_diff"
    echo (set_color $fish_git_dirty_color)$branch(set_color normal)
  else
    echo (set_color $fish_git_not_dirty_color)$branch(set_color normal)
  end
end

function fish_prompt
  if git st >/dev/null 2>/dev/null
    printf '%s@%s %s%s%s (%s)> ' (whoami) (hostname|cut -d . -f 1) (set_color $fish_color_cwd) (prompt_pwd) (set_color normal) (parse_git_branch)
  else
    printf '%s@%s %s%s%s> ' (whoami) (hostname|cut -d . -f 1) (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
  end
end
