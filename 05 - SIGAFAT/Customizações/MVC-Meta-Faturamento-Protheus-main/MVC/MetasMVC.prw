#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"  
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH" 

/*/{Protheus.doc} MetasMVC
Modulo MVC para cadastro de metas de faturamento mensais.
@type function
@version  1.0
@author matheus.amorim
@since 11/6/2025
@return variant, return_description
/*/
User Function MetasMVC()

    //Variavel que representa a tela
    local oBrowse

    //Criação do objeto do tipo Browse/Nova tela
    oBrowse := FwmBrowse():NEW

    //Definir qual a tabela que será apresentada no Browse
    oBrowse:SetAlias('Z2A')

    //Definir o título ou a descrição que será apresentado no Browse
    oBrowse:SetDescription("Cadastro de Metas de Faturamento")

    //Realiza a ativação do Browse
    oBrowse:Activate()

RETURN

Static Function MenuDef()
    Local aRotina := {}

    //=============================================================================================================
    //O ViewDef deve ser referenciado sempre de um fonte, pois ele é a função reponável pela interface da aplicação
    //=============================================================================================================
    AADD(aRotina, {"Pesquisar" , 'PesqBrw'         , 0, 1, 0, Nil })
    AADD(aRotina, {"Visualizar", 'VIEWDEF.MetasMVC', 0, 2, 0, Nil })
    AADD(aRotina, {"Incluir"   , 'VIEWDEF.MetasMVC', 0, 3, 0, Nil })
    AADD(aRotina, {"Alterar"   , 'VIEWDEF.MetasMVC', 0, 4, 0, Nil })
    AADD(aRotina, {"Excluir"   , 'VIEWDEF.MetasMVC', 0, 5, 0, Nil })
    
Return aRotina

Static Function ModelDef()
Local oModel    // Objeto do modelo de dados
Local oStruZ2A  // Objeto da estrutura de dados

//Cria a estrutura que será utilizada no modelo
oStruZ2A := FWFormStruct(1, "Z2A") //1-Para modelo de dados (Model) e 2-para View

//Cria o objeto do modelo de dados, nome deve ser único, armazena somente 10 caracteres
oModel := MPFormModel():New('MODELZ2A')

//Adiciona ao modelo um componete do tipo formulario
oModel:AddFields('Z2AMASTER', /*OWNER*/ ,oStruZ2A)

oModel:SetPrimaryKey({'Z2A_FILIAL'})

//Define a decrição para o modelo (Model)
oModel:SetDescription("Modelo de Dados - Cadastro de Metas de Faturamento")

Return oModel

Static Function ViewDef()
Local oModel    // Objeto do modelo de dados
Local oStruZ2A  // Objeto da estrutura de dados
Local oView     // Objeto de view

//Cria o objeto do modelo de dados com base no ModelDef do fonte informado
oModel := FwLoadModel('MetasMVC')

//Cria a estrutura do view
oStruZ2A := FWFormStruct(2,"Z2A")  

//Cria o objeto de view
oView :=FwFormView():New()

//Define qual é o modelo de dados que será utilizado na View
oView:SetModel(oModel)

//Adiciona no View um componente do tipo formulário (enchoice), vinculando o formulário da view com o formulario do modelo
oView:AddField('VIEW_Z2A',oStruZ2A,'Z2AMASTER')

//Cria um box horizontal para receber o elemento da View
oView:CreateHorizontalBox("TELA", 100)

oView:EnableTitleView("VIEW_Z2A", "Cadastro de Metas - View")

// Relaciona o box com a view criada para apresentação
oView:SetOwnerView('VIEW_Z2A' , 'TELA')

Return oView
