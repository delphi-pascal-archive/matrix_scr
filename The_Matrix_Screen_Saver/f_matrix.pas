unit f_matrix;
{$define nodebug}
{$E SCR}
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls,registry;
const
  MAXCOLUMNS = 165;
  NUMCOLUMNS:integer = 165;
  BWidth = 20;
  BHeight = 20;
  numBitmaps = 40;
  IgnoreCount : Integer = 10;

type  TSSMode = (ssSetPwd,ssPreview,ssConfig,ssRun);
const
  SSMode      : TSSMode = ssRun;
  TestMode    : Boolean = True;
type
  TGraphicManager=class
  private
    { Private declarations }
    fMapWidth : integer;
    fMapHeight : Integer;
    fBitMap : TBitmap;
    fDefaultDC : THandle;

  public

     procedure BltDefaultIndex(index : Integer;x,y : integer);
     procedure StretchBltToCanvas(sr:Trect;Dest:TRect;DestDC:Thandle);
     procedure BltToCanvas(sr:Trect;DestCoord:Tpoint;DestDC:Thandle);
     property OutPutDC : THandle read FDefaultDC write fDefaultDC;
     property Bitmap : TBitmap read fBitmap write fBitmap;
     property MapHeight : integer read fmapHeight write FMapHeight;
     property MapWidth : integer read fmapwidth write fMapWidth;
  end;

  TMatrixColumn = class
  private
    fStartPos : integer;
    fRendervar : integer;
    fIntense,FNormal : TGraphicManager;
    FNumLetters,flastSentIndex,fCurrentPosition : Integer;
    fMaxy,fColumnX : integer;
    FLetterWIdth,FLetterHeight : integer;
    procedure SetIntense(const Value: TGraphicManager);
    procedure SetNormal(const Value: TGraphicManager);
    procedure SetstartPos(index: Integer);
  protected

  public
    constructor create;
    procedure RenderNext;
    Property StartPos : Integer read fstartPos write SetstartPos;
    property NumLetters : integer read fnumletters write FNumLetters;
    property Intense : TGraphicManager read fintense write SetIntense;
    property Normal : TGraphicManager read fNormal write SetNormal;
    property ColumnX : integer read FColumnX write FColumnX;
    Property MaxY : integer read fmaxy write fmaxy;

  end;



type
 pintarray = ^intarray;
 intarray = array[0..0] of integer;

type
  TfrmMatrix = class(TForm)
    Image1: TImage;
    Timer1: TTimer;
    Image2: TImage;
    Image3: TImage;
   
    procedure Timer1Timer(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormClick(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
 //   fDefaultDC : THandle;
   mouse : Tpoint;
  public
    LoadingApp : Boolean;
    procedure GetPassword;

    { Public declarations }
  end;

var
  OutDc       : THandle;
  frmMatrix: TfrmMatrix;
  bm : Tbitmap;
  empty,gm,gmi : TGraphicManager;
  Columns : Array[0..MAXCOLUMNS-1] of TMatrixColumn;
implementation

{$R *.DFM}

// DEAD TEST CODE----------------

{ TGraphicManager }

procedure TGraphicManager.BltDefaultIndex(index: Integer; x,y :Integer);
var
  sr : TRect;
begin
  with sr do
  begin
   left := 0;
   top  := index*FMapHeight;
   right := fMapWidth;
   bottom := top +fMapHeight;
  end;
  BltToCanvas(sr,Point(x,y),fdefaultdc);
end;

procedure TGraphicManager.BltToCanvas(sr: Trect; DestCoord: Tpoint;
  DestDC: Thandle);
begin
  BitBlt(destdc,DestCoord.X,DestCoord.Y,sr.right-sr.left,sr.bottom-sr.top,fBitmap.canvas.handle,sr.Left,sr.top,srccopy);
end;


procedure TfrmMatrix.Timer1Timer(Sender: TObject);
const
  c : Integer = 0;
var
  i : integer;
  b : TBitmap;
  x, y : Integer;
begin
  Timer1.Enabled := False;
  try
    Inc(c);
    if c = 50 then begin
      c := 0;
      try
        b := TBitmap.Create;
        b.Width := Image3.Width;
        b.Height := Image3.Height;
        x := Random(Screen.Width-Image3.Width);
        y := Random(Screen.Height-Image3.Height);
        BitBlt(b.Canvas.Handle,0,0,Image3.Width,Image3.Height,OutDC,x,y,SrcCopy);
        BitBlt(OutDC,x,y,Image3.Width,Image3.Height,Image3.Canvas.Handle,0,0,SrcCopy);
        Sleep(500);
        BitBlt(OutDC,x,y,Image3.Width,Image3.Height,b.Canvas.Handle,0,0,SrcCopy);
      finally
        b.Free;
      end;
    end;
    for i := 0 to numColumns -1 do
      Columns[i].RenderNext;
  finally
    Timer1.Enabled := True;
  end;  
end;

procedure TfrmMatrix.FormActivate(Sender: TObject);
var

  i : integer;
begin
  IF Screen.Width <=800 then NUMCOLUMNS := 80;  // lower res.. don't need as many characters flying about
  if LoadingApp then begin
    LoadingApp := False;

    Mouse.X := -1;
    Mouse.Y := -1;
   // Application.OnIdle := Trigger;
//    SetWindowPos(Handle,HWND_TOPMOST,0,0,0,0,SWP_NOSIZE + SWP_NOMOVE);
  //  SystemParametersInfo(SPI_SCREENSAVERRUNNING,1,@Dummy,0);    CursorOff;
   // Scrn.Visible := True;
   // SetCapture(Scrn.Handle);
   end;
{$ifdef NODEBUG}
   ShowCursor(False);
{$endif}
  // For Clearing out the columns
  bm := Tbitmap.create;
  bm.Width := BWidth;
  bm.Height := BHeight*5;
  bm.canvas.brush.color := clblack;
  bm.Canvas.FillRect(rect(0,0,bwidth,bheight*5));
  empty := TGraphicManager.Create;
  empty.Bitmap := bm;
  empty.MapWidth := Image2.picture.bitmap.width;
  empty.MapHeight := BHeight;
  // These are for the Leading intense characters
  gmi := TGraphicManager.Create;
  gmi.Bitmap := Image2.picture.bitmap;
  gmi.MapWidth := Image2.picture.bitmap.width;
  gmi.MapHeight := BHeight;
 // These are the normal characters
  gm := TGraphicManager.Create;
  gm.Bitmap := Image1.picture.bitmap;
  gm.MapWidth := Image1.picture.bitmap.width;
  gm.MapHeight := BHeight;
  randomize;
  for i := 0 to numColumns - 1 do begin
    Columns[i] := TMatrixColumn.Create;
    with columns[i] do
    begin
      StartPos := Random(screen.height div bheight)*bHeight;

      if random(3) = 2 then  // This column will be an blank column??
      begin
        Intense := Empty;
        Normal :=  Empty;
        NumLetters := 2;
      end else
        begin
          Intense := gmi;
          Normal := gm;
          NumLetters := NUMBITMAPS;
        end;
      ColumnX := Random(Screen.width div BWidth)*BWidth;
      MaxY := Screen.Height;
    end;
  empty.OutPutDc := OutDc;
  gmi.outputdc := OutDC;
  gm.OutputDc := OutDC;
end;
end;

procedure TGraphicManager.StretchBltToCanvas(sr, Dest: TRect;
  DestDC: Thandle);
begin

end;

{ TMatrixColumn }

constructor TMatrixColumn.create;
begin
  frenderVar := 0;
end;

procedure TMatrixColumn.RenderNext;
var
 newletter : integer;
begin

  repeat
      NewLetter := random(fNumLetters);
  until newLetter <> fLastSentIndex;

  fCurrentPosition := FCurrentPosition + fLetterHeight;
  fIntense.BltDefaultIndex(NewLetter,fColumnX,FCurrentPosition);
  fNormal.BltDefaultIndex(fLastSentIndex,fcolumnX,FCurrentPosition - fLetterHeight);
  FLastSentIndex := NewLetter;
  fRenderVar := 0;
  if FcurrentPosition  > fMaxy Then
  begin
    FCurrentPosition := 0;
    self.ColumnX := Random(100) * self.FLetterWIdth;
  end;
end;

procedure TMatrixColumn.SetIntense(const Value: TGraphicManager);
begin
  fLetterWidth := value.MapWidth;
  fLetterHeight := Value.MapHeight;
  fintense := Value;
end;

procedure TMatrixColumn.SetNormal(const Value: TGraphicManager);
begin
  fLetterWidth := value.MapWidth;
  fLetterHeight := Value.MapHeight;
  fNormal := Value;
end;

procedure TMatrixColumn.SetstartPos(index : Integer);
begin
  fCurrentPosition := index;
  FstartPos := index;
end;

procedure TfrmMatrix.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  bm.free;
end;

procedure TfrmMatrix.FormClick(Sender: TObject);
begin
  close;
end;

procedure TfrmMatrix.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin

  if IgnoreCount > 0 then begin
    Dec(IgnoreCount);
    Exit;
  end;
  if (Mouse.X = -1) and (Mouse.Y = -1) then begin
    Mouse.X := X;
    Mouse.Y := Y;  end
    else
    if (Abs(X-Mouse.X) > 2) and (Abs(Y-Mouse.Y) > 2) then begin
      Mouse.X := X;
      Mouse.Y := Y;
      showCursor(true);
      close;
    //  GetPassword;
    end;
end;

procedure TfrmMatrix.FormKeyPress(Sender: TObject; var Key: Char);
begin
  close;
end;

procedure TfrmMatrix.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  close;
end;

procedure TfrmMatrix.GetPassword;    
var
  MyMod     : THandle;
  PwdFunc   : function (Parent : THandle) : Boolean; stdcall;
  SysDir    : String;  NewLen    : Integer;  MyReg     : TRegistry;
  OkToClose : Boolean;
  begin
   if (SSMode <> ssRun) or TestMode then begin
    Close;    Exit;  end;  IgnoreCount := 5;  OkToClose := False;
   MyReg := TRegistry.Create;  MyReg.RootKey := HKEY_CURRENT_USER;
   if MyReg.OpenKey('Control Panel\Desktop',False) then
   begin
     try
       try
        ShowCursor(True);
        if MyReg.ReadInteger('ScreenSaveUsePassword') <> 0 then begin
          SetLength(SysDir,MAX_PATH);
          NewLen := GetSystemDirectory(PChar(SysDir),MAX_PATH);
          SetLength(SysDir,NewLen);
          if (Length(SysDir) > 0) and (SysDir[Length(SysDir)] <> '\') then
            SysDir := SysDir+'\';
          MyMod := LoadLibrary(PChar(SysDir+'PASSWORD.CPL'));
          if MyMod = 0 then OkToClose := True else
          begin
            PwdFunc := GetProcAddress(MyMod,'VerifyScreenSavePwd');
            if PwdFunc(Handle) then              OkToClose := True;
            FreeLibrary(MyMod);          end;        end        else
          OkToClose := True;      finally        ShowCursor(False);      end;
    except      OkToClose := True;    end;  end  else    OkToClose := True;
  MyReg.Free;  if OkToClose then    Close;end;

initialization
finalization
 releaseDC(0,outdc);
end.
