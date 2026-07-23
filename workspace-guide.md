# Understanding Workspaces in Cognoscenti

## What Is a Workspace?

A **workspace** is the fundamental unit of collaboration in Cognoscenti. Think of it as a shared, persistent project room — a place where a team organizes its work, holds discussions, tracks action items, manages documents, and schedules meetings, all in one location.

Every workspace belongs to a **site**. A site is the top-level organizational container (roughly equivalent to a company or department), and it can hold many workspaces. A site defines the shared role types available to all its workspaces and manages billing and user directories. Within a site, workspaces are independent — each has its own membership, its own content, and its own settings.

A workspace can optionally have a **parent workspace**, which creates a hierarchy of workspaces within a site. This is useful for organizing large programs that have multiple sub-teams or phases.

---

## Identifying a Workspace

Every workspace is uniquely identified by two keys used together:

| Key | Description | Example |
|-----|-------------|---------|
| `siteId` | The site it belongs to | `acme` |
| `pageId` | The workspace key within that site | `q4-roadmap` |

These two keys appear as path segments in every API URL:

```
/{siteId}/{pageId}/someEndpoint.json
```

And in the browser:

```
t/{siteId}/{pageId}/FrontPage.htm
```

A workspace also has a globally unique combined key in the form `siteId|pageId`, and internally a `globalContainerKey` in the form `S{siteId}|W{pageId}`.

---

## Workspace Lifecycle States

A workspace progresses through states as a team's work evolves:

| State | Meaning |
|-------|---------|
| **Active** | Normal, open for editing and contribution |
| **Frozen** | Read-only preserved archive; content is visible but cannot be changed |
| **Deleted** | Soft-deleted; invisible to most users but retained for ~90 days before permanent removal |

Freezing a workspace is appropriate when a project has concluded and the team wants to preserve the record without risk of accidental changes. The `frozen` and `deleted` flags, along with the timestamps and user who made the change, are stored in the workspace metadata.

---

## What Lives Inside a Workspace

A workspace is a container for six types of content, plus configuration.

```
Workspace
 ├── Topics (discussions)
 │    └── Comments (threaded replies)
 ├── Goals (action items / tasks)
 ├── Meetings
 │    └── Agenda Items
 │         └── Comments
 ├── Documents (file attachments)
 │    └── Comments
 ├── Labels (tags for organizing content)
 └── Roles (who can do what)
```

---

### Topics (Discussions)

A **topic** is a discussion thread. It has a subject line and a body written in wiki markup. Team members can post comments in reply, creating a threaded conversation. Topics are the primary place for capturing decisions, proposals, and ongoing discussions.

Each topic moves through a **discussion phase** that reflects how mature the conversation is:

| Phase | Meaning |
|-------|---------|
| `DRAFT` | Being drafted, not yet shared |
| `FREEFORM` | Open brainstorming |
| `FORMING` | Ideas being formed |
| `SHAPING` | Narrowing toward a conclusion |
| `FINALIZING` | Nearly decided |
| `RESOLVED` | Decision or outcome reached |
| `TRASH` | Marked for removal |

Any user with workspace access can subscribe to a topic to receive email notifications when new comments are posted.

**Key APIs:**
- `GET /{siteId}/{pageId}/topicList.json` — list all topics
- `GET /{siteId}/{pageId}/getTopic.json?nid={topicId}` — get a topic with its comments
- `POST /{siteId}/{pageId}/noteHtmlUpdate.json?nid=~new~` — create a new topic
- `POST /{siteId}/{pageId}/noteHtmlUpdate.json?nid={topicId}` — update a topic
- `POST /{siteId}/{pageId}/mergeTopicDoc.json` — apply a collaborative merge to a topic's content
- `GET /{siteId}/{pageId}/getNoteHistory.json?nid={topicId}` — view change history
- `GET /{siteId}/{pageId}/topicSubscribe.json?nid={topicId}` — subscribe to notifications
- `GET /{siteId}/{pageId}/topicUnsubscribe.json?nid={topicId}` — unsubscribe

**Representative response for `getTopic.json`:**
```json
{
  "id": "0042",
  "subject": "Proposal: switch to async API pattern",
  "html": "<p>After reviewing the current approach...</p>",
  "modified": 1721654400000,
  "discussionPhase": "SHAPING",
  "comments": [
    {
      "id": "1721654450000",
      "html": "<p>I agree, but we need to handle retries.</p>",
      "author": "alice@example.com",
      "time": 1721654450000
    }
  ]
}
```

---

### Goals (Action Items / Tasks)

A **goal** is a tracked task or action item assigned to one or more people. Goals are the workspace's task board — they represent commitments, deliverables, and outstanding work.

Each goal tracks:
- A subject and description
- An assignee (or multiple assignees via a role)
- A due date and priority
- A percent-complete estimate
- A state that reflects where it is in its lifecycle

**Goal states:**

| State | Meaning |
|-------|---------|
| `UNSTARTED` | Not yet begun |
| `OFFERED` | Proposed but not accepted |
| `ACCEPTED` | Assignee has accepted the task |
| `WAITING` | Blocked on something external |
| `COMPLETE` | Done |
| `SKIPPED` | Consciously not done |
| `ERROR` | Problem encountered |

Goals can be organized into **task areas** — named columns or swimlanes (similar to a Kanban board). Each workspace can define multiple task areas, and goals are assigned to them to create visual groupings.

Goals can also be **sub-goals**, linked to a parent goal for decomposing complex work.

**Key APIs:**
- `GET /{siteId}/{pageId}/taskAreas.json` — list task areas (columns)
- `GET /{siteId}/{pageId}/fetchGoal.json?gid={goalId}` — fetch a single goal
- `POST /{siteId}/{pageId}/updateGoal.json` — create or update a goal
- `POST /{siteId}/{pageId}/updateMultiGoal.json` — batch update multiple goals
- `GET /{siteId}/{pageId}/getGoalHistory.json?gid={goalId}` — audit history for a goal
- `POST /{siteId}/{pageId}/moveActionItem.json` — move a goal from another workspace
- `POST /{siteId}/{pageId}/createActionItem.json` — create a new action item

**Representative response for `fetchGoal.json`:**
```json
{
  "id": "0017",
  "subject": "Write API documentation",
  "description": "Cover all endpoints with examples.",
  "state": "ACCEPTED",
  "assignTo": "bob@example.com",
  "dueDate": 1722124800000,
  "priority": 2,
  "percentComplete": 40,
  "labels": ["docs", "sprint-3"],
  "taskArea": "In Progress"
}
```

---

### Meetings

A **meeting** is a scheduled event with an agenda. Meetings let the team plan discussions in advance, track who attended, capture decisions and minutes, and link relevant documents and action items.

Each meeting has:
- A name, scheduled start time, and duration
- A list of agenda items (each with a subject, duration, and optional presenter)
- An attendance list (who said they would come, who actually came)
- A virtual meeting link if the meeting is remote
- A minutes document generated from the agenda

**Meeting states:**

| State | Meaning |
|-------|---------|
| `DRAFT` | Still being planned |
| `PLANNING` | Agenda is being assembled |
| `RUNNING` | Meeting is in progress |
| `COMPLETED` | Meeting has ended |

Before a meeting, attendees can respond to **proposed times** to help find the best slot. After a meeting, the `createMinutes.json` endpoint converts the agenda into a persistent topic document for the record.

**Key APIs:**
- `GET /{siteId}/{pageId}/meetingList.json` — list all meetings
- `GET /{siteId}/{pageId}/meetingRead.json?id={meetingId}` — get full meeting details
- `POST /{siteId}/{pageId}/meetingCreate.json` — create a meeting
- `POST /{siteId}/{pageId}/meetingUpdate.json` — update meeting metadata or agenda
- `POST /{siteId}/{pageId}/agendaAdd.json` — add an agenda item
- `POST /{siteId}/{pageId}/agendaUpdate.json` — update an agenda item
- `POST /{siteId}/{pageId}/agendaDelete.json` — remove an agenda item
- `GET /{siteId}/{pageId}/agendaGet.json?id={meetingId}&aid={agendaId}` — get one agenda item
- `POST /{siteId}/{pageId}/setSituation.json` — set attendance/availability status
- `POST /{siteId}/{pageId}/proposedTimes.json` — propose meeting time options
- `POST /{siteId}/{pageId}/createMinutes.json` — convert agenda to minutes topic
- `GET /{siteId}/{pageId}/getMeetingNotes.json?id={meetingId}` — get notes/minutes
- `POST /{siteId}/{pageId}/updateMeetingNotes.json` — update notes/minutes
- `POST /{siteId}/{pageId}/meetingDelete.json` — delete a meeting
- `POST /{siteId}/{pageId}/timeZoneList.json` — convert meeting time to multiple timezones

**Representative response for `meetingRead.json`:**
```json
{
  "id": "mtg-0003",
  "name": "Sprint Review",
  "scheduledTime": 1721750400000,
  "duration": 60,
  "state": "PLANNING",
  "agenda": [
    {
      "id": "ai-001",
      "subject": "Demo: new search feature",
      "duration": 15,
      "presenter": "carol@example.com"
    },
    {
      "id": "ai-002",
      "subject": "Retrospective",
      "duration": 20
    }
  ],
  "visitors": [
    { "uid": "alice@example.com", "situation": "attending" },
    { "uid": "bob@example.com", "situation": "tentative" }
  ],
  "serverTime": 1721740000000
}
```

---

### Documents (Attachments)

A **document** is a file or web resource attached to the workspace. Documents can be uploaded files (PDFs, spreadsheets, images, etc.) or links to external resources. Each document has a name, description, and version history — uploading a new version of a file preserves the previous versions.

Documents can also be **web files**: inline structured content that is authored directly within the tool rather than uploaded as a binary file. Web files support section-level commenting and review.

Documents can be attached to specific topics, meetings, or agenda items to create contextual links between content.

**Upload workflow (three steps):**
1. `GET GetTempName.json` — allocate a server-side temp filename and upload URL
2. `PUT UploadTempFile.json` — stream the file binary to the temp location
3. `POST AttachTempFile.json` — commit the temp file as a permanent document record

**Key APIs:**
- `GET /{siteId}/{pageId}/docsList.json` — list all documents
- `GET /{siteId}/{pageId}/docInfo.json?did={docId}` — get document metadata
- `POST /{siteId}/{pageId}/docsUpdate.json` — create or update a document record
- `GET /{siteId}/{pageId}/GetTempName.json` — step 1 of upload
- `PUT /{siteId}/{pageId}/UploadTempFile.json` — step 2 of upload
- `POST /{siteId}/{pageId}/AttachTempFile.json` — step 3 of upload
- `GET /{siteId}/{pageId}/a/{docName}.{ext}` — download a document file
- `POST /{siteId}/{pageId}/copyDocument.json` — copy a document from another workspace
- `POST /{siteId}/{pageId}/moveDocument.json` — move a document from another workspace
- `GET /{siteId}/{pageId}/attachedDocs.json` — documents attached to a meeting/topic/goal
- `GET /{siteId}/{pageId}/GetWebFile.json?aid={id}` — get a web file's content
- `POST /{siteId}/{pageId}/UpdateWebFile.json` — update a web file
- `POST /{siteId}/{pageId}/UpdateWebFileComments.json` — review comments on a web file section

---

### Labels

**Labels** (also called tags) are colored named tags that can be attached to goals, topics, and other workspace objects. They provide a lightweight way to categorize and filter content without creating formal structure.

Labels are defined per-workspace. A workspace can copy its label set from another workspace, which is useful for maintaining consistency across related workspaces on the same site.

**Key APIs:**
- `GET /{siteId}/{pageId}/getAllLabels.json` — list all labels
- `POST /{siteId}/{pageId}/labelUpdate.json` — create or delete a label
- `POST /{siteId}/{pageId}/copyLabels.json` — copy labels from another workspace

**Representative response for `getAllLabels.json`:**
```json
{
  "list": [
    { "id": "docs",     "name": "docs",     "color": "PaleGreen" },
    { "id": "sprint-3", "name": "sprint-3", "color": "Gold" },
    { "id": "blocked",  "name": "blocked",  "color": "Tomato" }
  ]
}
```

---

### Roles and Membership

Access to a workspace is controlled through **roles**. A role is a named group of users; being in a role grants a specific level of access.

Every workspace has two built-in roles:

| Role | Purpose |
|------|---------|
| **StewardsRole** | Administrators — can edit workspace settings, manage members, and modify all content |
| **MembersRole** | Standard participants — can view content and contribute (comments, tasks, documents) |

Additional **custom roles** can be defined at the site level and instantiated in workspaces. Each role definition specifies whether membership allows editing, administration, or only email-based participation.

Roles support an **approval workflow**: a role can be configured to require admin approval before a user's join request is granted. Pending requests are visible via `invitations.json` and resolved via `roleRequestResolution.json`.

Users can be invited to a role before they have an account — an invitation email is sent when a new invitation is created.

**Key APIs:**
- `GET /{siteId}/{pageId}/roleDefinitions.json` — list all role definitions with member counts
- `POST /{siteId}/{pageId}/rolePlayerUpdate.json` — join or leave a role
- `POST /{siteId}/{pageId}/roleRequestResolution.json` — approve or reject a join request
- `POST /{siteId}/{pageId}/roleUpdate.json` — create, update, or delete a role (admin)
- `GET /{siteId}/{pageId}/isRolePlayer.json?role={roleId}` — check if current user is in a role
- `POST /{siteId}/{pageId}/assureRolePlayer.json` — add a user to a role (admin)
- `GET /{siteId}/{pageId}/invitations.json` — list pending invitations
- `POST /{siteId}/{pageId}/invitationUpdate.json` — create or resend an invitation

**Representative response for `roleDefinitions.json`:**
```json
{
  "defs": [
    {
      "id": "StewardsRole",
      "name": "Stewards",
      "description": "Workspace administrators",
      "requiresApproval": false,
      "canEdit": true,
      "canAdminister": true,
      "memberCount": 2
    },
    {
      "id": "MembersRole",
      "name": "Members",
      "description": "Regular participants",
      "requiresApproval": false,
      "canEdit": true,
      "canAdminister": false,
      "memberCount": 8
    }
  ]
}
```

---

## Personal Settings Per Workspace

Each user has a set of **personal settings** for each workspace they access. These are stored separately from the workspace itself and are private to the user.

| Setting | Meaning |
|---------|---------|
| `isWatching` | User wants to see this workspace in their "watching" list |
| `lastReviewTime` | Timestamp of the user's last visit, used to compute what's new since last seen |
| `isNotify` | User wants email notifications for changes in this workspace |
| `isEmailMuted` | Suppress all email from this workspace even if in a notified role |

**Key APIs:**
- `POST /{siteId}/{pageId}/personalUpdate.json` — toggle watch/notify/mute settings
- `POST /{siteId}/{pageId}/setPersonal.json` — set the full personal settings block

---

## Comments Across the Workspace

Comments are the conversation layer that runs through every type of workspace content. A comment can be attached to a topic, a document, a meeting, or an agenda item. Comments support:

- Threaded replies (a comment can be a reply to another comment)
- Different **comment types** reflecting the nature of the exchange: `SIMPLE`, `PROPOSAL`, `REQUEST`, `MEETING`, `MINUTES`, `PHASE_CHANGE`
- Anonymous posting via email token (for email-based reply workflows)

**Key APIs:**
- `GET /{siteId}/{pageId}/getCommentList.json` — all comments in workspace
- `GET /{siteId}/{pageId}/getComment.json?cid={commentId}` — single comment
- `POST /{siteId}/{pageId}/updateComment.json` — update or delete a comment
- `POST /{siteId}/{pageId}/updateCommentAnon.json` — update a comment via email token
- `POST /{siteId}/{pageId}/SaveReply.json` — save a reply to any workspace object

---

## Scratchpad

Every workspace provides each user with a **personal scratchpad**: a private, freeform notes area visible only to that user. It is useful for jotting down ideas, tracking personal to-dos related to the workspace, or staging content before sharing it.

**Key APIs:**
- `GET /{siteId}/{pageId}/GetScratchpad.json` — retrieve your scratchpad
- `POST /{siteId}/{pageId}/UpdateScratchpad.json` — save your scratchpad

---

## Share Ports

A **share port** is an externally accessible link that provides controlled read access to workspace content without requiring the visitor to be a workspace member. Share ports are useful for publishing content to stakeholders or embedding workspace data in other tools.

**Key APIs:**
- `GET /{siteId}/{pageId}/sharePorts.json` — list all share ports
- `GET /{siteId}/{pageId}/share/{id}.json` — get a share port
- `POST /{siteId}/{pageId}/share/{id}.json` — update a share port

---

## Email Generators

A workspace can have one or more **email generators** — stored email templates that can be previewed, scheduled, or sent on demand to workspace members or specific roles. Email generators support templating with workspace data (member names, upcoming meetings, open action items, etc.).

**Key APIs:**
- `POST /{siteId}/{pageId}/emailGeneratorUpdate.json` — create, update, send, schedule, or delete a generator
- `POST /{siteId}/{pageId}/renderEmail.json` — preview a rendered email
- `POST /{siteId}/{pageId}/QueryEmail.json` — query email delivery history

---

## Creating and Managing Workspaces

Workspaces are created within a site by a site owner or admin.

**Key APIs:**
- `POST /{siteId}/$/createWorkspace.json` — create a new workspace
- `POST /{siteId}/{pageId}/updateProjectInfo.json` — update workspace configuration
- `POST /{siteId}/{pageId}/updateWorkspaceName.json` — rename a workspace
- `POST /{siteId}/{pageId}/deleteWorkspaceName.json` — soft-delete a workspace

When creating a workspace you can optionally:
- Supply a **template** workspace to clone its structure (roles, labels, task areas)
- Specify a **parent** workspace for hierarchy
- Seed the initial **members** list with roles already assigned

---

## Accessing a Workspace: Common Workflows

### Starting fresh — reading everything in a workspace

```
GET /{siteId}/{pageId}/topicList.json        → all discussion topics
GET /{siteId}/{pageId}/taskAreas.json        → task board columns
GET /{siteId}/{pageId}/allActionsList.json   → all action items
GET /{siteId}/{pageId}/meetingList.json      → all meetings
GET /{siteId}/{pageId}/docsList.json         → all documents
GET /{siteId}/{pageId}/roleDefinitions.json  → who has access
GET /{siteId}/{pageId}/getAllLabels.json     → available labels
```

### Drilling into a topic

```
GET /{siteId}/{pageId}/getTopic.json?nid={topicId}
  → returns the topic body plus all comments
GET /{siteId}/{pageId}/getNoteHistory.json?nid={topicId}
  → returns the change history
```

### Drilling into a meeting

```
GET /{siteId}/{pageId}/meetingRead.json?id={meetingId}
  → full meeting with agenda, attendee status, attached docs/actions
GET /{siteId}/{pageId}/agendaGet.json?id={meetingId}&aid={agendaId}
  → single agenda item with its comments and attachments
```

### Drilling into an action item

```
GET /{siteId}/{pageId}/fetchGoal.json?gid={goalId}
  → full goal details
GET /{siteId}/{pageId}/getGoalHistory.json?gid={goalId}
  → audit trail of state changes
```

### Getting attachments for a specific meeting or topic

```
GET /{siteId}/{pageId}/attachedDocs.json?meet={meetingId}
  → documents attached to a meeting
GET /{siteId}/{pageId}/attachedDocs.json?note={topicId}
  → documents attached to a topic
GET /{siteId}/{pageId}/attachedActions.json?meet={meetingId}
  → action items linked to a meeting
```

---

## How It All Fits Together

A workspace is designed to capture the full context of a team's work in one place. Here is how a typical team might use each part:

- **Topics** hold the living thinking — proposals, decisions, status updates, and discussions that need to be threaded and retrievable
- **Goals** track the work — concrete, assigned, time-bound tasks and deliverables that can be monitored against a deadline
- **Meetings** create the rhythm — scheduled events with agendas that link back to the goals and topics they address, and produce minutes that become part of the permanent record
- **Documents** keep the artifacts — any file or reference material the team needs, attached to the specific discussion or meeting that produced or depends on it
- **Labels** provide flexible organization — a simple tagging system that lets teams categorize content their own way without forcing rigid structure
- **Roles** define who belongs — and what they can do — making sure the right people have access and notifications are sent to the right audience

Because all of these are in one workspace and share a common URL scheme and comment layer, a team can navigate seamlessly from a meeting agenda to the action items it produced, to the topic that led to a decision, to the document that backs up the conclusion — without switching tools.
