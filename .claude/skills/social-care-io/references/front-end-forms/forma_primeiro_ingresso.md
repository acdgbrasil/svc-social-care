## Especificação Técnica de Backend (BFF) - Projeto Conecta Raros

### 1. Escopo de Operações

Todas as rotas descritas abaixo devem implementar exclusivamente o padrão **CRU**:

* **Create (POST):** Persistência de novos registros.
* **Read (GET):** Recuperação de dados para visualização e edição.
* **Update (PUT/PATCH):** Atualização de registros existentes.
* **Nota:** A operação de **Delete** não deve ser implementada.

### 2. Estratégia de Dados: Tabelas de Domínio (Lookup)

Para garantir flexibilidade sem alteração de código, os campos de seleção devem ser validados contra tabelas de domínio no banco de dados:

* **Parentesco:** (`id`, `codigo`, `descricao`, `ativo`)
* **Forma de Ingresso:** (`id`, `descricao`, `requer_detalhe_contato`, `ativo`)
* **Programas Sociais:** (`id`, `nome`, `permite_texto_livre`, `ativo`)

---

### 3. Tela: Composição Familiar

#### **Regras de Negócio (Business Rules)**

* **Struct de Membro:** Deve conter `nome`, `data_nascimento`, `sexo`, `parentesco_id`, `pcd` (booleano) e uma lista de `documentos_entregues`.
* **Pessoa de Referência (PR):** Validação mandatória de que existe **exatamente um** membro com o código de parentesco "01" por família.
* **Especificidades Sociais:** Seleção exclusiva (apenas um tipo). Se o tipo for "Outras", o campo de texto manual torna-se obrigatório.
* **Cálculo de Perfil Etário (Output do GET):** O BFF deve processar as idades e retornar um objeto agregador com as contagens por faixa (0-6, 7-14, 15-17, 18-29, 30-59, 60-64, 65-69, 70+).

---

### 4. Tela: Ingresso e Atendimento Inicial

#### **Regras de Negócio (Business Rules)**

* **Ingresso:** Seleção única via `ingresso_tipo_id`.
* **Condicional de Contato:** Se o tipo de ingresso for um "Encaminhamento", os campos `nome_origem` e `contato_origem` devem ser validados.
* **Motivo do Atendimento:** Campo de texto longo (Razões/Demandas).
* **Vínculo de Programas Sociais:** Seleção múltipla. Caso o item "Outros" seja selecionado, a descrição manual deve ser preenchida.

---

### 5. Contrato de API (Exemplo de Payload Unificado)

O BFF deve ser capaz de processar os dados seguindo esta estrutura de **Structs**:

```json
{
  "familia_id": "uuid",
  "composicao": {
    "membros": [...],
    "especificidade": { "tipo_id": "uuid", "descricao": "..." }
  },
  "atendimento": {
    "ingresso_id": "uuid",
    "encaminhamento": { "nome": "...", "contato": "..." },
    "motivo": "...",
    "programas_vinculados": [
      { "programa_id": "uuid", "observacao": "..." }
    ]
  }
}

```