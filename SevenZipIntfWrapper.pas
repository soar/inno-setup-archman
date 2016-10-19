unit SevenZipIntfWrapper;

interface

type
    TThreadParam = packed record
        fileName: string;
    end;
    PTThreadParam = ^TThreadParam;

    TProgressCallback = function(value: Cardinal): Integer;

procedure SZNewArchive(const archTypeName: PAnsiChar; const libDir: PAnsiChar); stdcall;
procedure SZAddFile(const fileName: PAnsiChar; const filePath: PAnsiChar); stdcall;
procedure SZAddFiles(const dir: PAnsiChar; const path: PAnsiChar; const wildCard: PAnsiChar; isRecurse: Boolean); stdcall;
procedure SZSetCompressionLevel(level: Cardinal); stdcall;
procedure SZSetCompressionMethod(const method: PAnsiChar); stdcall;
procedure SZSetProgressCallback(callback: Pointer); stdcall;
procedure SZSetProgressHandles(inWindowHandle: THandle; inProgressBarHandle: THandle); stdcall;
function SZSaveToFile(const fileName: PAnsiChar): THandle; stdcall;
function SZIsThreadRunning(handle: THandle; timeToWait: Cardinal): Boolean; stdcall;
function SZProgressCallback(sender: Pointer; isTotal: Boolean; value: Int64): HRESULT; stdcall;

implementation

uses
    Dialogs,
    StrUtils,
    SysUtils,
    Messages,
    Windows,
    CommCtrl,
    SevenZipIntf;

const
    ExceptionTitle = 'IS ArchMan.dll Error ';

var
    OArch: I7zOutArchive;
    IArch: I7zInArchive;

    ProgressTotal: Int64;
    ProgressCurrent: Int64;
    ProgressCallback: TProgressCallback;

    WindowHandle: THandle;
    ProgressBarHandle: THandle;

    ThreadParam: TThreadParam;

// =============================================================================
// Common
// =============================================================================


function SZProgressCallback(sender: Pointer; isTotal: Boolean; value: Int64): HRESULT; stdcall;
begin
    if (isTotal)
        then ProgressTotal := value
        else begin
            ProgressCurrent := value;

            if (ProgressBarHandle <> INVALID_HANDLE_VALUE)
                then PostMessage(ProgressBarHandle, PBM_SETPOS, Round(ProgressCurrent / (ProgressTotal / 100)), 0);

            //if (Assigned(ProgressCallback))
            //    then ProgressCallback(Round(ProgressCurrent / (ProgressTotal / 1000)));
        end;

    Result := S_OK;
end;

// =============================================================================
// Creation
// =============================================================================

function IsOutArchiveExists(): Boolean;
begin
    if (not Assigned(OArch))
        then begin
            ShowMessage(ExceptionTitle + ' #124' + #10#13 + 'Before do any action with archive - you need init it.');
            Result := false;
        end else
            Result := true;
end;

function SaveToFileThread(PParam: Pointer): Integer; // stdcall winapi; - not user for BeginThread
var
    PThreadParam: PTThreadParam;
begin
    Result := 0;
    if (not IsOutArchiveExists()) then Exit;

    try
        PThreadParam := PParam;
        OArch.SaveToFile(PThreadParam.fileName);
        OArch := nil;
    except
        on E: Exception do begin
            ShowMessage(ExceptionTitle + ' #512' + #10#13 + E.Message + #10#13 + SysErrorMessage(GetLastError()));
            EndThread(1);
        end;
    end;

    EndThread(0);
end;

procedure SZNewArchive(const archTypeName: PAnsiChar; const libDir: PAnsiChar);
var
    archType: TGUID;
begin
    if (Assigned(OArch))
        then OArch := nil;

    case AnsiIndexStr(string(archTypeName), ['7z', 'zip', 'rar']) of
        0: archType := CLSID_CFormat7z;
        1: archType := CLSID_CFormatZip;
        2: archType := CLSID_CFormatRar;
        else archType := CLSID_CFormat7z;
    end;

    try
        OArch := CreateOutArchive(archType, string(libDir));
    except
        on E: Exception do
            ShowMessage(ExceptionTitle + ' #812' + #10#13 + E.Message + #10#13 + SysErrorMessage(GetLastError()));
    end;
end;

procedure SZAddFile(const fileName: PAnsiChar; const filePath: PAnsiChar);
begin
    if (not IsOutArchiveExists()) then Exit;

    OArch.AddFile(string(fileName), string(filePath));
end;

procedure SZAddFiles(const dir: PAnsiChar; const path: PAnsiChar; const wildCard: PAnsiChar; isRecurse: Boolean);
begin
    if (not IsOutArchiveExists()) then Exit;

    OArch.AddFiles(string(dir), string(path), string(wildCard), isRecurse);
end;

procedure SZSetCompressionLevel(level: Cardinal);
begin
    if (not IsOutArchiveExists()) then Exit;

    SetCompressionLevel(OArch, level);
end;

// For ZIP: 'COPY', 'DEFLATE', 'DEFLATE64', 'BZIP2'
// For 7Zip: 'COPY', 'LZMA', 'LZMA2', 'BZIP2', 'PPMD', 'DEFLATE', 'DEFLATE64'
procedure SZSetCompressionMethod(const method: PAnsiChar);
begin
    if (not IsOutArchiveExists()) then Exit;

    if (IsEqualGUID(OArch.ClassId, CLSID_CFormatZip))
        then OArch.SetPropertie('M', string(method));
    if (IsEqualGUID(OArch.ClassId, CLSID_CFormat7z))
        then OArch.SetPropertie('0', string(method));
end;

procedure SZSetProgressCallback(callback: Pointer);
begin
    if (not IsOutArchiveExists()) then Exit;

    ProgressCallback := callback;
    OArch.SetProgressCallback(nil, SZProgressCallback);
end;

procedure SZSetProgressHandles(inWindowHandle: THandle; inProgressBarHandle: THandle);
begin
    if (not IsOutArchiveExists()) then Exit;

    WindowHandle := inWindowHandle;
    ProgressBarHandle := inProgressBarHandle;
    SendMessage(ProgressBarHandle, PBM_SETRANGE, 0, MakeLParam(0, 100));
    OArch.SetProgressCallback(nil, SZProgressCallback)
end;

function SZSaveToFile(const fileName: PAnsiChar): THandle;
var
    ThreadID: Cardinal;
begin
    Result := 0;

    if (not IsOutArchiveExists()) then
        Exit()
    else begin
        try
            ThreadParam.fileName := string(fileName);
            Result := BeginThread(nil, 0, @SaveToFileThread, @ThreadParam, 0, ThreadID);
        except
            on E: Exception do
                ShowMessage(ExceptionTitle + ' #815' + #10#13 + E.Message + #10#13 + SysErrorMessage(GetLastError()));
        end;
    end;
end;

function SZIsThreadRunning(handle: THandle; timeToWait: Cardinal): Boolean;
begin
    try
        Result := not (WaitForSingleObject(handle, timeToWait) <> WAIT_TIMEOUT);
    except
        on E: Exception do begin
            ShowMessage(ExceptionTitle + ' #156' + #10#13 + E.Message + #10#13 + SysErrorMessage(GetLastError()));
            Result := false;
        end;
    end;
end;

// =============================================================================
// System section
// =============================================================================

initialization

    WindowHandle := INVALID_HANDLE_VALUE;
    ProgressBarHandle := INVALID_HANDLE_VALUE;

finalization

    if (Assigned(OArch)) then OArch := nil;
    if (Assigned(IArch)) then IArch := nil;

end.
