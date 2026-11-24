# MedAgenda — contrato da API (v1)

Contrato REST entre o app e o backend. Enquanto não existe servidor real, o
**ServidorFake** (`lib/servicos/fake/servidor_fake.dart`) implementa exatamente
estas rotas e regras, em memória.

| Item | Valor |
|---|---|
| Prefixo | `/v1` |
| Formato | JSON UTF-8 |
| Autenticação | `Authorization: Bearer <token>` (token recebido em `/v1/sessoes` ou `/v1/pacientes`) |
| Data | `AAAA-MM-DD` |
| Data e hora | `AAAA-MM-DDTHH:mm` (horário local da clínica) |

## Rotas

| Método | Rota | Login | Onde o app usa |
|---|---|:---:|---|
| POST | `/v1/sessoes` | — | Entrar |
| POST | `/v1/pacientes` | — | Criar conta |
| GET | `/v1/pacientes/eu` | ✔ | Perfil |
| GET | `/v1/especialidades` | — | Início, filtros da Busca |
| GET | `/v1/medicos` | — | Início (mais bem avaliados), Busca |
| GET | `/v1/medicos/{id}` | — | Tela do profissional |
| GET | `/v1/medicos/{id}/horarios` | — | Agenda semanal |
| GET | `/v1/consultas` | ✔ | Início (próxima), Minhas consultas |
| POST | `/v1/consultas` | ✔ | Botão **Agendar** |
| POST | `/v1/consultas/{id}/cancelamento` | ✔ | Botão **Cancelar** |

## Formato de erro

Todo erro tem o mesmo corpo:

```json
{
  "codigo": "DADOS_INVALIDOS",
  "mensagem": "Alguns campos precisam de atenção.",
  "campos": { "celular": "Use DDD + 9 dígitos." }
}
```

`campos` só aparece quando o erro é de um campo específico.

| Status | Uso |
|---|---|
| 400 | `CORPO_INVALIDO`, `PARAMETRO_INVALIDO` |
| 401 | `CREDENCIAIS_INCORRETAS`, `NAO_AUTENTICADO` |
| 404 | `MEDICO_NAO_ENCONTRADO`, `CONSULTA_NAO_ENCONTRADA`, `ROTA_INEXISTENTE` |
| 409 | `EMAIL_EM_USO`, `HORARIO_INDISPONIVEL`, `CONFLITO_NA_AGENDA`, `JA_CANCELADA`, `JA_REALIZADA`, `PRAZO_ENCERRADO` |
| 422 | `DADOS_INVALIDOS`, `HORARIO_PASSADO`, `MODALIDADE_INDISPONIVEL` |

---

## Conta

### POST /v1/sessoes

```json
{ "email": "lucas@medagenda.app", "senha": "senha123" }
```

**200**

```json
{
  "token": "tk_p-001_1",
  "paciente": {
    "id": "p-001",
    "nome": "Lucas Andrade",
    "email": "lucas@medagenda.app",
    "celular": "62991234567",
    "nascimento": "1998-04-17"
  }
}
```

Erros: `422 DADOS_INVALIDOS` (campo vazio) · `401 CREDENCIAIS_INCORRETAS`.
O e-mail não diferencia maiúsculas/minúsculas.

### POST /v1/pacientes

```json
{
  "nome": "Beatriz Lima",
  "email": "bia@email.com",
  "celular": "(62) 99876-5432",
  "nascimento": "1995-03-02",
  "senha": "segura123"
}
```

| Campo | Regra |
|---|---|
| `nome` | nome e sobrenome |
| `email` | formato válido, ainda não cadastrado |
| `celular` | DDD + 9 dígitos (11 no total); máscara é aceita e removida |
| `nascimento` | data não futura |
| `senha` | 8+ caracteres com pelo menos um número |

**201** — mesmo corpo do login (o paciente já sai logado).
Erros: `422 DADOS_INVALIDOS` (todos os campos com problema em `campos`) · `409 EMAIL_EM_USO`.

> "Repita a senha" e "Aceito os termos" são validados só no app.

### GET /v1/pacientes/eu

**200** — objeto `paciente` (nunca inclui a senha).

---

## Catálogo

### GET /v1/especialidades

```json
[
  { "id": "cardio", "nome": "Cardiologia", "icone": "heart", "totalMedicos": 2 }
]
```

`icone` é um apelido (`heart`, `mind`, `food`…) que o app traduz para um ícone.

### GET /v1/medicos

| Query | Exemplo | Efeito |
|---|---|---|
| `especialidade` | `cardio` | filtra pela especialidade |
| `busca` | `nutricao` | procura em nome + especialidade, sem acento/maiúscula |
| `teleconsulta` | `true` | só quem atende online |
| `ordem` | `nota` (padrão), `valor`, `nome` | ordenação |
| `limite` | `5` | corta a lista |

```json
[
  {
    "id": "m-02",
    "nome": "Dra. Patrícia Nunes",
    "especialidadeId": "cardio",
    "especialidadeNome": "Cardiologia",
    "registro": "CRM-GO 18452",
    "nota": 4.9,
    "avaliacoes": 341,
    "valor": 280,
    "teleconsulta": false,
    "sobre": "Cardiologista com foco em hipertensão..."
  }
]
```

Erro: `400 PARAMETRO_INVALIDO` (`ordem` ou `teleconsulta` desconhecidos).

### GET /v1/medicos/{id}

**200** — um objeto como acima · **404** `MEDICO_NAO_ENCONTRADO`.

### GET /v1/medicos/{id}/horarios

| Query | Padrão | Regra |
|---|---|---|
| `inicio` | hoje | `AAAA-MM-DD` |
| `dias` | `7` | 1 a 21 dias corridos |

Devolve **todos** os dias do intervalo; os que o profissional não atende vêm com
`atende: false` (o app mostra riscados).

```json
{
  "medicoId": "m-01",
  "dias": [
    {
      "data": "2026-11-25",
      "atende": true,
      "horarios": [
        { "hora": "08:00", "livre": true },
        { "hora": "08:30", "livre": false }
      ]
    },
    { "data": "2026-11-28", "atende": false, "horarios": [] }
  ]
}
```

A grade sai da agenda do profissional (`diasSemana`, `inicio`, `fim`, `duracao`
em `assets/dados/base.json`). Um horário fica `livre: false` quando já passou,
quando já tem consulta agendada ou quando está ocupado por outros pacientes
(simulado de forma determinística, ~1 em cada 5 horários).

---

## Consultas (exigem login)

### Objeto `Consulta`

```json
{
  "id": "c-005",
  "medicoId": "m-01",
  "medicoNome": "Dr. Fernando Batista",
  "especialidadeNome": "Clínico geral",
  "inicio": "2026-11-25T09:00",
  "modalidade": "presencial",
  "motivo": "Dor de cabeça há 3 dias",
  "situacao": "agendada"
}
```

| `situacao` | Significado |
|---|---|
| `agendada` | ainda vai acontecer |
| `concluida` | o horário passou (calculado pelo servidor) |
| `cancelada` | cancelada pelo paciente |

### GET /v1/consultas?periodo=…

| `periodo` | Conteúdo | Ordem |
|---|---|---|
| `proximas` | agendadas | mais próxima primeiro |
| `anteriores` | concluídas e canceladas | mais recente primeiro |
| `todas` (padrão) | tudo | cronológica |

### POST /v1/consultas

```json
{
  "medicoId": "m-01",
  "inicio": "2026-11-25T09:00",
  "modalidade": "teleconsulta",
  "motivo": "opcional, até 140 caracteres"
}
```

**201** — `Consulta` com `situacao: "agendada"`.

| Status | Código | Quando |
|---|---|---|
| 422 | `DADOS_INVALIDOS` | campo ausente ou fora do formato |
| 422 | `HORARIO_PASSADO` | `inicio` já passou |
| 422 | `MODALIDADE_INDISPONIVEL` | teleconsulta com profissional só presencial |
| 404 | `MEDICO_NAO_ENCONTRADO` | — |
| 409 | `HORARIO_INDISPONIVEL` | fora da grade ou já ocupado |
| 409 | `CONFLITO_NA_AGENDA` | paciente já tem consulta no mesmo horário |

Quando recebe `409`, o app recarrega a agenda e desmarca o horário.

### POST /v1/consultas/{id}/cancelamento

Sem corpo. **200** — `Consulta` com `situacao: "cancelada"`; o horário volta a ficar livre.

| Status | Código | Quando |
|---|---|---|
| 404 | `CONSULTA_NAO_ENCONTRADA` | não existe ou é de outro paciente |
| 409 | `JA_CANCELADA` | — |
| 409 | `JA_REALIZADA` | consulta concluída |
| 409 | `PRAZO_ENCERRADO` | faltam menos de 2 horas |

---

## Dados de demonstração

`assets/dados/base.json` traz 1 paciente, 8 especialidades, 9 profissionais e 4
consultas. As datas das consultas são **relativas ao dia em que o app abre**
(`diasAPartirDeHoje`), então sempre há consultas futuras e passadas.

| E-mail | Senha |
|---|---|
| `lucas@medagenda.app` | `senha123` |
