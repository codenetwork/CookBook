pdf:
	pandoc --template=./template/template.html --listings -s ./recipes/*.md -o ./build/index.html --toc --toc-depth 2

clean:
	rm -f ./build/* && touch ./build/.keep

all:
	make clean && make pdf

