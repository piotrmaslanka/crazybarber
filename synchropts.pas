unit Synchropts;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, semaphores, fgl;

type
  TManagedThread = class
  public
    MySemaphore: TSemaphore; // watek do synchronizacji animacji

    procedure SignalStep; // watek wywoluje jesli wykonal jakis element pracy
    constructor Create(CreateSuspended: Boolean);

  end;

  TManagedThreadList = specialize TFPGList<TManagedThread>;


var
  EverybodySynchronizedSemaphore: TSemaphore;
  ThreadList: TManagedThreadList;

procedure Initialize(syncers: Cardinal);    // inicjuje modul kontroli watkow
procedure AddThread(t: TManagedThread);     // dodaj watek do listy
procedure Tick();                    // poczekaj na wszystkie watki i pusc dalej
implementation
constructor TManagedThread.Create(CreateSuspended: Boolean);
begin
   MySemaphore := TSemaphore.Create();
   inherited Create(CreateSuspended);
end;

procedure AddThread(t: TManagedThread);     // dodaj watek do listy
begin
  ThreadList.Add(t);
end;

procedure Tick();
var
  i: Integer;
begin
     EverybodySynchronizedSemaphore.HangUntilBusy();
     for i := 0 to ThreadList.Count-1 do ThreadList[i].MySemaphore.V(); // odwies gosci
end;

procedure Initialize(syncers: Cardinal);
begin
  EverybodySynchronizedSemaphore := TSemaphore.Create(syncers, syncers);
end;

procedure TManagedThread.SignalStep();
begin
  EverybodySynchronizedSemaphore.P();  // zaznacz ze czekasz na tick
  MySemaphore.P();                     // powies sie na wlasnym semaforze :D
  EverybodySynchronizedSemaphore.V();  // zaznacz ze juz nie czekasz
end;
initialization
begin
  TThreadList := TManagedThreadList.Create();
end;
end.

