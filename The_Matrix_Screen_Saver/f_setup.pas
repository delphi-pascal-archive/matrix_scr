unit f_setup;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, jpeg, ComCtrls;

type
  Tsetup = class(TForm)
    Image1: TImage;
    procedure Image1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  setup: Tsetup;

implementation

{$R *.DFM}

procedure Tsetup.Image1Click(Sender: TObject);
begin
  close;
end;

end.
