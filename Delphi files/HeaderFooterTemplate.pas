(*****************************************************************************)
{    Project BsAs IoT project
    Android Application to control an IoT board which measures temperature and humidity as well as
    controls a light state in a house in Buenos Aires, Argentina.
    The IoT board is a Wemos D1 R2 and the software connect it with the borker "broker.hivemq.com"
    Other broker options include
    "test.mosquitto.org"; //"broker.hivemq.com";  //"iot.eclipse.com";
    //"mqtt.fluux.io"; //"test.mosca.io"; //"broker.mqttdashboard.com"; //"broker.emqx.io";,
    and the port is the open MQTT port 1883
    To test this application the sketch SetupLuz.ino must be previously stored on the IoT board.
    The topics on which the IoT board publishes are
    CasaBuenosAires/MessFromEndDevice
    CasaBuenosAires/MessFromEndDevice/LightState
    CasaBuenosAires/MessFromEndDevice/Temperature
    CasaBuenosAires/MessFromEndDevice/Humidity
    CasaBuenosAires/MessFromEndDevice/RelayState
    and the board subscribes to the topic CasaBuenosAires/MessFromClient.
   According to the payload received, the IoT board reports the temperature, humidity,
   and toggle the light state, reporting this as well.  }
    //      Copyright: Fernando Pazos
    //      september 2024
(*****************************************************************************)






unit HeaderFooterTemplate;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.IOUtils,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  TMS.MQTT.Global, FMX.Edit, FMX.ScrollBox, FMX.Memo, FMX.ListBox,
  TMS.MQTT.Client, FMX.Objects,  FMX.Controls.Presentation, FMX.Memo.Types,
  System.ImageList, FMX.ImgList, FMX.Layouts, FMX.ExtCtrls, FMX.Ani;

  
  {System.Sensors,
  FMX.WebBrowser, System.Sensors.Components, System.Android.Sensors, FMX.MultiView;}

 
type
  TMainForm = class(TForm)
    Header: TToolBar;
    Footer: TToolBar;
    HeaderLabel: TLabel;
    TMSMQTTClient1: TTMSMQTTClient;
    MemoLog: TMemo;
    ConnectBtn: TSpeedButton;
    DisconnectBtn: TSpeedButton;
    PanelTemp: TPanel;
    TempLabel: TLabel;
    EditTemp: TEdit;
    LabelC: TLabel;
    RefTempBut: TSpeedButton;
    PanelHum: TPanel;
    HumLabel: TLabel;
    EditHum: TEdit;
    LabH: TLabel;
    HumRefBut: TSpeedButton;
    PanelBroker: TPanel;
    brokerLbl: TLabel;
    BrokerList: TComboBox;
    Circle1: TCircle;
    Label1: TLabel;
    led: TCircle;
    portLbl: TLabel;
    PanelLamp: TPanel;
    LabelToggle: TLabel;
    RefLightBut: TSpeedButton;
    ImageViewer1: TImageViewer;
    LedRelay: TCircle;
    procedure BrokerListChange(Sender: TObject);
    procedure ConnectBtnClick(Sender: TObject);
    procedure DisconnectBtnClick(Sender: TObject);
    procedure MemoLogChange(Sender: TObject);
    procedure TMSMQTTClient1ConnectedStatusChanged(ASender: TObject;
      const AConnected: Boolean; AStatus: TTMSMQTTConnectionStatus);
    procedure TMSMQTTClient1PublishReceived(ASender: TObject; APacketID: Word;
      ATopic: string; APayload: TArray<System.Byte>);
    procedure FormCreate(Sender: TObject);
    procedure ImageViewer1Click(Sender: TObject);
    procedure RefLightButClick(Sender: TObject);
    procedure RefTempButClick(Sender: TObject);
    procedure HumRefButClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}
{$R *.NmXhdpiPh.fmx ANDROID}
{$I-}


const
  cImageWidth=4160;
  cImageHeight=3120;

var
  FileName: String;
  LuzAcessaBMP, LuzApagadaBMP: TBitMap;

//Event executed when the form is created
//It creates the bitmaps of the lamp on and lamp off images
procedure TMainForm.FormCreate(Sender: TObject);
var LIndex : integer;
begin
      LIndex:=BrokerList.ItemIndex;
      TMSMQTTClient1.BrokerHostName:=BrokerList.Items[LIndex];
      TMSMQTTClient1.BrokerPort:=1883;
      LuzAcessaBMP:=TBitMap.Create(cImageWidth,cImageHeight);       //create and loas the bitmaps
      try
        FileName:=System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetDocumentsPath, 'luzacessa.jpg');   //path of the text fileFileName:=TPath.Combine(TPath.GetDocumentsPath, 'LuzAcessa.jpg');  { Internal }
        LuzAcessaBMP.LoadFromFile(FileName);
      except
        on EInOutError do
          ShowMessage('IO Result: '+IntToStr(IOResult))
      end;
      LuzApagadaBMP:=TBitMap.Create(cImageWidth,cImageHeight);
      try
        FileName:=System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetDocumentsPath, 'luzapagada.jpg');  { Internal }
        LuzApagadaBMP.LoadFromFile(FileName);
      except
        on EInOutError do
          ShowMessage('IO Result: '+IntToStr(IOResult))
      end
end;




//event executed when a broker URL is selected from the list box
procedure TMainForm.BrokerListChange(Sender: TObject);
var LIndex:integer;
begin
  LIndex:=BrokerList.ItemIndex;
  TMSMQTTClient1.BrokerHostName:=BrokerList.Items[LIndex];
end;

//Event executed when the Connect button is pressed
procedure TMainForm.ConnectBtnClick(Sender: TObject);
begin
    TMSMQTTClient1.Connect();
end;

//Event executed when the disconnect button os pressed
procedure TMainForm.DisconnectBtnClick(Sender: TObject);
begin
    TMSMQTTClient1.Disconnect();
end;



//EVENT executed when MemoLog is on change to scroll the memoLog until the last row
procedure TMainForm.MemoLogChange(Sender: TObject);
begin
   //SendMessage(MemoLog.Handle, EM_LINESCROLL, 0,MemoLog.Lines.Count);
   //MemoLog.GoToTextEnd;
     MemoLog.ScrollBy(0,MemoLog.Lines.Count);
end;





//Event executed when the Connection state changes
//It toggles the connect and disconnect enabled status, and put on/off the drawn led
//prints on the memo log window the connection status.
//when connected, subscribes to the topics Estado/Led, Estado/Botao and TopicIoTboard71
procedure TMainForm.TMSMQTTClient1ConnectedStatusChanged(ASender: TObject;
  const AConnected: Boolean; AStatus: TTMSMQTTConnectionStatus);
begin
    if (AConnected) then
      begin
        ConnectBtn.Enabled:=False;
        BrokerList.Enabled:=False;
        DisconnectBtn.Enabled:=True;
        TMSMQTTClient1.Subscribe('CasaBuenosAires/MessFromEndDevice/#');
        Led.Fill.Color:=$FFFF0000;             //led color=red
        MemoLog.Lines.Add('Client connected to server '+TMSMQTTClient1.BrokerHostName+' at '+FormatDateTime('hh:nn:ss', Now));
        TMSMQTTClient1.Publish('CasaBuenosAires/MessFromClient','client connected');
        sleep(100);
        TMSMQTTClient1.Publish('CasaBuenosAires/MessFromClient','/ReportLightStatus');
        sleep(100);
        TMSMQTTClient1.Publish('CasaBuenosAires/MessFromClient','/ReportTemp');
        sleep(100);
        TMSMQTTClient1.Publish('CasaBuenosAires/MessFromClient','/ReportHum');
      end
      else
      begin
        ConnectBtn.Enabled:=True;
        BrokerList.Enabled:=True;
        DisconnectBtn.Enabled:=False;
        Led.Fill.Color:=$FF800000;     //led color=maroon
        MemoLog.Lines.Add('Client disconnected from server '+TMSMQTTClient1.BrokerHostName+' at '+FormatDateTime('hh:nn:ss', Now));
        case AStatus of
          csNotConnected: MemoLog.Lines.Add('Client not connected');
          //csConnectionRejected_InvalidProtocolVersion: ;
          //csConnectionRejected_InvalidIdentifier: ;
          csConnectionRejected_ServerUnavailable: MemoLog.Lines.Add('Server Unavailable');
          //csConnectionRejected_InvalidCredentials: ;
          csConnectionRejected_ClientNotAuthorized: MemoLog.Lines.Add('Client not authorized');
          csConnectionLost: MemoLog.Lines.Add('Connection lost');
          //csConnecting: ;
          //csReconnecting: ;
          //csConnected: ;
        end;
        EditTemp.Text:='';
        EditHum.Text:='';
        ImageViewer1.Bitmap.Clear(TAlphaColorRec.White);
      end;
end;


//Event executed when a message is received from the publisher (IoT board)
//It prints the received message on the Memo Log window
//and updates light state, temperature or humidity
procedure TMainForm.TMSMQTTClient1PublishReceived(ASender: TObject;
  APacketID: Word; ATopic: string; APayload: TArray<System.Byte>);
var msg:string;
begin
  msg := TEncoding.UTF8.GetString(APayload);
  MemoLog.Lines.Add('Message from end device ['+ATopic+']: '+msg);
  if ATopic='CasaBuenosAires/MessFromEndDevice/LightState' then
    begin
      if msg='light is on' then
        begin
          ImageViewer1.BitMap:=LuzAcessaBMP;
          ImageViewer1.BestFit;
        end;
      if msg='light is off' then
        begin
          ImageViewer1.BitMap:=LuzApagadaBMP;
          ImageViewer1.BestFit;
        end;
    end;
    if ATopic='CasaBuenosAires/MessFromEndDevice/Temperature' then
      EditTemp.Text:=msg;
    if ATopic='CasaBuenosAires/MessFromEndDevice/Humidity' then
      EditHum.Text:=msg;
    if ATopic='CasaBuenosAires/MessFromEndDevice/RelayState' then
        begin
          if msg='relay is on' then
            LedRelay.Fill.Color:=$FF800000;                  //led color=maroon
          if msg='relay is off' then
            LedRelay.Fill.Color:=$FFFF0000;             //led color=red
        end
end;

//event to toggle the light state
procedure TMainForm.ImageViewer1Click(Sender: TObject);
begin
  TMSMQTTClient1.Publish('CasaBuenosAires/MessFromClient','/ToggleLight');
end;

//event to refresh light state
procedure TMainForm.RefLightButClick(Sender: TObject);
begin
   TMSMQTTClient1.Publish('CasaBuenosAires/MessFromClient','/ReportLightStatus');
end;

//event to refresh the temperature
procedure TMainForm.RefTempButClick(Sender: TObject);
begin
  TMSMQTTClient1.Publish('CasaBuenosAires/MessFromClient','/ReportTemp');
end;


//event to refresh the humidity
procedure TMainForm.HumRefButClick(Sender: TObject);
begin
  TMSMQTTClient1.Publish('CasaBuenosAires/MessFromClient','/ReportHum');
 end;

end.
