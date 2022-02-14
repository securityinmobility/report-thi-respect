MAINDOC = report
GIT_VERSION = $(git describe --always --dirty)
.PHONY: all clean
all: $(MAINDOC).pdf

%.pdf: %.md
	pandoc $< \
		--from=markdown+smart \
		--to=pdf \
		--listings \
		--number-sections \
		--pdf-engine=xelatex \
		--pdf-engine-opt=-shell-escape \
		--output=$@

%.tex: %.md
	pandoc $< \
		--from=markdown+smart \
		--to=latex \
		--standalone \
		--listings \
		--number-sections \
		--pdf-engine=xelatex \
		--pdf-engine-opt=-shell-escape \
		--output=$@

clean:
	@rm -f *.pdf
