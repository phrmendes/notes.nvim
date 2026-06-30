{ pkgs, ... }:

{
  name = "notes";

  packages = with pkgs; [
    ripgrep
    fd
    ltex-ls-plus
  ];

  scripts = {
    test.exec = "${pkgs.neovim}/bin/nvim --headless --noplugin -u ./scripts/init.lua -c 'lua MiniTest.run()'";
    doc.exec = "${pkgs.neovim}/bin/nvim --headless --noplugin -u ./scripts/init.lua -c 'lua MiniDoc.generate({\"lua/notes/init.lua\"}, \"doc/notes.txt\")' -c 'qa!'";
  };
}
