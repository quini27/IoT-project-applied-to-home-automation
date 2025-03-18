
//Programa para controlar la luz de la casa de Buenos Aires
//Reporta el estado de la luz, y el sensor DHT22 la temperatura y humedad.
//Puede cambiar el estado de la luz
//La comunicación es através del broker MQTT broker.hivemq.com
// Program to test a MQTT broker as controller and server of an IoT project,
//where an IoT board and a Delphi based application exchange information using
//a MQTT communication protocol.
//Copyright: Fernando Pazos
//September 2024

#include <ESP8266WiFi.h>   // Importa a Biblioteca ESP8266WiFi
#include <PubSubClient.h> // Importa a Biblioteca PubSubClient
#include <DHT.h>          // Importa a bilbioteca DHT


//WIFI
const char* SSID = "Helena 2.4Ghz";   //"Helena-2G";    //variable que almacena el nombre de la red wifi a la que el nodemcu se va a conectar
const char* password = "cenoura04";     //"DaniyFercenoura04";  //variable que almacena la seña de la red wifi donde el nodemcu se va a conectar

// MQTT
const char* BROKER_MQTT = "broker.hivemq.com";  //"iot.eclipse.com"; //"mqtt.fluux.io"; //"test.mosca.io"; //"broker.mqttdashboard.com"; //"test.mosquitto.org"; //"ioticos.org"; //URL do broker MQTT que se deseja utilizar
const char* broker_username = NULL;
const char* broker_password = NULL;                  //username and password when credentials are requiredint BROKER_PORT = 1883; // Port of the Broker MQTT
#define ID_MQTT  "MQTTtest1965"     //id mqtt (session identification)
int BROKER_PORT = 1883;             // Port of the Broker MQTT

//GPIO of the LightSensor and the relay and the DHT11
#define LIGHT_SENSOR 12  //D6
#define RELAY 14          //D5
#define DHTPIN 13         //D7  Pin donde está conectado el DHT11
#define DHTTYPE DHT22    // Tipo de sensor DHT11

DHT dht(DHTPIN, DHTTYPE);    //define DHT parameters
 
//Variáveis e objetos globais
WiFiClient ESPcliente;         // Cria o objeto cliente
PubSubClient MQTT(ESPcliente); // Instancia o Cliente MQTT passando o objeto cliente

String request;   //subscriber request
const unsigned long postingLSInterval = 10 * 1000L;      //period to send the Light Status
unsigned long lastUpdateTime = 0;

//prototypes
//Function called every time when an information is received
void mqtt_callback(char* topic, byte* payload, unsigned int length);
//function to reconnect the board to the broker when connection is lost
void reconnectMQTT() ;

// put your setup code here, to run once:
void setup() {
  //states the input and output pins
  pinMode(RELAY, OUTPUT);
  pinMode(LIGHT_SENSOR,INPUT);
  //pinMode(DHTPIN,INPUT_PULLUP);    //this sentence seems to be not necessary
  digitalWrite(RELAY,HIGH);

  //inicializate DHT sensor
  dht.begin();
  
  //inicializate serial communication
  Serial.begin(115200);
  delay(50);

  //manda al monitor serie el nombre de la red a la cual se conectará
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(SSID);
  // Connect to the WiFi net
  WiFi.begin(SSID, password);

  // Waits for the WiFi connection
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("WiFi connected"); 
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP()); // Prints the local IP of the local net where the board is connected

   // print the received signal strength:
  long rssi = WiFi.RSSI();
  Serial.print("signal strength (RSSI):");
  Serial.print(rssi);
  Serial.println(" dBm");

  //inicializate the MQTT borker  parameters
  //broker address, port and states the callback function (function called wtih an incoming message from the broker)
  MQTT.setServer(BROKER_MQTT, BROKER_PORT);   //informa qual broker e porta deve ser conectado
  MQTT.setCallback(mqtt_callback);            //atribui função de callback (função chamada quando qualquer informação de um dos tópicos subescritos chega)
}




//Function: callback 
//        This function is called every time the information from one of the subscribed topics is arriving
//Parameters: none
//Returns: none
void mqtt_callback(char* topic, byte* payload, unsigned int length) 
{
    Serial.print("Message arrived [");
    Serial.print(topic);
    Serial.print("]: ");
    request="";
    //obtem a string do payload recebido
    for(int i = 0; i < length; i++) 
    {
       char c = (char)payload[i];
       request += c;
    }
    Serial.println(request);
}

//Function: reconnectMQTT
//  Reconnect the board with the MQTT broker, if it is not connected yet or if connection fails
//  Subscribes to the topic CasaBuenosAires/MessFromClient
//Parameters: none
//Returns: none
void reconnectMQTT() 
{
    while (!MQTT.connected()) 
    {
        Serial.print(" Trying to connect to the broker MQTT: ");
        Serial.println(BROKER_MQTT);
        if (MQTT.connect(ID_MQTT,broker_username,broker_password,"CasaBuenosAires/MessFromEndDevice",0,false,"IoT board connection lost")) 
        {
            Serial.println("Succesfully connected to broker MQTT!");
            MQTT.publish("CasaBuenosAires/MessFromEndDevice","IoT board connected to broker");
            MQTT.subscribe("CasaBuenosAires/MessFromClient"); 
        } 
        else
        {
            Serial.print("Connection lost ");
            Serial.println(MQTT.state());
            Serial.println("Traying again in 2s");
            delay(2000);
        }
    }
}

void loop() {
  // put your main code here, to run repeatedly:
    if (!MQTT.connected()) 
        reconnectMQTT();       //if there is no connection with the broker, it is redone

    // request discrimination
    if (request.indexOf("/ReportTemp") != -1){                //report temperature
        float temperature = dht.readTemperature();
        if (!isnan(temperature)){
          String tempStr = String(temperature);
          char tempChar[tempStr.length()+1];
          tempStr.toCharArray(tempChar,tempStr.length()+1);     //converts the string into an array of char
          MQTT.publish("CasaBuenosAires/MessFromEndDevice/Temperature",tempChar);
          Serial.println("temperature: "+tempStr+" C");}
        else{
          MQTT.publish("CasaBuenosAires/MessFromEndDevice/Temperature","fail to read from DHT sensor");
          Serial.println("temperature: fail to read from DHT sensor");}
        request="";
    }
    if (request.indexOf("/ReportHum") != -1){                 //report humidity
        float humidity = dht.readHumidity();
        if (!isnan(humidity)){
           String humStr = String(humidity);
           char humChar[humStr.length()+1];
           humStr.toCharArray(humChar,humStr.length()+1);
           MQTT.publish("CasaBuenosAires/MessFromEndDevice/Humidity",humChar);
           Serial.println("humidity: "+humStr+" %");}
        else{
          MQTT.publish("CasaBuenosAires/MessFromEndDevice/Humidity","fail to read from DHT sensor");
          Serial.println("humidity: fail to read from DHT sensor");}
        request="";
    }
    if (request.indexOf("/ReportLightStatus") != -1){         //report Light status
        int estadoLuz = digitalRead(LIGHT_SENSOR);
        if (estadoLuz==LOW) {
            MQTT.publish("CasaBuenosAires/MessFromEndDevice/LightState", "light is on");
            Serial.println("light is on");}             //e informa ao subscriber
        else {     
            MQTT.publish("CasaBuenosAires/MessFromEndDevice/LightState", "light is off");
            Serial.println("light is off");}            //e informa ao subscriber
        request="";
    }
    if (request.indexOf("/ToggleLight") != -1){               //toogle light status
        bool estadoRelay = digitalRead(RELAY);
        digitalWrite(RELAY,!estadoRelay);
        request="/ReportLightStatus";
        delay(700);                           //delay necessary for the light to toggle status and the light sensor can detect the change
    }
    if (request.indexOf("client connected") != -1){
        MQTT.publish("CasaBuenosAires/MessFromEndDevice","welcome client");
        Serial.println("Client connected");
        request="";
    }

    //periodically sends the LightStatus
    if ((millis()-lastUpdateTime > postingLSInterval) || (millis()<lastUpdateTime)){
      lastUpdateTime = millis();
      //if (lastUpdateTime > 4320E6) {lastUpdateTime=0;}    //millis goes to zero after 50 days
      request = "/ReportLightStatus";
    }
    
    //keep-alive communication with broker MQTT
    MQTT.loop();
}
