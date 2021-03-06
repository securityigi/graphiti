G_CFLAGS := -W -Wall -ansi -Wno-missing-field-initializers -O3 -Wno-deprecated -std=c++11
G_INCLUDES := -I./ -I../ -I../raindance/Lib/glm-0.9.5.4

PYTHON_CFLAGS := `python2.7-config --cflags | sed s/"-mno-fused-madd"//g`
PYTHON_LDFLAGS := `python2.7-config --ldflags`

GLFW_CFLAGS := `pkg-config --cflags glfw3`
GLFW_LDFLAGS := `pkg-config --static --libs glfw3`

BINARY := graphiti
DIST := $(binary)-$(shell date +"%Y%m%d")

UNAME := $(shell uname -s)
ifeq ($(UNAME), Darwin)
	CC=clang++
	CFLAGS=$(G_CFLAGS) $(PYTHON_CFLAGS) $(GLFW_CFLAGS) -stdlib=libc++ -pthread
	INCLUDES=$(G_INCLUDES)
	LDFLAGS=$(G_LDFLAGS) $(PYTHON_LDFLAGS) $(GLFW_LDFLAGS) -framework OpenGL -framework OpenCL
endif
ifeq ($(UNAME), Linux)
	CC=g++
	CFLAGS=$(G_CFLAGS) $(PYTHON_CFLAGS) $(GLFW_CLFAGS)
	INCLUDES=$(G_INCLUDES)
	LDFLAGS=$(G_LDFLAGS) $(PYTHON_LDFLAGS) $(GLFW_LDFLAGS) -lm -lGL -lGLU -lOpenCL -pthread
endif

EMS_CC := $(EMSCRIPTEN)/em++
EMS_CFLAGS := -std=c++11
EMS_INCLUDES := $(G_INCLUDES)

.PHONY: all pack native debug web clean dist

all: native

pack:
	( cd ../raindance && make )
	@echo "--- Packing OpenGraphiti resources ---"
	./pack.sh

native: pack
	@echo "--- Compiling release version for $(UNAME) ---"
	$(CC) $(CFLAGS) $(INCLUDES) Main.cc -o $(BINARY) $(LDFLAGS)

debug: pack
	@echo "--- Compiling debug version for $(UNAME) ---"
	$(CC) $(CFLAGS) -g $(INCLUDES) Main.cc -o $(BINARY) $(LDFLAGS)

web: pack
	@echo "--- Compiling web version with Emscripten ---"
	mkdir -p Web
	$(EMS_CC) --bind $(EMS_CFLAGS) $(EMS_INCLUDES) Main.cc -s FULL_ES2=1 -s TOTAL_MEMORY=268435456 -o Web/$(BINARY).html

webrun: pack web
	@echo "--- Appending launcher script to Web/$(BINARY).html ---"
	echo "<script async src='../Javascript/main.js'></script>" >> Web/$(BINARY).html

clean:
	@echo "--- Cleaning ---"
	( cd ../raindance && make clean )
	rm -rf *~
	rm -rf */*~
	rm -rf *.pyc */*.pyc
	rm -rf Pack.hh
	rm -rf Web/
	rm -rf $(BINARY)
	rm -rf $(BINARY).dSYM

dist: clean native
	@echo "--- Making distributable tarball ---"
	rm -rf $(DIST)
	mkdir $(DIST)
	cp ${NATIVE_OUT} $(DIST)/
	cp -r Scripts $(DIST)/
	rm -rf $(DIST)/Scripts/*.pyc ${DIST}/.DS_Store
	cp LICENSE $(DIST)/

	@echo "--- Copying external libraries ---"
	mkdir $(DIST)/Lib
	cp Lib/pygeoip-0.2.7.tar.gz $(DIST)/Lib
	cp Lib/GeoLiteCity.dat $(DIST)/Lib
	cp Lib/networkx-1.8.1.zip $(DIST)/Lib

	@echo "--- Removing temporary files ---"
	zip -r $(DIST).zip $(DIST)
	rm -rf $(DIST)
