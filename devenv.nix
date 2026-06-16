{ pkgs, ... }:

{
  name = "notes";

  packages = with pkgs; [ neovim ];

  tasks = {
    "test:run".exec = ''nvim --headless --noplugin -u ./scripts/init.lua -c "lua MiniTest.run()"'';
    "doc:run".exec =
      ''nvim --headless --noplugin -u ./scripts/init.lua -c "lua MiniDoc.generate({'lua/notes/init.lua'}, 'doc/notes.txt')"'';
  };
}
