JC = processing-java

judging: jargon.pde
	$(JC) --sketch=`pwd` --output=judging --run --force
