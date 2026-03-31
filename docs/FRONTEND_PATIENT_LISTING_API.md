# API de Listagem de Pacientes — Guia de Integracao Frontend

> **Versao da API:** v0.7.0
> **Data:** 2026-03-30
> **Escopo:** Tela HOME / Listagem de Familias do Conecta Raros
> **Base URL:** `https://<host>/api/v1`

---

## 1. VISAO GERAL

A listagem de pacientes usa **dois endpoints** em conjunto:

| Finalidade | Endpoint | Quando chamar |
|---|---|---|
| Lista (FamilyList) | `GET /patients` | Ao carregar a tela, ao buscar, ao paginar |
| Detalhe (DetailPanel) | `GET /patients/:patientId` | Ao clicar num item da lista (on-demand) |

**Importante:** O endpoint de lista retorna um payload leve (7 campos por item). O endpoint de detalhe retorna o agregado completo (20+ campos aninhados). Nunca use o endpoint de detalhe para popular a lista.

---

## 2. ENDPOINT DE LISTAGEM

### Request

```
GET /api/v1/patients?search=&cursor=&limit=20
```

**Headers obrigatorios:**

| Header | Valor | Descricao |
|---|---|---|
| `Authorization` | `Bearer <jwt_token>` | Token JWT do Zitadel |

**Roles permitidas:** `social_worker`, `owner`, `admin`

**Query parameters:**

| Param | Tipo | Obrigatorio | Default | Descricao |
|---|---|---|---|---|
| `search` | `string` | Nao | — | Filtra por firstName, lastName ou CPF. Case-insensitive. Busca parcial (contém). |
| `cursor` | `string (UUID)` | Nao | — | UUID do ultimo item da pagina anterior. Omitir para primeira pagina. |
| `limit` | `integer` | Nao | `20` | Itens por pagina. Min: 1, Max: 100. |

### Response (200 OK)

```json
{
  "data": [
    {
      "patientId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "personId": "f0e1d2c3-b4a5-6789-0abc-def123456789",
      "firstName": "Maria",
      "lastName": "Costa",
      "fullName": "Maria Costa",
      "primaryDiagnosis": "Fibrose Cistica",
      "memberCount": 4
    },
    {
      "patientId": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
      "personId": "e1d2c3b4-a5f6-7890-1bcd-ef2345678901",
      "firstName": "Joao",
      "lastName": "Franklin",
      "fullName": "Joao Franklin",
      "primaryDiagnosis": "Sindrome de Down",
      "memberCount": 3
    }
  ],
  "meta": {
    "timestamp": "2026-03-30T14:30:00Z",
    "pageSize": 20,
    "totalCount": 8,
    "hasMore": false,
    "nextCursor": null
  }
}
```

**Campos de cada item:**

| Campo | Tipo | Nullable | Mapeamento no frontend |
|---|---|---|---|
| `patientId` | `string (UUID)` | Nao | `family.id` — usado como key e para chamar detalhe |
| `personId` | `string (UUID)` | Nao | Referencia cruzada (nao exibido na lista) |
| `firstName` | `string` | **Sim** | `family.firstName` — subtitulo do hover |
| `lastName` | `string` | **Sim** | `family.lastName` — texto principal da lista (40px) |
| `fullName` | `string` | **Sim** | `family.fullName` — usado na busca local e no painel |
| `primaryDiagnosis` | `string` | **Sim** | `family.diagnosis` — exibido no painel Dados |
| `memberCount` | `integer` | Nao | `family.members` — subtitulo: "N membros" |

> **Nota sobre campos null:** Pacientes cadastrados sem `personalData` terao `firstName`, `lastName`, `fullName` e `primaryDiagnosis` como `null`. O frontend deve tratar com fallback (ex: "Sem nome" ou em-dash `—`).

**Campos do meta:**

| Campo | Tipo | Descricao |
|---|---|---|
| `timestamp` | `string (ISO 8601)` | Momento da resposta no servidor |
| `pageSize` | `integer` | Tamanho da pagina solicitado |
| `totalCount` | `integer` | Total de pacientes (com filtro de busca aplicado). **Usar no FamilyCounter**: `"{totalCount} familias cadastradas"` |
| `hasMore` | `boolean` | `true` se existem mais paginas |
| `nextCursor` | `string (UUID) \| null` | Cursor para a proxima pagina. `null` quando `hasMore` e `false` |

---

## 3. PAGINACAO (Cursor-Based)

A paginacao e baseada em cursor, nao em offset/limit numerico.

### Fluxo

```
1. Primeira pagina:
   GET /patients?limit=20

2. Proxima pagina (se hasMore === true):
   GET /patients?limit=20&cursor={nextCursor da resposta anterior}

3. Repetir ate hasMore === false
```

### Exemplo pratico (8 pacientes, limit=3)

```
Pagina 1: GET /patients?limit=3
  -> data: [Costa, Franklin, Aderaldo]
  -> meta: { totalCount: 8, hasMore: true, nextCursor: "uuid-do-aderaldo" }

Pagina 2: GET /patients?limit=3&cursor=uuid-do-aderaldo
  -> data: [Colaco, Faco, Soriano]
  -> meta: { totalCount: 8, hasMore: true, nextCursor: "uuid-do-soriano" }

Pagina 3: GET /patients?limit=3&cursor=uuid-do-soriano
  -> data: [Gouveia, Benevides]
  -> meta: { totalCount: 8, hasMore: false, nextCursor: null }
```

### Regras

- O cursor e o `patientId` do ultimo item retornado — o backend sabe de onde continuar.
- Ao mudar o `search`, **descartar o cursor** e comecar da primeira pagina.
- A ordenacao e estavel por `patientId` (UUID). Novos cadastros nao alteram a posicao de itens ja paginados.

---

## 4. BUSCA (Search)

```
GET /patients?search=costa
GET /patients?search=maria
GET /patients?search=123.456  (busca parcial por CPF)
```

- Busca server-side por `firstName`, `lastName` ou `CPF`.
- **Case-insensitive** (buscar "COSTA" encontra "Costa").
- **Busca parcial** (buscar "mar" encontra "Maria").
- O `totalCount` no meta reflete o total **filtrado**, nao o total geral.
- Combinar com paginacao: `GET /patients?search=costa&limit=10&cursor=...`

### Integracao com a SearchBar

```javascript
// Debounce de 300ms recomendado para evitar requests excessivos
const handleSearchChange = debounce(async (query) => {
  const params = new URLSearchParams();
  if (query) params.set('search', query);
  params.set('limit', '20');
  // SEM cursor — nova busca sempre comeca da pagina 1

  const response = await fetch(`/api/v1/patients?${params}`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const { data, meta } = await response.json();

  setFamilies(data);
  setTotalCount(meta.totalCount);  // FamilyCounter
  setNextCursor(meta.nextCursor);
  setHasMore(meta.hasMore);
}, 300);
```

---

## 5. ENDPOINT DE DETALHE (Painel Dados)

Chamado **on-demand** ao clicar num item da lista.

### Request

```
GET /api/v1/patients/:patientId
```

### Response (200 OK)

```json
{
  "data": {
    "patientId": "a1b2c3d4-...",
    "personId": "f0e1d2c3-...",
    "version": 3,
    "personalData": {
      "firstName": "Maria",
      "lastName": "Costa",
      "motherName": "Ana Maria Costa",
      "nationality": "Brasileira",
      "sex": "feminino",
      "socialName": null,
      "birthDate": "1990-05-15T00:00:00Z",
      "phone": "(85) 9 9876-5432"
    },
    "civilDocuments": {
      "cpf": "123.456.789-00",
      "nis": "12345678901",
      "rgDocument": {
        "number": "2006002345678",
        "issuingState": "CE",
        "issuingAgency": "SSP",
        "issueDate": "2010-03-20T00:00:00Z"
      }
    },
    "address": {
      "cep": "60000-000",
      "isShelter": false,
      "residenceLocation": "urbana",
      "street": "Rua das Flores",
      "neighborhood": "Centro",
      "number": "123",
      "complement": "Apt 4",
      "state": "CE",
      "city": "Fortaleza"
    },
    "socialIdentity": { "typeId": "uuid-...", "otherDescription": null },
    "familyMembers": [
      {
        "personId": "uuid-...",
        "relationshipId": "uuid-...",
        "isPrimaryCaregiver": true,
        "residesWithPatient": true,
        "hasDisability": false,
        "requiredDocuments": [],
        "birthDate": "1990-05-15T00:00:00Z"
      }
    ],
    "diagnoses": [
      {
        "icdCode": "E840",
        "description": "Fibrose Cistica",
        "date": "2024-01-10T00:00:00Z"
      }
    ],
    "housingCondition": { "..." : "..." },
    "socioeconomicSituation": { "..." : "..." },
    "workAndIncome": { "..." : "..." },
    "educationalStatus": { "..." : "..." },
    "healthStatus": { "..." : "..." },
    "communitySupportNetwork": { "..." : "..." },
    "socialHealthSummary": { "..." : "..." },
    "placementHistory": { "..." : "..." },
    "intakeInfo": { "..." : "..." },
    "appointments": [],
    "referrals": [],
    "violationReports": [],
    "computedAnalytics": { "..." : "..." }
  },
  "meta": {
    "timestamp": "2026-03-30T14:30:00Z"
  }
}
```

### Mapeamento para o Painel "Dados"

| Campo no Figma | Caminho no JSON |
|---|---|
| Nome completo | `data.personalData.firstName` + `" "` + `data.personalData.lastName` |
| Nome da mae | `data.personalData.motherName` |
| Diagnostico | `data.diagnoses[0].description` |
| Data de nascimento | `data.personalData.birthDate` (formatar DD/MM/YYYY) |
| CPF | `data.civilDocuments.cpf` (ja formatado: 000.000.000-00) |
| Status | Derivar: se `data` existe e tem dados -> "Ativo". Sem campo explicito no backend. |
| Data de ingresso | `data.appointments[0].date` (primeiro atendimento, se houver) |
| Tec. responsavel | `data.appointments[0].professionalId` (UUID do profissional) |
| CEP | `data.address.cep` (ja formatado: 00000-000) |
| Telefone | `data.personalData.phone` |
| Endereco | `data.address.street` + `", "` + `data.address.number` |

### Mapeamento para o Painel "Fichas"

Derivar `filled: true/false` pela presenca (nao-null) de cada campo no detalhe:

| Ficha | Campo no JSON | filled |
|---|---|---|
| Composicao familiar | `data.familyMembers.length > 0` | `true` se tem membros |
| Acesso a beneficios eventuais | `data.socioeconomicSituation` | `!== null` |
| Condicoes de saude da familia | `data.healthStatus` | `!== null` |
| Convivencia familiar e comunitaria | `data.communitySupportNetwork` | `!== null` |
| Condicoes educacionais da familia | `data.educationalStatus` | `!== null` |
| Violencia e violacao de direitos | `data.violationReports.length > 0` | `true` se tem reports |
| Trabalho e rendimento da familia | `data.workAndIncome` | `!== null` |
| Especificidades sociais/culturais | `data.socialIdentity` | `!== null` |
| Forma de ingresso | `data.intakeInfo` | `!== null` |
| Servicos e programas | `data.housingCondition` | `!== null` |

---

## 6. ERROS

### Erros da listagem

| HTTP | Codigo | Causa | Quando acontece |
|---|---|---|---|
| `400` | `QLP-001` | Cursor invalido | `cursor` nao e um UUID valido |
| `400` | `QLP-002` | Limite fora do range | `limit` < 1 ou > 100 |
| `401` | — | Token ausente ou expirado | Header `Authorization` faltando |
| `403` | — | Role insuficiente | Usuario nao tem `social_worker`, `owner` ou `admin` |

### Erros do detalhe

| HTTP | Codigo | Causa |
|---|---|---|
| `400` | — | `patientId` nao e um UUID valido |
| `404` | — | Paciente nao encontrado |

### Formato do body de erro

```json
{
  "error": true,
  "reason": "The cursor format is invalid. Expected a valid patient UUID.",
  "code": "QLP-001"
}
```

---

## 7. FLUXO COMPLETO DE INTEGRACAO

```
                          TELA HOME
                             |
                    [1] useEffect mount
                             |
                    GET /patients?limit=20
                             |
                     +----- 200 -----+
                     |               |
              data -> setFamilies    meta.totalCount -> FamilyCounter
                     |               "8 familias cadastradas"
                     |
           [2] Usuario digita na SearchBar (debounce 300ms)
                     |
              GET /patients?search=costa&limit=20
                     |
              data -> setFamilies (filtrado)
              meta.totalCount -> FamilyCounter (total filtrado)
                     |
           [3] Scroll / "carregar mais" (se hasMore)
                     |
              GET /patients?limit=20&cursor={nextCursor}
                     |
              data -> append em families
                     |
           [4] Usuario clica num FamilyItem
                     |
              GET /patients/{patientId}     <-- detalhe on-demand
                     |
              +--- panelView === "dados" ---+
              |                             |
         PanelDados                    PanelFichas
         (campos do detalhe)           (derivar filled de campos null)
```

---

## 8. TYPESCRIPT — INTERFACES DE REFERENCIA

```typescript
// === LISTAGEM ===

interface PatientSummary {
  patientId: string;      // UUID
  personId: string;       // UUID
  firstName: string | null;
  lastName: string | null;
  fullName: string | null;
  primaryDiagnosis: string | null;
  memberCount: number;
}

interface PaginatedMeta {
  timestamp: string;      // ISO 8601
  pageSize: number;
  totalCount: number;
  hasMore: boolean;
  nextCursor: string | null;  // UUID ou null
}

interface PatientListResponse {
  data: PatientSummary[];
  meta: PaginatedMeta;
}

// === DETALHE ===

interface PersonalData {
  firstName: string;
  lastName: string;
  motherName: string;
  nationality: string;
  sex: string;           // "masculino" | "feminino"
  socialName: string | null;
  birthDate: string;     // ISO 8601
  phone: string | null;
}

interface CivilDocuments {
  cpf: string | null;     // Ja formatado: "123.456.789-00"
  nis: string | null;
  rgDocument: {
    number: string;
    issuingState: string;
    issuingAgency: string;
    issueDate: string;
  } | null;
}

interface Address {
  cep: string | null;     // Ja formatado: "60000-000"
  isShelter: boolean;
  residenceLocation: string;
  street: string | null;
  neighborhood: string | null;
  number: string | null;
  complement: string | null;
  state: string;
  city: string;
}

interface Diagnosis {
  icdCode: string;
  description: string;
  date: string;           // ISO 8601
}

interface FamilyMember {
  personId: string;
  relationshipId: string;
  isPrimaryCaregiver: boolean;
  residesWithPatient: boolean;
  hasDisability: boolean;
  requiredDocuments: string[];
  birthDate: string;
}

interface PatientDetail {
  patientId: string;
  personId: string;
  version: number;
  personalData: PersonalData | null;
  civilDocuments: CivilDocuments | null;
  address: Address | null;
  socialIdentity: { typeId: string; otherDescription: string | null } | null;
  familyMembers: FamilyMember[];
  diagnoses: Diagnosis[];
  housingCondition: object | null;
  socioeconomicSituation: object | null;
  workAndIncome: object | null;
  educationalStatus: object | null;
  healthStatus: object | null;
  communitySupportNetwork: object | null;
  socialHealthSummary: object | null;
  placementHistory: object | null;
  intakeInfo: object | null;
  appointments: object[];
  referrals: object[];
  violationReports: object[];
  computedAnalytics: object;
}

interface PatientDetailResponse {
  data: PatientDetail;
  meta: { timestamp: string };
}
```

---

## 9. EXEMPLO DE HOOK REACT

```typescript
// usePatients.ts

import { useState, useCallback, useRef, useEffect } from 'react';

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:3000';

export function usePatients(token: string) {
  const [families, setFamilies] = useState<PatientSummary[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [hasMore, setHasMore] = useState(false);
  const [loading, setLoading] = useState(false);
  const nextCursorRef = useRef<string | null>(null);
  const searchRef = useRef<string>('');

  const fetchPatients = useCallback(async (
    search?: string,
    cursor?: string | null
  ) => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (search) params.set('search', search);
      if (cursor) params.set('cursor', cursor);
      params.set('limit', '20');

      const res = await fetch(`${API_BASE}/api/v1/patients?${params}`, {
        headers: { 'Authorization': `Bearer ${token}` },
      });

      if (!res.ok) throw new Error(`HTTP ${res.status}`);

      const { data, meta }: PatientListResponse = await res.json();

      if (cursor) {
        // Paginacao: append
        setFamilies(prev => [...prev, ...data]);
      } else {
        // Nova busca ou carga inicial: replace
        setFamilies(data);
      }

      setTotalCount(meta.totalCount);
      setHasMore(meta.hasMore);
      nextCursorRef.current = meta.nextCursor;
    } finally {
      setLoading(false);
    }
  }, [token]);

  // Carga inicial
  useEffect(() => {
    fetchPatients();
  }, [fetchPatients]);

  // Busca (reseta cursor)
  const search = useCallback((query: string) => {
    searchRef.current = query;
    nextCursorRef.current = null;
    fetchPatients(query || undefined);
  }, [fetchPatients]);

  // Proxima pagina
  const loadMore = useCallback(() => {
    if (hasMore && nextCursorRef.current) {
      fetchPatients(searchRef.current || undefined, nextCursorRef.current);
    }
  }, [hasMore, fetchPatients]);

  return { families, totalCount, hasMore, loading, search, loadMore };
}
```

---

## 10. CHECKLIST DE INTEGRACAO

- [ ] Substituir array `FAMILIES` mock pela chamada `GET /patients`
- [ ] Usar `meta.totalCount` no FamilyCounter (em vez de `FAMILIES.length`)
- [ ] Conectar SearchBar ao query param `search` com debounce 300ms
- [ ] Ao limpar busca, chamar `GET /patients` sem `search` (reset)
- [ ] Ao clicar num FamilyItem, chamar `GET /patients/:patientId` para popular PanelDados
- [ ] Mapear campos null para fallback visual (`—` ou "Sem informacao")
- [ ] Derivar `filled` das fichas pela presenca dos campos no detalhe
- [ ] Implementar paginacao infinita ou botao "carregar mais" usando `nextCursor`
- [ ] Tratar erros 401/403 com redirect para login
- [ ] Tratar erro 404 no detalhe (paciente deletado entre lista e clique)
- [ ] Todas as datas chegam em ISO 8601 — formatar para DD/MM/YYYY no frontend
- [ ] CPF e CEP ja chegam formatados do backend (nao formatar novamente)
