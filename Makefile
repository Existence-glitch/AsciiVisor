visor:
	mkdir -p bin
	ghc Visor.hs -o bin/visor

visor4threads:
	mkdir -p bin
	ghc -j4 -threaded Visor.hs -o bin/visor4threads

visor24threads:
	mkdir -p bin
	ghc -j24 -threaded Visor.hs -o bin/visor24threads
