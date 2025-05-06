SET Server="QUALITYR"
SET DBName="New_OGS_DataBanking"
SET DBPath="C:\MS SQL"
SET script_folder=C:\Haller-Erne GmbH\SQL SCRIPT
SET User="sys3xx"
SET Pass="sys3xx"

sqlcmd -S %Server% -U %User% -P %Pass% -i "%script_folder%\create_db.sql" -v script_folder="%script_folder%" DBName = %DBName% DBPath = %DBPath%

pause