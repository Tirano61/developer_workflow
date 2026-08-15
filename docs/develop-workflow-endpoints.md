# Develop Workflow Endpoints

Base URL:
- http://localhost:3000/api/v1

Autenticacion:
- Usuario autenticado: requiere JWT Bearer valido.
- Developer: requiere JWT Bearer con rol developer.

## Applications

### GET /develop-workflow/applications
- Auth: Usuario autenticado
- Descripcion: Lista solo applications activas.

### GET /develop-workflow/applications/all
- Auth: Developer
- Descripcion: Lista applications activas e inactivas.

### GET /develop-workflow/applications/:id
- Auth: Usuario autenticado
- Descripcion: Obtiene una application activa por id.

### GET /develop-workflow/applications/all/:id
- Auth: Developer
- Descripcion: Obtiene una application por id incluyendo inactivas.

### POST /develop-workflow/applications
- Auth: Developer
- Body:
```json
{
  "name": "Remoto",
  "description": "Aplicacion de asistencia remota"
}
```

### PATCH /develop-workflow/applications/:id
- Auth: Developer
- Body:
```json
{
  "name": "Remoto V2",
  "description": "Descripcion actualizada"
}
```

### PATCH /develop-workflow/applications/:id/active
- Auth: Developer
- Body:
```json
{
  "active": false
}
```

## Indicators

### GET /develop-workflow/indicators
- Auth: Usuario autenticado
- Descripcion: Lista solo indicators activos.

### GET /develop-workflow/indicators/all
- Auth: Developer
- Descripcion: Lista indicators activos e inactivos.

### GET /develop-workflow/indicators/:id
- Auth: Usuario autenticado
- Descripcion: Obtiene un indicator activo por id.

### GET /develop-workflow/indicators/all/:id
- Auth: Developer
- Descripcion: Obtiene un indicator por id incluyendo inactivos.

### POST /develop-workflow/indicators
- Auth: Developer
- Body:
```json
{
  "name": "ST-456",
  "description": "Indicador de prueba"
}
```

### PATCH /develop-workflow/indicators/:id
- Auth: Developer
- Body:
```json
{
  "name": "ST-456-NEW",
  "description": "Descripcion actualizada"
}
```

### PATCH /develop-workflow/indicators/:id/active
- Auth: Developer
- Body:
```json
{
  "active": false
}
```

## Relations Application <-> Indicator

### POST /develop-workflow/applications/:applicationId/indicators/:indicatorId
- Auth: Developer
- Descripcion: Asocia un indicator a una application.

### DELETE /develop-workflow/applications/:applicationId/indicators/:indicatorId
- Auth: Developer
- Descripcion: Elimina asociacion entre application e indicator.

### GET /develop-workflow/applications/:applicationId/indicators
- Auth: Usuario autenticado
- Descripcion: Lista indicators activos asociados a una application.

### GET /develop-workflow/indicators/:indicatorId/applications
- Auth: Usuario autenticado
- Descripcion: Lista applications activas asociadas a un indicator.

## Discussions

### POST /develop-workflow/discussions
- Auth: Usuario autenticado
- Descripcion: Crea una discussion con estado inicial NEW y createdBy tomado del token. Requiere initialMessageContent y crea el primer DiscussionMessage de tipo TEXT en la misma transaccion.
- Body:
```json
{
  "type": "ERROR",
  "title": "Problema en la app remota",
  "initialMessageContent": "Descripcion inicial del problema",
  "applicationIds": ["{{applicationId}}"],
  "indicatorIds": ["{{indicatorId}}"],
  "tagIds": ["{{tagId}}"]
}
```

### GET /develop-workflow/discussions
- Auth: Usuario autenticado
- Descripcion: Lista discussions paginadas con filtros. Cada item incluye `isUnread` calculado para el usuario autenticado.
- Query params opcionales:
  - page (default 1)
  - limit (default 20)
  - type (ERROR | IDEA | IMPROVEMENT | QUESTION)
  - status (NEW | REVIEW | IN_PROGRESS | RESOLVED)
  - applicationIds (CSV de UUIDs)
  - indicatorIds (CSV de UUIDs)
  - tagIds (CSV de UUIDs)
  - createdBy (UUID de usuario)
  - mine (true|false)
  - assignedToMe (true|false)
  - assignedDeveloperId (UUID de developer asignado)
  - unread (true|false)

### GET /develop-workflow/discussions/:id
- Auth: Usuario autenticado
- Descripcion: Obtiene una discussion por id con creador, applications, indicators y tags. Incluye `isUnread` para el usuario autenticado.

### POST /develop-workflow/discussions/:id/read
- Auth: Usuario autenticado
- Descripcion: Marca la discussion como leida para el usuario autenticado (idempotente, usa UPSERT por `(discussion_id, user_id)`).

### PATCH /develop-workflow/discussions/:id
- Auth: Usuario autenticado
- Descripcion: Actualiza discussion (propia o cualquiera si rol developer).
- Body:
```json
{
  "type": "IMPROVEMENT",
  "title": "Titulo actualizado",
  "applicationIds": ["{{applicationId}}"],
  "indicatorIds": ["{{indicatorId}}"],
  "tagIds": ["{{tagId}}"]
}
```

### PATCH /develop-workflow/discussions/:id/status
- Auth: Developer
- Descripcion: Cambia el estado Kanban de la discussion. No impone flujo lineal de transicion.
- Body:
```json
{
  "status": "IN_PROGRESS"
}
```

### GET /develop-workflow/developers
- Auth: Usuario autenticado
- Descripcion: Lista usuarios activos asignables como developers (id, fullName, email).

### POST /develop-workflow/discussions/:id/assignments
- Auth: Developer
- Descripcion: Agrega developers asignados (sin duplicar).
- Body:
```json
{
  "developerUserIds": ["{{developerUserId}}"]
}
```

### PUT /develop-workflow/discussions/:id/assignments
- Auth: Developer
- Descripcion: Reemplaza completamente la coleccion de developers asignados.
- Body:
```json
{
  "developerUserIds": ["{{developerUserId}}"]
}
```

### DELETE /develop-workflow/discussions/:id/assignments/:developerUserId
- Auth: Developer
- Descripcion: Quita un developer asignado de la discussion.

## Discussion relations (Developer)

### POST /develop-workflow/discussions/:id/applications
- Auth: Developer
- Body:
```json
{
  "applicationId": "{{applicationId}}"
}
```

### DELETE /develop-workflow/discussions/:id/applications/:applicationId
- Auth: Developer

### POST /develop-workflow/discussions/:id/indicators
- Auth: Developer
- Body:
```json
{
  "indicatorId": "{{indicatorId}}"
}
```

### DELETE /develop-workflow/discussions/:id/indicators/:indicatorId
- Auth: Developer

### POST /develop-workflow/discussions/:id/tags
- Auth: Developer
- Body:
```json
{
  "tagId": "{{tagId}}"
}
```

### DELETE /develop-workflow/discussions/:id/tags/:tagId
- Auth: Developer

## Discussion Messages

### POST /develop-workflow/discussions/:discussionId/messages
- Auth: Usuario autenticado
- Descripcion: Crea un mensaje TEXT dentro de la discussion usando author del token. El autor queda marcado como leido hasta ese momento.
- Body:
```json
{
  "type": "TEXT",
  "content": "Necesitamos revisar este caso en produccion"
}
```

### POST /develop-workflow/discussions/:discussionId/messages/files
- Auth: Usuario autenticado
- Content-Type: multipart/form-data
- Descripcion: Sube un archivo a Cloudinary y crea un DiscussionMessage de tipo IMAGE, AUDIO, VIDEO o FILE. El autor queda marcado como leido hasta ese momento.
- Form-data:
  - type (IMAGE | AUDIO | VIDEO | FILE)
  - file (binary)
  - content (opcional, texto adicional)

### GET /develop-workflow/discussions/:discussionId/messages
- Auth: Usuario autenticado
- Descripcion: Lista mensajes de la discussion en orden cronologico ascendente.
- Query params opcionales:
  - page (default 1)
  - limit (default 50)
  - type (TEXT | IMAGE | AUDIO | VIDEO | FILE)

### PATCH /develop-workflow/discussions/:discussionId/messages/:messageId
- Auth: Usuario autenticado
- Descripcion: Actualiza el contenido de un mensaje (autor del mensaje o developer).
- Body:
```json
{
  "content": "Actualizacion del mensaje"
}
```

## Tags

### GET /develop-workflow/tags
- Auth: Usuario autenticado
- Descripcion: Lista tags activas.

### GET /develop-workflow/tags/all
- Auth: Developer
- Descripcion: Lista tags activas e inactivas.

### POST /develop-workflow/tags
- Auth: Developer
- Body:
```json
{
  "name": "Urgente"
}
```

### PATCH /develop-workflow/tags/:id
- Auth: Developer
- Body:
```json
{
  "name": "Urgencia alta"
}
```

### PATCH /develop-workflow/tags/:id/active
- Auth: Developer
- Body:
```json
{
  "active": false
}
```

## Variables recomendadas para pruebas
- applicationId: UUID valido de dw_applications
- indicatorId: UUID valido de dw_indicators
- discussionId: UUID valido de dw_discussions
- tagId: UUID valido de dw_tags
- messageId: UUID valido de dw_discussion_messages
- developerUserId: UUID valido de users con rol developer

## Read State / Unread

- El estado `status` de la discussion (NEW, REVIEW, IN_PROGRESS, RESOLVED) representa flujo de trabajo global y no se usa para leido/no leido.
- El estado de lectura es por usuario y se guarda en `dw_discussion_read_states` con `lastReadAt`.
- Si no existe read-state para una discussion+usuario, se interpreta como "nunca leida".
- `isUnread` se calcula comparando `lastReadAt` contra la ultima actividad de la discussion.
- Actividad nueva considerada en backend:
  - nuevo mensaje (TEXT, IMAGE, AUDIO, VIDEO, FILE);
  - cualquier actualizacion de la discussion que impacte `updatedAt` (ej: cambios de status, asignaciones, relaciones/contexto, edicion).
