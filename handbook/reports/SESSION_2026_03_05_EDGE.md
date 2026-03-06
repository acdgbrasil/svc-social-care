# Relatório de Sessão — 2026-03-05 (Edge Network Integration)

## Estado Atual
- **Fase Ativa:** 1 (Foundation) & 5 (Outbox Relay)
- **Progresso Geral:** ~25%
- **Integração Edge:** Iniciada.
- **Bloqueios:** 
    - G6: Sem health checks para o K3s.
    - G2: Outbox Relay implementado mas não instanciado/iniciado no boot.
    - Configurações de DB desalinhadas com o serviço `postgres` do cluster.

## Plano para Esta Sessão
1. **Alinhamento de Variáveis** — Configurar `ApplicationContext` para os nomes de ENV usados no `postgres.yaml` da infra.
2. **G6 - Health Checks** — Implementar endpoints `/health` e `/ready` para probes do Kubernetes.
3. **G2 - Ativação do Outbox Relay** — Instanciar e iniciar o polling de eventos no boot da aplicação.
4. **Resiliência de Rede** — Ajustar o pooling para lidar com a latência da rede overlay (Tailscale).

## Critérios de Aceite
- [ ] Suporte a `POSTGRES_PASSWORD` (conforme manifestos Bitwarden).
- [ ] Endpoint `/health` retornando 200 OK.
- [ ] Logs confirmando o início do `SQLKitOutboxRelay`.
