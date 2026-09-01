---
name: social-care-suas
description: >
  Origem normativa do domínio — Prontuário SUAS (MDS/SNAS) e o fluxo de
  atendimento socioeducativo em meio aberto. Use ao criar ou alterar campo de
  avaliação, ao decidir se um dado é obrigatório, ao nomear conceito de domínio,
  ao interpretar formulário do front-end, ou quando a dúvida for "o que este
  campo significa para quem preenche". Gatilhos: SUAS, prontuário, bloco,
  CRAS, CREAS, PAIF, PAEFI, medida socioeducativa, acolhimento institucional,
  violação de direitos, benefício eventual, pessoa de referência, composição
  familiar.
---

# Prontuário SUAS — a norma que este serviço implementa

O `social-care` não inventou seu modelo de dados: ele digitaliza o **Prontuário
SUAS**, instrumento do Ministério do Desenvolvimento Social. Quando o código e o
manual divergem sobre o que um campo significa, **o manual manda** — é o que a
assistente social vai preencher, e é dele que vem a obrigatoriedade legal.

Isto vale para o *significado*. Para forma do código (nome de tipo, camada,
concorrência), valem as invariantes do projeto e os ADRs em `docs/adr/`.

## Os 16 blocos e onde cada um vive no código

O manual organiza o prontuário em 16 blocos. O mapeamento abaixo foi conferido
contra `Sources/` — se um caminho não bater, o código mudou e esta tabela é que
está errada.

| # | Bloco (norma) | No código |
|---:|---|---|
| 1 | Registro Simplificado dos Atendimentos | `Domain/Care/` — `SocialCareAppointment` |
| 2 | Identificação da Pessoa de Referência e Endereço | `Domain/Registry/` — `PersonalData`, `Kernel/Address` |
| 3 | Forma de Ingresso e Motivo do 1º Atendimento | `Domain/Care/ValueObjects/IngressInfo.swift` |
| 4 | Composição Familiar | `Domain/Registry/Entities/FamilyMember/` + `FamilyAnalytics` |
| 5 | Condições Habitacionais | `Domain/Assessment/ValueObjects/HousingCondition/` |
| 6 | Condições Educacionais | `Domain/Assessment/ValueObjects/EducationalStatus/` |
| 7 | Trabalho e Rendimento | `Domain/Assessment/ValueObjects/WorkAndIncome/` |
| 8 | Condições de Saúde | `Domain/Assessment/ValueObjects/HealthStatus/` |
| 9 | Acesso a Benefícios Eventuais | `Domain/Assessment/` — `SocialBenefit*` |
| 10 | Convivência Familiar e Comunitária | `Domain/Assessment/ValueObjects/CommunitySupportNetwork/` |
| 11 | Participação em Serviços, Programas e Projetos | *sem tipo dedicado — verifique antes de assumir* |
| 12 | Situações de Violência e Violação de Direitos | `Domain/Protection/Aggregates/RightsViolationReport/` |
| 13 | Histórico de Medidas Socioeducativas | *sem tipo dedicado — ver o 2º manual* |
| 14 | Histórico de Acolhimento Institucional | `Domain/Protection/Entities/PlacementHistory.swift` |
| 15 | Planejamento e Evolução do Acompanhamento | *sem tipo dedicado* |
| 16 | Controle de Encaminhamentos | `Domain/Protection/Aggregates/Referral/` |

**Os blocos 11, 13 e 15 não têm tipo próprio hoje.** Isso é lacuna de
implementação, não decisão registrada: antes de modelar um deles, leia o bloco
no manual e confirme se parte já não caiu dentro de outro agregado.

## Os manuais

Ficam em `references/`, e são grandes — leia o bloco que interessa, não o
arquivo inteiro.

| Arquivo | O que é |
|---|---|
| `references/prontuario-suas-mds.md` | Manual de Instruções do Prontuário SUAS (MDS/SNAS). A seção **3. ORIENTAÇÕES PARA O REGISTRO** detalha bloco a bloco o que cada campo quer dizer e quando é obrigatório. |
| `references/fluxo-socioeducativo-meio-aberto.md` | Manual de orientação do fluxo socioeducativo em meio aberto (Ceará / PROARES III, 2019). Cobre as medidas — advertência, reparação de dano, PSC, liberdade assistida, semiliberdade, internação — e o SINASE. Fonte para o bloco 13. |

Para achar um bloco: `grep -n "BLOCO" references/prontuario-suas-mds.md`.

## Por que isto é uma skill, e não handbook

Estes manuais estavam em `handbook/tooling/suas/`, ao lado de um espelho da doc
do Vapor — 55 mil linhas de referência de linguagem que ninguém abria. O
conteúdo normativo ficava invisível por associação. Como skill, ele carrega
quando a conversa fala de domínio e custa zero contexto quando não fala.

⚠️ **Não copie trecho de manual para dentro do código ou de outra doc.** Cite o
bloco e o arquivo. Manual copiado vira manual desatualizado — foi assim que o
handbook anterior passou a ensinar padrões que o código já tinha abandonado.
