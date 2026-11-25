{ pkgs, ... }:

{
  languages.lua = {
    enable = true;
    package = pkgs.luajit;
    lsp.package = pkgs.lua-language-server;
  };

  packages = with pkgs; [
    commitizen
    git
    neovim
    nushell
    nufmt
    nu-lint
    stylua
    ripgrep
    fd
    ltex-ls-plus
    marksman
  ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.glibcLocales ];

  env = {
    MINI_NVIM = "${pkgs.vimPlugins.mini-nvim}";
  } // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
    LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
  };

  enterTest = "nu scripts/test.nu";

  git-hooks.hooks = {
    stylua.enable = true;
    nufmt.enable = true;
    nu-lint.enable = true;
    luacheck = {
      enable = true;
      name = "luacheck";
      entry = "${pkgs.luaPackages.luacheck}/bin/luacheck";
      files = "\\.lua$";
      language = "system";
    };
    commitizen = {
      enable = true;
      name = "commitizen";
      entry = "${pkgs.commitizen}/bin/cz check --commit-msg-file";
      language = "system";
      stages = [ "commit-msg" ];
    };
    docs = {
      enable = true;
      name = "docs";
      entry = "${pkgs.coreutils}/bin/env MINI_NVIM=${pkgs.vimPlugins.mini-nvim}  ${pkgs.neovim}/bin/nvim --headless --noplugin -u ./scripts/init.lua -c 'lua MiniDoc.generate(nil, \"doc/notes.txt\")' -c 'qa!'";
      files = "^lua/";
      pass_filenames = false;
      language = "system";
    };
  };
}
