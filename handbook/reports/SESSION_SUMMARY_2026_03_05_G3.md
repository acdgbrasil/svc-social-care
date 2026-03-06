# Encerramento — 2026-03-05 (Gap G3 & Visibility)

## Entregas Realizadas
- [x] **Gap G3 - DELETE Member**: Rota `DELETE /patients/{id}/family-members/{memberId}` totalmente funcional.
- [x] **Registry Controller**: Handlers tornados públicos e integrados ao RouterBootstrap.
- [x] **Router Configuration**: Injeção de dependência completa para `RemoveFamilyMemberUseCase`.
- [x] **AnySendable Fix**: Implementação de `Encodable` para suporte a dicionários heterogêneos em respostas JSON.

## Testes
- Novos testes: `RemoveFamilyMemberServiceTests.swift` (PASSANDO).
- Status Geral: Build íntegro e suítes validadas.

## Estado Atualizado do IMPLEMENTATION_PLAN.md
- **FASE 3: HTTP Layer**: 90% concluída.
- **Próxima tarefa**: Padronizar todos os Response Bodies de sucesso para o formato `SuccessResponseWithActionResult`.

## Notas / Decisões Tomadas
- O comando de remoção foi normalizado para usar `memberId` (o UUID público/PersonId do membro) para manter consistência com o path parameter.
- Corrigida a sintaxe de registro do Middleware no ApplicationContext para o padrão idiomático do Hummingbird 2.0.
