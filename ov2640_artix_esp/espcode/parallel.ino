#include <WiFi.h>
#include <WebServer.h>
#include <WebSocketsServer.h>

#include "soc/gpio_struct.h"
#include "soc/gpio_reg.h"

const char* ssid = "kewal";
const char* password = "kews2607";

WebServer server(80);
WebSocketsServer webSocket = WebSocketsServer(81);

#define D0 13
#define D1 14
#define D2 15
#define D3 16
#define D4 17
#define D5 18
#define D6 19
#define D7 21

#define PCLK  22
#define VSYNC 23
#define HREF  25

const int FRAME_SIZE = 320 * 240; 
uint8_t* frameBuffer; 
volatile bool frameReady = false;

const char index_html[] PROGMEM = R"rawliteral(
<!DOCTYPE html>
<html>
<body style="background:#222; text-align:center;">
    <h2 style="color:white; font-family:sans-serif;">Arty A7 Parallel Stream (320x240)</h2>
    <canvas id="cam" width="320" height="240" style="width:640px; height:480px; image-rendering:pixelated; border: 2px solid #555;"></canvas>
    <script>
        var canvas = document.getElementById('cam');
        var ctx = canvas.getContext('2d');
        var imgData = ctx.createImageData(320, 240);
        var ws = new WebSocket('ws://' + window.location.hostname + ':81/');
        ws.binaryType = 'arraybuffer';

        ws.onmessage = function(e) {
            var bytes = new Uint8Array(e.data);
            if (bytes.length >= 76600) { // Accept slightly imperfect frames
                for (var i = 0; i < bytes.length; i++) {
                    var val = bytes[i];
                    imgData.data[i*4] = val;    
                    imgData.data[i*4+1] = val;  
                    imgData.data[i*4+2] = val;  
                    imgData.data[i*4+3] = 255;  
                }
                ctx.putImageData(imgData, 0, 0);
            }
        };
    </script>
</body>
</html>
)rawliteral";

TaskHandle_t WiFiTask;

void wifi_task_code(void * pvParameters) {
  for(;;) {
    server.handleClient();
    webSocket.loop();
    if (frameReady) {
      webSocket.broadcastBIN(frameBuffer, FRAME_SIZE);
      frameReady = false; 
    }
    vTaskDelay(2 / portTICK_PERIOD_MS); 
  }
}

void setup() {
  Serial.begin(115200);

  frameBuffer = (uint8_t*)malloc(FRAME_SIZE);
  
  pinMode(D0, INPUT); pinMode(D1, INPUT); pinMode(D2, INPUT); pinMode(D3, INPUT);
  pinMode(D4, INPUT); pinMode(D5, INPUT); pinMode(D6, INPUT); pinMode(D7, INPUT);
  pinMode(PCLK, INPUT); pinMode(VSYNC, INPUT); pinMode(HREF, INPUT);

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) { delay(500); Serial.print("."); }
  Serial.print("\nConnected! Parallel Stream live at: http://");
  Serial.println(WiFi.localIP());

  server.on("/", []() { server.send(200, "text/html", index_html); });
  server.begin();
  webSocket.begin();

  xTaskCreatePinnedToCore(wifi_task_code, "WiFiTask", 10000, NULL, 1, &WiFiTask, 0); 
}

void loop() {
  const uint32_t VSYNC_MASK = (1UL << 23);
  const uint32_t HREF_MASK  = (1UL << 25);
  const uint32_t PCLK_MASK  = (1UL << 22);

  // Wait for new frame
  while(!(REG_READ(GPIO_IN_REG) & VSYNC_MASK));
  while((REG_READ(GPIO_IN_REG) & VSYNC_MASK));

  int idx = 0;
  while (idx < FRAME_SIZE) {
      if (REG_READ(GPIO_IN_REG) & VSYNC_MASK) break; 
      
      // WAIT FOR RISING EDGE OF HREF 
      while(!(REG_READ(GPIO_IN_REG) & HREF_MASK)) {
          if (REG_READ(GPIO_IN_REG) & VSYNC_MASK) break;
      }
      if (REG_READ(GPIO_IN_REG) & VSYNC_MASK) break;
      
      noInterrupts(); 
      
      // Capture the row
      while ((REG_READ(GPIO_IN_REG) & HREF_MASK) && (idx < FRAME_SIZE)) {
          while(!(REG_READ(GPIO_IN_REG) & PCLK_MASK)); 
          
          uint32_t raw_pins = REG_READ(GPIO_IN_REG);
          frameBuffer[idx++] = ((raw_pins >> 13) & 0x7F) | ((raw_pins >> 14) & 0x80);

          while((REG_READ(GPIO_IN_REG) & PCLK_MASK));  
      }
      
      interrupts(); 
  }

  
  if (idx >= FRAME_SIZE - 200) {
      frameReady = true;
      Serial.println("*");
  } else {
      Serial.printf("X (Missed! Got %d / 76800)\n", idx);
  }
}