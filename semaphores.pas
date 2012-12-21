unit semaphores;

{$mode objfpc}{$H+}


interface
uses
  Classes, SysUtils, Windows;

type
    TSemaphore = class
      private
        Handle: HANDLE;
      public
        constructor Create();
        constructor Create(StartingStatus, MaximumStatus: Cardinal);
        destructor Destroy;

        procedure P();
        procedure V();

        procedure VIfLocked();

        procedure HangUntilBusy();         // wisi az semafor == 0

    end;

    TBinarySemaphore = TSemaphore;         // zeby intencja byla jasna

implementation
procedure TSemaphore.VIfLocked();
begin
     if WaitForSingleObject(Handle, 0) = WAIT_TIMEOUT then self.V();
end;

procedure TSemaphore.HangUntilBusy();
begin
   while WaitForSingleObject(Handle, 0) <> WAIT_TIMEOUT do
   begin
        self.V();
        ThreadSwitch();
   end;
end;
constructor TSemaphore.Create();
begin
     Handle := CreateSemaphore(nil, 0, $FFFF, nil);
end;
constructor TSemaphore.Create(StartingStatus, MaximumStatus: Cardinal);
begin
     Handle := CreateSemaphore(nil, StartingStatus, MaximumStatus, nil);
end;
destructor TSemaphore.Destroy();
begin
     CloseHandle(Handle);
     inherited Destroy;
end;
procedure TSemaphore.P();
begin
   WaitForSingleObject(Handle, INFINITE);
end;
procedure TSemaphore.V();
begin
   ReleaseSemaphore(Handle, 1, nil);
end;

end.

