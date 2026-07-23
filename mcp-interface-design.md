# Weaver MCP Interface Design

## Purpose

This document describes a new set of API endpoints designed to expose Weaver to an AI system via the Model Context Protocol (MCP). The goal is to give an AI assistant enough read access to understand a user's workspaces — what is happening, what needs attention, who is involved — and enough write access to take meaningful actions on the user's behalf.

The design follows three principles:
1. **Context-first** — endpoints return rich, connected summaries rather than raw collection dumps. An AI should be able to understand the state of a workspace from a small number of calls.
2. **Safe by default** — read operations are always available; write operations are narrow and explicit.
3. **Grounded** — every item returned carries the identifiers needed to navigate deeper or take action.

All endpoints live under a `/mcp/` prefix to distinguish them from the existing UI-facing API.

---

## Authentication

All MCP endpoints use the same `AuthRequest` mechanism as the existing API. The authenticated user's identity determines which workspaces are visible and what write operations are permitted. No new authentication model is required.

---

## Endpoint Overview

| # | Endpoint | Method | Purpose |
|---|----------|--------|---------|
| 1 | `/mcp/myWorkspaces.json` | GET | List all workspaces the user belongs to |
| 2 | `/mcp/recentActivity.json` | GET | Recent changes across the user's workspaces |
| 3 | `/{siteId}/{pageId}/mcp/workspaceSummary.json` | GET | Full context snapshot of one workspace |
| 4 | `/{siteId}/{pageId}/mcp/openItems.json` | GET | All unresolved work in a workspace |
| 5 | `/{siteId}/{pageId}/mcp/search.json` | POST | Full-text search within a workspace |
| 6 | `/mcp/searchAll.json` | POST | Full-text search across all accessible workspaces |
| 7 | `/{siteId}/{pageId}/mcp/topicDetail.json` | GET | A topic and full discussion thread |
| 8 | `/{siteId}/{pageId}/mcp/goalDetail.json` | GET | A goal with history and linked items |
| 9 | `/{siteId}/{pageId}/mcp/meetingDetail.json` | GET | A meeting with agenda, attendees, and linked items |
| 10 | `/{siteId}/{pageId}/mcp/createTopic.json` | POST | Create a new discussion topic |
| 11 | `/{siteId}/{pageId}/mcp/createGoal.json` | POST | Create a new action item |
| 12 | `/{siteId}/{pageId}/mcp/updateGoalState.json` | POST | Change the state of a goal |
| 13 | `/{siteId}/{pageId}/mcp/addComment.json` | POST | Add a comment to any workspace object |
| 14 | `/{siteId}/{pageId}/mcp/createMeeting.json` | POST | Create a new meeting with agenda |
| 15 | `/mcp/userContext.json` | GET | Who the authenticated user is and their role memberships |

---

## Read Endpoints

---

### 1. `GET /mcp/myWorkspaces.json`

**Purpose**: Returns all workspaces the user is a member of, sorted by most recently changed. This is the entry point — an AI would call this first to discover what exists.

**Query Parameters**:
- `site` (string, optional) — filter to one site
- `watching` (boolean, optional) — if `true`, only return workspaces the user is watching
- `limit` (integer, optional, default 50) — max results

**Output Schema**:
```json
{
  "user": "string (authenticated user email)",
  "workspaces": [
    {
      "siteId": "string",
      "siteName": "string",
      "pageId": "string",
      "name": "string",
      "lastChanged": "number (epoch ms)",
      "isFrozen": "boolean",
      "isWatching": "boolean",
      "isNotified": "boolean",
      "parentPageId": "string (null if top-level)",
      "summaryUrl": "string (URL to call workspaceSummary.json for this workspace)"
    }
  ]
}
```

**Notes**: Uses `Cognoscenti.getWorkspacesUserIsIn()` sorted by `NGPageIndex.lastChange` descending. `summaryUrl` is a convenience field so the AI can immediately follow up without constructing URLs manually.

---

### 2. `GET /mcp/recentActivity.json`

**Purpose**: Returns a time-ordered feed of recent changes across all workspaces the user can see. Answers the question "what has happened lately?"

**Query Parameters**:
- `since` (number, optional) — epoch ms timestamp; only return activity after this time (defaults to 7 days ago)
- `limit` (integer, optional, default 30) — max items
- `site` (string, optional) — scope to one site

**Output Schema**:
```json
{
  "since": "number (epoch ms — start of the window)",
  "items": [
    {
      "time": "number (epoch ms)",
      "workspaceName": "string",
      "siteId": "string",
      "pageId": "string",
      "type": "string (TOPIC | GOAL | MEETING | DOCUMENT | COMMENT | ROLE)",
      "action": "string (created | updated | closed | commented | etc.)",
      "subject": "string (title or summary of the changed item)",
      "itemId": "string (ID of the changed item)",
      "actor": "string (user email who made the change)",
      "detailUrl": "string (URL to fetch full detail for this item)"
    }
  ]
}
```

**Notes**: Built by iterating `getWorkspacesUserIsIn()`, loading each workspace's history records (already stored per-workspace in `HistoryRecord`), merging and sorting them. The `detailUrl` points to the appropriate MCP detail endpoint (e.g. `topicDetail.json?nid=…`).

---

### 3. `GET /{siteId}/{pageId}/mcp/workspaceSummary.json`

**Purpose**: Returns a complete, self-contained context snapshot of one workspace. An AI should be able to call this single endpoint and understand the state of a team's work — who is in it, what is open, recent discussions, upcoming meetings.

**Output Schema**:
```json
{
  "siteId": "string",
  "pageId": "string",
  "name": "string",
  "description": "string",
  "isFrozen": "boolean",
  "lastChanged": "number (epoch ms)",
  "roles": [
    {
      "id": "string",
      "name": "string",
      "members": ["array of user emails"]
    }
  ],
  "labels": [
    { "id": "string", "name": "string", "color": "string" }
  ],
  "openGoals": [
    {
      "id": "string",
      "subject": "string",
      "state": "string",
      "assignTo": "string",
      "dueDate": "number (epoch ms, or null)",
      "priority": "number",
      "labels": ["array of label names"]
    }
  ],
  "recentTopics": [
    {
      "id": "string",
      "subject": "string",
      "discussionPhase": "string",
      "modified": "number (epoch ms)",
      "commentCount": "number"
    }
  ],
  "upcomingMeetings": [
    {
      "id": "string",
      "name": "string",
      "scheduledTime": "number (epoch ms)",
      "agendaItemCount": "number"
    }
  ],
  "recentDocuments": [
    {
      "id": "string",
      "name": "string",
      "modified": "number (epoch ms)"
    }
  ],
  "stats": {
    "totalGoals": "number",
    "openGoals": "number",
    "totalTopics": "number",
    "totalMeetings": "number",
    "totalDocuments": "number"
  }
}
```

**Notes**: `recentTopics` returns the 10 most recently modified topics. `upcomingMeetings` returns meetings with `scheduledTime > now`, sorted ascending. `openGoals` returns goals not in `COMPLETE` or `SKIPPED` state.

---

### 4. `GET /{siteId}/{pageId}/mcp/openItems.json`

**Purpose**: Returns every piece of unresolved work in the workspace — open goals, unresolved topics, upcoming meetings. Optimized for letting an AI answer "what still needs to be done here?"

**Output Schema**:
```json
{
  "openGoals": [
    {
      "id": "string",
      "subject": "string",
      "state": "string",
      "assignTo": "string",
      "dueDate": "number (epoch ms, or null)",
      "overdue": "boolean",
      "priority": "number",
      "labels": ["array of label names"]
    }
  ],
  "unresolvedTopics": [
    {
      "id": "string",
      "subject": "string",
      "discussionPhase": "string",
      "modified": "number (epoch ms)",
      "commentCount": "number"
    }
  ],
  "upcomingMeetings": [
    {
      "id": "string",
      "name": "string",
      "scheduledTime": "number (epoch ms)",
      "agendaItemCount": "number"
    }
  ]
}
```

**Notes**: `overdue` is `true` when `dueDate < now` and state is not `COMPLETE`/`SKIPPED`. `unresolvedTopics` excludes phases `RESOLVED` and `TRASH`.

---

### 5. `POST /{siteId}/{pageId}/mcp/search.json`

**Purpose**: Full-text search within a single workspace across all content types. Lets an AI find relevant items when the user asks about a specific topic, person, or keyword.

**Input Schema**:
```json
{
  "query": "string (search terms)",
  "types": ["array of strings: TOPIC | GOAL | MEETING | DOCUMENT | COMMENT (optional, default all)"],
  "limit": "number (optional, default 20)"
}
```

**Output Schema**:
```json
{
  "query": "string",
  "results": [
    {
      "type": "string (TOPIC | GOAL | MEETING | DOCUMENT | COMMENT)",
      "id": "string",
      "subject": "string",
      "snippet": "string (excerpt showing where the match appears)",
      "modified": "number (epoch ms)",
      "score": "number (relevance, higher is better)"
    }
  ]
}
```

---

### 6. `POST /mcp/searchAll.json`

**Purpose**: Full-text search across all workspaces the user can access. Lets an AI answer questions like "find everything related to the budget proposal" without knowing which workspace it lives in.

**Input Schema**:
```json
{
  "query": "string",
  "site": "string (optional — restrict to one site)",
  "types": ["array of content type strings (optional)"],
  "limit": "number (optional, default 20)"
}
```

**Output Schema**:
```json
{
  "query": "string",
  "results": [
    {
      "siteId": "string",
      "pageId": "string",
      "workspaceName": "string",
      "type": "string",
      "id": "string",
      "subject": "string",
      "snippet": "string",
      "modified": "number (epoch ms)"
    }
  ]
}
```

**Notes**: Uses the existing `searchNotes.json` infrastructure but aggregates across workspaces and extends to goals/meetings/documents.

---

### 7. `GET /{siteId}/{pageId}/mcp/topicDetail.json`

**Purpose**: Returns a topic with its full discussion thread, formatted so an AI can understand the arc of the conversation — what was proposed, what was debated, what was concluded.

**Query Parameters**: `nid` (string — topic ID)

**Output Schema**:
```json
{
  "id": "string",
  "subject": "string",
  "body": "string (HTML content)",
  "discussionPhase": "string",
  "created": "number (epoch ms)",
  "modified": "number (epoch ms)",
  "subscribers": ["array of user emails"],
  "labels": ["array of label names"],
  "comments": [
    {
      "id": "string",
      "type": "string (SIMPLE | PROPOSAL | REQUEST | PHASE_CHANGE)",
      "html": "string",
      "author": "string (user email)",
      "time": "number (epoch ms)",
      "replyToId": "string (null if top-level)",
      "replies": ["array of comment IDs"]
    }
  ],
  "attachedDocuments": [
    { "id": "string", "name": "string" }
  ],
  "attachedGoals": [
    { "id": "string", "subject": "string", "state": "string" }
  ],
  "history": [
    { "time": "number (epoch ms)", "actor": "string", "action": "string" }
  ]
}
```

---

### 8. `GET /{siteId}/{pageId}/mcp/goalDetail.json`

**Purpose**: Returns a goal with its full context: history of state changes, who it is assigned to, linked documents, linked topics, and any sub-goals.

**Query Parameters**: `gid` (string — goal ID)

**Output Schema**:
```json
{
  "id": "string",
  "subject": "string",
  "description": "string",
  "state": "string",
  "assignTo": "string (user email)",
  "dueDate": "number (epoch ms, or null)",
  "priority": "number",
  "percentComplete": "number",
  "labels": ["array of label names"],
  "taskArea": "string (task area name, or null)",
  "parentGoalId": "string (or null)",
  "subGoals": [
    { "id": "string", "subject": "string", "state": "string" }
  ],
  "history": [
    {
      "time": "number (epoch ms)",
      "actor": "string",
      "action": "string",
      "fromState": "string (or null)",
      "toState": "string (or null)"
    }
  ],
  "attachedDocuments": [
    { "id": "string", "name": "string" }
  ],
  "linkedTopics": [
    { "id": "string", "subject": "string", "discussionPhase": "string" }
  ]
}
```

---

### 9. `GET /{siteId}/{pageId}/mcp/meetingDetail.json`

**Purpose**: Returns a meeting with everything an AI needs to understand it — agenda, attendee responses, linked action items, linked documents, and notes/minutes.

**Query Parameters**: `id` (string — meeting ID)

**Output Schema**:
```json
{
  "id": "string",
  "name": "string",
  "scheduledTime": "number (epoch ms)",
  "duration": "number (minutes)",
  "state": "string (DRAFT | PLANNING | RUNNING | COMPLETED)",
  "conferenceUrl": "string (or null)",
  "agenda": [
    {
      "id": "string",
      "subject": "string",
      "duration": "number (minutes)",
      "presenter": "string (user email, or null)",
      "notes": "string (or null)",
      "attachedDocuments": [{ "id": "string", "name": "string" }],
      "attachedGoals": [{ "id": "string", "subject": "string", "state": "string" }]
    }
  ],
  "attendees": [
    {
      "uid": "string (user email)",
      "name": "string",
      "situation": "string (attending | tentative | unavailable | no-response)"
    }
  ],
  "minutes": "string (HTML, or null if not yet created)",
  "attachedDocuments": [
    { "id": "string", "name": "string" }
  ]
}
```

---

## Write Endpoints

Write operations are intentionally narrow. They create new content or make clearly defined state transitions — they do not expose arbitrary field-level updates.

---

### 10. `POST /{siteId}/{pageId}/mcp/createTopic.json`

**Purpose**: Creates a new discussion topic. Appropriate when an AI needs to capture a decision, record a proposal, or start a discussion thread on behalf of a user.

**Input Schema**:
```json
{
  "subject": "string (topic title, required)",
  "body": "string (HTML body, required)",
  "discussionPhase": "string (optional, default FREEFORM — DRAFT | FREEFORM | FORMING | SHAPING)",
  "labels": ["array of label names (optional)"]
}
```

**Output Schema**:
```json
{
  "id": "string (newly created topic ID)",
  "subject": "string",
  "created": "number (epoch ms)"
}
```

**Notes**: Delegates to the existing `noteHtmlUpdate.json` with `nid=~new~`. The AI is recorded as the author via the authenticated user.

---

### 11. `POST /{siteId}/{pageId}/mcp/createGoal.json`

**Purpose**: Creates a new action item. Appropriate when an AI identifies a task that needs tracking — for example, extracting action items from a meeting discussion.

**Input Schema**:
```json
{
  "subject": "string (required)",
  "description": "string (optional)",
  "assignTo": "string (user email, optional)",
  "dueDate": "number (epoch ms, optional)",
  "priority": "number (optional, default 3)",
  "labels": ["array of label names (optional)"],
  "taskArea": "string (task area name, optional)"
}
```

**Output Schema**:
```json
{
  "id": "string (newly created goal ID)",
  "subject": "string",
  "state": "string",
  "created": "number (epoch ms)"
}
```

---

### 12. `POST /{siteId}/{pageId}/mcp/updateGoalState.json`

**Purpose**: Changes a goal's state. The most common write action for a goal — marking it complete, accepting it, or flagging it as blocked.

**Input Schema**:
```json
{
  "gid": "string (goal ID, required)",
  "state": "string (UNSTARTED | OFFERED | ACCEPTED | WAITING | COMPLETE | SKIPPED | ERROR, required)",
  "note": "string (optional comment explaining the state change)"
}
```

**Output Schema**:
```json
{
  "id": "string",
  "subject": "string",
  "previousState": "string",
  "newState": "string",
  "time": "number (epoch ms)"
}
```

**Notes**: If `note` is provided, a comment is automatically added to the goal recording the reason for the state change. Delegates to `updateGoal.json` but validates the transition and rejects invalid states.

---

### 13. `POST /{siteId}/{pageId}/mcp/addComment.json`

**Purpose**: Adds a comment to any workspace object (topic, document, meeting, or agenda item). Used when an AI needs to contribute to a discussion or annotate an item.

**Input Schema**:
```json
{
  "targetType": "string (TOPIC | DOCUMENT | MEETING | AGENDA, required)",
  "targetId": "string (ID of the target object, required)",
  "agendaId": "string (required only when targetType is AGENDA)",
  "html": "string (comment HTML content, required)",
  "commentType": "string (optional, default SIMPLE — SIMPLE | PROPOSAL | REQUEST)"
}
```

**Output Schema**:
```json
{
  "commentId": "string",
  "targetType": "string",
  "targetId": "string",
  "time": "number (epoch ms)",
  "author": "string (authenticated user email)"
}
```

---

### 14. `POST /{siteId}/{pageId}/mcp/createMeeting.json`

**Purpose**: Creates a new meeting with an initial agenda. Useful when an AI is helping plan a team session.

**Input Schema**:
```json
{
  "name": "string (required)",
  "scheduledTime": "number (epoch ms, required)",
  "duration": "number (minutes, required)",
  "conferenceUrl": "string (optional)",
  "agenda": [
    {
      "subject": "string (required)",
      "duration": "number (minutes, required)",
      "presenter": "string (user email, optional)"
    }
  ]
}
```

**Output Schema**:
```json
{
  "id": "string (newly created meeting ID)",
  "name": "string",
  "scheduledTime": "number (epoch ms)",
  "agendaItemCount": "number"
}
```

---

### 15. `GET /mcp/userContext.json`

**Purpose**: Returns the identity of the authenticated user, their site memberships, and a digest of their workspace involvements. An AI calls this at the start of a session to understand who it is acting as and what they have access to.

**Output Schema**:
```json
{
  "uid": "string (user email)",
  "name": "string (display name)",
  "sites": [
    {
      "siteId": "string",
      "siteName": "string",
      "role": "string (owner | executive | member)"
    }
  ],
  "watchedWorkspaces": [
    {
      "siteId": "string",
      "pageId": "string",
      "name": "string",
      "lastReviewTime": "number (epoch ms)"
    }
  ],
  "totalWorkspaceCount": "number (total workspaces user is a member of)"
}
```

---

## Error Responses

All MCP endpoints return a consistent error shape on failure:

```json
{
  "error": true,
  "code": "string (e.g. NOT_FOUND | FORBIDDEN | INVALID_INPUT | INTERNAL_ERROR)",
  "message": "string (human-readable explanation)",
  "detail": "string (optional technical detail for debugging)"
}
```

HTTP status codes follow standard conventions: 400 for bad input, 403 for permission failures, 404 for missing items, 500 for server errors.

---

## Implementation Notes

### Controller Placement

All MCP endpoints should live in a new `McpController.java`. Cross-workspace endpoints (1, 2, 6, 15) are site-agnostic and take no `siteId`/`pageId` path variables. Workspace-scoped endpoints (3–14) follow the existing `/{siteId}/{pageId}/...` pattern and can reuse the standard `AuthRequest` setup.

### Delegation to Existing Logic

The MCP endpoints are thin wrappers — they should delegate to existing model and service methods rather than duplicating logic:

| MCP Endpoint | Delegates to |
|---|---|
| `myWorkspaces.json` | `Cognoscenti.getWorkspacesUserIsIn()` |
| `recentActivity.json` | Per-workspace `HistoryRecord` list, merged and sorted |
| `workspaceSummary.json` | `getAllGoals()`, `getAllDiscussionTopics()`, `getMeetings()`, `getAllAttachments()` |
| `openItems.json` | Same collections, filtered by state |
| `search.json` / `searchAll.json` | Existing `searchNotes` infrastructure, extended |
| `topicDetail.json` | `TopicRecord`, `getComments()`, `attachedDocs` |
| `goalDetail.json` | `GoalRecord`, `getGoalHistory()`, `attachedDocs` |
| `meetingDetail.json` | `MeetingRecord`, `getAgendaItems()`, `attachedDocs` |
| `createTopic.json` | `noteHtmlUpdate.json` with `nid=~new~` |
| `createGoal.json` | `updateGoal.json` |
| `updateGoalState.json` | `updateGoal.json` with state field + optional comment |
| `addComment.json` | `SaveReply.json` |
| `createMeeting.json` | `meetingCreate.json` |

### HTML vs Plain Text

Many existing model objects store content as HTML. MCP endpoints should return HTML as-is (an LLM handles HTML fine) but should strip `<script>` tags before emitting. For the `snippet` field in search results, strip all tags and return plain text.

### Response Size Limits

`workspaceSummary.json` caps `recentTopics` at 10 and `openGoals` at 50 to avoid overwhelming context windows. `recentActivity.json` defaults to a 7-day window. Search results default to 20 items. All limits are overridable via query parameters.

### Read-Only Enforcement

The four write endpoints (10–14) should check `canUpdateWorkspace(user)` and return `403 FORBIDDEN` for frozen workspaces or users without edit rights. The state-change endpoint (12) should additionally validate that the requested state transition is legal.

---

## Suggested MCP Tool Names

When exposing these endpoints as MCP tools, the following names and descriptions provide good signal to an AI:

| Tool Name | MCP Description |
|-----------|----------------|
| `list_workspaces` | List all workspaces you are a member of, sorted by most recently changed |
| `recent_activity` | What has changed across your workspaces in the last N days |
| `workspace_summary` | Full snapshot of one workspace: members, open work, recent discussions, upcoming meetings |
| `open_items` | All unresolved goals and active discussions in a workspace |
| `search_workspace` | Find topics, goals, meetings, or documents in a workspace by keyword |
| `search_all` | Find content across all accessible workspaces by keyword |
| `topic_detail` | Read a discussion topic and its full comment thread |
| `goal_detail` | Read an action item with its history and linked content |
| `meeting_detail` | Read a meeting with its agenda and attendee responses |
| `create_topic` | Start a new discussion topic in a workspace |
| `create_goal` | Create a new action item in a workspace |
| `update_goal_state` | Mark a goal as complete, accepted, waiting, or skipped |
| `add_comment` | Add a comment to a topic, document, meeting, or agenda item |
| `create_meeting` | Schedule a new meeting with an agenda |
| `user_context` | Who you are and which workspaces you have access to |
