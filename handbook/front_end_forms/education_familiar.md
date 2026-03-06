## Documentação Técnica: Condições Educacionais da Família (Conecta Raros)

### 1. Visão Geral

Esta tela gerencia o perfil educacional de cada membro da família e monitora o cumprimento de condicionalidades de programas sociais (como o Bolsa Família).

### 2. Estrutura de Dados (Structs & Enums)

As informações educacionais são vinculadas obrigatoriamente aos membros já cadastrados na **Composição Familiar**.

#### **Definição de Enums Fixos**

* **EscolaridadeCodigo:** `00-Nunca frequentou`, `01-Creche`, `02-Educação Infantil`, `11-1º ano E.F.`, ..., `30-Superior Incompleto`, `99-Outros`.
* **EfeitoCondicionalidade:** `1-Advertência`, `2-Bloqueio`, `3-Suspensão`, `4-Cancelamento`.

#### **Structs de Dados**

```rust
struct PerfilEducacionalMembro {
    membro_id: Uuid, // FK para Composição Familiar
    sabe_ler_escrever: bool,
    frequenta_escola: bool,
    escolaridade: EscolaridadeCodigo,
}

struct OcorrenciaBolsaFamilia {
    id: Option<Uuid>,
    membro_id: Uuid, // Pessoa que sofreu a ocorrência
    data_ocorrencia: Date,
    efeito: EfeitoCondicionalidade,
    suspensao_solicitada: bool,
}

struct CondicoesEducacionais {
    id_familia: Uuid,
    perfis_membros: Vec<PerfilEducacionalMembro>,
    ocorrencias_programas: Vec<OcorrenciaBolsaFamilia>,
}

```

---

### 3. Regras de Negócio e Lógica do BFF

#### **A. Escopo de Operação**

* **CRU (Create, Read, Update):** Suporte total para criação e edição. O **Delete** não é permitido neste domínio.

#### **B. Vinculação de Membros**

* O sistema deve carregar a lista de nomes da **Composição Familiar** para permitir a edição dos dados educacionais e a adição de ocorrências.
* Dados de **Idade** são calculados dinamicamente no BFF a partir da data de nascimento registrada na composição.

#### **C. Agregação de Vulnerabilidades (Output do GET)**

No endpoint de leitura (Read), o BFF deve processar os dados dos membros e retornar a tabela de **Identificação de Vulnerabilidades Educacionais**, consolidando os seguintes contadores:

1. **0 a 5 anos:** Qtd. de pessoas que **não** frequentam escola ou creche.
2. **6 a 14 anos:** Qtd. de pessoas que **não** frequentam escola ou creche.
3. **15 a 17 anos:** Qtd. de pessoas que **não** frequentam escola ou creche.
4. **10 a 17 anos:** Qtd. de pessoas que **não** sabem ler/escrever.
5. **18 a 59 anos:** Qtd. de pessoas que **não** sabem ler/escrever.
6. **60 anos ou mais:** Qtd. de pessoas que **não** sabem ler/escrever.

---

### 4. Contrato da API

* **GET `/api/v1/educacao/{id_familia}**`: Retorna a struct `CondicoesEducacionais` completa, incluindo os cálculos de vulnerabilidade por faixa etária.
* **POST/PUT `/api/v1/educacao**`: Recebe a atualização dos perfis educacionais e a lista de ocorrências de condicionalidades.
