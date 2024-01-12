// ----- Imports -----
// Unfolding Maps Imports
import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.utils.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.providers.*;
import de.fhpotsdam.unfolding.marker.*;
// Processing Related Imports
import processing.data.*;

// Image Processing and Utility Imports
import java.io.File;
import java.util.Arrays;
import java.util.List;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import javax.imageio.ImageIO;
import java.util.Base64;
import java.io.*;
import java.util.*;
// QR Code Generator
import io.nayuki.qrcodegen.QrCode;

// HTTP Requests
import http.requests.*;

// ControlP5 GUI Library
import controlP5.*;


UnfoldingMap map;
Location cityLocation = new Location(53.3811, -1.4701); // Sheffield's coordinates
float maxPanningDistance = 10.0;
int mapZoomLevel = 14, mapMaxZoom = 18, mapMinZoom = 12;

int screenWidth = 800, screenHeight = 600;

ControlP5 cp5;
Button qrButton, screenshotButton;
int buttonWidth = 150, buttonHeight = 40, qrY, qrX, qrButtonY, qrButtonX;
int screenshotButtonX = screenWidth - 170, screenshotButtonY = screenHeight - 55;
int screenshotButtonWidth = 160, screenshotButtonHeight = 35;

boolean displayQR = false;
boolean display;
PImage qrImage;

int defaultFrameRate = 30;
String fontPath = "data/Obvia.ttf";
int fontSize = 15;
boolean devMode = false; // Debug mode

int c1, c2; // for colors on buttons

// Zoom Indicator Variables
int zoomIndicatorX = 25; // X position of the zoom indicator
int zoomIndicatorY = 25; // Starting Y position of the zoom indicator
int zoomIndicatorHeight = 200; // Height of the zoom indicator
int zoomIndicatorWidth = 10; // Width of the zoom indicator

// Weather Variables
String openWeatherAPIKey;
String openWeatherURL = "https://api.openweathermap.org/data/2.5/weather";
PImage weatherIcon;
float tempC;
String currentWeatherCondition;
List<ImageMarker> busMarkers = new ArrayList<>();
PImage busStopIcon;
JSONArray busElements;
float maxSearchArea = 0.08; 
// Due to the nature of Processing,
// the .env needs to be manually targeted.
String getApiKey(String path) {
    Properties prop = new Properties();
    try {
      println(path);
        prop.load(new FileInputStream(path));
    } catch (FileNotFoundException e) {
        println("'.env' file not found in /data folder.");
        e.printStackTrace();
    } catch (IOException e) {
        println("Error reading '.env' file.");
        e.printStackTrace();
    }
    // Return the API key
    String apiKey = prop.getProperty("KEY");
    if (apiKey == null) {
        println("API Key not found in '.env' file.");
    }
    return apiKey;
}

// ----- Functions -----
// Settings and initial setup
void settings() {
  size(screenWidth, screenHeight, P2D);
  smooth(5);
  

}

void setup() {
  frameRate(defaultFrameRate);
  textFont(createFont(fontPath, fontSize)); // Reduced font size for performance
  initialiseMap();
  setupButtons();
  openWeatherAPIKey = getApiKey(dataPath(".env")); 
  fetchWeatherData("Sheffield");
  busElements = getStops("highway", "bus_stop", cityLocation, maxSearchArea);
  // Visualize the bus stops
  visualiseMarkers(busElements, busMarkers, map, "data/imgs/Bus-Marker.png");
}    

// Main drawing loop
void draw() {
  map.draw();
    boolean shouldDisplayMarkers = map.getZoomLevel() > mapZoomLevel;
  // Update visibility for each marker type based on zoom level and stop type
  updateMarkersVisibility(busMarkers, "bus", shouldDisplayMarkers);
  handleQRDisplay();
  drawZoomIndicator();
  drawWeatherIcon();
}

// Handles the display of the QR code
void handleQRDisplay() {
  if (displayQR) {
    displayQRCode();
  } else {
    qrButton.hide();
  }
}


// Initialises the map with error handling
void initialiseMap() {
  try {
    map = new UnfoldingMap(this, new Microsoft.RoadProvider());
    map.zoomAndPanTo(mapZoomLevel, cityLocation);
    MapUtils.createDefaultEventDispatcher(this, map);
    map.setPanningRestriction(cityLocation, maxPanningDistance);
    map.setZoomRange(mapMinZoom, mapMaxZoom);
  } catch (Exception e) {
    println("Error initializing map: " + e.getMessage());
  }
}

// Sets up buttons on the UI
void setupButtons() {
  cp5 = new ControlP5(this);
  ControlFont cf1 = new ControlFont(createFont(sketchPath(fontPath), fontSize));
  createScreenshotButton(cf1);
  createQRConfirmationButton(cf1);
}

void createScreenshotButton(ControlFont cf1) {
  screenshotButton = createButton("Screenshot", screenshotButtonX, screenshotButtonY, 150, 39, color(255, 0, 0), cf1);
  screenshotButton.addCallback(new CallbackListener() {
    public void controlEvent(CallbackEvent event) { 
      if (event.getAction() == ControlP5.ACTION_RELEASE) {
        saveCurrentView();
        displayQR = true;
        screenshotButton.hide();
      }
    }
  });
}

void createQRConfirmationButton(ControlFont cf1) {
  qrButton = createButton("Confirm", 100, 100, 150, 39, color(255, 0, 0), cf1);
  qrButton.addCallback(new CallbackListener(){
    public void controlEvent(CallbackEvent event) { 
      if (event.getAction() == ControlP5.ACTION_RELEASE) {
        displayQR = false;
        screenshotButton.show();
      }
    }
  });
}

void displayQRCode() {
  fill(0, 0, 0, 120); // Semi-transparent black overlay
  rect(0, 0, width, height);
  image(qrImage, qrX, qrY);
  qrButton.show();
}

void saveCurrentView() {
  String timestamp = year() + nf(month(), 2) + nf(day(), 2) + "_" + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2);
  PImage currentView = get(); // This gets the current view of the canvas.
  String directLink;
  // To avoid server clog during development this logic is set in place
  // instead of a server upload, you're directed to a video of cats
  if (devMode){
    directLink = "https://www.youtube.com/watch?v=dQw4w9WgXcQ";
  }else{directLink = uploadImageToServer(currentView);}
  
  if (directLink != null) {
    qrImage = generateQRCode(directLink);
    // Error handling incase qr generation fails.
    try {
      // Recalculate the positions
      qrX = (width - qrImage.width) / 2;
      qrY = (height - qrImage.height) / 2 - 80;
      qrButtonX = (int)(width - buttonWidth) / 2;
      qrButtonY = qrY + qrImage.height + 20;
      qrButton.setPosition(qrButtonX,qrButtonY);
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

}

// This function uses qrcodegen to translate text to a qr
// then after creating a new PImage of the correct size
// it colours in the pixels of the image according to whether
// they should be black or white
PImage generateQRCode(String text) {
  QrCode qr = QrCode.encodeText(text, QrCode.Ecc.MEDIUM);
  int border = 4;
  int scale = 5;
  int imgSize = (qr.size + 2 * border) * scale;
  PImage result = createImage(imgSize, imgSize, RGB);

  for (int y = 0; y < imgSize; y++) {
    int scaledY = y / scale - border;
    for (int x = 0; x < imgSize; x++) {
      int scaledX = x / scale - border;
      boolean isBlack = qr.getModule(scaledX, scaledY);
      result.set(x, y, isBlack ? color(0) : color(255));
    }
  }
  return result;
}


// uploadImageToServer allows the program to post the screenshots to a server where they
// can easily be downloaded for offline viewing via a qr code.
String uploadImageToServer(PImage img) {
  img.loadPixels();

  // Convert PImage to BufferedImage
  BufferedImage bufferedImage = new BufferedImage(img.width, img.height, BufferedImage.TYPE_INT_ARGB);
  bufferedImage.setRGB(0, 0, img.width, img.height, img.pixels, 0, img.width);

  // Convert BufferedImage to byte array
  ByteArrayOutputStream baos = new ByteArrayOutputStream();
  try {
    ImageIO.write(bufferedImage, "PNG", baos);
  } catch (IOException e) {
    e.printStackTrace();
    return "Error converting image to byte array";
  }

  byte[] imageInByte = baos.toByteArray();
  String encodedImage = Base64.getEncoder().encodeToString(imageInByte);

  PostRequest post = new PostRequest("http://molefilms.co.uk/uploadImage.php");
  post.addData("image", encodedImage);
  post.send();
  return "Reponse Content: " + post.getContent();
}

// Creates a button using the current ControlP5 methods
Button createButton(String theName, int theX, int theY, int theWidth, int theHeight, int theColor, ControlFont theFont) {
    Button b = cp5.addButton(theName)
                  .setPosition(theX, theY)
                  .setSize(theWidth, theHeight)
                  .setColorActive(theColor) // Color for mouse-over
                  .setColorBackground(color(90, 0, 255)) // Default color
                  .setFont(theFont);

    return b;
}


void hideButton(Button b) {
  if (!display) {
    b.hide();
  } else {
    b.show();
  }
}

void drawZoomIndicator() {
  // Draw the zoom bar
  stroke(0); // Black color
  strokeWeight(2);
  line(zoomIndicatorX, zoomIndicatorY, zoomIndicatorX, zoomIndicatorY + zoomIndicatorHeight);

  // Calculate the current zoom indicator position
  float currentZoomLevel = map.getZoomLevel();
  float zoomLevelRange = mapMaxZoom - mapMinZoom;
  float currentZoomPosition = map(currentZoomLevel, mapMinZoom, mapMaxZoom, zoomIndicatorY + zoomIndicatorHeight, zoomIndicatorY);
  
  
  // Draw the movable indicator
  strokeWeight(2);
  fill(0, 0, 0);
  line(zoomIndicatorX - zoomIndicatorWidth, currentZoomPosition, zoomIndicatorX + zoomIndicatorWidth, currentZoomPosition);
}

void fetchWeatherData(String city) {
  
    JSONObject response;

    String url = openWeatherURL + "?lat="+ cityLocation.getLat()+"&lon="+cityLocation.getLon() + "&units=metric&appid=" + openWeatherAPIKey; // added "&units=metric" to get Celsius
    println(url);
    try{
    GetRequest get = new GetRequest(url);
    get.send();
      response = parseJSONObject(get.getContent()); 

  if (response != null) {
      JSONObject main = response.getJSONObject("main");
      tempC = main.getFloat("temp"); // Temperature in Celsius
      JSONArray weatherArray = response.getJSONArray("weather");
      if (weatherArray.size() > 0) {
        JSONObject weather = weatherArray.getJSONObject(0);
        currentWeatherCondition = weather.getString("main"); // e.g., Rain, Clouds
        
        // Depending on the condition, change the icon
        switch (currentWeatherCondition.toLowerCase()) {
          case "clear":
            weatherIcon = loadImage("data/imgs/Default.png");
            break;
          case "cloud":
            weatherIcon = loadImage("data/imgs/Cloudy.png");
            break;
          case "rain":
            weatherIcon = loadImage("data/imgs/Rainy.png");
            break;
          case "snow":
            weatherIcon = loadImage("data/imgs/Snowy.png");
            break;
          case "wind":
            weatherIcon = loadImage("data/imgs/Windy.png");
            break;
          default:
            weatherIcon = loadImage("data/imgs/Default.png");
            break;
        }
        println("Current temperature: " + tempC + " C, Weather: " + currentWeatherCondition);
      }
    } else {
      println("Failed to fetch weather data.");
    }
   }
   catch(Exception e) {
        println("Error fetching weather data: " + e.getMessage());
        // Handle the error gracefully here
        // For example, you could set a flag to indicate that the weather data is unavailable
        // and then check this flag before trying to display weather data in your application.
    }
}
void drawWeatherIcon(){
 if (weatherIcon != null) {
    // Draw the weather icon in the top right corner
    image(weatherIcon, screenWidth - weatherIcon.width - 10, 10);
  }
}


// Function to retrieve stops data from Overpass API using a given type and value.
// The search area is determined by the location and a maximum distance (in degrees).
JSONArray getStops(String key, String value, Location location, float maxDistance) {
  String overpassUrl = "https://overpass-api.de/api/interpreter";
  
  // Calculate the bounding box based on the location and max distance
  float minLat = location.getLat() - maxDistance;
  float minLon = location.getLon() - maxDistance;
  float maxLat = location.getLat() + maxDistance;
  float maxLon = location.getLon() + maxDistance;

  // Build the query using the bounding box
  String query = 
    "[out:json][timeout:25];" +
    "(" +
    "node[\"" + key + "\"=\"" + value + "\"](" +
    minLat + "," + minLon + "," + maxLat + "," + maxLon +
    ");" +
    ");" +
    "out body;" +
    ">;" +
    "out skel qt;";

  // Use the PostRequest class from the http.requests library
  PostRequest post = new PostRequest(overpassUrl);
  post.addData("data", query);
  post.send();

  // Parse the response as JSON and return the elements array
  JSONObject response = parseJSONObject(post.getContent());
  return response.getJSONArray("elements");
}

// ImageMarker class taken from the examples section of the
// Unfolding library. Modified for our needs
public class ImageMarker extends AbstractMarker {

  PImage img;

  public ImageMarker(Location location, PImage img) {
    super(location);
    this.img = img;
  }
 
  public void draw(PGraphics pg, float x, float y) {
    // Add if statement logic added to remove markers from view
    if(!this.isHidden()){
      pg.pushStyle();
      pg.imageMode(PConstants.CORNER);
      // The image is drawn in object coordinates, i.e. the marker's origin (0,0) is at its geo-location.
      pg.image(img, x - 11, y - 37);
      pg.popStyle();
    }
  }

  protected boolean isInside(float checkX, float checkY, float x, float y) {
    return checkX > x && checkX < x + img.width && checkY > y && checkY < y + img.height;
  }

}
void visualiseMarkers(JSONArray elements, List<ImageMarker> markers, UnfoldingMap map, String iconPath) {
  if (elements != null) {
    for (int i = 0; i < elements.size(); i++) {
      JSONObject element = elements.getJSONObject(i);
      float lat = element.getFloat("lat");
      float lon = element.getFloat("lon");
      Location stopPosLL = new Location(lat, lon);
      ImageMarker stop = new ImageMarker(stopPosLL, loadImage(iconPath));
      markers.add(stop);
      map.addMarker(stop);
    }
  }
  markers.forEach((marker) ->marker.setHidden(true));
}
void updateMarkersVisibility(List<ImageMarker> markers, String stopType, boolean shouldDisplayMarkers) {
  // The logic for this for loop essentially states, when the program is allowed to display markers, and the stop type
  // is correct for the type we're checking, display the marker for the stop
  markers.forEach((marker) -> marker.setHidden(!(shouldDisplayMarkers)));
}
