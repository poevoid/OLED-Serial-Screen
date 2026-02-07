//Import the AWT (Abstract Window Toolkit)
import java.awt.*;
//Make a AWT robot, which will help us to capture a part of the screen,
//and works on multiple operating systems
Robot robot;
import java.awt.image.*;
//Import the processing serial library (to communicate with the Arduino)
import processing.serial.*;
private static final int screen_width = 128;
private static final int screen_height = 64;
private static final int display_scale = 4;
// Create object from Serial class
Serial myPort;
void settings() {
  noSmooth();
  size(screen_width*display_scale, screen_height*display_scale);
}

void setup() {
  //
  //You can set the framerate to your preference, but too high might be causing troubles with the communication
  frameRate(3);

  // List all available ports
  println("Available serial ports:");
  printArray(Serial.list());

  // Try to find COM5, if not available, use the first port
  String portName = "COM5";
  boolean portFound = false;

  for (String port : Serial.list()) {
    if (port.equals("COM5")) {
      portFound = true;
      break;
    }
  }

  if (!portFound) {
    println("COM5 not found! Using first available port instead.");
    if (Serial.list().length > 0) {
      portName = Serial.list()[0];
    } else {
      println("ERROR: No serial ports found!");
      exit();
      return;
    }
  }

  println("Using port: " + portName);
  myPort = new Serial(this, portName, 200000);

  try {
    robot = new Robot();
  }
  catch (AWTException e) {
    throw new RuntimeException("Unable to Initialize", e);
  }
}

//MouseX
int mX = 0;
//MouseY
int mY = 0;

//Saved x
int sX = -1;
//Saved Y
int sY = -1;
int rX = 0;
int rY = 0;
int aX = 0;
int aY = 0;
int time = 0;

void draw() {
  //If no location is saved
  PImage c;
  Point mouse;
  mouse = MouseInfo.getPointerInfo().getLocation();
  mX = mouse.x;
  mY = mouse.y;
  if (sX == -1) {
    Rectangle bounds = new Rectangle(mX, mY, screen_width, screen_height);
    BufferedImage test = robot.createScreenCapture(bounds);
    c = new PImage(test);
  } else {
    Rectangle bounds = new Rectangle(sX, sY, screen_width, screen_height);
    BufferedImage test = robot.createScreenCapture(bounds);
    c = new PImage(test);
  }
  //Since the OLED is only displaying Black/White, set a threshold filter to mimic this
  c.filter(THRESHOLD);
  scale(4);
  background(c.get(50, 50));
  image(c, 0, 0);

  myPort.write((byte) 'R');
  myPort.write((byte) '.');
  //Brightness of the display
  myPort.write((byte) 255);
  //Send all the pixels in groups of bytes
  // CORRECTED LOGIC: Send data in ROW-MAJOR order.
  // Each byte represents 8 horizontal pixels (bits) in one row.
  for (int y = 0; y < screen_height; y++) {          // For each row (0 to 63)
    for (int x = 0; x < screen_width; x += 8) {      // Move in steps of 8 pixels (16 bytes per row)
      byte b = 0;
      // Pack the next 8 horizontal pixels into one byte
      for (int bit = 0; bit < 8; bit++) {
        int currentX = x + bit;
        // Safety check, though screen_width is divisible by 8
        if (currentX < screen_width) {
          // If pixel is dark, set the corresponding bit.
          // Your test showed: Bit 7 = leftmost pixel (x), Bit 0 = rightmost pixel (x+7)
          if (brightness(c.get(currentX, y)) <= 128) {
            b |= (1 << (7 - bit)); // MSB (bit 7) = first (leftmost) pixel in the group
          }
        }
      }
      myPort.write(b);
    }
  }
  println("Data sent in correct row-major format.");
}
/*
By pressing the UP key on the keyboard you can lock the screen to a specfic position
 //on your monitor, this is great for f.e. figma.com/mirror, where you can scale the window
 //using the inspector tools (in Chrome(ium), Firefox...)
 */

void keyPressed() {
  if (keyCode == DOWN) {
    sX = mX;
    sY = mY;
  }
}
