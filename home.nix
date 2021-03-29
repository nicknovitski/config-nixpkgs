{ config, pkgs, lib, ... }:

{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "nick";
  home.homeDirectory = "/Users/nick";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "20.09";

  nixpkgs.config = import ./config.nix;

  home.packages = with pkgs;
    [ fd gitAndTools.gh gnugrep jq hledger hledger-web ripgrep youtube-dl taskwarrior tasksh vscode ]
    ++ [ fira-code inconsolata ]
    ++ [ macvim ];

  home.activation = {
    copyApplications =
      let
        apps = pkgs.buildEnv {
          name = "home-manager-applications";
          paths = config.home.packages;
          pathsToLink = "/Applications";
        };
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        baseDir="$HOME/Applications/Home Manager Apps"
        if [ -d "$baseDir" ]; then
          rm -rf "$baseDir"
        fi
        mkdir -p "$baseDir"
        for appFile in ${apps}/Applications/*; do
          target="$baseDir/$(basename "$appFile")"
          $DRY_RUN_CMD cp ''${VERBOSE_ARG:+-v} -fHRL "$appFile" "$baseDir"
          $DRY_RUN_CMD chmod ''${VERBOSE_ARG:+-v} -R +w "$target"
        done
      '';
    copyFonts =
      let
        fonts = pkgs.buildEnv {
          name = "home-manager-fonts";
          paths = config.home.packages;
          pathsToLink = "/share/fonts/truetype";
        };
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        baseDir="$HOME/Library/Fonts/Home Manager Fonts"
        if [ -d "$baseDir" ]; then
          rm -rf "$baseDir"
        fi
        mkdir -p "$baseDir"
        $DRY_RUN_CMD cp ''${VERBOSE_ARG:+-v} -f ${fonts}/share/fonts/truetype{/,/**/}*.ttf "$baseDir"
      '';
  };

  home.sessionVariables = {
    EDITOR = "vim";
    VISUAL = "mvim -f";
    GIT_EDITOR = "mvim -f --nomru -c 'au VimLeave * !open -a Alacritty'";
  };

  programs.alacritty = {
    enable = true;
    # To see default options:
    # less $(nix-build '<nixpkgs>' -A alacritty.src)/alacritty.yml
    settings = {
      font = {
        normal.family = "Fira Code";
        bold.family = "Fira Code";

        italic.family = "Inconsolata";
        bold_italic.family = "Inconsolata";

        size = 20.0;
      };
      shell = {
        program = "${pkgs.tmux}/bin/tmux";
        args = [ "new-session" "-A" "-s" "alacritty" ];
      };
      window.startup_mode = "Maximized";
    };
  };

  programs.taskwarrior = {
    enable = true;
    colorTheme = "solarized-dark-256";
    config = {
      taskd = {
        server = "freecinc.com:53589";
        key = "~/.local/share/task/freecinc.key.pem";
        certificate = "~/.local/share/task/freecinc.cert.pem";
        ca = "~/.local/share/task/freecinc.ca.pem";
        # NOTE: the results of this are world-readable, but so was my task
        # config file before using home-manager, so...
        credentials =
          let
            envCreds = builtins.getEnv "FREECINC_CREDENTIALS";
          in
          assert envCreds != ""; envCreds;
      };
    };
  };

  programs.tmux = {
    enable = true;

    baseIndex = 1;
    historyLimit = 999999999;
    keyMode = "vi";
    secureSocket = false; # don't think this works on darwin
    shortcut = "a";

    extraConfig = ''
      set-option -g mouse on

      set-option -g status-interval 1
      set-option -g status-right '+0%Y-%m-%dT%H:%M:%S'

      # vimish controls
      bind-key p paste-buffer

      bind-key Escape copy-mode
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel pbcopy
      unbind -T copy-mode-vi MouseDragEnd1Pane

      # open new windows and panes with vim keys, and in the same path
      bind c new-window -c "#{pane_current_path}"
      bind-key s split-window -c "#{pane_current_path}"
      bind-key v split-window -h -c "#{pane_current_path}"
    '';
  };

  # create vimrc, mvimrc, and package in ~/.vim
  #home.files
  #with pkgs.vimPlugins;

  #programs.vim = {
  #  enable = true;
  #  extraConfig = ''
  #    let g:elm_format_autosave = 1

  #    syntax on
  #    if has('gui_running')
  #        set background=light
  #    else
  #        set background=dark
  #    endif
  #    colorscheme solarized
  #
  #    let mapleader = " "
  #    nnoremap <unique> <Leader>w :w<Enter>
  #    nnoremap <unique> <Leader>q :q<Enter>
  #    nnoremap <unique> <Leader>e :e<Enter>
  #    nnoremap <unique> <Leader>n :cn<Enter>
  #    nnoremap <unique> <Leader>N :N<Enter>
  # here we should use the location of the rg package
  #    set grepprg=rg\ --vimgrep\ --no-heading
  #    set grepformat=%f:%l:%c:%m,%f:%l:%m
  #    set guioptions=M
  #    set mouse=a
  #    tnoremap <Esc> <C-W>N
  #    tnoremap <Leader>q <C-W><C-C>
  #    nnoremap Y y$
  #    
  #    set clipboard=unnamed
  #    
  #    set directory=~/.local/share/vim/swap
  #    set backupdir=~/.local/share/vim/backup
  #    set undodir=~/.local/share/vim/undo
  #    set undofile
  #    
  #    set colorcolumn=89
  #    
  #    set ts=2 sts=2 sw=2 expandtab
  #  '';
  #};

  programs.direnv = {
    enable = true;
    config = {
      whitelist.prefix = ["/Users/nick/Source/universe" "/Users/nick/Source/expo"];
    };
  };

  xdg = {
    enable = true;
    configFile = {
      "youtube-dl/config".text = ''
        --format best[ext=mp4]/best
        -o "~/Movies/%(uploader)s - %(title)s.%(ext)s"
      '';
      "newsboat/urls".text = ''
        http://blog.erlang.org/feed.xml
        http://blog.kubernetes.io/feeds/posts/default
        http://joeduffyblog.com/feed.xml
        http://willgallego.com/feed/
        https://blog.janestreet.com/feed.xml
        https://blog.plover.com/index.atom
        https://circleci.com/blog/feed.xml
        https://feeds.akkartik.name/kartiks-scrapbook
        https://feeds.feedburner.com/GDBcode
        https://n-gate.com/index.atom
        https://newsboat.org/news.atom
        https://nixos.org/blogs.xml
        https://nixos.org/news-rss.xml
        https://rachelbythebay.com/w/atom.xml "~Rachel By the Bay"
        https://www.nginx.com/feed/
        https://www.recurse.com/blog.rss
        https://www.tedinski.com/feed.xml
        https://www.tnhh.net/feed.xml
        https://www.tweag.io/rss.xml
        https://www.youtube.com/feeds/videos.xml?channel_id=UCZ2bu0qutTOM0tHYa_jkIwg
        https://zwischenzugs.com/feed/
      '';
      "newsboat/config".text = ''
        browser open
        datetime-format "+0%F"
        refresh-on-startup yes
        show-read-articles no
        show-read-feeds no
        text-width 120
      '';
    };
  };

  programs.zsh = {
    enable = true;
    history = {
      expireDuplicatesFirst = true;
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
      path = "${config.xdg.dataHome}/zsh/zsh_history";
      size = 10000000;
      save = 10000000;
      share = true;
    };
    profileExtra = ''
      export CLICOLOR=1
    '';
    initExtra = ''
      export PROMPT='%D{%H:%M:%S} %2~ %(?.%F{green}.%F{red})%#%f '

      export PATH="''${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
      export PATH="$HOME/.cargo/bin:$PATH"

      msr() {
        log="$HOME/.local/share/msr/log"
        case "$#" in
          0)
            $EDITOR $log
            ;;
          1)
            grep "$1" $log | tail -n 10
            ;;
          *)
            echo "$(date '+%Y-%m-%d') $@" >> "$log"
            ;;
        esac
      }

      roll () {
        sides=''${1:-6}
        echo $((1 + RANDOM % $sides))
      }

      g() {
        if [ $# -eq 0 ]; then
          git status
        else
          git "$@"
        fi
      }
      compdef g='git'

      bindkey "^[[1;3C" forward-word
      bindkey "^[[1;3D" backward-word
      bindkey '^[^?' backward-kill-word
      autoload -U select-word-style
      select-word-style bash

      bindkey '^R'    history-incremental-search-backward
      setopt BANG_HIST                 # Treat the '!' character specially during expansion.
      setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
      setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
      setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
      setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
      setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
      setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
      setopt HIST_BEEP                 # Beep when accessing nonexistent history.

      # The next line updates PATH for the Google Cloud SDK.
      if [ -f '/Users/nick/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/nick/google-cloud-sdk/path.zsh.inc'; fi

      # The next line enables shell command completion for gcloud.
      if [ -f '/Users/nick/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/nick/google-cloud-sdk/completion.zsh.inc'; fi

      export NIX_PATH=$HOME/.nix-defexpr/channels''${NIX_PATH:+:}$NIX_PATH
      export VOLTA_HOME="/Users/nick/.volta"
      grep --silent "$VOLTA_HOME/bin" <<< $PATH || export PATH="$VOLTA_HOME/bin:$PATH"
      if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then . ~/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
    '';
  };

  programs.git = {
    enable = true;
    aliases = {
      force-push = "push --force-with-lease";
      ap = "add --patch";
      co = "checkout";
      ci = "commit";
      cia = "commit --amend";
      br = "branch";
      undo = "revert --no-commit";
      d = "diff --color-words";
      dc = "diff --cached --color-words";
      f = "fetch --prune";
      # fzf!
      #bs = "!git branch | fzf | xargs git checkout";
      rb = "rebase";
      rbc = "rebase --continue";
      rba = "rebase --abort";
      rbi = "rebase --interactive";
      out = "!cd $(git rev-parse --show-toplevel)/..";
      rs = "restore --staged";
    };
    ignores = [ "*~" "*.swp" ];
    userName = "Nick Novitski";
    userEmail = "github@nicknovitski.com";
    extraConfig = {
      status = { submoduleSummary = true; };
      pull = { rebase = true; };
      merge = {
        conflictstyle = "diff3";
        renameLimit = 999999;
      };
      commit = { verbose = true; };
      credential = { helper = "osxkeychain"; };
      color = { ui = "auto"; };
      fetch = { pruneTags = true; };
      diff = { renameLimit = 999999; };
    };
  };
}
