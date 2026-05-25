default: test

nvim := "nvim --headless --noplugin -u ./scripts/init.lua"

@test:
    {{ nvim }} -c "lua MiniTest.run()"

@test_file file:
    {{ nvim }} -c "lua MiniTest.run_file('{{ file }}')"

@doc:
    {{ nvim }} -c "lua MiniDoc.generate({'lua/notes/init.lua'}, 'doc/notes.txt')"
