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

        procedure HangUntilBusy();         // wisi az semafor == 0

    end;

implementation
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
     Handle := CreateSemaphore(nil, 1, 1, nil);
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

