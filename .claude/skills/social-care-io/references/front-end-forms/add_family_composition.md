Essa é uma excelente decisão de arquitetura, Gabriel! No mundo corporativo e em sistemas de gestão pública ou social, chamamos isso de **Tabela de Domínio** ou **Lookup Table**.

Fazer isso traz várias vantagens:

1. **Flexibilidade:** Se o governo mudar as regras e adicionar "012 - Padrasto/Madrasta", você só insere uma linha no banco sem precisar mexer em uma linha de código sequer.
2. **Integridade:** Você usa uma *Foreign Key* (FK) no banco, garantindo que ninguém insira um código de parentesco que não exista.
3. **Metadados:** Você pode adicionar colunas extras na tabela de parentesco, como `ativo (bool)` para desativar opções antigas sem apagar o histórico.

Aqui está a atualização do seu arquivo `.md` incorporando essa lógica de banco de dados para o Gemini CLI entender:

---

## Documentação Técnica: Domínio de Composição Familiar (Conecta Raros) - v2

### 1. Visão Geral

Este documento define as especificações para o BFF da tela de Composição Familiar. O sistema deve gerenciar o núcleo familiar, utilizando tabelas de domínio dinâmicas para tipos de parentesco.

### 2. Estrutura de Dados e Banco de Dados

#### **Tabela de Domínio: `parentesco**`

O sistema não deve usar Enums fixos para parentesco. Os códigos devem vir desta tabela:

* `id`: UUID ou Integer (Primary Key)
* `codigo`: String (ex: "01", "02")
* `descricao`: String (ex: "Cônjuge/companheiro(a)")
* `ordem_exibicao`: Integer (Para ordenar no dropdown do frontend)

#### **Structs (Modelo de Dados)**

```rust
struct MembroFamiliar {
    id: Option<Uuid>,
    nome_completo: String,
    data_nascimento: Date,
    sexo: Sexo, 
    // Referência para a tabela de domínio 'parentesco'
    parentesco_id: Uuid, 
    pcd: bool,
    documentos: Vec<TipoDocumento>,
}

```

---

### 3. Regras de Negócio de Backend (BFF)

* **Validação Dinâmica:** Ao receber um `POST` ou `PUT`, o BFF deve validar se o `parentesco_id` fornecido existe na tabela de domínio.
* **Carregamento do Formulário:** O BFF deve prover um endpoint `GET /api/v1/dominios/parentescos` para que o frontend popule o dropdown dinamicamente com base no banco.
* **Seleção Exclusiva de Especificidade:**
* Apenas uma opção pode ser `true`.
* Se `tipo == 'OUTRAS'`, o campo `descricao_outros` é obrigatório.


* **Pessoa de Referência (PR):**
* A validação deve buscar na tabela de domínio qual ID corresponde ao código `"01"`.
* Garantir que exatamente um membro na lista tenha esse ID.



---

### 4. Operações (CRUD Parcial)

1. **CREATE / UPDATE:** Deve aceitar o objeto da família e a lista de membros. Se o membro já possuir um `id`, atualiza; se não, cria.
2. **READ:** O retorno deve incluir:
* Dados da família.
* Lista de membros com os nomes das descrições de parentesco (via Join ou busca no cache).
* **Perfil Etário Calculado:** Objeto com a contagem de pessoas por faixa etária.