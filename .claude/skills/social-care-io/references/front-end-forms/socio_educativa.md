## Documentação Técnica: Histórico de Medidas Socioeducativas (Conecta Raros)

### 1. Visão Geral

Este módulo registra o histórico e o acompanhamento atual de adolescentes em cumprimento de medidas socioeducativas. O sistema diferencia registros históricos de situações de acompanhamento ativo pelo CREAS.

### 2. Arquitetura de Dados (Database & Structs)

#### **Tabela de Domínio (Lookup): `dominio_tipo_medida**`

Para garantir que o sistema aceite novas modalidades sem mudar o código:

* `id`: UUID (Primary Key).
* `descricao`: String (ex: "Liberdade Assistida (LA)", "Prestação de Serviços à Comunidade (PSC)").
* `ativo`: Boolean.

#### **Structs de Domínio**

```rust
struct RegistroHistoricoMedida {
    id: Option<Uuid>,
    membro_id: Uuid,        // FK Composição Familiar
    medida_tipo_id: Uuid,   // FK dominio_tipo_medida
    numero_processo: String,
    data_inicio: Date,
    data_fim: Date,
}

struct AcompanhamentoAtual {
    membro_id: Uuid,        // FK Composição Familiar
    acompanhado_creas: bool,
}

struct MedidasSocioeducativas {
    id_familia: Uuid,
    historico: Vec<RegistroHistoricoMedida>,
    acompanhamentos_ativos: Vec<AcompanhamentoAtual>,
    detalhes_contatos_psc: Option<String>, // Texto longo para orientadores/locais
}

```

---

### 3. Regras de Negócio e Lógica do BFF

#### **A. Escopo de Operação (CRU)**

* O sistema deve realizar **Create, Read e Update**. A exclusão de histórico jurídico/social é proibida para manter o rastreio protetivo do adolescente.

#### **B. Validações de Integridade**

* **Vínculo por Idade:** Embora o sistema aceite o registro, o BFF pode emitir um alerta caso o `membro_id` selecionado não esteja na faixa etária de adolescência (calculada pela data de nascimento).
* **Consistência de Datas:** A `data_fim` deve ser obrigatoriamente igual ou posterior à `data_inicio`.
* **Regra de Contatos PSC:** O campo `detalhes_contatos_psc` é recomendado sempre que houver pelo menos um registro ativo do tipo "PSC" (Prestação de Serviços à Comunidade).

#### **C. Agregação no GET (Read)**

* O BFF deve retornar as descrições das medidas realizando o join com a tabela de domínio.
* O histórico deve ser apresentado de forma tabular, agrupado por membro da família.

---

### 4. Contrato da API Sugerido

* **GET `/api/v1/medidas-socioeducativas/{id_familia}**`: Retorna o histórico completo, acompanhamentos do CREAS e metadados das medidas.
* **POST/PUT `/api/v1/medidas-socioeducativas**`: Salva ou atualiza o prontuário socioeducativo da família.

> "Gemini, utilize este `.md` para criar as rotas de Medidas Socioeducativas. Mantenha o padrão **Metadata-Driven** para os tipos de medidas e garanta que o BFF valide a cronologia das datas (fim >= início). O escopo é estritamente **CRU** e os dados devem ser vinculados aos UUIDs dos membros da família."
