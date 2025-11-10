#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"  
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH" 

/*/{Protheus.doc} LinhaPrdMVC
Modulo MVC para cadastro de Linhas de Produtos.
@type function
@version  1.0
@author matheus.amorim
@since 11/10/2025
@return variant, return_description
/*/
User Function LinhaPrdMVC()

    //Variavel que representa a tela
    local oBrowse

    //Criação do objeto do tipo Browse/Nova tela
    oBrowse := FwmBrowse():NEW

    //Definir qual a tabela que será apresentada no Browse
    oBrowse:SetAlias('Z1A')

    oBrowse:AddLegend( "Z1A->Z1A_ATIVO == '1'", "GREEN", "COR É VERDE")
    oBrowse:AddLegend( "Z1A->Z1A_ATIVO == '0'", "RED", "COR É VERMELHO")

    //Definir o título ou a descrição que será apresentado no Browse
    oBrowse:SetDescription("Cadastro de Linha de Produtos")

    //Realiza a ativação do Browse
    oBrowse:Activate()

RETURN

Static Function MenuDef()
    Local aRotina := {}

    //=============================================================================================================
    //O ViewDef deve ser referenciado sempre de um fonte, pois ele é a função reponável pela interface da aplicação
    //=============================================================================================================
    AADD(aRotina, {"Pesquisar" , 'PesqBrw'         , 0, 1, 0, Nil })
    AADD(aRotina, {"Visualizar", 'VIEWDEF.LinhaPrdMVC', 0, 2, 0, Nil })
    AADD(aRotina, {"Incluir"   , 'VIEWDEF.LinhaPrdMVC', 0, 3, 0, Nil })
    AADD(aRotina, {"Alterar"   , 'VIEWDEF.LinhaPrdMVC', 0, 4, 0, Nil })
    AADD(aRotina, {"Excluir"   , 'VIEWDEF.LinhaPrdMVC', 0, 5, 0, Nil })
    
Return aRotina

Static Function ModelDef()
    Local oModel    // Objeto do modelo de dados
    Local oStruZ1A  // Objeto da estrutura de dados

    //Cria a estrutura que será utilizada no modelo
    oStruZ1A := FWFormStruct(1, "Z1A") //1-Para modelo de dados (Model) e 2-para View

    //Cria o objeto do modelo de dados, nome deve ser único, armazena somente 10 caracteres
    oModel := MPFormModel():New('MODELZ1A')

    //Adiciona ao modelo um componete do tipo formulario
    oModel:AddFields('Z1AMASTER', /*OWNER*/ ,oStruZ1A)

    oModel:SetPrimaryKey({'Z1A_FILIAL'})

    //Define a decrição para o modelo (Model)
    oModel:SetDescription("Modelo de Dados - Cadastro de Metas de Faturamento")

Return oModel

Static Function ViewDef()
    Local oModel    // Objeto do modelo de dados
    Local oStruZ1A  // Objeto da estrutura de dados
    Local oView     // Objeto de view

    //Cria o objeto do modelo de dados com base no ModelDef do fonte informado
    oModel := FwLoadModel('LinhaPrdMVC')

    //Cria a estrutura do view
    oStruZ1A := FWFormStruct(2,"Z1A")  

    //Cria o objeto de view
    oView :=FwFormView():New()

    //Define qual é o modelo de dados que será utilizado na View
    oView:SetModel(oModel)

    //Adiciona no View um componente do tipo formulário (enchoice), vinculando o formulário da view com o formulario do modelo
    oView:AddField('VIEW_Z1A',oStruZ1A,'Z1AMASTER')

    //Cria um box horizontal para receber o elemento da View
    oView:CreateHorizontalBox("TELA", 100)

    oView:EnableTitleView("VIEW_Z1A", "Cadastro de Linha de Faturamento - View")

    // Relaciona o box com a view criada para apresentação
    oView:SetOwnerView('VIEW_Z1A' , 'TELA')

Return oView
