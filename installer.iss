[Setup]
AppName=Wash Delivery
AppVersion=1.0
AppPublisher=Kaizen Gaming
DefaultDirName={autopf}\WashDelivery
DefaultGroupName=Wash Delivery
OutputBaseFilename=WashDelivery_Setup
Compression=lzma2
SolidCompression=yes
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\washer_app.exe
PrivilegesRequired=lowest

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Wash Delivery"; Filename: "{app}\washer_app.exe"
Name: "{commondesktop}\Wash Delivery"; Filename: "{app}\washer_app.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"

[Run]
Filename: "{app}\washer_app.exe"; Description: "Launch Wash Delivery"; Flags: nowait postinstall skipifsilent
