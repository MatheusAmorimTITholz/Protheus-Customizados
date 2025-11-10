#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} CRM980MDEF
Ponto de Entrada para incluir botão customizado no módulo de clientes
@type function
@author matheus.amorim
@since 10/13/2025
/*/
User Function CRM980MDEF()
Local aRotina  := {} as array
    aAdd(aRotina,{"Cadastrar CNPJ", 'U_CallMVCCNPJ()', 0, 9})
Return( aRotina )
