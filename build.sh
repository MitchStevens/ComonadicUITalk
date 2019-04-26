#!/bin/bash

# sudo apt-get install pandoc pandoc-extras inotify-hookable

# beamer
inotify-hookable -f comonad_ui.md -c "pandoc comonad_ui.md \
    -t beamer \
    -o comonad_ui.pdf"

# revealjs
# inotify-hookable -f comonad_ui.md -c "pandoc \
#     -t revealjs \
#     -s \
#     -o myslides.html comonad_ui.md \
#     -V revealjs-url=https://revealjs.com \
#     -V theme=serif"