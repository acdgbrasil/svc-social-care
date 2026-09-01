## Documentação Técnica: Acesso a Benefícios Eventuais (Conecta Raros)

### 1. Visão Geral

Este módulo gerencia a concessão de benefícios suplementares e temporários. Para garantir a escalabilidade do sistema, o catálogo de benefícios é **dinâmico**, permitindo a inclusão de novas modalidades via banco de dados sem alteração de código.

### 2. Arquitetura de Dados (Database & Structs)

#### **Tabela de Domínio (Lookup): `dominio_tipo_beneficio**`

Esta tabela armazena os metadados que regem o comportamento da interface:

* `id`: UUID (Primary Key).
* `descricao`: String (ex: "Auxílio Natalidade", "Cesta Básica").
* `exige_registro_nascimento`: Boolean (Ativado para Natalidade).
* `exige_cpf_falecido`: Boolean (Ativado para Funeral).
* `ativo`: Boolean (Para desativação lógica).

#### **Struct de Registro Individual**

```rust
struct RegistroBeneficio {
    id: Option<Uuid>,
    data_concessao: Date,
    tipo_beneficio_id: Uuid, // FK para dominio_tipo_beneficio
    registro_nascimento_crianca: Option<String>,
    cpf_pessoa_falecida: Option<String>,
}

struct AcessoBeneficios {
    id_familia: Uuid,
    historico_beneficios: Vec<RegistroBeneficio>,
}

```

---

### 3. Regras de Negócio e Lógica do BFF

#### **A. Escopo de Operação (CRU)**

* **Create/Update:** Persistência de novos auxílios ou correções de registros existentes.
* **Read:** Recuperação do histórico cronológico.
* **Nota:** Operações de **Delete** são proibidas para manter a integridade da prestação de contas pública.

#### **B. Validação Baseada em Metadados (Metadata-Driven)**

Diferente de um `if/else` fixo, o BFF deve consultar a tabela de domínio antes de salvar:

1. Busca o `tipo_beneficio_id` no banco.
2. Se `exige_registro_nascimento` for `true`, valida se o campo `registro_nascimento_crianca` foi preenchido.
3. Se `exige_cpf_falecido` for `true`, valida o formato do `cpf_pessoa_falecida`.
4. Para os demais casos, ignora a validação desses campos específicos.

#### **C. Contrato de Entrega (Read)**

O endpoint de leitura (GET) deve retornar:

1. A lista de benefícios já concedidos à família.
2. A lista atualizada de `dominio_tipo_beneficio` para que o frontend saiba quais campos exibir/ocultar dinamicamente no modal de cadastro.

---

### 4. Endpoints sugeridos

* **GET `/api/v1/beneficios/{id_familia}**`: Retorna histórico + metadados de tipos.
* **POST/PUT `/api/v1/beneficios**`: Salva o registro validando contra os metadados da tabela de domínio.

> "Gemini, implemente o BFF para a tela de Benefícios Eventuais seguindo o padrão **Metadata-Driven** definido no `.md`. Use a tabela de domínio para validar dinamicamente se o registro exige CPF ou Certidão de Nascimento. O objetivo é que, se eu adicionar um novo tipo de benefício no banco, o código do BFF continue funcionando sem alterações."
