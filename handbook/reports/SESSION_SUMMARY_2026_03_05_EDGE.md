# Encerramento — 2026-03-05 (Rede Edge)

## Entregas Realizadas
- [x] **Infra Alignment**: `ApplicationContext` ajustado para usar `POSTGRES_PASSWORD` e host `postgres` (Service K8s).
- [x] **G6 - Health Check**: Criação do `HealthController` com endpoints `/health` (liveness) e `/ready` (readiness com check de DB).
- [x] **G2 - Outbox Relay Ativado**: Instanciação do `SQLKitOutboxRelay` no boot da aplicação, iniciando o polling de eventos de domínio.
- [x] **Router Configuration**: Atualização do `RouterBootstrap` para incluir rotas de infraestrutura.

## Testes
- Novos testes: Validação manual dos endpoints de health sugerida para o próximo deploy.
- Cobertura: Expandida para a camada de I/O de infraestrutura.

## Estado Atualizado do IMPLEMENTATION_PLAN.md
- **FASE 1: Foundation**: 100% concluída.
- **FASE 5: Outbox Relay**: 50% concluída (Relay ativo, falta marcar como processado no banco - G16).
- **Proxima tarefa**: FASE 3 - HTTP Layer Compliant com OpenAPI (Ajuste de rotas para paths flat).

## Notas / Decisões Tomadas
- O Outbox Relay agora loga eventos processados, preparando o caminho para integração com o NATS JetStream (nats:4222) presente na infraestrutura.
- A rede overlay Tailscale (100.x.y.z) é abstraída pelos nomes de serviço do K3s, garantindo portabilidade entre Xeon e Raspberry Pis.
