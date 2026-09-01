## Documentação Técnica: Condições de Saúde da Família (Conecta Raros)

### 1. Visão Geral

Este módulo monitora o estado de saúde física e mental, deficiências, necessidades de cuidados, segurança alimentar e acompanhamento de gestantes do núcleo familiar.

### 2. Estrutura de Dados (Structs & Enums)

Assim como na tela de habitação, utilizaremos **Enums fixos** para as categorias de deficiência e estados de saúde.

#### **Definição de Enums Fixos**

* **TipoDeficiencia:** -> Será uma tabela dinamica no banco de dados que possa ser expandida com o tempo, mas podemos já fazer um bootstrap adicionando algumas já: 01-Cegueira, 02-Baixa visão, 03-Surdez severa/profunda, 04-Surdez leve/moderada, 05-Deficiência física, 06-Deficiência mental ou intelectual, 07-Síndrome de Down, 08-Transtorno/doença mental [...]

#### **Structs de Domínio**

```rust
struct PessoaComDeficiencia {
    membro_id: Uuid, // FK Composição Familiar
    tipo_deficiencia: TipoDeficiencia,
    necessita_cuidados: bool,
    responsavel_cuidado: Option<String>,
}

struct Gestante {
    membro_id: Uuid, // FK Composição Familiar
    meses_gestacao: u8,
    iniciou_pre_natal: bool,
}

struct CondicoesSaude {
    id_familia: Uuid,
    
    // Tabelas e Listas
    deficiencias: Vec<PessoaComDeficiencia>,
    necessitam_cuidado_constante: Vec<Uuid>, // Membros (doença/envelhecimento)
    portadores_doenca_grave: Vec<Uuid>,
    uso_remedio_controlado: Vec<Uuid>,
    uso_abusivo_alcool: Vec<Uuid>,
    uso_abusivo_drogas: Vec<MembroUsoSubstancia>,
    gestantes: Vec<Gestante>,

    // Declarações Gerais
    inseguranca_alimentar: bool,
}

struct MembroUsoSubstancia {
    membro_id: Uuid,
    substancias: String, // Texto livre para especificar drogas
}

```

---

### 3. Regras de Negócio e Lógica do BFF

#### **A. Operações Suportadas (CRU)**

* O sistema deve realizar **Create, Read e Update**. A integridade dos dados de saúde é crítica, por isso o **Delete** não é implementado para manter o histórico de acompanhamento.

#### **B. Regras de Dependência e Validação**

* **Vínculo Unívoco:** Todas as listas de membros (gestantes, deficientes, etc.) devem obrigatoriamente referenciar UUIDs existentes na **Composição Familiar** daquela família.
* **Condicional de Cuidado:** Na struct `PessoaComDeficiencia`, se `necessita_cuidados` for `true`, o campo `responsavel_cuidado` deve ser validado para garantir que não esteja vazio.
* **Gestação:** Apenas membros do sexo "Feminino" (conforme definido na Composição) devem ser permitidos na lista de gestantes.

#### **C. Segurança Alimentar**

* Trata-se de uma declaração binária da família sobre a insuficiência de alimentos.

---

### 4. Contrato da API

* **GET `/api/v1/saude/{id_familia}**`: Retorna a struct completa com todos os quadros de saúde e gestação preenchidos.
* **POST/PUT `/api/v1/saude**`: Atualiza ou cria o diagnóstico de saúde da família.

