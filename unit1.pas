unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, Synchropts;

type

  TKlient = class(TManagedThread)

  end;


  TFryzjer = class(TManagedThread)

  end;

  TForm1 = class(TForm)
    Label1: TLabel;
  private
    { private declarations }
  public
    { public declarations }
  end;

var


  Form1: TForm1;

implementation

{$R *.lfm}

end.

