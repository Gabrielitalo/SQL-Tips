Declare @Url Varchar(800) = 'FormFiscal/RegEntradas/RegEntradas.aspx'


if (@Url like '%/%')
  Begin
    Select RIGHT(@Url, CHARINDEX('/', REVERSE(@Url)) - 1)
	End
Else
  Begin
		 Select @Url
	End

