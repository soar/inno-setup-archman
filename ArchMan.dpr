library ArchMan;

{.$define ShareMM}
{.$define ShareMMIfLibrary}
{.$define AttemptToUseSharedMM}

uses
    // FastMM4,
    SysUtils,
    Classes,
    Windows,
    SevenZipIntf in '7zAPI\SevenZipIntf.pas',
    SevenZipIntfWrapper in 'SevenZipIntfWrapper.pas';

{$R *.res}

(*
procedure TestProc(const param: PAnsiChar); stdcall winapi;
var
    i: integer;
begin
    //ShowMessage('Test from dll called, param is: ' + string(param));
    for i := 0 to 10 do begin
        sleep(1000);
    end;
    //ShowMessage('Test from dll ended');
end;

function TestCreateThread(): THandle; stdcall;
var
    TID: Cardinal;
    test: PAnsiChar;
begin
    test := 'test text';
    Result := CreateThread(nil, 0, @TestProc, test, 0, TID);
end;

function WaitForThread(param: THandle; time: Cardinal): Boolean; stdcall;
var
    r: Cardinal;
begin
    r := WaitForSingleObject(param, time);
    case r of
        WAIT_TIMEOUT: Result := true;
        WAIT_FAILED: Result := False;
        WAIT_OBJECT_0: Result := False;
        else Result := False;
    end;

end;

procedure TestCallback(param: Pointer); stdcall;
type
    TCallback = procedure(param: PAnsiChar);
var
    Q: TCallback;
begin
    Q := param;
    Q('test');
end;

exports TestCreateThread, WaitForThread, TestCallback;

*)

exports
    SZNewArchive,
    SZAddFile,
    SZAddFiles,
    SZSetCompressionLevel,
    SZSetCompressionMethod,
    SZSetProgressCallback,
    SZSetProgressHandles,
    SZSaveToFile,
    SZIsThreadRunning;

begin
end.
