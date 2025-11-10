# MVC-Linha-de-Produto
Módulo customizado para cadastro de Linha de Produto.

## Tabela Customizada

Z1A - Linha de Produto

## Campos

| Campo       |   Tipo   | Tamanho | Decimal |      Formato         |    Lista Opções       |              Validação          | Obrigatório |
|-------------|----------|---------|---------|----------------------|-----------------------|---------------------------------|-------------|
|Z1A_FILIAL   |Caracter  | 2       | 0       | @!                   |                       |                                 |             |
|Z1A_DESC     |Caracter  | 25      | 0       | @!                   |                       | ExistChav("Z1A", M->Z1A_DESC, 1)|    X        |
|Z1A_ATIVO    |Caracter  | 1       | 0       | @!                   | 1=Ativa;0=Desativada; |                                 |    X        |

## Índice

Z1A_DESC 


## Consulta Padrão - Z1AD

- Coluna: Z1A_DESC
- Filtro: `Z1A_ATIVO=='1'`
- Retorno: Z1A->Z1A_DESC

## Obs. Uso

A linha de produto será cadastrada na tabela de produto (SB1) como campo B1_XLIN e será utilizado a consulta padrão para trazer as descrições da linha ativa. 

B1_XLIN validação: `ExistCPO( "Z1A", M->B1_LIN)`
