--Select * From Relatorios

--Select * From Modulos Where Url = 'FormPessoal/Empregados/Outros/MRemuneracaoSistemaAnterior/MRemuneracaoSistemaAnterior.aspx'

		Insert Relatorios
		(Pk, Departamento, NomeTecnico, NomePopular, Finalidade, SaibaMais)
		Select 397,
		1,
		--NomeTecnico
		'MRemuneracaoSistemaAnterior',
		--NomePopular
		'Maior Remunera��o Sistema Anterior',
		--Finalidade
		'Cadastro de Maior Remunera��o do empregado que n�o comp�e a folha de pagamento e ser� base para apura��o da Maior Remunera��o',
		--SaibaMais
		null
		
--Select * From RelatoriosModulos

		Insert RelatoriosModulos
		(FkRelatorios, FkModulos)
	  Select 397, 961

		Select * From RelatoriosModulos Where FkModulos = 829

		Update RelatoriosModulos Set FkRelatorios = 330 Where Pk = 4332
	

    Select * From Relatorios Where NomeTecnico = 'ProcessoReferenciado'
		Select * From RelatoriosModulos Where FkRelatorios = 712
		Select * From RelatoriosModulos Where FkModulos = 1109
		Select * From Modulos Where Pk = 1109

		Update RelatoriosModulos Set FkRelatorios = 328 Where FkModulos = 1109

		Select dbo.FPassaParametrosRelatorio(2532, 'PkRendDesc') ValorParametro

		Select dbo.FPassaParametrosRelatorio(2532, 'Fkc') ValorParametro

		Select * From PassaParametrosRelatorio Where PkUsuario = 2532
		And ValorParametro = '3595'

		Select * From UsuariosPreferencia Where FkUsuario = 2532
		And Modulo = 'RendDesc'

		Select dbo.FPreferencia(@PkUsuario, 'CadSindicato', 'Codigo', 2) ValorParametro

Select * From UsuariosPreferencia Where Valor = '2533'