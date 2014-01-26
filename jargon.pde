// -*- java -*-

import processing.video.*;
import processing.serial.*;
import java.awt.Rectangle;

int numPorts = 0;
int maxPorts = 24;

Serial[] vlla_serial = new Serial[maxPorts];
Rectangle[] area = new Rectangle[maxPorts];
boolean[] layout = new boolean[maxPorts];
PImage[] vlla_img = new PImage[maxPorts];
int errorCount = 0;
float framerate = 0;

void setup() {
    String[] list = Serial.list();
    delay(20);
    println("Serial Ports List:");
    println(list);
    // serialConfigure("/dev/ttyACM0");
    // serialConfigure("/dev/ttyACM1");
    serialConfigure("/dev/ttyp1");
    if (errorCount > 0) exit();
    size(60, 26);
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
	vlla_serial[numPorts] = new Serial(this, portName);
	if (vlla_serial[numPorts] == null) throw new NullPointerException();
	vlla_serial[numPorts].write('?');
    } catch (Throwable e) {


	return;
    }
    delay(50);
    String line = vlla_serial[numPorts].readStringUntil(10);
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

    vlla_img[numPorts] = new PImage(Integer.parseInt(param[0]), Integer.parseInt(param[1]), RGB);
    area[numPorts] = new Rectangle(Integer.parseInt(param[5]), Integer.parseInt(param[6]),
				      Integer.parseInt(param[7]), Integer.parseInt(param[8]));
    layout[numPorts] = (Integer.parseInt(param[5]) == 0);
    numPorts++;
}

void draw() {
    PImage img;
    byte[] data;
    int idx, usec;

    idx = 0;

    img = loadImage ("feed.png");
    data = new byte[(img.width * img.height * 3) + 3];
    image2data (img, data, layout[idx]);
    image (img, 0, 0);

    if (idx == 0) {
	data[0] = '*';
	usec = (int) ((1000000.0 / framerate) * 0.75);
	data[1] = (byte) usec;
	data[2] = (byte) (usec >> 8);
    } else {
	data[0] = '%';
	data[1] = 0;
	data[2] = 0;
    }

    for (idx = 0; idx < numPorts; idx++) {
	try {
	    vlla_serial[idx].write (data);
	} catch (Exception e) {
	    System.exit (1);
	}
    }
}
