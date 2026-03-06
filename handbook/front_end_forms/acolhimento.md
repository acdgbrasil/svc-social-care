## Documentação Técnica: Histórico de Acolhimento e Afastamento (Conecta Raros)

### 1. Visão Geral

Este módulo registra eventos de separação do convívio familiar, incluindo acolhimento institucional, guarda por terceiros e afastamentos por internação ou prisão. O foco aqui é a **integridade referencial e lógica** entre os eventos e os membros da família.

### 2. Estrutura de Dados (Structs)

As informações são divididas em três blocos lógicos:

#### **A. Acolhimento Individual**

```rust
struct RegistroAcolhimento {
    id: Option<Uuid>,
    membro_id: Uuid,        // Obrigatório: Link com Composição Familiar
    data_inicio: Date,
    data_fim: Option<Date>, // Pode ser nulo se o acolhimento for atual
    motivo: String,         // Texto livre ou seleção (Validação Pesada)
}

```

#### **B. Situações Coletivas e de Guarda**

```rust
struct SituacoesEspecificas {
    id_familia: Uuid,
    relato_perda_domicilio: Option<String>, // Contexto de catástrofe/fatalidade
    relato_guarda_terceiros: Option<String>, // Guarda legal ou informal
}

```

#### **C. Checklist de Afastamento**

```rust
struct AfastamentoConvivio {
    id_familia: Uuid,
    membro_adulto_prisao: bool,
    adolescente_internacao_medida: bool,
}

```

---

### 3. Validações Pesadas (Server-Side Logic)

Diferente de outras telas, o BFF deve realizar as seguintes verificações antes de persistir (POST/PUT):

* **Validação de Datas:** É mandatório que 
$$DataFim \ge DataInicio$$


. O sistema deve rejeitar o registro caso a data de fim seja anterior ao início.
* **Validação por Ciclo de Vida:**
* **Guarda por Terceiros:** O relato de guarda por terceiros deve ser validado contra a composição familiar. Se houver relato, a família **deve** possuir pelo menos um membro com idade $< 18$ anos.
* **Internação Socioeducativa:** A flag `adolescente_internacao_medida` só pode ser `true` se houver pelo menos um membro na família com idade entre $12$ e $18$ anos incompletos.


* **Vínculo de Membro:** O `membro_id` enviado no acolhimento deve obrigatoriamente pertencer ao `id_familia` da transação para evitar injeção de dados de outras famílias.

---

### 4. Operações (CRU)

* **Create (POST):** Registra um novo evento de acolhimento ou atualiza o status de afastamento da família.
* **Read (GET):** Retorna o histórico completo. No caso de acolhimentos ativos (sem `data_fim`), o BFF deve marcar um status visual de "Em curso".
* **Update (PUT):** Permite fechar um acolhimento (adicionando a `data_fim`) ou corrigir relatos textuais.
* **Delete:** Operação **não implementada** para garantir a rastreabilidade de medidas protetivas.

---

### 5. Exemplo de Contrato JSON (BFF Output)

```json
{
  "id_familia": "uuid-da-familia",
  "acolhimentos_individuais": [
    {
      "membro_nome": "Davi Costa...", 
      "inicio": "2024-05-25",
      "fim": null,
      "motivo": "Negligência familiar"
    }
  ],
  "relatos": {
    "perda_domicilio": "Família perdeu a casa em enchente em Jan/2026",
    "guarda_terceiros": null
  },
  "flags": {
    "adulto_prisao": false,
    "adolescente_internacao": true
  }
}

```

> "Gemini, utilize o arquivo `acolhimento.md` para criar o BFF. A regra principal é a **validação cruzada**: o servidor não deve aceitar registros de internação de adolescentes ou guarda de terceiros se a composição familiar (pela idade dos membros) não condizer com a situação. Aplique o padrão de **Structs** e suporte apenas **CRU**."
