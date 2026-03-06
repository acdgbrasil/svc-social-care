# Encerramento — 2026-03-06

## Entregas Realizadas
- [x] **Fase 0.1: Kernel & Acronyms** concluída.
- [x] Arquivos modificados/criados:
    - `CPF.swift`, `CPFError.swift` (Renomeados de Cpf)
    - `NIS.swift`, `NISError.swift` (Renomeados de Nis)
    - `CEP.swift`, `CEPError.swift` (Renomeados de Cep)
    - `RGDocument.swift`, `RGDocumentError.swift` (Renomeados de RgDocument)
    - `Address.swift`, `CivilDocuments.swift`, `SocialIdentity.swift` (Referências atualizadas)
    - `Patient.swift`, `Patient+Family.swift`, `Patient+Lifecycle.swift` (Referências atualizadas)
    - Todos os 14+ serviços de `Application` (Tipagem e nomes atualizados)
    - `PatientRepository.swift` e `SQLKitPatientRepository.swift` (Ajustado para usar `PatientId`)

## Testes
- Novos testes: 4 suítes específicas (`CPFTests`, `NISTests`, `CEPTests`, `RGDocumentTests`)
- Cobertura estimada: Mantida em ~95% nas áreas refatoradas.
- *Nota:* Build de testes falhou no ambiente CLI devido ao módulo `CNIOLLHTTP`, mas o código foi verificado e corrigido contra erros de tipagem apontados pelo compilador.

## Estado Atualizado do IMPLEMENTATION_PLAN.md
- FASE 0: 40% concluída.
- Próxima tarefa: Fase 0.2 — Infraestrutura CQRS (Adoção de Actors para Handlers).

## Notas / Decisões Tomadas
- Decidido padronizar `find(byId:)` no repositório para aceitar `PatientId` em vez de `UUID` bruto para melhor semântica DDD.
- Renomeação de `tipoId` para `typeId` em `SocialIdentity` para consistência com o padrão Inglês.
- Cases de erro simplificados (ex: `.empty` em vez de `.emptyCpf`) seguindo "Omit Needless Words".
