# Meeting Object Schema Documentation

This document describes the complete JSON schema for Meeting objects in the Cognoscenti system, including all nested objects.

## Top-Level Meeting Object

The complete meeting object returned by `getFullJSON()` includes:

```json
{
  // Basic Meeting Information (from getMinimalJSON)
  "id": "string",
  "name": "string",
  "targetRole": "string",
  "state": "integer (0=DRAFT, 1=PLANNING, 2=RUNNING, 3=COMPLETED)",
  "startTime": "long (timestamp in milliseconds)",
  "duration": "long (duration in minutes)",
  "reminderTime": "integer (minutes before meeting to send reminder)",
  "reminderSent": "long (timestamp when reminder was sent)",
  "owner": "string (email address)",
  "previousMeeting": "string (ID of previous meeting)",
  "defaultLayout": "string (template name, e.g., 'MinutesDetails.chtml')",
  "notifyLayout": "string (template name, e.g., 'AgendaDetail.chtml')",
  "minutesId": "string (universal ID of minutes topic)",
  "conferenceUrl": "string (URL for online meeting)",

  // Additional Fields (from getListableJSON)
  "description": "string (markdown description of meeting)",
  "rollCall": [
    {
      "uid": "string (email address)",
      "key": "string (user key)",
      "attend": "string (yes|no|maybe)",
      "situation": "string (comment about attendance)"
    }
  ],
  "attended": ["string (email addresses of attendees)"],
  "agendaUrl": "string (URL to print agenda)",
  "minutesUrl": "string (URL to print minutes)",

  // Full Meeting Data (from getFullJSON)
  "agenda": [
    // Array of AgendaItem objects (see below)
  ],
  "minutesLocalId": "string (local ID of minutes topic)",
  "timeSlots": [
    // Array of MeetingProposeTime objects (see below)
  ],
  "previousMinutes": "string (universal ID of previous meeting's minutes)",
  "prevMeet": {
    // Previous meeting object (same structure as getListableJSON)
  },
  "participants": [
    {
      "uid": "string (email address)",
      "name": "string",
      "key": "string (user key)"
    }
  ],
  "people": {
    "userKey": {
      "uid": "string (email address)",
      "name": "string",
      "key": "string (user key)",
      "attended": "boolean (true if person attended)",
      "expect": "string (yes|no|maybe - expected attendance)",
      "situation": "string (comment about attendance)"
    }
  },
  "baseUrl": "string (base URL of server)",
  "workspaceUrl": "string (URL to workspace)"
}
```

## Meeting State Constants

```javascript
MEETING_STATE_DRAFT = 0      // Initial draft state
MEETING_STATE_PLANNING = 1   // Planning phase
MEETING_STATE_RUNNING = 2    // Meeting is in progress
MEETING_STATE_COMPLETED = 3  // Meeting has concluded
```

## Meeting Type Constants

```javascript
MEETING_TYPE_CIRCLE = 1       // Circle meeting
MEETING_TYPE_OPERATIONAL = 2  // Operational meeting
```

---

## AgendaItem Object

Each item in the `agenda` array has this structure:

```json
{
  // Basic Agenda Item Information
  "id": "string",
  "subject": "string",
  "description": "string (markdown description)",
  "duration": "long (duration in minutes)",
  "status": "integer (1=GOOD, 2=MID, 3=POOR)",
  "position": "integer (sort order)",
  "number": "integer (visible number for agenda item)",
  "isSpacer": "boolean (true for BREAK, LUNCH, DINNER items)",
  "readyToGo": "boolean",
  "proposed": "boolean (true if agenda item is still proposed)",

  // Timing Information
  "schedStart": "long (calculated scheduled start time)",
  "schedEnd": "long (calculated scheduled end time)",
  "timerRunning": "boolean",
  "timerStart": "long (timestamp when timer started)",
  "timerElapsed": "long (milliseconds elapsed)",

  // Presenters
  "presenterList": [
    {
      "uid": "string (email address)",
      "name": "string",
      "key": "string (user key)"
    }
  ],
  "presenters": ["string (email addresses)"],

  // Linked Action Items
  "aiList": [
    {
      "id": "string",
      "url": "string",
      // Additional minimal goal fields
      "synopsis": "string",
      "state": "integer",
      "assignTo": ["array of user objects"]
    }
  ],

  // Linked Documents
  "attList": [
    {
      "id": "string",
      "url": "string",
      "name": "string",
      "size": "long",
      "modifiedtime": "long",
      "modifieduser": "string",
      "type": "string"
    }
  ],

  // Comments
  "comments": [
    // Array of CommentRecord objects (see below)
  ],

  // Minutes
  "showMinutes": "boolean",
  "minutes": "string (markdown minutes text)",
  "lastMeetingMinutes": "string",

  // Linked Topics
  "topicList": [
    {
      "id": "string",
      "universalid": "string",
      "subject": "string",
      "url": "string"
    }
  ]
}
```

## AgendaItem Status Constants

```javascript
STATUS_GOOD = 1  // Good status
STATUS_MID = 2   // Medium status
STATUS_POOR = 3  // Poor status
```

---

## CommentRecord Object

Comments appear in agenda items and have this structure:

```json
{
  // Basic Comment Information
  "containerType": "string (numeric container type)",
  "containerID": "string (e.g., 'meetingId:agendaItemId')",
  "containerName": "string (human-readable container name)",
  "user": "string (email address of commenter)",
  "userName": "string",
  "userKey": "string",
  "time": "long (comment timestamp - unique ID)",
  "postTime": "long (when comment was posted)",
  "state": "integer (1=DRAFT, 2=OPEN, 3=CLOSED, 9=DELETED)",
  "dueDate": "long (timestamp)",
  "commentType": "integer",
  "emailPending": "boolean (display only)",
  "replyTo": "long (timestamp of parent comment)",
  "replies": ["array of long (timestamps of reply comments)"],
  "decision": "integer",
  "suppressEmail": "boolean",
  "excludeSelf": "boolean",
  "includeInMinutes": "boolean",
  "poll": "boolean (true if commentType > COMMENT_TYPE_SIMPLE)",

  // Complete Comment Information
  "body": "string (HTML content)",
  "outcome": "string",
  "newPhase": "string",

  // Responses (for polls/decisions)
  "responses": [
    {
      "user": "string (email address)",
      "userName": "string",
      "choice": "string",
      "html": "string",
      "time": "long"
    }
  ],

  // Poll Choices
  "choices": ["array of strings"],

  // Notification Recipients
  "notify": [
    {
      "uid": "string (email address)",
      "name": "string",
      "key": "string"
    }
  ],

  // Attached Documents
  "docList": ["array of string document IDs"],
  "docDetails": [
    {
      "id": "string",
      "name": "string",
      "size": "long",
      "url": "string"
      // Additional document fields
    }
  ]
}
```

## Comment State Constants

```javascript
COMMENT_STATE_DRAFT = 1   // Draft comment
COMMENT_STATE_OPEN = 2    // Open/active comment
COMMENT_STATE_CLOSED = 3  // Closed comment
COMMENT_STATE_DELETED = 9 // Deleted comment
```

## Comment Type Constants

```javascript
COMMENT_TYPE_SIMPLE = 1     // Simple comment
COMMENT_TYPE_PROPOSAL = 2   // Proposal requiring approval
COMMENT_TYPE_ROUND = 3      // Discussion round
COMMENT_TYPE_MINUTES = 4    // Meeting minutes
// Types > 1 are considered polls
```

---

## ResponseRecord Object

Responses to comments/proposals:

```json
{
  "user": "string (email address)",
  "userName": "string",
  "choice": "string (user's choice from poll options)",
  "html": "string (HTML response content)",
  "time": "long (timestamp)",
  "removeMe": "boolean (optional - used in updates to remove response)"
}
```

---

## MeetingProposeTime Object

Proposed meeting times with participant preferences:

```json
{
  "proposedTime": "long (timestamp of proposed time)",
  "people": {
    "email@address.com": "integer (1-5, preference rating)",
    "another@email.com": "integer (1-5, preference rating)"
  }
}
```

### People Preference Scale

- **1**: Cannot attend / Strongly against
- **2**: Prefer not to
- **3**: Neutral / No preference (default)
- **4**: Good time
- **5**: Best time / Strongly prefer

---

## Complete Example

Here's a complete example of a meeting object with nested data:

```json
{
  "id": "123456",
  "name": "Sprint Planning Meeting",
  "targetRole": "Members",
  "state": 1,
  "startTime": 1710777600000,
  "duration": 90,
  "reminderTime": 60,
  "reminderSent": 0,
  "owner": "manager@example.com",
  "previousMeeting": "123455",
  "defaultLayout": "MinutesDetails.chtml",
  "notifyLayout": "AgendaDetail.chtml",
  "minutesId": null,
  "conferenceUrl": "https://zoom.us/j/123456789",
  "description": "Sprint planning for Q2 initiatives",
  "rollCall": [
    {
      "uid": "alice@example.com",
      "key": "alice123",
      "attend": "yes",
      "situation": "Will join remotely"
    },
    {
      "uid": "bob@example.com",
      "key": "bob456",
      "attend": "maybe",
      "situation": "Conflict with another meeting"
    }
  ],
  "attended": ["alice@example.com"],
  "agendaUrl": "https://server.com/workspace/MeetPrint.htm?id=123456...",
  "minutesUrl": "https://server.com/workspace/MeetPrint.htm?id=123456...",
  "agenda": [
    {
      "id": "ai001",
      "subject": "Review Sprint Goals",
      "description": "Review and finalize goals for the sprint",
      "duration": 30,
      "status": 1,
      "position": 1,
      "number": 1,
      "isSpacer": false,
      "readyToGo": true,
      "proposed": false,
      "schedStart": 1710777600000,
      "schedEnd": 1710779400000,
      "timerRunning": false,
      "timerStart": 0,
      "timerElapsed": 0,
      "presenterList": [
        {
          "uid": "manager@example.com",
          "name": "Project Manager",
          "key": "mgr123"
        }
      ],
      "presenters": ["manager@example.com"],
      "aiList": [
        {
          "id": "goal789",
          "url": "https://server.com/workspace/taskgoal789.htm",
          "synopsis": "Implement user authentication",
          "state": 2,
          "assignTo": [
            {
              "uid": "alice@example.com",
              "name": "Alice Developer"
            }
          ]
        }
      ],
      "attList": [
        {
          "id": "doc001",
          "url": "https://server.com/workspace/doc001",
          "name": "Sprint Goals Document.pdf",
          "size": 245678,
          "modifiedtime": 1710777000000,
          "modifieduser": "manager@example.com",
          "type": "application/pdf"
        }
      ],
      "comments": [
        {
          "containerType": "3",
          "containerID": "123456:ai001",
          "containerName": "Sprint Planning Meeting:Review Sprint Goals",
          "user": "alice@example.com",
          "userName": "Alice Developer",
          "userKey": "alice123",
          "time": 1710777700000,
          "postTime": 1710777700000,
          "state": 2,
          "dueDate": 0,
          "commentType": 1,
          "emailPending": false,
          "replyTo": 0,
          "replies": [],
          "decision": 0,
          "suppressEmail": false,
          "excludeSelf": false,
          "includeInMinutes": true,
          "poll": false,
          "body": "<p>I think we should prioritize authentication first.</p>",
          "outcome": "",
          "newPhase": "",
          "responses": [],
          "choices": [],
          "notify": [],
          "docList": [],
          "docDetails": []
        }
      ],
      "showMinutes": false,
      "minutes": "",
      "lastMeetingMinutes": "",
      "topicList": []
    },
    {
      "id": "ai002",
      "subject": "BREAK",
      "description": "",
      "duration": 10,
      "status": 1,
      "position": 2,
      "number": 0,
      "isSpacer": true,
      "readyToGo": true,
      "proposed": false,
      "schedStart": 1710779400000,
      "schedEnd": 1710780000000,
      "timerRunning": false,
      "presenterList": [],
      "presenters": [],
      "aiList": [],
      "attList": [],
      "comments": [],
      "showMinutes": false,
      "topicList": []
    }
  ],
  "timeSlots": [
    {
      "proposedTime": 1710777600000,
      "people": {
        "alice@example.com": 5,
        "bob@example.com": 3,
        "carol@example.com": 4
      }
    },
    {
      "proposedTime": 1710864000000,
      "people": {
        "alice@example.com": 4,
        "bob@example.com": 5,
        "carol@example.com": 2
      }
    }
  ],
  "previousMinutes": "topic-prev-123",
  "prevMeet": {
    "id": "123455",
    "name": "Previous Sprint Review",
    "state": 3,
    "startTime": 1708185600000,
    "duration": 60
  },
  "participants": [
    {
      "uid": "alice@example.com",
      "name": "Alice Developer",
      "key": "alice123"
    },
    {
      "uid": "bob@example.com",
      "name": "Bob Developer",
      "key": "bob456"
    },
    {
      "uid": "manager@example.com",
      "name": "Project Manager",
      "key": "mgr123"
    }
  ],
  "people": {
    "alice123": {
      "uid": "alice@example.com",
      "name": "Alice Developer",
      "key": "alice123",
      "attended": true,
      "expect": "yes",
      "situation": "Will join remotely"
    },
    "bob456": {
      "uid": "bob@example.com",
      "name": "Bob Developer",
      "key": "bob456",
      "attended": false,
      "expect": "maybe",
      "situation": "Conflict with another meeting"
    },
    "mgr123": {
      "uid": "manager@example.com",
      "name": "Project Manager",
      "key": "mgr123"
    }
  },
  "baseUrl": "https://server.com/",
  "workspaceUrl": "https://server.com/workspace/"
}
```

---

## API Endpoints for Meetings

See `API_ENDPOINTS.md` for complete documentation, but key meeting endpoints include:

- **GET** `/{siteId}/{pageId}/meetingList.json` - List all meetings
- **GET** `/{siteId}/{pageId}/meetingRead.json` - Get full meeting object
- **POST** `/{siteId}/{pageId}/meetingCreate.json` - Create new meeting
- **POST** `/{siteId}/{pageId}/meetingUpdate.json` - Update meeting
- **POST** `/{siteId}/{pageId}/meetingDelete.json` - Delete meeting
- **POST** `/{siteId}/{pageId}/agendaAdd.json` - Add agenda item
- **POST** `/{siteId}/{pageId}/agendaUpdate.json` - Update agenda item
- **GET** `/{siteId}/{pageId}/agendaGet.json` - Get agenda item
- **POST** `/{siteId}/{pageId}/agendaMove.json` - Reorder agenda item
- **POST** `/{siteId}/{pageId}/agendaDelete.json` - Delete agenda item
- **POST** `/{siteId}/{pageId}/proposedTimes.json` - Manage time proposals
- **GET** `/{siteId}/{pageId}/getMeetingNotes.json` - Get meeting notes
- **POST** `/{siteId}/{pageId}/updateMeetingNotes.json` - Update meeting notes

---

## Notes on Field Usage

1. **Timestamps**: All time values are Unix timestamps in milliseconds (Java `long` type)
2. **Email Addresses**: User identifiers are typically email addresses (universal IDs)
3. **Keys**: User keys are internal identifiers used for lookups
4. **Markdown**: Description and minutes fields typically contain markdown text
5. **HTML**: Comment bodies contain HTML content
6. **Universal IDs**: Documents, topics, and action items use universal IDs for cross-workspace references
7. **Deprecated Fields**: Some fields like `actionItems`, `docList`, and `topics` (arrays of strings) are deprecated in favor of their object-based equivalents (`aiList`, `attList`, `topicList`)

---

## Schema Evolution

The schema includes migration logic for:
- Converting single topic links to topic lists (Oct 2021)
- Clearing stuck timers (running > 24 hours)
- Default layout template values
- Handling missing/deleted linked objects gracefully
