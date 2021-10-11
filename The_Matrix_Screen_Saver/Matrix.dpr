program Matrix;

{%ToDo 'Matrix.todo'}

uses
  Forms,
  SysUtils,
  Windows,
  Graphics,
  Dialogs,
  Classes,
  f_matrix in 'f_matrix.pas' {frmMatrix},
  f_setup in 'f_setup.pas' {setup};

{$E SCR}

{$R *.RES}
var

  MySem       : THandle;
  Arg1,  Arg2        : String;
  DemoWnd     : HWnd;
  MyRect      : TRect;
  MyCanvas    : TCanvas;
  x, y,  dx, dy      : Integer;
  MyBkgBitmap,  InMemBitmap : TBitmap;
  ScrWidth,  ScrHeight   : Integer;
  SysDir      : String;
  NewLen      : Integer;
  MyMod       : THandle;




 PwdFunc     : function (a : PChar; ParentHandle : THandle; b, c : Integer) :
                    Integer; stdcall;
begin

  OutDc := GetDc(0);
  Arg1 := UpperCase(ParamStr(1));  Arg2 := UpperCase(ParamStr(2));
  if (Copy(Arg1,1,2) = '/A') or (Copy(Arg1,1,2) = '-A') or
     (Copy(Arg1,1,1) = 'A') then    SSMode := ssSetPwd;
  if (Copy(Arg1,1,2) = '/P') or (Copy(Arg1,1,2) = '-P') or
     (Copy(Arg1,1,1) = 'P') then    SSMode := ssPreview;
  if (Copy(Arg1,1,2) = '/C')or (Copy(Arg1,1,2) = '-C') or
     (Copy(Arg1,1,1) = 'C') or (Arg1 = '') then    SSMode := ssConfig;
  if SSMode = ssSetPwd then begin    SetLength(SysDir,MAX_PATH);
    NewLen := GetSystemDirectory(PChar(SysDir),MAX_PATH);
    SetLength(SysDir,NewLen);
    if (Length(SysDir) > 0) and (SysDir[Length(SysDir)] <> '\') then
      SysDir := SysDir+'\';    MyMod := LoadLibrary(PChar(SysDir+'MPR.DLL'));
    if MyMod <> 0 then
    begin
      PwdFunc := GetProcAddress(MyMod,'PwdChangePasswordA');
      if Assigned(PwdFunc) then  PwdFunc('SCRSAVE',StrToInt(Arg2),0,0);
      FreeLibrary(MyMod);
    end;
      Halt;
  end;




  Application.Initialize;

  if SSMode = ssPreview then
  begin
    DemoWnd := StrToInt(Arg2);
    while not IsWindowVisible(DemoWnd) do
        Application.ProcessMessages;
    GetWindowRect(DemoWnd,MyRect);
    ScrWidth :=  MyRect.Right-MyRect.Left+1;
    ScrHeight := MyRect.Bottom-MyRect.Top+1;
    MyRect := Rect(0,0,ScrWidth-1,ScrHeight-1);
    MyCanvas := TCanvas.Create;
    MyCanvas.Handle := GetDC(DemoWnd);
    MyCanvas.Pen.Color := clWhite;
    x := (ScrWidth div 2)-16;
    y := (ScrHeight div 2)-16;
    dx := 1;
    dy := 1;
    MyBkgBitmap := TBitmap.Create;
    with MyBkgBitmap do
    begin
      Width := ScrWidth;
      Height := ScrHeight;
    end;
    MyBkgBitmap.Canvas.FillRect(Rect(0,0,ScrWidth-1,ScrHeight-1));
    InMemBitmap := TBitmap.Create;
    with InMemBitmap do
    begin
      Width := ScrWidth;
      Height := ScrHeight;
    end;
    MyCanvas.Brush.color := ClBlack;
    mycanvas.font.color := clgreen;
    while IsWindowVisible(DemoWnd) do
    begin
      MyCanvas.Textout(12,12,'MATRIX');
    end;
    MyBkgBitmap.Free;
    InMemBitmap.Free;
    MyCanvas.Free;
    CloseHandle(MySem);
    Halt;
  end;



  if SSMode = ssConfig then
  begin
     Application.CreateForm(TSetup, Setup);
  end else
  begin
     MySem := CreateSemaphore(nil,0,1,'MatrixSaverSemaphore');
     if ((MySem <> 0) and (GetLastError = ERROR_ALREADY_EXISTS)) then
     begin
       CloseHandle(MySem);
       Exit;
     end;
     Application.CreateForm(TFrmMatrix, FrmMatrix);
  end;
  Application.Run;
end.
