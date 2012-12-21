unit Synchropts;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, semaphores, fgl;

type
  TManagedThread = class(TThread)
  public
    CategoryCode: Cardinal;
    MySemaphore: TSemaphore; // do synchronizacji animacji
                 // jak watek juz na czyms nie wisi to zawisnie wlasnie na tym

    // podczas normalnej pracy MySemaphore ma wartosc 0. W momencie kiedy
    // watek chce sie na nim powiesic, P()uje go i sie wiesza
    // watek glowny kiedys go odwiesi

    procedure SignalStep; // watek wywoluje jesli wykonal jakis element pracy
    constructor Create(CreateSuspended: Boolean);

  end;

  TManagedThreadList = specialize TFPGList<TManagedThread>;

var
  ThreadList: TManagedThreadList;

procedure AddThread(t: TManagedThread);     // dodaj watek do listy
procedure StartLockstep();
procedure EndLockstep();
implementation

constructor TManagedThread.Create(CreateSuspended: Boolean);
begin
   MySemaphore := TSemaphore.Create();
   FreeOnTerminate := false;
   inherited Create(CreateSuspended);
end;

procedure AddThread(t: TManagedThread);     // dodaj watek do listy
begin
  ThreadList.Add(t);
end;

procedure StartLockstep();
var
  i: Integer;
  KilledADeadOne: Boolean;
  c: TManagedThread;
begin
     KilledADeadOne := true;
     // w tym momencie wszyscy powinni wisiec. Zabij martwych.
     while KilledADeadOne do
     begin
           KilledADeadOne := false;
           for i := 0 to ThreadList.Count-1 do
               if ThreadList[i].Terminated then
               begin
                  c := ThreadList[i];

                  ThreadList.Delete(i);
                  KilledADeadOne := true;
                  c.Destroy;
                  break;
               end;
     end;
end;

procedure EndLockstep();
var
  i: Integer;
begin
     // odwies powieszonych na wlasnym semaforze
     for i := 0 to ThreadList.Count-1 do ThreadList[i].MySemaphore.VIfLocked();
end;

procedure TManagedThread.SignalStep();
begin
  MySemaphore.P();                      // powies sie na wlasnym semaforze :D
end;
initialization
begin
  ThreadList := TManagedThreadList.Create();
end;
end.

