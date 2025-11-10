#include "TOTVS.CH"
#include "FWMVCDef.ch"

/*/{Protheus.doc} CallMVCCNPJ
Consulta dados de empresa pelo CNPJ via API e cria o modelo MVC automaticamente para inclusão.
@type function
@author matheus.amorim
@since 10/10/2025
/*/
User Function CallMVCCNPJ()
    Local cCnpj  := FWInputBox("Informe o CNPJ do cliente:", "")
    Local oModel := NIL
    Local cAlias := "SA1"
    Local lAchou := .F.

    cCnpj := U_OnlyCharNum(cCnpj)

    If Empty(cCnpj)
        Return
    EndIf

    /*Verifica se já existe cadastro*/
    DbSelectArea(cAlias)
    SA1->(DbSetOrder(3)) 
    lAchou := SA1->(DbSeek(xFilial("SA1") + cCnpj))

    If lAchou
        MsgInfo("CNPJ já cadastrado para o cliente: " + SA1->A1_NOME)
        return
    EndIf

    // Executa a consulta dentro do loading
    FWMsgRun( NIL, {|| oModel := LoadCNPJModel(cCnpj) }, 'Consultando a API', 'Buscando Dados do Cliente...')
Return

Static Function LoadCNPJModel(cCnpj)
    Local cURL      := ""
    Local cRet      := ""
    Local oRest     := NIL
    Local oJSON     := NIL
    Local oModel    := NIL
    Local oSA1Mod   := NIL
    Local aHeaders  := { ;
        {"Content-Type", "application/json; charset=utf-8"}, ;
        {"Accept", "application/json"} ;
    }
    Local aInscricoesEstaduais := {}
    Local aAtividadesSegundarias := {}
    Local aInscricoesSuframa := {}
    Local bInscricaoEstadualAtiva := .F.
    Local nAux := 0
    Local nDivisaoCnae := 0
    Local nDivisaoSegundaria := 0
    
    /*Se existe WS_TOKEN utiliza a comercial, se não, publica*/
    Local cToken := superGetMV("WS_TOKEN", .F., "")
    If !Empty(cToken)
        cURL := "https://comercial.cnpj.ws/cnpj/"
        AAdd(aHeaders, "x_api_token: " + AllTrim(cToken))
    else
        cURL := "https://publica.cnpj.ws/cnpj/"
    EndIf

    oRest := FWRest():New(cURL + AllTrim(cCnpj))
    oRest:setPath("")

    If oRest:Get(aHeaders)
        cRet := oRest:GetResult()

        If !Empty(cRet)
            cRet := FWNoAccent(DecodeUtf8(cRet))
            cRet := StrTran(cRet, '\/', '/')
            cRet := StrTran(cRet, ':null', ': ""')
            cRet := StrTran(cRet, '"self"', '"_self"')

            oJSON := JsonObject():New()
            oJSON:FromJson(cRet)
        Else
            Alert("Resposta vazia da API.")
            Return NIL
        EndIf
    Else
        //if oRest:GetLastError() 
        Alert("Dados inválidos ou CNPJ não encontrado.")
        Return NIL
    EndIf

    FreeObj(oRest)

    If oJSON == NIL .or. Empty(oJSON["razao_social"])
        Alert("Dados inválidos ou CNPJ não encontrado.")
        Return NIL
    EndIf

    oModel := FWLoadModel("CRMA980")
    oModel:SetOperation(MODEL_OPERATION_INSERT)
    oModel:Activate()

    oSA1Mod := oModel:getModel("SA1MASTER")

    oSA1Mod:setValue("A1_PESSOA"    ,"J")
    oSA1Mod:setValue("A1_CGC"       ,cCnpj)
    oSA1Mod:setValue("A1_NOME"      ,SubStr(oJSON["razao_social"], 1, 45))
    oSA1Mod:setValue("A1_NREDUZ"    ,SubStr(oJSON["estabelecimento"]["nome_fantasia"], 1, 20))
    oSA1Mod:setValue("A1_PAIS"      ,"1") //teste é 105, prd é 1
    oSA1Mod:setValue("A1_CEP"       ,oJSON["estabelecimento"]["cep"])
    oSA1Mod:setValue("A1_END"       ,SubStr(oJSON["estabelecimento"]["logradouro"], 1, 70) + ", " + oJSON["estabelecimento"]["numero"])
    oSA1Mod:setValue("A1_BAIRRO"    ,SubStr(oJSON["estabelecimento"]["bairro"], 1, 40))
    oSA1Mod:setValue("A1_EST"       ,oJSON["estabelecimento"]["estado"]["sigla"])
    oSA1Mod:setValue("A1_EMAIL"     ,SubStr(oJSON["estabelecimento"]["email"], 1, 100))
    oSA1Mod:setValue("A1_DDD"       ,oJSON["estabelecimento"]["ddd1"])
    oSA1Mod:setValue("A1_TEL"       ,oJSON["estabelecimento"]["telefone1"])
    oSA1Mod:setValue("A1_CONTATO"   ,oJSON["estabelecimento"]["ddd2"] + " " + oJSON["estabelecimento"]["telefone2"])
    oSA1Mod:setValue("A1_COD_MUN"   ,SubStr(Alltrim(AllToChar(oJSON["estabelecimento"]["cidade"]["ibge_id"])), 3, 5))
    oSA1Mod:setValue("A1_CNAE"      ,AllTrim(oJSON["estabelecimento"]["atividade_principal"]["subclasse"]))

    /*Verifica Optante Simples Nacional caso exista*/
    if AllToChar(oJSON["simples"]) != ""
        if AllTrim(oJSON["simples"]["simples"]) == "Sim"
            oSA1Mod:setValue("A1_SIMPNAC", "1")
        elseif AllTrim(oJSON["simples"]["simples"]) == "Nao"
            oSA1Mod:setValue("A1_SIMPNAC", "2")
        endif
    else
        oSA1Mod:setValue("A1_SIMPNAC", "2")
    endif
    
    /*Verifica a inscrição estadual conforme estado do CNPJ*/
    aInscricoesEstaduais := oJSON["estabelecimento"]["inscricoes_estaduais"]
    for nAux := 1 to Len(aInscricoesEstaduais)
        if aInscricoesEstaduais[nAux]["estado"]["sigla"] == oJSON["estabelecimento"]["estado"]["sigla"]
            oSA1Mod:setValue("A1_INSCR",AllTrim(AllToChar(oJSON["estabelecimento"]["inscricoes_estaduais"][nAux]["inscricao_estadual"])))
        endif

        /*Guarda se existe uma inscrição ativa*/
        if aInscricoesEstaduais[nAux]["ativo"] == .T.
            bInscricaoEstadualAtiva = .T.
        endif
    next

    /*Verifica o TIPO conforme a divisão CNAE*/
    nDivisaoCnae :=  oJSON["estabelecimento"]["atividade_principal"]["divisao"]
    if nDivisaoCnae >= "01" .AND. nDivisaoCnae <= "03"
        oSA1Mod:setValue("A1_TIPO", "L")
    elseif nDivisaoCnae >= "45" .AND. nDivisaoCnae <= "47"
        oSA1Mod:setValue("A1_TIPO", "R")
    else
        oSA1Mod:setValue("A1_TIPO", "F")
    endif

    /*Verifica se o cliente possui inscrição estadual e um CNAE que seja REVENDEDOR ou CONSUMIDOR FINAL para setar Contribuinte = SIM*/
    aAtividadesSegundarias := oJSON["estabelecimento"]["atividades_secundarias"]
    nAux := 0
    if bInscricaoEstadualAtiva == .T.
        if nDivisaoCnae >= "05" .AND. nDivisaoCnae <= "47"
            oSA1Mod:setValue("A1_CONTRIB", "1")
        else
            for nAux := 1 to Len(aAtividadesSegundarias)
                nDivisaoSegundaria := oJSON["estabelecimento"]["atividades_secundarias"][nAux]["divisao"]
                if nDivisaoSegundaria >= "05" .AND. nDivisaoSegundaria <= "33" .OR. nDivisaoSegundaria >= "45" .AND. nDivisaoSegundaria <= "47"
                    oSA1Mod:setValue("A1_CONTRIB", "1")
                endif
            next
        endif    
    else
        oSA1Mod:setValue("A1_CONTRIB", "2")   
    endif


    /*Verifica se o cliente possui inscrição ativa no suframa*/
    aInscricoesSuframa := oJSON["estabelecimento"]["inscricoes_suframa"]
    nAux := 0
    for nAux := 1 to Len(aInscricoesSuframa)
        if oJSON["estabelecimento"]["inscricoes_suframa"][nAux]["ativo"] == .T.
            oSA1Mod:setValue("A1_SUFRAMA"  , oJSON["estabelecimento"]["inscricoes_suframa"][nAux]["inscricao_suframa"])
            oSA1Mod:setValue("A1_CODMUN"   ,"0" + Alltrim(AllToChar(oJSON["estabelecimento"]["cidade"]["siafi_id"])))
        endif
    next

    /*Verifica o TPJ do cliente 3=MEI, 2=Pequeno Porte, 1=Micro Empresa, demais deixa em */  
    if oJSON["porte"]["id"] == "03"
        oSA1Mod:setValue("A1_TPJ", "2")
    elseif oJSON["porte"]["id"] == "02"
        oSA1Mod:setValue("A1_TPJ", "1")
    else
        if AllToChar(oJSON["simples"]) != "" 
            if AllToChar(oJSON["simples"]["mei"]) == "Sim"
                oSA1Mod:setValue("A1_TPJ", "3")
            endif
        endif
    endif

    oSA1Mod:Activate()

    FWExecView("Inclusão via API", "CRMA980", MODEL_OPERATION_INSERT, , , , , , , , , oModel)
    FreeObj(oJSON)
Return 