PROCESSING = processing-java

judging: jargon.pde
	$(PROCESSING) --sketch=`pwd` --output=judging --run --force

.PHONY:
run:
	$(PROCESSING) --sketch=`pwd` --output=judging --run --force

clean:
	rm -f *~
