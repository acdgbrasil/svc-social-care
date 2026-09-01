## Documentação Técnica: Trabalho e Rendimento (Conecta Raros)

### 1. Visão Geral

Este módulo gerencia a situação ocupacional, qualificações e a composição da renda mensal da família, integrando rendimentos do trabalho com benefícios de programas sociais.

### 2. Estrutura de Dados (Structs & Enums)

#### **Definição de Enums Fixos**

* **CondicaoOcupacao:** `0-Não trabalha`, `1-Autônomo/Bico`, `2-Trabalhador Rural`, `3-Empregado sem Carteira`, `4-Empregado com Carteira`, `5/6-Doméstico`, `7-Não remunerado`, `8-Militar/Servidor`, `9-Empregado`, `10-Estagiário`, `11-Aprendiz`.

#### **Structs de Domínio**

```rust
struct RendimentoMembro {
    membro_id: Uuid, // FK Composição Familiar
    condicao_ocupacao: CondicaoOcupacao,
    possui_carteira_trabalho: bool,
    qualificacao_profissional: Option<String>,
    renda_mensal: f64,
}

struct ProgramasSociaisRenda {
    recebe_auxilio: bool,
    valor_bolsa_familia: f64,
    valor_bpc: f64,
    valor_peti: f64,
    valor_outros: f64,
    beneficiarios_bpc: Vec<Uuid>, // Lista de membros
}

struct TrabalhoERendimento {
    id_familia: Uuid,
    rendimentos_individuais: Vec<RendimentoMembro>,
    programas_sociais: ProgramasSociaisRenda,
    possui_aposentados: bool,
    membros_aposentados: Vec<Uuid>, // Lista de membros
}

```

---

### 3. Regras de Negócio e Cálculos do BFF

O BFF deve processar os dados para fornecer quatro indicadores financeiros essenciais no **Read (GET)**:

#### **A. Cálculos Sem Programas Sociais**

* **Renda Total Familiar (RTF_S):** Soma de todas as `renda_mensal` dos membros da família.

$$RTF_S = \sum_{i=1}^{n} \text{renda\_mensal}_i$$


* **Renda Per Capita (RPC_S):** $RTF_S$ dividido pelo número total de membros.

#### **B. Cálculos Com Programas Sociais**

* **Renda Total Global (RTG):** Soma da $RTF_S$ com os valores de Bolsa Família, BPC, PETI e Outros.

$$RTG = RTF_S + \text{Soma Benefícios}$$


* **Renda Per Capita Global (RPC_G):** $RTG$ dividido pelo número total de membros.

#### **C. Operações (CRU)**

* **Create/Update:** Salva ou atualiza os rendimentos e a lista de beneficiários/aposentados.
* **Read:** Retorna a struct completa com os 4 cálculos acima já realizados pelo backend.

---

### 4. Requisitos de Integridade

* **Vínculo de Membros:** As listas de beneficiários de BPC e de aposentados só podem conter UUIDs que existam na **Composição Familiar** dessa família.
* **Validação de Valor:** Campos de renda e benefícios não podem aceitar valores negativos.

> "Gemini, na rota de GET de Trabalho e Rendimento, implemente a lógica para que o BFF calcule automaticamente as rendas totais e per capita (com e sem programas sociais). Lembre-se que o divisor para o cálculo per capita deve ser o `count` de membros registrados na Composição Familiar desta família. Use os enums fixos para as condições de ocupação."
