#include "TOTVS.CH"

/*/{Protheus.doc} OnlyCharNum
Remove caracteres especiais e letras, deixando somente númericos na String. 
@type function
@author matheus.amorim
@since 10/13/2025
@param cCnpj, character, Recebe uma String
@return variant, Retorna a String tratada
/*/
User Function OnlyCharNum(cCnpj)
    Local cSomenteNumero := ""
    Local nLen := Len(cCnpj)
    Local i

    for i := 1 to nLen
        if SubStr(cCnpj, i, 1) >= "0" .And. SubStr(cCnpj, i, 1) <= "9"
            cSomenteNumero += SubStr(cCnpj, i, 1)
        endif
    next
Return cSomenteNumero
