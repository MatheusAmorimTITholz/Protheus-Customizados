# PROTHEUS-Automacao-Cadastro-Cliente-PJ
Automatização do fluxo de cadastro de clientes PJ, preenchendo automaticamente os valores necessários, conforme regras de negócio aplicadas ao configurador de tributos. A automação consome os dados da API CNPJws. 


## API CNPJws

[Documentação da API](https://docs.cnpj.ws/)

Comercial: `GET https://comercial.cnpj.ws/cnpj/{cnpj}`

Nesse endpoint deve enviar o header x_api_token com o token.

Publica `GET https://publica.cnpj.ws/cnpj/{cnpj}`

Na API pública é possível fazer até 3 consultas por minuto de um CNPJ utilizando o método GET. 

## Configuração

Para a user function funcionar no módulo comercial é necessário cadastrar o parâmetro no protheus `WS_TOKEN` informando o TOKEN da API.