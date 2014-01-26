// -*- java -*-

import processing.video.*;
import processing.serial.*;
import java.awt.Rectangle;

Movie myMovie = new Movie(this, "/home/atw/Downloads/www.rofl.to_nyan-cat.avi");

int numPorts=0;  
int maxPorts=24; 

Serial[] ledSerial = new Serial[maxPorts];     
Rectangle[] ledArea = new Rectangle[maxPorts]; 
boolean[] ledLayout = new boolean[maxPorts];   
PImage[] ledImage = new PImage[maxPorts];      
int errorCount=0;
float framerate=0;

void setup() {
    String[] list = Serial.list();
    delay(20);
    println("Serial Ports List:");
    println(list);
    serialConfigure("/dev/ttyACM0");  
    serialConfigure("/dev/ttyACM1");
    if (errorCount > 0) exit();
    size(480, 400);  
    myMovie.loop();  
}
 

void movieEvent(Movie m) {
  
    m.read();
  
    framerate = 30.0; 
  
    for (int i=0; i < numPorts; i++) {    
    
	int xoffset = percentage(m.width, ledArea[i].x);
	int yoffset = percentage(m.height, ledArea[i].y);
	int xwidth =  percentage(m.width, ledArea[i].width);
	int yheight = percentage(m.height, ledArea[i].height);
	ledImage[i].copy(m, xoffset, yoffset, xwidth, yheight,
			 0, 0, ledImage[i].width, ledImage[i].height);
    
	byte[] ledData =  new byte[(ledImage[i].width * ledImage[i].height * 3) + 3];
	image2data(ledImage[i], ledData, ledLayout[i]);
	if (i == 0) {
	    ledData[0] = '*';  
	    int usec = (int)((1000000.0 / framerate) * 0.75);
	    ledData[1] = (byte)(usec);   
	    ledData[2] = (byte)(usec >> 8); 
	} else {
	    ledData[0] = '%';  
	    ledData[1] = 0;
	    ledData[2] = 0;
	}
    
	ledSerial[i].write(ledData); 
    }
}




void image2data(PImage image, byte[] data, boolean layout) {
    int offset = 3;
    int x, y, xbegin, xend, xinc, mask;
    int linesPerPin = image.height / 8;
    int pixel[] = new int[8];
  
    for (y = 0; y < linesPerPin; y++) {
	if ((y & 1) == (layout ? 0 : 1)) {
      
	    xbegin = 0;
	    xend = image.width;
	    xinc = 1;
	} else {
      
	    xbegin = image.width - 1;
	    xend = -1;
	    xinc = -1;
	}
	for (x = xbegin; x != xend; x += xinc) {
	    for (int i=0; i < 8; i++) {
        
		pixel[i] = image.pixels[x + (y + linesPerPin * i) * image.width];
		pixel[i] = colorWiring(pixel[i]);
	    }
      
	    for (mask = 0x800000; mask != 0; mask >>= 1) {
		byte b = 0;
		for (int i=0; i < 8; i++) {
		    if ((pixel[i] & mask) != 0) b |= (1 << i);
		}
		data[offset++] = b;
	    }
	}
    } 
}



int colorWiring(int c) {
  
    return ((c & 0xFF0000) >> 8) | ((c & 0x00FF00) << 8) | (c & 0x0000FF); 
}


void serialConfigure(String portName) {
    if (numPorts >= maxPorts) {
	println("too many serial ports, please increase maxPorts");
	errorCount++;
	return;
    }
    try {
	ledSerial[numPorts] = new Serial(this, portName);
	if (ledSerial[numPorts] == null) throw new NullPointerException();
	ledSerial[numPorts].write('?');
    } catch (Throwable e) {
    
    
	return;
    }
    delay(50);
    String line = ledSerial[numPorts].readStringUntil(10);
    if (line == null) {
	println("Serial port " + portName + " is not responding.");
	println("Is it really a Teensy 3.0 running VideoDisplay?");
	errorCount++;
	return;
    }
    String param[] = line.split(",");
    if (param.length != 12) {
	println("Error: port " + portName + " did not respond to LED config query");
	errorCount++;
	return;
    }
  
    ledImage[numPorts] = new PImage(Integer.parseInt(param[0]), Integer.parseInt(param[1]), RGB);
    ledArea[numPorts] = new Rectangle(Integer.parseInt(param[5]), Integer.parseInt(param[6]),
				      Integer.parseInt(param[7]), Integer.parseInt(param[8]));
    ledLayout[numPorts] = (Integer.parseInt(param[5]) == 0);
    numPorts++;
}


void draw() {
  
    image(myMovie, 0, 80);
  
  
  
    for (int i=0; i < numPorts; i++) {
    
	int xsize = percentageInverse(ledImage[i].width, ledArea[i].width);
	int ysize = percentageInverse(ledImage[i].height, ledArea[i].height);
    
	int xloc =  percentage(xsize, ledArea[i].x);
	int yloc =  percentage(ysize, ledArea[i].y);
    
	image(ledImage[i], 240 - xsize / 2 + xloc, 10 + yloc);
    } 
}


boolean isPlaying = true;
void mousePressed() {
    if (isPlaying) {
	myMovie.pause();
	isPlaying = false;
    } else {
	myMovie.play();
	isPlaying = true;
    }
}


int percentage(int num, int percent) {
    double mult = percentageFloat(percent);
    double output = num * mult;
    return (int)output;
}


int percentageInverse(int num, int percent) {
    double div = percentageFloat(percent);
    double output = num / div;
    return (int)output;
}




double percentageFloat(int percent) {
    if (percent == 33) return 1.0 / 3.0;
    if (percent == 17) return 1.0 / 6.0;
    if (percent == 14) return 1.0 / 7.0;
    if (percent == 13) return 1.0 / 8.0;
    if (percent == 11) return 1.0 / 9.0;
    if (percent ==  9) return 1.0 / 11.0;
    if (percent ==  8) return 1.0 / 12.0;
    return (double)percent / 100.0;
}
