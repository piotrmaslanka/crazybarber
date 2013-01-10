unit Unit1;
// Crazy Barber - program demonstrujacy zagadnienie spiacego fryzjera
// Copyright by Piotr Maślanka 2013, wszystkie prawa zastrzezone
//
//
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Menus, Synchropts, fgl, semaphores;

ResourceString
   Author = 'Piotr Maślanka';
   AuthorEmail = 'piotr.maslanka@henrietta.com.pl';

type
  TKlient = class(TManagedThread)
    public
          TID: Cardinal;
          BrodatySemafor: TBinarySemaphore;
          status: String;
          Brodaty: Boolean;

          constructor Create(); // stworz klienta i dodaj go do kolejki
          procedure Execute; override;

  end;


  TFryzjer = class(TManagedThread)
        public
          TID: Cardinal;
          status: String;

          constructor Create();
          procedure Execute; override;

  end;

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    loseClients: TCheckBox;
    stsGotKli: TLabel;
    stsGotKli1: TLabel;
    stsPoczekalni: TLabel;
    Memo1: TMemo;
    Memo2: TMemo;
    Timer1: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
  public
    procedure WypiszStatusWatkow;
    procedure Krok;
  end;

  TKolejkaWPoczekalni = specialize TFPGList<TKlient>;
var
  Kolejka: TKolejkaWPoczekalni;
  MonitorKolejki: TBinarySemaphore;         // blokada do korzystania z listy kolejki

  PoczekalniaSemafor: TBinarySemaphore;     // blokada do sprawdzania poczekalni

  Fryzjer: TFryzjer;


  GotowiKlienci: TSemaphore;                // semafor z liczba gotowych klientow w kolejce
  LiczbaWolnychSiedzen: Cardinal = 10;

  Form1: TForm1;

  Memo2Semaphore: TBinarySemaphore;   // semafor do ochrony Memo2

  CzytelnikowKlamiacych: Cardinal = 0;   // czytelnikow ktorzy potencjalnie moga 'sklamac'
   // mechanizm klamstwa jest po to zeby symulowac gubienie klientow, ze wzgledu na to ze
   // na szybkich komputerach naturalny deadlock jest bardzo malo prawdopodobny, a pasuje
   // zeby sie zamanifestowal

   // jesli mamy tutaj wiecej niz jeden, to jeden z klientow moze sklamac i sie
   // nie dopisac do kolejki ;)

implementation

{$R *.lfm}

procedure Log(s: String);
begin
  Memo2Semaphore.P();
  Form1.Memo2.Lines.Append(IntToStr(GetThreadID())+': '+s);
  Memo2Semaphore.V();
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  AddThread(TFryzjer.Create);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  AddThread(TKlient.Create);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  if Timer1.Enabled then     // button was PAUSE
  begin
    Timer1.Enabled := False;
    Button3.Caption := 'PLAY';
    Button4.Enabled := True;
  end else
  begin
    timer1.Enabled := True;
    Button3.Caption := 'PAUSE';
    Button4.Enabled := False;
  end;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  Krok;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
end;

procedure TForm1.FormCreate(Sender: TObject);
begin

end;


procedure TForm1.Krok;
begin
  StartLockstep();
  Label1.Caption := IntToStr(GotowiKlienci.CurrentValue);
  Label2.Caption := IntToStr(PoczekalniaSemafor.CurrentValue);
  Label3.Caption := IntToStr(LiczbaWolnychSiedzen);
  WypiszStatusWatkow();
  EndLockstep();
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Krok;
end;

procedure TForm1.WypiszStatusWatkow;
var
  i: Integer;
  k: TKlient;
  f: TFryzjer;
begin
  Memo1.Clear;
  MonitorKolejki.P();
  for i := 0 to ThreadList.Count-1 do
  begin
    if ThreadList[i].CategoryCode = 0 then        // klient
    begin
      k := ThreadList[i] as TKlient;
      Memo1.Lines.Append('Klient '+IntToStr(k.TID)+': '+k.status)
    end
    else
    begin
      f := ThreadList[i] as TFryzjer;
      Memo1.Lines.Append('Fryzjer '+IntToStr(f.TID)+': '+f.status);
    end;
  end;
  Memo1.Lines.Append('Klientow w kolejce: '+IntToStr(Kolejka.Count));
  MonitorKolejki.V();
end;


function MSP: string;
// zwraca [MAM SEMAFOR p] jesli nie gubimy klientow
begin
  result := '';
  if not Form1.loseClients.Checked then result := ' [MAM SEMAFOR p]';
end;

procedure TFryzjer.Execute();
var
  GolonyKlient: TKlient;
begin
  TID := GetThreadID();
  Form1.Memo2.Lines.Append('Fryzjer '+IntToStr(TID)+' przychodzi do pracy');
  status := 'Dopiero przyszedlem; mala czarna...';
  self.SignalStep();

  while True do
  begin
    status := 'Czekam na klienta';
    self.SignalStep;
    GotowiKlienci.P();
    status := 'Hej, jest klient!';
    self.SignalStep;

    if not Form1.loseClients.Checked then
    begin
         status := 'Ide w kierunku poczekalni...';
         PoczekalniaSemafor.P();
         Log('Pozyskany semafor poczekalni');
    end;
    status := 'Jestem w poczekalni...'+MSP;
    self.SignalStep;

    status := 'Zgarniam klienta'+MSP;
    InterlockedIncrement(LiczbaWolnychSiedzen);
    if not Form1.loseClients.Checked then MonitorKolejki.P();
        GolonyKlient := Kolejka[0];
        Kolejka.Delete(0);
    if not Form1.loseClients.Checked then MonitorKolejki.V();

    if not GolonyKlient.Brodaty then
       Halt;

    if not Form1.loseClients.Checked then
    begin
        status := 'Zwalniam semafor poczekalni';
        PoczekalniaSemafor.V();
        Log('Zwolniony semafor poczekalni');
        self.SignalStep;
    end;

    status := 'Gole klienta...';
    GolonyKlient.status := 'Jestem golony...';
    self.SignalStep;
    self.SignalStep;
    GolonyKlient.Brodaty := false;
    GolonyKlient.BrodatySemafor.V();
    status := 'Voila';
    self.SignalStep;
  end;
  Form1.Memo2.Lines.Append('Fryzjer '+IntToStr(TID)+' wychodzi z pracy');

end;


procedure TKlient.Execute();
begin
  TID := GetThreadID();
  Form1.Memo2.Lines.Append('Klient '+IntToStr(TID)+' wkracza do gry');
  status := 'Czesc wszyscy';
  self.SignalStep;
  if not Form1.loseClients.Checked then
  begin
    status := 'Blokuje semafor poczekalni...';
    self.SignalStep;
    PoczekalniaSemafor.P();
    Log('Pozyskany semafor poczekalni');
  end;

  InterlockedIncrement(CzytelnikowKlamiacych);

  if LiczbaWolnychSiedzen > 0 then
  begin
    status := 'Rozsiadam sie'+MSP;
    InterlockedDecrement(LiczbaWolnychSiedzen);
    if not Form1.loseClients.Checked then MonitorKolejki.P();

    if Form1.loseClients.Checked and (CzytelnikowKlamiacych > 1) then
       // to co, klamiemy :D
    begin
        if random(4) <> 1 then Kolejka.Add(self);           // 25% szansy na klamstwo
    end else
       Kolejka.Add(self); // albo nie chcemy zebys klamal albo nikogo nie przekonasz
                          // nie dopisujac sie jak tylko jeden klient - ty - tutaj siedzisz
    if not Form1.loseClients.Checked then MonitorKolejki.V();
    self.SignalStep;

    InterlockedDecrement(CzytelnikowKlamiacych);
    status := 'Zglaszam ze jestem gotowy fryzjerowi'+MSP;
    GotowiKlienci.V();
    self.SignalStep;

    if not Form1.loseClients.Checked then
    begin
      status := 'Bede zwalnial blokade poczekalni'+MSP;
      self.SignalStep;
      Log('Zwolniony semafor poczekalni');
      PoczekalniaSemafor.V();

      status := 'Juz zwolnilem blokade';
      self.SignalStep;
    end;

    status := 'Czekam az fryzjer mnie ogoli';
    self.BrodatySemafor.P();

    status := 'Ogolony i zadowolony';
    self.SignalStep;
  end else
  begin
    if form1.loseClients.Checked then
    begin
      status := 'Wychodze, nie ma miejsca';
      self.SignalStep;
    end else
    begin
      status := 'Wychodze, nie ma miejsca. Zwalniam semafor poczekalni';
      Log('Zwolniony semafor poczekalni');
      PoczekalniaSemafor.V();
      self.SignalStep;
    end;
  end;

  Form1.Memo2.Lines.Append('Klient '+IntToStr(TID)+' wychodzi z gry');
end;

constructor TKlient.Create();
begin
  BrodatySemafor := TSemaphore.Create;
  self.CategoryCode := 0;
  self.Brodaty := true;
  inherited Create(false);
end;

constructor TFryzjer.Create();
begin
  self.CategoryCode := 1;
  FreeOnTerminate := true;
  inherited Create(false);
end;

initialization
begin
  PoczekalniaSemafor := TSemaphore.Create(1, 1);
  MonitorKolejki := TSemaphore.Create(1, 1);
  GotowiKlienci := TSemaphore.Create;
  Memo2Semaphore := TSemaphore.Create(1,1);
  Kolejka := TKolejkaWPoczekalni.Create;
end;

end.

