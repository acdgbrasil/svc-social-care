## Documentação Técnica: Situações de Violência e Violação de Direitos (Conecta Raros)

### 1. Visão Geral

Este módulo registra a ocorrência de violações de direitos e situações de violência no núcleo familiar, monitorando se tais situações ainda persistem no momento do atendimento. A estrutura é **Metadata-Driven**, permitindo a expansão do catálogo de violações diretamente no banco de dados.

### 2. Arquitetura de Dados (Database & Structs)

#### **Tabela de Domínio (Lookup): `dominio_tipo_violacao**`

Armazena o catálogo de situações que podem ser identificadas:

* `id`: UUID (Primary Key).
* `descricao`: String (ex: "Trabalho Infantil", "Violência Psicológica", "Tráfico de Pessoas").
* `exige_descricao`: Boolean (Ativado para o item "Outras").
* `ativo`: Boolean (Para controle de exibição).

#### **Structs de Domínio**

```rust
struct RegistroViolacao {
    tipo_violacao_id: Uuid, // FK para dominio_tipo_violacao
    persiste: bool,        // Resposta Sim/Não da coluna "Situação ainda persiste"
    descricao_detalhada: Option<String>, // Preenchido apenas se exige_descricao for true
}

struct SituacaoViolenciaFamilia {
    id_familia: Uuid,
    violacoes: Vec<RegistroViolacao>,
}

```

---

### 3. Regras de Negócio e Lógica do BFF

#### **A. Escopo de Operação (CRU)**

* **Create/Update:** O sistema deve permitir marcar ou atualizar o status de persistência das situações identificadas.
* **Read:** Recuperação do estado atual de todas as violações vinculadas à família.
* **Nota:** A operação de **Delete** não é permitida por razões de histórico e segurança do domínio.

#### **B. Validação e Integridade**

* **Campo "Outras":** Se o ID do tipo de violação for referente a "Outras", o BFF deve validar obrigatoriamente a presença da `descricao_detalhada`.
* **Lógica de Persistência:** O campo `persiste` deve ser tratado como um booleano obrigatório para cada violação que for enviada no payload.

#### **C. Agregação no GET (Read)**

* O BFF deve realizar o `JOIN` com a tabela de domínio para entregar as descrições textuais ao frontend.
* Caso uma violação nunca tenha sido registrada para a família, o BFF pode retornar o objeto com `persiste: null` ou omiti-lo, dependendo da sua estratégia de frontend.

---

### 4. Contrato da API Sugerido

* **GET `/api/v1/situacoes-violencia/{id_familia}**`: Retorna a lista de violações registradas e as opções disponíveis na tabela de domínio.
* **POST/PUT `/api/v1/situacoes-violencia**`: Salva a lista de violações identificadas, aplicando a regra de descrição para o item "Outras".


> "Gemini, utilize este `.md` para implementar o BFF da tela de Violência e Violação de Direitos. Note que a lista de situações deve ser consumida de uma **tabela de domínio**. No endpoint de gravação, aplique a regra de que o campo 'Descrever' é obrigatório apenas para o tipo 'Outras'. Mantenha o padrão de **Structs** e suporte apenas **CRU**."
