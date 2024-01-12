# ProcessingMap
## Overview

This project is an interactive mapping and weather application developed in Processing 4. It utilizes functionalities such as map display, real-time weather data fetching, QR code generation, and screenshot capabilities. The application leverages the Unfolding Maps library for map visualization, combined with other libraries for additional features.

### Key Features:
- Interactive map with advanced panning and zooming capabilities.
- Real-time weather data display for a specified location.
- QR code generation for easy sharing of map screenshots.
- Customizable UI elements with ControlP5 library.
- Integration with OpenWeatherMap API for fetching weather data.
- Visualization of bus stop markers using OpenStreetMap data.

## Prerequisites

- **Processing 4**: Ensure you have Processing 4 installed for running this application.
- **Unfolding Maps Library**: A beta version of Unfolding Maps compatible with Processing 4 is needed. This might be found on GitHub.
- **Additional Libraries**: The application uses ControlP5 for GUI elements, `http.requests` for HTTP requests, and `io.nayuki.qrcodegen` for QR code generation.

## Installation

1. **Install Processing 4**: Download and install Processing 4 from the [Processing website](https://processing.org/download/).
2. **Unfolding Maps Library**: Locate and download the beta version of the Unfolding Maps library for Processing 4. The library might be available on GitHub, but the exact link is unknown.
3. **Install Other Libraries**: Install the ControlP5, `http.requests`, and `io.nayuki.qrcodegen` libraries through the library manager in Processing IDE.

## Configuration

Before running the application:

1. **Create a `.env` File**:
    - Navigate to the `data` folder in the project directory.
    - Create a `.env` file.
    - Add your OpenWeatherMap API key in this format: `KEY=YOUR_OPENWEATHERMAP_KEY`.

2. **Set Up Unfolding Maps**:
    - Ensure the beta version of Unfolding Maps for Processing 4 is placed in the `libraries` folder of your Processing sketchbook.

## Usage

- **Running the App**: Open the Processing sketch and execute it. You should see the interactive map with additional features like weather data.
- **Map Interaction**: Utilize mouse controls for map navigation. The interface includes buttons for screenshots and QR code generation.
- **Weather Data Display**: Weather information for Sheffield (default location) is automatically displayed.

## Troubleshooting

- Confirm all libraries are correctly installed.
- Ensure the `.env` file has the proper API key format.
- If the map fails to load, check the installation of the Unfolding Maps library.
