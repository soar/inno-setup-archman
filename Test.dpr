program Test;
{$APPTYPE CONSOLE}

uses
  SysUtils,
  SevenZipIntfWrapper in 'SevenZipIntfWrapper.pas',
  SevenZipIntf in '7zAPI\SevenZipIntf.pas';

begin
    try
        SZNewArchive('zip');
        SZNewArchive('zip');
    except
        on E: Exception do
            Writeln(E.ClassName, ': ', E.Message);
    end;

    WriteLn('done');
    Readln;
end.
