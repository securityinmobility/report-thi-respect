MAINDOC = report
GIT_VERSION = $(git describe --always --dirty)
.PHONY: all clean
all: $(MAINDOC).pdf

%.pdf: %.md
	pandoc $< \
		--from=markdown+smart \
		--to=pdf \
		--standalone \
		--pdf-engine=xelatex \
		--pdf-engine-opt=-shell-escape \
		--output=$@

clean:
	@rm -f *.pdf
