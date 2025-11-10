#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
 

Class MonitorMetaFat FROM LongNameClass
    Static Method BuscaDados(oFiltros, cTipo, cSubTipo)
    Static Method BuscaDetalhes(oFiltros, nPagina)
    Static Method ValidaPropriedades(oFiltros)
EndClass

Method BuscaDados(oFiltros, cTipo, cSubTipo) Class MonitorMetaFat
    Local aArea    := FWGetArea()
    Local aFaturado  := {}
    Local aMeta      := {}
    Local aFilial    := {}
    Local dDataIni   := FirstDate(dDataBase)
    Local dDataFin   := LastDate(dDataBase)
    Local cJsonDados := ""
    Local nIndSerie  := 0
    Local nPosTag    := 0
    Local cQuery     := ""
    Local nMeta      := 0
    Local nFaturado  := 0
    Local oDados     := JsonObject():New()
    Local oJsonRet   := JsonObject():New()
 
    oJsonRet["alturaMinimaWidget"] := "350px"
    oJsonRet["alturaMaximaWidget"] := "500px"
    oJsonRet["categorias"] := {}
    oJsonRet["series"]     := {}
    oJsonRet["tags"]       := {}

    cQuery := montaQuery(oFiltros, @dDataIni, @dDataFin)

    TCQuery cQuery New Alias "QRY_FAT"

    //Salva os dados da QUERY nas variaveis 
    while ! QRY_FAT->(EoF())
         nMeta     := QRY_FAT->META
         nFaturado := QRY_FAT->FATURADO
         QRY_FAT->(DbSkip())
    enddo

    aAdd(aFaturado,nFaturado)
    aAdd(aMeta,nMeta)
    aAdd(aFilial,"")


    /*Exibe a TAG contemplando o filtro de data inicial e data final informadas*/
    PCPMonitorUtils():AdicionaTagMonitor(oJsonRet["tags"],@nPosTag,"po-icon-calendar",PCPMonitorUtils():FormataData(dToS(dDataIni),5) + " - " + PCPMonitorUtils():FormataData(dToS(dDataFin),5))

    /*Exibe a TAG com a filial selecionada*/
    if oFiltros["FILIAL"] == "01"
        PCPMonitorUtils():AdicionaTagMonitor(oJsonRet["tags"],@nPosTag,"po-icon-star-filled","Matriz")
    elseif oFiltros["FILIAL"] == "02"
        PCPMonitorUtils():AdicionaTagMonitor(oJsonRet["tags"],@nPosTag,"po-icon-star-filled","São Paulo")
    endif 

    /*Adiciona as SERIES ao monitor com os dados da query*/
    PCPMonitorUtils():AdicionaSerieGraficoMonitor(oJsonRet["series"],@nIndSerie,"rgba(126,226,148,1)",aFaturado,"Faturado")
    PCPMonitorUtils():AdicionaSerieGraficoMonitor(oJsonRet["series"],@nIndSerie,"rgba(241,143,136,1)",aMeta,"Meta")
    PCPMonitorUtils():AdicionaCategoriasGraficoMonitor(oJsonRet["categorias"], aFilial)

    cJsonDados := oJsonRet:ToJson()
     
    /*Libera os objetos e limpa o ambiente*/
    QRY_FAT->(DbCloseArea())
    FreeObj(oDados)
    FreeObj(oJsonRet)
    FwFreeArray(aFaturado)
    FwFreeArray(aMeta)
    FwFreeArray(aFilial)
    FWRestArea(aArea)
Return cJsonDados
 

 //Dados ao Clicar no gráfico 
Method BuscaDetalhes(oFiltros, nPagina) Class MonitorMetaFat
    Local cAliasQry  := GetNextAlias()
    Local cJsonDados := ""
    Local cQuery     := ""
    Local dDataIni   := FirstDate(dDataBase)
    Local dDataFin   := LastDate(dDataBase)
    Local lExpResult := .F.
    Local nPosTag    := 0
    Local nStart     := 0
    Local oDados     := JsonObject():New() 
 
    Default nPagina    := 1
    Default nTamPagina := 20
 
    If nPagina == 0
        lExpResult := .T.
    EndIf
     
    cQuery := montaQuery(oFiltros, @dDataIni, @dDataFin)

    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasQry,.F.,.F.)
 
    oDados["items"]   := {}
    oDados["columns"] := montaColun(lExpResult)
    oDados["headers"] := {}
    oDados["tags"] := {}
    oDados["canExportCSV"] := .T.
 
    PCPMonitorUtils():AdicionaTagMonitor(oDados["tags"],@nPosTag,"po-icon-calendar",dDataIni + " - " + dDataFin)
 
    If !Empty(oFiltros["SERIE"])
        PCPMonitorUtils():AdicionaTagMonitor(oDados["tags"],@nPosTag,"po-icon-filter",oFiltros["SERIE"])
    EndIf
 
    If nPagina > 1
        nStart := ( (nPagina-1) * nTamPagina )
        If nStart > 0
            (cAliasQry)->(DbSkip(nStart))
        EndIf
    EndIf
 

    oDados["hasNext"] := (cAliasQry)->(!Eof())
    (cAliasQry)->(dbCloseArea())
    cJsonDados := oDados:toJson()
    FreeObj(oDados)
Return cJsonDados

Static Function montaColun(lExpResult)
    Local aColunas   := {}
    Local aLabels    := {}
    Local nIndice    := 0
    Local nIndLabels := 0
 
    //Tipos de label
    PCPMonitorUtils():AdicionaLabelsColunaTabela(aLabels,@nIndLabels,"1","rgba(255, 30, 0, 1)","Faturado","rgb(0,0,0)")
    PCPMonitorUtils():AdicionaLabelsColunaTabela(aLabels,@nIndLabels,"2","rgb(126,226,148)","Meta","rgb(255,255,255)")

    //Colunas das tabelas
    PCPMonitorUtils():AdicionaColunaTabela(aColunas,@nIndice,"C2_FILIAL","Filial","string",lExpResult)
    PCPMonitorUtils():AdicionaColunaTabela(aColunas,@nIndice,"FATURADO","FATURADO","string",.T.)
    PCPMonitorUtils():AdicionaColunaTabela(aColunas,@nIndice,"ANO","ANO","string",.T.)
    PCPMonitorUtils():AdicionaColunaTabela(aColunas,@nIndice,"MES","MES","string",lExpResult)
    PCPMonitorUtils():AdicionaColunaTabela(aColunas,@nIndice,"META","META","string",.T.)
Return aColunas
 
Static Function montaQuery(oFiltros, dDataIni, dDataFin)
    Local cQuery    := ""
 
    cQuery := " SELECT "
    cQuery += "     CAST(SUM(SD2.D2_VALBRUT - SD2.D2_DESC) AS DECIMAL(15,2)) AS 'FATURADO' "
    cQuery += "     ,MONTH(SD2.D2_EMISSAO) AS 'MES' "
    cQuery += "     ,YEAR(SD2.D2_EMISSAO) AS 'ANO' "
    cQuery += "     ,CAST(Z2A.Z2A_META AS DECIMAL(15,2)) AS 'META' "
    cQuery += " FROM " +RetSqlName("SD2")+ " SD2 "
    cQuery += " LEFT JOIN " +RetSqlName("Z2A")+ " Z2A ON Z2A.Z2A_FILIAL = SD2.D2_FILIAL AND Z2A.Z2A_ANO = YEAR(SD2.D2_EMISSAO) AND Z2A.Z2A_MES = MONTH(SD2.D2_EMISSAO) AND Z2A.D_E_L_E_T_ = '' "
    cQuery += " WHERE SD2.D_E_L_E_T_ = '' "
    cQuery += "     AND SD2.D2_FILIAL = '" + oFiltros["FILIAL"] + "' " 
    cQuery += "     AND SD2.D2_TES >= 501 " //incluir tes prd
    cQuery += "     AND SD2.D2_TIPO = 'N'  "
    cQuery += "     AND SD2.D2_EMISSAO <= '" + dToS(dDataFin) +"' "
    cQuery += "     AND SD2.D2_EMISSAO >= '" + dToS(dDataIni) +"' "
    cQuery += " GROUP BY "
    cQuery += "     YEAR(SD2.D2_EMISSAO) "
    cQuery += "     ,MONTH(SD2.D2_EMISSAO) "
    cQuery += "     ,Z2A.Z2A_META "

Return cQuery
 
Method ValidaPropriedades(oFiltros) Class MonitorMetaFat
    Local aRetorno := {.T.,""}
 
    PCPMonitorUtils():ValidaPropriedadeFilial(oFiltros["FILIAL"],aRetorno)
 
    If aRetorno[1] .And. oFiltros["TIPOPERIODO"] == "X"
        If !oFiltros:HasProperty("PERIODO") .Or. oFiltros["PERIODO"] == Nil .Or. Empty(oFiltros["PERIODO"])
            aRetorno[1] := .F.
            aRetorno[2] := "Deve ser informada a quantidade de dias para o período personalizado."
        EndIf
    EndIf
Return aRetorno
