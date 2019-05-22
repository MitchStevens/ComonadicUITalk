build: comonad_ui.md
	pandoc comonad_ui.md -o comonad_ui.pdf -t beamer

watch: comonad_ui.md
	echo "comonad_ui.md" | entr make  
