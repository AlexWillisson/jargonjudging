PROCESSING = processing-java
CFLAGS = -g -Wall
LIBS = `pkg-config --libs x11 xtst` -lcap

judging: jargon.pde
	$(PROCESSING) --sketch=`pwd` --output=judging --run --force

btns: btns.o
	$(CC) $(CFLAGS) -o btns btns.o $(LIBS)

caps:
	setcap cap_dac_override+ep btns
	chmod 550 btns

.PHONY:
run:
	$(PROCESSING) --sketch=`pwd` --output=judging --run --force

clean:
	rm -f *~
