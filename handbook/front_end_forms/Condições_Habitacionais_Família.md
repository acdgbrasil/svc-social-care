## Documentação Técnica: Condições Habitacionais da Família (Conecta Raros)

### 1. Visão Geral

Este documento especifica o contrato de dados e lógica de negócio para o mapeamento da infraestrutura física e contexto socioambiental das famílias atendidas.

### 2. Estrutura de Dados (Structs & Enums)

Diferente de outras telas, aqui os campos de seleção são definidos como **Enums fixos** no backend.

#### **Definição de Enums**

* **TipoResidencia:** `PROPRIA`, `ALUGADA`, `CEDIDA`, `OCUPADA`.
* **MaterialParedes:** `ALVENARIA_MADEIRA_APARELHADA`, `MADEIRA_APROVEITADA_TAIPA`, `OUTROS`.
* **AcessoEnergia:** `MEDIDOR_PROPRIO`, `MEDIDOR_COMPARTILHADO`, `SEM_MEDIDOR`, `NAO_POSSUI`.
* **AbastecimentoAgua:** `REDE_GERAL`, `POCO_NASCENTE`, `CISTERNA`, `CARRO_PIPA`, `OUTRA_FORMA`.
* **EscoamentoSanitario:** `REDE_COLETORA`, `FOSSA_SEPTICA`, `FOSSA_RUDIMENTAR`, `VALA_RIO_MAR`, `SEM_BANHEIRO`.
* **ColetaLixo:** `DIRETA`, `INDIRETA`, `NAO_POSSUI`.
* **Acessibilidade:** `TOTAL`, `APENAS_INTERNA`, `NAO_POSSUI`.

#### **Struct Principal: CondicoesHabitacionais**

```rust
struct CondicoesHabitacionais {
    id_familia: Uuid,
    tipo_residencia: TipoResidencia,
    material_paredes: MaterialParedes,
    acesso_energia: AcessoEnergia,
    abastecimento_agua: AbastecimentoAgua,
    escoamento_sanitario: EscoamentoSanitario,
    coleta_lixo: ColetaLixo,
    acessibilidade: Acessibilidade,
    
    // Flags Booleanas (Sim/Não)
    agua_canalizada: bool,
    area_risco: bool,
    dificil_acesso: bool,
    conflito_violencia: bool,
    observacoes_diagnostico: bool,

    // Dados Numéricos
    total_comodos: u8,
    total_dormitorios: u8,
}

```

---

### 3. Regras de Negócio e Lógica de BFF

* **Escopo CRU:** O sistema deve suportar apenas **Create**, **Read** e **Update**. A operação de exclusão não é permitida para este domínio.
* **Cálculo de Densidade Habitacional (GET):** No retorno dos dados (Read), o BFF deve calcular e enviar o campo:
* **Lógica:** `densidade = total_membros_familia / total_dormitorios`.
* *Nota:* O `total_membros_familia` deve ser obtido da tabela de Composição Familiar.


* **Integridade Numérica:** O `total_dormitorios` deve ser sempre menor ou igual ao `total_comodos`.

---

### 4. Contrato da API

* **GET `/api/v1/habitacao/{id_familia}**`: Retorna a struct preenchida + o valor calculado da densidade.
* **POST/PUT `/api/v1/habitacao**`: Recebe a struct para salvar ou atualizar o diagnóstico da família.
