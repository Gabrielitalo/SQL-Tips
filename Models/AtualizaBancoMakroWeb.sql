------------------------------------------------------------------------------------------------------------------------
--Criado Por Paulo Morais em 12/08/2016
--Script Criado para atualizar bancos muito antigos que vem do makroContabil
------------------------------------------------------------------------------------------------------------------------

Declare @PkScript int, @Tipo tinyint, @NomePc varchar(300), @NomePCBanco varchar(300), @ConteudoScript1 varchar(Max), @ConteudoScript2 varchar(Max),
@ConteudoScript3 varchar(Max),@ConteudoScript4 varchar(Max),@ConteudoScript5 varchar(Max), @DataInicial DateTime, 
@CodEmpresa int, @Texto Varchar(Max)

Set @DataInicial = '01/01/2016' -- Data da Ultima Atualização
------------------------------------------------------------------------------------------------------------------------
if (DB_NAME() not Like '%MakroContabil%')
	Begin
		Declare CrScript cursor local static for
		Select S.Pk, S.Tipo, Coalesce(S.NomePc, '')
		From MakroContabil.dbo.Script S 
		Where (S.Situacao = 1) and --1 = Ativa
		Coalesce(S.NomePc, '') = '' and
		S.Tipo= 1 and 
		(((S.DataCriacao >= @DataInicial) and
		(S.DataAlteracao is null)) or
		(S.DataAlteracao >= @DataInicial)) and
    (FkCadEmpresa is null)
		Order By S.DataCriacao, S.Pk

		Open CrScript
		Fetch next from CrScript into @PkScript, @Tipo, @NomePc
		While @@Fetch_Status = 0
			Begin
          Print (@PkScript)

					Begin try
						Select 
						@ConteudoScript1 = Conteudo, 
						@ConteudoScript2 = Conteudo2,					
						@ConteudoScript3 = Conteudo3,
						@ConteudoScript4 = Conteudo4,
						@ConteudoScript5 = Conteudo5
						From MakroContabil.dbo.Script
						Where (Pk = @PkScript)

						If @ConteudoScript1 is not null
							Begin
								If @ConteudoScript1 Like '%sp_dropserver%'
									Begin
											Print 'Não pode Alterar nada do Linked Server'
									End
								Else 
									Begin
										exec (@ConteudoScript1)
									End		                      
							End
						Else
							Begin
								Print( @NomePc + ' Select retornou nulo no conteudo 1')
							End
			  
						If @ConteudoScript2 is not null
							Begin	
							If @ConteudoScript2 Like '%sp_dropserver%'
									Begin
											Print 'Não pode Alterar nada do Linked Server'
									End
								Else 
									Begin
										exec (@ConteudoScript2)
									End		
								
							End
						Else
							Begin
								Print( @NomePc + ' Select retornou nulo no conteudo 2')       			  
							End

						If @ConteudoScript3 is not null
							Begin
								If @ConteudoScript3 Like '%sp_dropserver%'
									Begin
											Print 'Não pode Alterar nada do Linked Server'
									End
								Else 
									Begin
										exec (@ConteudoScript3)
									End		
								
							End
						Else
							Begin
								Print( @NomePc + ' Select retornou nulo no conteudo 3')         			  
							End

						If @ConteudoScript4 is not null
							Begin
								If @ConteudoScript4 Like '%sp_dropserver%'
									Begin
											Print 'Não pode Alterar nada do Linked Server'
									End
								Else 
									Begin
										exec (@ConteudoScript4)
									End		
								
							End
						Else
							Begin
								Print( @NomePc + ' Select retornou nulo no conteudo 4')         			          			  
							End

						If @ConteudoScript5 is not null
							Begin
								If @ConteudoScript5 Like '%sp_dropserver%'
									Begin
											Print 'Não pode Alterar nada do Linked Server'
									End
								Else 
									Begin
										exec (@ConteudoScript5)
									End		
								
							End
						Else
							Begin
								Print( @NomePc + ' Select retornou nulo no conteudo 5')         			         			  
							End

					End Try
					------------------------------------------------------------------------------------------------------------------------------------
  				----------------------------------------------------------------------------------------------------------------------------------
					Begin Catch
						If @@trancount > 0
							Begin
								Rollback Transaction
							End
					End Catch
  	

  			----------------------------------------------------------------------------------------------------------------------------------
				Fetch next from CrScript into @PkScript, @Tipo, @NomePc
			End
		Close CrScript
		Deallocate CrScript
    
    Exec PcAtualizaScriptPastas
		
    Declare CrProcedure Cursor local static for
		Select Distinct Mc.name, Ob.Name
		From MakroContabil.sys.Objects Mc
		 left join sys.objects OB on (Mc.name = OB.name)
		 inner join MakroContabil.SYS.sql_modules MD on (Mc.object_id = MD.object_id) 
		 left join SYS.sql_modules MO on (MO.object_id = OB.object_id) 
		Where (Mc.modify_date >= @DataInicial ) and 
		(Mc.name not in ('FCreateToAlter', 'FAlterToCreate')) and
		(Mc.[type] in('FN', 'P', 'TF', 'TR', 'V')) and 
		(Md.definition <> Mo.definition) or (Ob.name is null) or (Mo.definition is NULL )
		Order By Mc.name

		Open CrProcedure
		Fetch next from CrProcedure Into @NomePc, @NomePCBanco
		While @@Fetch_Status = 0
			Begin
				Set @Texto = ''

				Select @Texto = M.definition
				From MakroContabil.SYS.sql_modules M
				inner join MakroContabil.sys.Objects O on (O.object_id = M.object_id) 
				Where (O.Name = @NomePc)
        if @NomePCBanco is not null Set @Texto = dbo.FCreateToAlter(@Texto)
				Print(@NomePc)
				Exec (@Texto)

				Fetch next from CrProcedure Into @NomePc, @NomePCBanco
			End
		Close CrProcedure
		Deallocate CrProcedure
	end
else
	begin
		Print('NÃO EXECUTE ESSA ROTINA EM NENHUM DOS BANCOS MAKROCONTABIL! Att Paulo Morais.')
	end 

