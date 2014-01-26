// -*- java -*-

import processing.video.*;
import processing.serial.*;
import java.nio.file.attribute.FileTime;
import java.nio.file.attribute.BasicFileAttributes;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

Serial vlla_serial;
boolean layout;
PImage vlla_img;
int errorCount = 0;
float framerate = 0;

int WIDTH = 60;
int HEIGHT = 26;

boolean first;

void setup() {
    String[] list = Serial.list();
    delay(20);
    println("Serial Ports List:");
    println(list);
    // serialConfigure("/dev/pts/4");
    if (errorCount > 0) exit();
    size(60, 26);
    first = true;
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
    try {
	vlla_serial = new Serial(this, portName);
	if (vlla_serial == null) throw new NullPointerException();
	vlla_serial.write('?');
    } catch (Throwable e) {
	println ("Failed to write to serial port " + portName);
	System.exit (1);
    }
    delay(50);
    String line = vlla_serial.readStringUntil(10);
    if (line == null) {
	println("Serial port " + portName + " is not responding.");
	println("Is it really a Teensy 3.0 running VideoDisplay?");
	System.exit (1);
    }
    String param[] = line.split(",");
    if (param.length != 12) {
	println("Error: port " + portName + " did not respond to LED config query");
	System.exit (1);
    }

    vlla_img = new PImage(Integer.parseInt(param[0]), Integer.parseInt(param[1]), RGB);
    layout = (Integer.parseInt(param[5]) == 0);
}

void draw() {
    Process p;
    byte[] data;
    int idx, usec;
    FileTime atime, mtime;
    BasicFileAttributes attrs;
    Path path;

    if (first) {
	    vlla_img = loadImage ("feed.png");
	    first = false;
    }

    try {
	path = Paths.get("feed.png");
	attrs = Files.readAttributes (path, BasicFileAttributes.class);
	atime = attrs.lastAccessTime ();
	mtime = attrs.lastModifiedTime ();

	if (mtime.toMillis () >= atime.toMillis ()) {
	    vlla_img = loadImage ("feed.png");

	    p = Runtime.getRuntime().exec ("touch -a feed.png");
	    p.waitFor ();

	}
    } catch (Exception e) {
	return;
    }

    image (vlla_img, 0, 0);

    data = new byte[(vlla_img.width * vlla_img.height * 3) + 3];
    image2data (vlla_img, data, layout);
    data[0] = '*';
    usec = (int) ((1000000.0 / framerate) * 0.75);
    data[1] = (byte) usec;
    data[2] = (byte) (usec >> 8);

    try {
	vlla_serial.write (data);
    } catch (Exception e) {
	return;
    }
}
