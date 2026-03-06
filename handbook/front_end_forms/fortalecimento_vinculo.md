## Documentação Técnica: Fortalecimento de Vínculos e Benefícios (Conecta Raros)

### 1. Visão Geral

Este módulo gerencia a participação dos membros em serviços de convivência e o histórico de concessão de benefícios eventuais. Toda a lógica de seleção é baseada em **metadados dinâmicos** para permitir expansão via banco de dados.

### 2. Arquitetura de Dados (Database & Structs)

As seleções de serviços, unidades e tipos de benefícios devem ser validadas contra tabelas de domínio.

#### **A. Participação em Serviços e Programas**

**Tabelas de Domínio:**

* `dominio_servico_vinculo`: (`id`, `descricao`, `ativo`).
* `dominio_unidade_realizacao`: (`id`, `descricao`, `ativo`).

**Struct de Registro:**

```rust
struct ParticipacaoServico {
    id: Option<Uuid>,
    membro_id: Uuid, // FK Composição Familiar
    servico_id: Uuid, // FK dominio_servico_vinculo
    unidade_id: Uuid, // FK dominio_unidade_realizacao
    data_ingresso: Date,
    data_desligamento: Option<Date>,
}

```

#### **B. Benefícios Eventuais (Metadata-Driven)**

**Tabela de Domínio:** `dominio_tipo_beneficio`

* `id`: UUID (PK).
* `descricao`: String (ex: "Auxílio Natalidade").
* `exige_certidao`: Boolean (Valida campo de nascimento).
* `exige_cpf_falecido`: Boolean (Valida campo de óbito).

**Struct de Registro:**

```rust
struct RegistroBeneficio {
    id: Option<Uuid>,
    id_familia: Uuid,
    data_concessao: Date,
    tipo_beneficio_id: Uuid, // FK dominio_tipo_beneficio
    registro_nascimento: Option<String>,
    cpf_falecido: Option<String>,
}

```

---

### 3. Regras de Negócio e Lógica do BFF

#### **A. Escopo CRU (Create, Read, Update)**

* O sistema deve permitir a persistência, leitura e atualização dos registros.
* **Proibição de Delete:** Registros de benefícios e participações não podem ser apagados por questões de auditoria governamental.

#### **B. Validações de Integridade**

* **Cronologia de Datas:** Na participação em serviços, a `data_desligamento` (se preenchida) deve ser posterior à `data_ingresso`.
* **Vínculo de Membro:** O `membro_id` deve pertencer obrigatoriamente à família em edição.
* **Validação Dinâmica de Benefícios:** Antes de salvar um benefício, o BFF deve consultar os flags `exige_certidao` e `exige_cpf_falecido` na tabela de domínio para validar os campos correspondentes.

#### **C. Agregação no GET (Read)**

* O BFF deve realizar o `JOIN` (ou busca em cache) para retornar a descrição textual dos serviços e benefícios, evitando que o frontend exiba apenas UUIDs.
* Retornar o histórico em ordem cronológica decrescente.

---

### 4. Contrato da API Sugerido

* **GET `/api/v1/servicos-vinculo/{id_familia}**`: Retorna histórico de participações + opções das tabelas de domínio.
* **POST/PUT `/api/v1/servicos-vinculo**`: Salva ou atualiza a participação de um membro.
* **POST/PUT `/api/v1/beneficios**`: Salva benefício aplicando as regras dinâmicas de validação.

---


> "Gemini, utilize este `.md` para criar as rotas de Fortalecimento de Vínculos e Benefícios Eventuais. Implemente a lógica **Metadata-Driven** para os benefícios: o BFF deve olhar os booleanos na tabela de domínio para decidir quais campos validar. Mantenha o padrão de **Structs** e apenas operações **CRU**."
