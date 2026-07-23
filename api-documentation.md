# Cognoscenti API Endpoints Documentation

All API endpoints follow the naming convention `xxx.json` where `xxx` is the endpoint name. All endpoints receive and send JSON data.

## Table of Contents
- [User Management APIs](#user-management-apis)
- [Project Settings APIs](#project-settings-apis)
- [Topic/Discussion APIs](#topicdiscussion-apis)
- [Comment APIs](#comment-apis)
- [Goal/Action Item APIs](#goalaction-item-apis)
- [Meeting APIs](#meeting-apis)
- [Document APIs](#document-apis)
- [Workspace/Site Management APIs](#workspacesite-management-apis)
- [Super Admin APIs](#super-admin-apis)
- [Admin APIs](#admin-apis)

---

## User Management APIs

### 1. RemoteProfileUpdate.json
- **URL**: `/{userKey}/RemoteProfileUpdate.json`
- **Method**: POST
- **Controller**: `UserController.RemoteProfileUpdate()`
- **Description**: Creates or deletes a remote profile reference for the user. Used to link or unlink external email addresses to the user's account.
- **Input Schema**:
```json
{
  "address": "string (email address to link/unlink)",
  "act": "string (Create | Delete)"
}
```
- **Output**: Plain text confirmation message

---

### 2. updateProfile.json
- **URL**: `/{userKey}/updateProfile.json`
- **Method**: POST
- **Controller**: `UserController.updateProfile()`
- **Description**: Updates the user's profile. The caller must be either the user themselves or a super admin.
- **Input Schema** (UserProfile fields):
```json
{
  "name": "string (display name)",
  "description": "string (bio)",
  "image": "string (icon/avatar URL or filename)",
  "isFacilitator": "boolean"
}
```
- **Output Schema**:
```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "image": "string",
  "isFacilitator": "boolean",
  "lastLogin": "number (epoch ms)"
}
```

---

### 3. updateMicroProfile.json
- **URL**: `/updateMicroProfile.json`
- **Method**: POST
- **Controller**: `UserController.updateMicroProfile()`
- **Description**: Updates a micro-profile display name by email address. Lightweight name-only update used when full profile editing is not needed.
- **Input Schema**:
```json
{
  "uid": "string (email ID)",
  "name": "string (display name)"
}
```
- **Output Schema**: Echoes back the posted JSON object

---

### 4. searchNotes.json (User)
- **URL**: `/{userKey}/searchNotes.json`
- **Method**: POST
- **Controller**: `UserController.searchPublicNotesJSON()`
- **Description**: Searches notes/topics accessible by the user, optionally filtered by workspace. Returns matching search result records.
- **Input Schema**:
```json
{
  "searchFilter": "string (search text)",
  "searchProject": "string (optional workspace ID to scope search)"
}
```
- **Output Schema**:
```json
[
  {
    "id": "string",
    "subject": "string",
    "snippet": "string",
    "workspace": "string",
    "modified": "number (epoch ms)"
  }
]
```

---

### 5. QueryUserEmail.json
- **URL**: `/{userKey}/QueryUserEmail.json`
- **Method**: POST
- **Controller**: `UserController.queryEmail()`
- **Description**: Queries the email history for a specific user. Delegates to `EmailSender.queryUserEmail()`. Useful for debugging mail delivery.
- **Input Schema**: Posted JSON object (query parameters added by server: `userKey`, `userEmail`)
- **Output Schema**: Email query results from `EmailSender`

---

### 6. GetFacilitatorInfo.json
- **URL**: `/{userKey}/GetFacilitatorInfo.json`
- **Method**: GET
- **Controller**: `UserController.getFacilitatorInfo()`
- **Description**: Returns facilitator-specific fields for a user, identified by the `key` query parameter.
- **Query Parameters**: `key` (string — user key)
- **Output Schema**:
```json
{
  "isActive": "boolean",
  "isFacilitator": "boolean",
  "facilitatorBio": "string",
  "facilitatorRate": "string"
}
```

---

### 7. UpdateFacilitatorInfo.json
- **URL**: `/{userKey}/UpdateFacilitatorInfo.json`
- **Method**: POST
- **Controller**: `UserController.updateFacilitatorInfo()`
- **Description**: Updates facilitator-specific fields for a user. Sets facilitator flag on main profile as well.
- **Input Schema**:
```json
{
  "isActive": "boolean",
  "facilitatorBio": "string",
  "facilitatorRate": "string"
}
```
- **Output Schema**: Same structure as `GetFacilitatorInfo.json` — updated facilitator fields

---

### 8. MailProblems.json
- **URL**: `/{userKey}/MailProblems.json`
- **Method**: GET
- **Controller**: `UserController.mailProblems()`
- **Description**: Returns all mail delivery problems (blocks, bounces, spam reports) across the entire system. Super admin / admin use.
- **Output Schema**:
```json
{
  "blocks": ["array of blocked addresses"],
  "bounces": ["array of bounced addresses"],
  "spams": ["array of spam-reported addresses"]
}
```

---

### 9. MailProblemsUser.json
- **URL**: `/{userKey}/MailProblemsUser.json`
- **Method**: GET
- **Controller**: `UserController.mailProblemsUser()`
- **Description**: Returns mail delivery problems specific to the calling user's email address.
- **Output Schema**:
```json
{
  "blocks": ["block records for this user's address"],
  "bounces": ["bounce records for this user's address"],
  "spams": ["spam reports for this user's address"]
}
```

---

### 10. ClearLearningDone.json
- **URL**: `/{userKey}/ClearLearningDone.json`
- **Method**: POST
- **Controller**: `UserController.clearLearningPath()`
- **Description**: Clears all "learning completed" flags for the user, resetting their learning path so tutorials show again.
- **Output Schema**:
```json
{
  "status": "cleared"
}
```

---

### 11. UserPostOps.json
- **URL**: `/{userKey}/UserPostOps.json`
- **Method**: POST
- **Controller**: `UserController.userPostOps()`
- **Description**: Multi-operation endpoint for user file operations. `tempFile` allocates a new temp filename/URL. `finishIcon` finalizes a previously uploaded temp image as the user's icon.
- **Input Schema**:
```json
{
  "op": "string (tempFile | finishIcon)",
  "tempFileName": "string (required for finishIcon op)"
}
```
- **Output Schema** (`tempFile` op):
```json
{
  "responseCode": 200,
  "tempFileName": "string (server-assigned temp name)",
  "tempFileURL": "string (URL to PUT the file to)"
}
```
- **Output Schema** (`finishIcon` op):
```json
{
  "responseCode": 200,
  "tempFileName": "string",
  "iconFileName": "string (final icon filename)"
}
```

---

## Project Settings APIs

### 12. personalUpdate.json
- **URL**: `/{siteId}/{pageId}/personalUpdate.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.personalUpdate()`
- **Description**: Updates personal per-workspace settings for the logged-in user. Supports watch/notify/mute toggles.
- **Input Schema**:
```json
{
  "op": "string (SetWatch | ClearWatch | SetReviewTime | SetNotify | ClearNotify | SetEmailMute | ClearEmailMute)"
}
```
- **Output Schema**:
```json
{
  "wsSettings": {
    "isWatching": "boolean",
    "lastReviewTime": "number (epoch ms)",
    "isNotified": "boolean",
    "isEmailMuted": "boolean"
  }
}
```

---

### 13. setPersonal.json
- **URL**: `/{siteId}/{pageId}/setPersonal.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.setPersonal()`
- **Description**: Sets the full block of personal workspace settings for the logged-in user in one call.
- **Input Schema**: Personal workspace settings JSON object
- **Output Schema**: Updated personal workspace settings JSON

---

### 14. rolePlayerUpdate.json
- **URL**: `/{siteId}/{pageId}/rolePlayerUpdate.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.rolePlayerUpdate()`
- **Description**: Joins or leaves a role within the workspace. For roles with approval workflows, joining creates a pending role request; leaving removes the membership immediately.
- **Input Schema**:
```json
{
  "op": "string (Join | Leave)",
  "roleId": "string (role identifier)",
  "desc": "string (optional reason/message for the request)"
}
```
- **Output Schema**:
```json
{
  "op": "string",
  "success": "boolean",
  "player": "boolean (whether user is now a player)",
  "reqPending": "boolean (whether a join request is pending approval)"
}
```

---

### 15. roleRequestResolution.json
- **URL**: `/{siteId}/{pageId}/roleRequestResolution.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.roleRequestResolution()`
- **Description**: Approves or rejects a pending role membership request. Only role admins can resolve requests.
- **Input Schema**:
```json
{
  "op": "string (Approve | Reject)",
  "rrId": "string (role request ID)"
}
```
- **Output Schema**:
```json
{
  "state": "string (approved | rejected)",
  "completed": "boolean"
}
```

---

### 16. roleUpdate.json
- **URL**: `/{siteId}/{pageId}/roleUpdate.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.roleUpdate()`
- **Description**: Creates, updates, or deletes a role definition, or retrieves all roles (`GetAll`). Only workspace admins can create/delete roles.
- **Input Schema**:
```json
{
  "op": "string (Update | Create | Delete | GetAll)",
  "id": "string (role ID, required for Update/Delete)",
  "name": "string",
  "description": "string",
  "requiresApproval": "boolean"
}
```
- **Output Schema**: Role definition JSON for Update/Create/Delete; `{"roles": [...]}` for GetAll

---

### 17. roleDefinitions.json
- **URL**: `/{siteId}/{pageId}/roleDefinitions.json`
- **Method**: GET
- **Controller**: `ProjectSettingController.roleDefinitions()`
- **Description**: Returns all role definitions for the workspace, including membership counts and settings.
- **Output Schema**:
```json
{
  "defs": [
    {
      "id": "string",
      "name": "string",
      "description": "string",
      "requiresApproval": "boolean",
      "memberCount": "number"
    }
  ]
}
```

---

### 18. getAllLabels.json
- **URL**: `/{siteId}/{pageId}/getAllLabels.json`
- **Method**: GET
- **Controller**: `ProjectSettingController.getAllLabels()`
- **Description**: Returns all labels defined in the workspace.
- **Output Schema**:
```json
{
  "list": [
    {
      "id": "string",
      "name": "string",
      "color": "string (hex color code)"
    }
  ]
}
```

---

### 19. isRolePlayer.json
- **URL**: `/{siteId}/{pageId}/isRolePlayer.json`
- **Method**: GET
- **Controller**: `ProjectSettingController.isRolePlayer()`
- **Description**: Checks whether the logged-in user is a member of the specified role.
- **Query Parameters**: `role` (string — role ID)
- **Output Schema**:
```json
{
  "isPlayer": "boolean"
}
```

---

### 20. assureRolePlayer.json
- **URL**: `/{siteId}/{pageId}/assureRolePlayer.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.assureRolePlayer()`
- **Description**: Ensures a specific user is a member of a role, adding them if not already present. Admin operation.
- **Input Schema**:
```json
{
  "role": "string (role ID)",
  "uid": "string (user email/ID to add)"
}
```
- **Output Schema**:
```json
{
  "isPlayer": true
}
```

---

### 21. emailGeneratorUpdate.json
- **URL**: `/{siteId}/{pageId}/emailGeneratorUpdate.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.emailGeneratorUpdate()`
- **Description**: Creates, updates, sends, schedules, or deletes a workspace email generator (a stored email template). Pass `sendIt: true` to immediately send; `scheduleIt: true` to schedule; `deleteIt: true` to remove.
- **Input Schema**:
```json
{
  "id": "string (generator ID, omit to create)",
  "subject": "string",
  "body": "string (HTML)",
  "sendIt": "boolean (optional)",
  "scheduleIt": "boolean (optional)",
  "deleteIt": "boolean (optional)"
}
```
- **Output Schema**: `emailGenerator.getJSON(ar, ngw)` — full email generator state including schedule and recipient list

---

### 22. renderEmail.json
- **URL**: `/{siteId}/{pageId}/renderEmail.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.renderEmail()`
- **Description**: Renders an email generator template to HTML for preview, optionally targeted to a specific user.
- **Input Schema**:
```json
{
  "id": "string (email generator ID)",
  "toUser": "string (optional — user email for personalized preview)"
}
```
- **Output Schema**:
```json
{
  "subject": "string (rendered subject line)",
  "html": "string (rendered HTML body)",
  "addressees": ["array of recipient addresses"]
}
```

---

### 23. getLabels.json
- **URL**: `/{siteId}/{pageId}/getLabels.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.getLabels()`
- **Description**: Returns all labels for the workspace. Equivalent to `getAllLabels.json` but accessed via POST.
- **Output Schema**:
```json
{
  "list": [
    {
      "id": "string",
      "name": "string",
      "color": "string"
    }
  ]
}
```

---

### 24. labelUpdate.json
- **URL**: `/{siteId}/{pageId}/labelUpdate.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.labelUpdate()`
- **Description**: Creates or deletes a label in the workspace.
- **Input Schema**:
```json
{
  "op": "string (Create | Delete)",
  "name": "string (current label name)",
  "editedName": "string (new name for Create)",
  "color": "string (hex color for Create)"
}
```
- **Output Schema**: `label.getJSON()` — the created or affected label

---

### 25. copyLabels.json
- **URL**: `/{siteId}/{pageId}/copyLabels.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.copyLabels()`
- **Description**: Copies all labels from another workspace into this one.
- **Input Schema**:
```json
{
  "from": "string (source workspace page ID)"
}
```
- **Output Schema**:
```json
{
  "list": ["array of newly copied label objects"]
}
```

---

### 26. QueryEmail.json
- **URL**: `/{siteId}/{pageId}/QueryEmail.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.QueryEmail()`
- **Description**: Queries email sending history for the workspace. Useful for debugging delivery issues.
- **Input Schema**: Posted JSON query object (passed directly to `EmailSender.queryWorkspaceEmail`)
- **Output Schema**: Email query results from `EmailSender`

---

### 27. invitations.json
- **URL**: `/{siteId}/{pageId}/invitations.json`
- **Method**: GET
- **Controller**: `ProjectSettingController.invitations()`
- **Description**: Returns all pending role invitations for the workspace.
- **Output Schema**:
```json
{
  "invitations": [
    {
      "id": "string",
      "email": "string",
      "role": "string",
      "status": "string",
      "sentDate": "number (epoch ms)"
    }
  ]
}
```

---

### 28. invitationUpdate.json
- **URL**: `/{siteId}/{pageId}/invitationUpdate.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.invitationUpdate()`
- **Description**: Creates, updates, or resends a role invitation. The `ss` field is required and controls the invitation status.
- **Input Schema**:
```json
{
  "email": "string (invitee email address)",
  "role": "string (role ID to invite to)",
  "ss": "string (required — status/action flag)"
}
```
- **Output Schema**: Invitation record JSON

---

## Topic/Discussion APIs

### 29. getTopics.json
- **URL**: `/{siteId}/{pageId}/getTopics.json`
- **Method**: GET
- **Controller**: `TopicController.getTopics()`
- **Description**: Returns all non-deleted discussion topics for the workspace as a flat JSON array.
- **Output Schema**:
```json
[
  {
    "id": "string",
    "subject": "string",
    "modified": "number (epoch ms)",
    "commentCount": "number"
  }
]
```

---

### 30. topicList.json
- **URL**: `/{siteId}/{pageId}/topicList.json`
- **Method**: GET
- **Controller**: `TopicController.topicList()`
- **Description**: Returns the list of discussion topics filtered by member/access settings.
- **Output Schema**:
```json
{
  "topics": [
    {
      "id": "string",
      "subject": "string",
      "modified": "number (epoch ms)",
      "commentCount": "number"
    }
  ]
}
```

---

### 31. getTopic.json
- **URL**: `/{siteId}/{pageId}/getTopic.json`
- **Method**: GET
- **Controller**: `TopicController.getTopic()`
- **Description**: Returns a single topic with all its comments. The `nid` query parameter identifies the topic.
- **Query Parameters**: `nid` (string — note/topic ID)
- **Output Schema**:
```json
{
  "id": "string",
  "subject": "string",
  "html": "string (body content)",
  "modified": "number (epoch ms)",
  "comments": [
    {
      "id": "string",
      "html": "string",
      "author": "string",
      "time": "number (epoch ms)"
    }
  ]
}
```

---

### 32. getNoteHistory.json
- **URL**: `/{siteId}/{pageId}/getNoteHistory.json`
- **Method**: GET
- **Controller**: `TopicController.getGoalHistory()`
- **Description**: Returns the change history for a specific note/topic.
- **Query Parameters**: `nid` (string — note/topic ID)
- **Output Schema**:
```json
[
  {
    "time": "number (epoch ms)",
    "user": "string (email)",
    "action": "string",
    "subject": "string"
  }
]
```

---

### 33. mergeTopicDoc.json
- **URL**: `/{siteId}/{pageId}/mergeTopicDoc.json`
- **Method**: POST
- **Controller**: `TopicController.mergeTopicDoc()`
- **Description**: Applies a three-way merge to a topic's markdown content. Sends `old` (original), `new` (client's proposed changes), and `nid` (topic ID). If the server has diverged from `old`, the merge is attempted.
- **Input Schema**:
```json
{
  "nid": "string (topic ID)",
  "old": "string (original markdown the client started from)",
  "new": "string (client's updated markdown)",
  "subject": "string (optional — new subject line)"
}
```
- **Output Schema**: `topic.getJSONWithComments(ar, ngw)` — full topic with comments

---

### 34. updateNote.json
- **URL**: `/{siteId}/{pageId}/updateNote.json`
- **Method**: POST
- **Controller**: `TopicController.updateNote()`
- **Description**: Updates a topic/note's fields including comments. Creates a history record.
- **Query Parameters**: `nid` (string — note ID)
- **Input Schema**:
```json
{
  "subject": "string",
  "html": "string",
  "comments": ["array of comment objects (optional)"]
}
```
- **Output Schema**: `topic.getJSONWithComments(ar, ngw)` — updated topic with comments

---

### 35. noteHtmlUpdate.json
- **URL**: `/{siteId}/{pageId}/noteHtmlUpdate.json`
- **Method**: POST
- **Controller**: `TopicController.noteHtmlUpdate()`
- **Description**: Creates or updates a topic's HTML content. Pass `nid=~new~` to create a new topic. Autosave mode (`saveMode: "autosave"`) skips history creation.
- **Query Parameters**: `nid` (string — note ID, or `~new~` to create)
- **Input Schema**:
```json
{
  "subject": "string",
  "html": "string",
  "saveMode": "string (optional — 'autosave' to skip history)"
}
```
- **Output Schema**: `topic.getJSONWithComments(ar, ngw)` — topic with comments

---

### 36. topicSubscribe.json
- **URL**: `/{siteId}/{pageId}/topicSubscribe.json`
- **Method**: GET
- **Controller**: `TopicController.topicSubscribe()`
- **Description**: Subscribes a user to a topic to receive notifications on new comments. Non-logged-in users can subscribe via `emailId`.
- **Query Parameters**: `nid` (string — topic ID), `emailId` (string — optional, for unauthenticated users)
- **Output Schema**: `topic.getJSONWithComments(ar, ngw)`

---

### 37. topicUnsubscribe.json
- **URL**: `/{siteId}/{pageId}/topicUnsubscribe.json`
- **Method**: GET
- **Controller**: `TopicController.topicUnsubscribe()`
- **Description**: Unsubscribes a user from topic notifications. Non-logged-in users can unsubscribe via `emailId`.
- **Query Parameters**: `nid` (string — topic ID), `emailId` (string — optional, for unauthenticated users)
- **Output Schema**: `topic.getJSONWithComments(ar, ngw)`

---

## Comment APIs

### 38. getComment.json
- **URL**: `/{siteId}/{pageId}/getComment.json`
- **Method**: GET
- **Controller**: `CommentController.getTopic()`
- **Description**: Returns complete information for a single comment.
- **Query Parameters**: `cid` (long — comment ID)
- **Output Schema**: `comment.getCompleteJSON()` — full comment details

---

### 39. getCommentList.json
- **URL**: `/{siteId}/{pageId}/getCommentList.json`
- **Method**: GET
- **Controller**: `CommentController.getCommentList()`
- **Description**: Returns all comments in the workspace.
- **Output Schema**:
```json
{
  "list": [
    {
      "id": "string",
      "html": "string",
      "author": "string",
      "time": "number (epoch ms)"
    }
  ]
}
```

---

### 40. updateComment.json
- **URL**: `/{siteId}/{pageId}/updateComment.json`
- **Method**: POST
- **Controller**: `CommentController.updateComment()`
- **Description**: Updates a comment's content, or deletes it if `deleteMe: true` is set. After update, refreshes the containing meeting's cache if applicable.
- **Query Parameters**: `cid` (long — comment ID)
- **Input Schema**:
```json
{
  "html": "string (comment body)",
  "deleteMe": "boolean (optional — set true to delete)"
}
```
- **Output Schema** (update): `comment.getJSONWithDocs(ngw)` — comment with attached documents
- **Output Schema** (delete): `{"delete": "success"}`

---

### 41. updateCommentAnon.json
- **URL**: `/{siteId}/{pageId}/updateCommentAnon.json`
- **Method**: POST
- **Controller**: `CommentController.updateCommentAnon()`
- **Description**: Allows an anonymous (unauthenticated) user to update a comment, authorized by an email message token. Used for email-based reply workflows.
- **Query Parameters**: `cid` (long — comment ID), `msg` (long — email message ID for authorization)
- **Input Schema**: Comment fields (same as `updateComment.json`)
- **Output Schema**: `comment.getJSONWithDocs(ngw)`

---

## Goal/Action Item APIs

### 42. fetchGoal.json
- **URL**: `/{siteId}/{pageId}/fetchGoal.json`
- **Method**: GET
- **Controller**: `ProjectGoalController.fetchGoal()`
- **Description**: Fetches a single goal/action item by ID.
- **Query Parameters**: `gid` (string — goal ID)
- **Output Schema**: `goal.getJSON4Goal(ngw)` — full goal data

---

### 43. updateGoal.json
- **URL**: `/{siteId}/{pageId}/updateGoal.json`
- **Method**: POST
- **Controller**: `ProjectGoalController.updateGoal()`
- **Description**: Creates or updates a goal/action item. Tracks state transitions and creates history records. Omit `id` to create a new goal.
- **Input Schema**:
```json
{
  "id": "string (omit to create new)",
  "subject": "string",
  "description": "string",
  "state": "string (Open | Closed | etc.)",
  "assignTo": "string (user email)",
  "dueDate": "number (epoch ms)",
  "priority": "number",
  "labels": ["array of label IDs"]
}
```
- **Output Schema**: `goal.getJSON4Goal(ngw)`

---

### 44. updateMultiGoal.json
- **URL**: `/{siteId}/{pageId}/updateMultiGoal.json`
- **Method**: POST
- **Controller**: `ProjectGoalController.updateMultiGoal()`
- **Description**: Updates multiple goals in a single request. Useful for batch state changes or reordering.
- **Input Schema**:
```json
{
  "list": ["array of goal JSON objects (same schema as updateGoal input)"]
}
```
- **Output Schema**:
```json
{
  "list": ["array of updated goal objects"]
}
```

---

### 45. getGoalHistory.json
- **URL**: `/{siteId}/{pageId}/getGoalHistory.json`
- **Method**: GET
- **Controller**: `ProjectGoalController.getGoalHistory()`
- **Description**: Returns the change history for a specific goal/action item.
- **Query Parameters**: `gid` (string — goal ID)
- **Output Schema**:
```json
[
  {
    "time": "number (epoch ms)",
    "user": "string (email)",
    "action": "string",
    "subject": "string"
  }
]
```

---

### 46. updateDecision.json
- **URL**: `/{siteId}/{pageId}/updateDecision.json`
- **Method**: POST
- **Controller**: `ProjectGoalController.updateDecision()`
- **Description**: Creates, updates, or deletes a decision record. Pass `deleteMe: true` to delete. Creates a history record.
- **Input Schema**:
```json
{
  "id": "string (omit to create new)",
  "subject": "string",
  "description": "string",
  "deleteMe": "boolean (optional — true to delete)"
}
```
- **Output Schema**: `decision.getJSON4Decision(ngw, ar)`

---

### 47. taskAreas.json
- **URL**: `/{siteId}/{pageId}/taskAreas.json`
- **Method**: GET
- **Controller**: `ProjectGoalController.taskAreas()`
- **Description**: Returns all task areas (columns/swimlanes) for the workspace.
- **Output Schema**:
```json
{
  "taskAreas": [
    {
      "id": "string",
      "name": "string",
      "position": "number"
    }
  ]
}
```

---

### 48. moveTaskArea.json
- **URL**: `/{siteId}/{pageId}/moveTaskArea.json`
- **Method**: POST
- **Controller**: `ProjectGoalController.moveTaskArea()`
- **Description**: Moves a task area up or down in order, or deletes it entirely.
- **Input Schema**:
```json
{
  "areaId": "string (task area ID)",
  "moveDown": "boolean (optional — true moves down, false moves up)",
  "deleteTaskArea": "boolean (optional — true deletes the area)"
}
```
- **Output Schema**:
```json
{
  "taskAreas": ["updated array of task area objects"]
}
```

---

### 49. taskArea{id}.json
- **URL**: `/{siteId}/{pageId}/taskArea{id}.json`
- **Method**: GET / POST
- **Controller**: `ProjectGoalController.getTaskArea()`
- **Description**: GET returns a task area's details and contained goals. POST updates the task area's properties.
- **Path Parameters**: `id` (string — task area ID embedded in URL)
- **Output Schema**: Task area JSON with contained action items

---

### 50. moveActionItem.json
- **URL**: `/{siteId}/{pageId}/moveActionItem.json`
- **Method**: POST
- **Controller**: `ProjectGoalController.moveActionItem()`
- **Description**: Moves an action item from another workspace into the current one (copy + delete from source). Requires admin access on the source workspace.
- **Input Schema**:
```json
{
  "from": "string (source workspace page ID)",
  "id": "string (goal ID to move)"
}
```
- **Output Schema**:
```json
{
  "created": "goal JSON object in new workspace"
}
```

---

### 51. createActionItem.json
- **URL**: `/{siteId}/{pageId}/createActionItem.json`
- **Method**: POST
- **Controller**: `MainTabsViewControler.createActionItem()`
- **Description**: Creates a new action item/goal in the workspace with history tracking.
- **Input Schema**: Goal JSON object (same fields as `updateGoal`)
- **Output Schema**: `goalRecord.getJSON4Goal(ngw)`

---

## Meeting APIs

### 52. meetingCreate.json
- **URL**: `/{siteId}/{pageId}/meetingCreate.json`
- **Method**: POST
- **Controller**: `MeetingControler.meetingCreate()`
- **Description**: Creates a new meeting with optional agenda items and action item links.
- **Input Schema**:
```json
{
  "name": "string (meeting title)",
  "scheduledTime": "number (epoch ms)",
  "duration": "number (minutes)",
  "agenda": ["array of agenda item objects (optional)"],
  "actionItems": ["array of action item IDs (optional)"]
}
```
- **Output Schema**: `newMeeting.getFullJSON(ar, ngw, true)` — full meeting record including agenda

---

### 53. meetingList.json
- **URL**: `/{siteId}/{pageId}/meetingList.json`
- **Method**: GET
- **Controller**: `MeetingControler.meetingList()`
- **Description**: Returns all meetings for the workspace, sorted chronologically.
- **Output Schema**:
```json
{
  "meetings": [
    {
      "id": "string",
      "name": "string",
      "scheduledTime": "number (epoch ms)",
      "duration": "number (minutes)",
      "agendaItemCount": "number"
    }
  ]
}
```

---

### 54. meetingRead.json
- **URL**: `/{siteId}/{pageId}/meetingRead.json`
- **Method**: GET
- **Controller**: `MeetingControler.meetingRead()`
- **Description**: Returns full meeting details including agenda items, attached docs, and visitor (attendee) information.
- **Query Parameters**: `id` (string — meeting ID)
- **Output Schema**: Meeting JSON with visitor/attendee array

---

### 55. meetingUpdate.json
- **URL**: `/{siteId}/{pageId}/meetingUpdate.json`
- **Method**: POST
- **Controller**: `MeetingControler.meetingUpdate()`
- **Description**: Updates a meeting's metadata (name, time, notes) and/or its agenda. Refreshes caches and creates a history record. Returns `serverTime` for client synchronization.
- **Input Schema**:
```json
{
  "id": "string (meeting ID)",
  "name": "string",
  "scheduledTime": "number (epoch ms)",
  "duration": "number",
  "agenda": ["array of agenda item objects (optional)"],
  "comments": ["array of comment objects (optional)"]
}
```
- **Output Schema**: Meeting JSON with `visitors` array and `serverTime` (epoch ms)

---

### 56. proposedTimes.json
- **URL**: `/{siteId}/{pageId}/proposedTimes.json`
- **Method**: POST
- **Controller**: `MeetingControler.proposedTimes()`
- **Description**: Updates proposed meeting time options for attendee polling.
- **Input Schema**:
```json
{
  "id": "string (meeting ID)",
  "proposedTimes": ["array of timestamp proposals"]
}
```
- **Output Schema**: Meeting JSON with `visitors` array and `serverTime`

---

### 57. setSituation.json
- **URL**: `/{siteId}/{pageId}/setSituation.json`
- **Method**: POST
- **Controller**: `MeetingControler.setSituation()`
- **Description**: Sets a user's attendance/availability situation for a meeting (will attend, unavailable, etc.).
- **Input Schema**:
```json
{
  "id": "string (meeting ID)",
  "uid": "string (user email)",
  "situation": "string (attending | unavailable | tentative)"
}
```
- **Output Schema**: Meeting JSON with updated `visitors` array

---

### 58. getMeetingNotes.json
- **URL**: `/{siteId}/{pageId}/getMeetingNotes.json`
- **Method**: GET
- **Controller**: `MeetingControler.getMeetingNotes()`
- **Description**: Returns meeting notes/minutes along with visitor information.
- **Query Parameters**: `id` (string — meeting ID)
- **Output Schema**: Meeting notes JSON with `visitors` array

---

### 59. updateMeetingNotes.json
- **URL**: `/{siteId}/{pageId}/updateMeetingNotes.json`
- **Method**: POST
- **Controller**: `MeetingControler.updateMeetingNotes()`
- **Description**: Updates the minutes/notes for a meeting.
- **Input Schema**:
```json
{
  "id": "string (meeting ID)",
  "minutes": ["array of minute/note objects"]
}
```
- **Output Schema**: Updated meeting notes JSON with `visitors` array

---

### 60. meetingDelete.json
- **URL**: `/{siteId}/{pageId}/meetingDelete.json`
- **Method**: POST
- **Controller**: `MeetingControler.meetingDelete()`
- **Description**: Deletes a meeting and all its associated data.
- **Input Schema**:
```json
{
  "id": "string (meeting ID)"
}
```
- **Output Schema**: Plain text deletion confirmation

---

### 61. agendaAdd.json
- **URL**: `/{siteId}/{pageId}/agendaAdd.json`
- **Method**: POST
- **Controller**: `MeetingControler.agendaAdd()`
- **Description**: Adds a new agenda item to a meeting.
- **Input Schema**:
```json
{
  "id": "string (meeting ID)",
  "subject": "string (agenda item title)",
  "duration": "number (minutes for this item)",
  "presenter": "string (optional user email)"
}
```
- **Output Schema**: `agendaItem.getJSON(ar, ngw, meeting, true)`

---

### 62. agendaDelete.json
- **URL**: `/{siteId}/{pageId}/agendaDelete.json`
- **Method**: POST
- **Controller**: `MeetingControler.agendaDelete()`
- **Description**: Deletes an agenda item from a meeting.
- **Input Schema**:
```json
{
  "id": "string (meeting ID)",
  "aid": "string (agenda item ID)"
}
```
- **Output Schema**: Plain text deletion confirmation

---

### 63. agendaMove.json
- **URL**: `/{siteId}/{pageId}/agendaMove.json`
- **Method**: POST
- **Controller**: `MeetingControler.agendaMove()`
- **Description**: Moves an agenda item from one meeting to another.
- **Input Schema**:
```json
{
  "src": "string (source meeting ID)",
  "dest": "string (destination meeting ID)",
  "id": "string (agenda item ID)"
}
```
- **Output Schema**: `agendaItem.getJSON(ar, ngw, meeting, true)`

---

### 64. agendaGet.json
- **URL**: `/{siteId}/{pageId}/agendaGet.json`
- **Method**: GET
- **Controller**: `MeetingControler.agendaGet()`
- **Description**: Returns the details for a single agenda item.
- **Query Parameters**: `id` (string — meeting ID), `aid` (string — agenda item ID)
- **Output Schema**: `agendaItem.getJSON(ar, ngw, meeting, true)`

---

### 65. agendaUpdate.json
- **URL**: `/{siteId}/{pageId}/agendaUpdate.json`
- **Method**: POST
- **Controller**: `MeetingControler.agendaUpdate()`
- **Description**: Updates an agenda item's content and/or position within the meeting.
- **Input Schema**:
```json
{
  "id": "string (meeting ID)",
  "aid": "string (agenda item ID)",
  "subject": "string",
  "duration": "number (minutes)",
  "presenter": "string (user email)",
  "position": "number (optional — new position)"
}
```
- **Output Schema**: `agendaItem.getJSON(ar, ngw, meeting, true)`

---

### 66. createMinutes.json
- **URL**: `/{siteId}/{pageId}/createMinutes.json`
- **Method**: POST
- **Controller**: `MeetingControler.createMinutes()`
- **Description**: Creates a discussion topic from the meeting's agenda, effectively converting the meeting into a minutes document.
- **Input Schema**:
```json
{
  "id": "string (meeting ID)"
}
```
- **Output Schema**: `meeting.getFullJSON(ar, ngw, false)`

---

### 67. timeZoneList.json
- **URL**: `/{siteId}/{pageId}/timeZoneList.json`
- **Method**: POST
- **Controller**: `MeetingControler.timeZoneList()`
- **Description**: Converts a timestamp into multiple timezone representations. Useful for displaying a meeting time to participants across time zones. Can also expand a list of user emails into their preferred zones.
- **Input Schema**:
```json
{
  "date": "number (epoch ms timestamp to convert)",
  "zones": ["array of timezone ID strings (optional)"],
  "users": ["array of user emails (optional — will use each user's timezone)"],
  "template": "string (optional — format template)"
}
```
- **Output Schema**:
```json
{
  "dates": [
    {
      "zone": "string (timezone ID)",
      "display": "string (formatted date/time)"
    }
  ],
  "sourceDate": "number (epoch ms)"
}
```

---

## Document APIs

### 68. docInfo.json
- **URL**: `/{siteId}/{pageId}/docInfo.json`
- **Method**: GET
- **Controller**: `ProjectDocsController.docInfo()`
- **Description**: Returns metadata for a single document attachment, with access control check.
- **Query Parameters**: `did` (string — document ID)
- **Output Schema**: `attachment.getJSON4Doc(ar, ngw)`

---

### 69. docsUpdate.json
- **URL**: `/{siteId}/{pageId}/docsUpdate.json`
- **Method**: POST
- **Controller**: `ProjectDocsController.docsUpdate()`
- **Description**: Creates or updates a document attachment. Omit `did` to create; include it to update. Creates a history record.
- **Input Schema**:
```json
{
  "did": "string (document ID, omit to create)",
  "docInfo": {
    "name": "string",
    "description": "string",
    "visibility": "string"
  }
}
```
- **Output Schema**: `attachment.getJSON4Doc(ar, ngw)`

---

### 70. docsList.json
- **URL**: `/{siteId}/{pageId}/docsList.json`
- **Method**: GET
- **Controller**: `ProjectDocsController.docsList()`
- **Description**: Lists all document attachments in the workspace. Optionally filter by meeting ID.
- **Query Parameters**: `meet` (string — optional meeting ID filter)
- **Output Schema**:
```json
{
  "docs": [
    {
      "id": "string",
      "name": "string",
      "size": "number (bytes)",
      "modified": "number (epoch ms)"
    }
  ]
}
```

---

### 71. copyDocument.json
- **URL**: `/{siteId}/{pageId}/copyDocument.json`
- **Method**: POST
- **Controller**: `ProjectDocsController.copyDocument()`
- **Description**: Copies a document from another workspace into this one.
- **Input Schema**:
```json
{
  "from": "string (source workspace page ID)",
  "id": "string (document ID to copy)"
}
```
- **Output Schema**:
```json
{
  "created": "new document JSON object in destination workspace"
}
```

---

### 72. moveDocument.json
- **URL**: `/{siteId}/{pageId}/moveDocument.json`
- **Method**: POST
- **Controller**: `ProjectDocsController.moveDocument()`
- **Description**: Moves a document from another workspace into this one (copy + delete from source).
- **Input Schema**:
```json
{
  "from": "string (source workspace page ID)",
  "id": "string (document ID to move)"
}
```
- **Output Schema**:
```json
{
  "created": "new document JSON object in destination workspace"
}
```

---

### 73. sharePorts.json
- **URL**: `/{siteId}/{pageId}/sharePorts.json`
- **Method**: GET
- **Controller**: `ProjectDocsController.sharePorts()`
- **Description**: Returns all share port definitions for the workspace.
- **Output Schema**:
```json
{
  "shares": [
    {
      "id": "string",
      "name": "string",
      "url": "string"
    }
  ]
}
```

---

### 74. share/{id}.json
- **URL**: `/{siteId}/{pageId}/share/{id}.json`
- **Method**: GET / POST
- **Controller**: `ProjectDocsController.share()`
- **Description**: GET retrieves a share port definition. POST updates it.
- **Path Parameters**: `id` (string — share port ID)
- **Input Schema** (POST): Share port JSON object
- **Output Schema**: `sharePort.getFullJSON(ngw)`

---

### 75. SaveReply.json
- **URL**: `/{siteId}/{pageId}/SaveReply.json`
- **Method**: POST
- **Controller**: `ProjectDocsController.SaveReply()`
- **Description**: Saves a reply/comment to a topic, document, meeting, or agenda item. Identified by one of the `topicId`, `docId`, `meetId`, or `agendaId` fields.
- **Input Schema**:
```json
{
  "comments": "string (reply HTML content)",
  "topicId": "string (one of these four — identifies the parent)",
  "docId": "string",
  "meetId": "string",
  "agendaId": "string",
  "emailId": "string (optional — for unauthenticated replies)",
  "userName": "string (optional — display name for unauthenticated replies)"
}
```
- **Output Schema**: Updated parent object JSON (topic, document, meeting, or agenda item)

---

### 76. attachedDocs.json
- **URL**: `/{siteId}/{pageId}/attachedDocs.json`
- **Method**: GET / POST
- **Controller**: `ProjectDocsController.attachedDocs()`
- **Description**: GET returns the list of documents attached to a meeting, note, comment, goal, or email. POST updates the attachment list. Use `ai` with `meet` or `note` to identify an agenda item.
- **Query Parameters**: `meet` (meeting ID), `note` (note ID), `cmt` (comment ID), `goal` (goal ID), `email` (email ID), `ai` (agenda item ID modifier)
- **Output Schema**:
```json
{
  "list": ["array of document objects"]
}
```

---

### 77. allActionsList.json
- **URL**: `/{siteId}/{pageId}/allActionsList.json`
- **Method**: GET
- **Controller**: `ProjectDocsController.allActionsList()`
- **Description**: Returns all action items (goals) in the workspace.
- **Output Schema**:
```json
{
  "list": ["array of goal/action item objects"]
}
```

---

### 78. attachedActions.json
- **URL**: `/{siteId}/{pageId}/attachedActions.json`
- **Method**: GET / POST
- **Controller**: `ProjectDocsController.attachedActions()`
- **Description**: GET returns action items attached to a meeting or note. POST updates the attachment list. Use `ai` with `meet` or `note` to specify an agenda item.
- **Query Parameters**: `meet` (meeting ID), `note` (note ID), `ai` (agenda item ID modifier)
- **Output Schema**:
```json
{
  "list": ["array of action item objects"]
}
```

---

### 79. GetTempName.json
- **URL**: `/{siteId}/{pageId}/GetTempName.json`
- **Method**: GET
- **Controller**: `ProjectDocsController.GetTempName()`
- **Description**: Generates a new temporary filename and returns the URL to PUT the file content to.
- **Output Schema**:
```json
{
  "tempFileName": "string (server-assigned temp name)",
  "tempFileURL": "string (URL to PUT binary content to)"
}
```

---

### 80. UploadTempFile.json
- **URL**: `/{siteId}/{pageId}/UploadTempFile.json`
- **Method**: PUT
- **Controller**: `ProjectDocsController.UploadTempFile()`
- **Description**: Uploads binary file content to a temporary server location. The `tempName` query parameter identifies the allocation from `GetTempName.json`.
- **Query Parameters**: `tempName` (string — temp file name from GetTempName)
- **Input**: Binary file content in request body
- **Output Schema**:
```json
{
  "tempFileName": "string",
  "tempFileURL": "string"
}
```

---

### 81. AttachTempFile.json
- **URL**: `/{siteId}/{pageId}/AttachTempFile.json`
- **Method**: POST
- **Controller**: `ProjectDocsController.AttachTempFile()`
- **Description**: Moves a previously uploaded temp file into permanent storage as a document attachment.
- **Input Schema**:
```json
{
  "tempName": "string (temp file name from GetTempName/UploadTempFile)",
  "doc": {
    "id": "string (optional — if attaching to existing doc slot)",
    "size": "number (bytes)"
  }
}
```
- **Output Schema**: `attachment.getJSON4Doc(ar, ngw)`

---

### 82. GetScratchpad.json
- **URL**: `/{siteId}/{pageId}/GetScratchpad.json`
- **Method**: GET
- **Controller**: `ProjectDocsController.GetScratchpad()`
- **Description**: Returns the logged-in user's personal scratchpad for this workspace.
- **Output Schema**:
```json
{
  "scratchpad": {
    "html": "string (scratchpad content)",
    "modified": "number (epoch ms)"
  }
}
```

---

### 83. UpdateScratchpad.json
- **URL**: `/{siteId}/{pageId}/UpdateScratchpad.json`
- **Method**: POST
- **Controller**: `ProjectDocsController.UpdateScratchpad()`
- **Description**: Saves the user's personal scratchpad content for this workspace.
- **Input Schema**: Scratchpad JSON object with `html` field
- **Output Schema**:
```json
{
  "scratchpad": {
    "html": "string",
    "modified": "number (epoch ms)"
  }
}
```

---

### 84. GetWebFile.json
- **URL**: `/{siteId}/{pageId}/GetWebFile.json`
- **Method**: GET
- **Controller**: `ProjectDocsController.GetWebFile()`
- **Description**: Returns a web file (an inline editable file attachment) by attachment ID.
- **Query Parameters**: `aid` (string — attachment ID)
- **Output Schema**: `webFile.getJson()`

---

### 85. UpdateWebFile.json
- **URL**: `/{siteId}/{pageId}/UpdateWebFile.json`
- **Method**: POST
- **Controller**: `ProjectDocsController.UpdateWebFile()`
- **Description**: Updates a web file's content and metadata.
- **Query Parameters**: `aid` (string — attachment ID)
- **Input Schema**: Web file JSON (content and metadata fields)
- **Output Schema**: `webFile.getJson()`

---

### 86. UpdateWebFileComments.json
- **URL**: `/{siteId}/{pageId}/UpdateWebFileComments.json`
- **Method**: POST
- **Controller**: `ProjectDocsController.UpdateWebFileComments()`
- **Description**: Updates user review comments on a specific section of a web file.
- **Query Parameters**: `aid` (string — attachment ID), `sec` (number — section number)
- **Input Schema**: Comments JSON object
- **Output Schema**: `webFile.getJson()`

---

## Workspace/Site Management APIs

### 87. getLearning.json
- **URL**: `/{siteId}/{pageId}/getLearning.json`
- **Method**: GET
- **Controller**: `MainTabsViewControler.getLearning()`
- **Description**: Returns the learning path data for the logged-in user for a specific JSP page. Used to drive onboarding tutorials.
- **Query Parameters**: `jsp` (string — JSP page identifier)
- **Output Schema**:
```json
{
  "list": ["array of learning path step objects with completion status"]
}
```

---

### 88. setLearning.json
- **URL**: `/{siteId}/{pageId}/setLearning.json`
- **Method**: POST
- **Controller**: `MainTabsViewControler.setLearning()`
- **Description**: Sets the learning path definition for a page. Super admin only.
- **Input Schema**: Learning path JSON with `jsp`, `mode`, and step definitions
- **Output Schema**:
```json
{
  "list": ["updated learning path list"]
}
```

---

### 89. MarkLearningDone.json
- **URL**: `/{siteId}/{pageId}/MarkLearningDone.json`
- **Method**: POST
- **Controller**: `MainTabsViewControler.MarkLearningDone()`
- **Description**: Marks or unmarks a learning path step as completed for the user.
- **Input Schema**:
```json
{
  "esp": "string (learning step identifier)",
  "mode": "string",
  "done": "boolean (true to mark done, false to unmark)"
}
```
- **Output Schema**:
```json
{
  "list": ["user's updated learning path with completion flags"]
}
```

---

### 90. removeMe.json
- **URL**: `/removeMe.json`
- **Method**: GET
- **Controller**: `MainTabsViewControler.removeMe()`
- **Description**: Removes the logged-in user from a specified role in a workspace.
- **Query Parameters**: `p` (string — workspace page ID), `role` (string — role name)
- **Output Schema**:
```json
{
  "result": "ok"
}
```

---

### 91. searchNotes.json (Workspace)
- **URL**: `/{siteId}/{pageId}/searchNotes.json`
- **Method**: POST
- **Controller**: `MainTabsViewControler.searchNotes()`
- **Description**: Searches for topics across workspaces. Scoped to a site or a specific project if provided.
- **Input Schema**:
```json
{
  "searchFilter": "string (search text)",
  "searchSite": "string (optional — site ID to scope search)",
  "searchProject": "string (optional — workspace ID to scope search)"
}
```
- **Output Schema**: JSON array of search result records

---

### 92. siteRequest.json
- **URL**: `/{userKey}/siteRequest.json`
- **Method**: POST
- **Controller**: `SiteController.siteRequest()`
- **Description**: Submits a request to create a new site. Sends a notification email and creates a pending site request record.
- **Input Schema**: Site request JSON (name, purpose, description, etc.)
- **Output Schema**: `siteRequest.getJSON()` — site request record with ID and status

---

### 93. replaceUsers.json
- **URL**: `/{siteId}/$/replaceUsers.json`
- **Method**: POST
- **Controller**: `SiteController.replaceUsers()`
- **Description**: Replaces one user with another across all workspaces in the site. Admin operation used for user account merges.
- **Input Schema**:
```json
{
  "sourceUser": "string (email of user to replace)",
  "destUser": "string (email of replacement user)"
}
```
- **Output Schema**:
```json
{
  "updated": "number (count of workspaces updated)"
}
```

---

### 94. findUserProfile.json
- **URL**: `/{siteId}/$/findUserProfile.json`
- **Method**: POST
- **Controller**: `SiteController.findUserProfile()`
- **Description**: Finds a user profile by ID or email and checks their site membership.
- **Input Schema**:
```json
{
  "uid": "string (user ID or email)"
}
```
- **Output Schema**: `user.getFullJSON()` with `isPaid` field added

---

### 95. assureUserProfile.json
- **URL**: `/{siteId}/$/assureUserProfile.json`
- **Method**: POST
- **Controller**: `SiteController.assureUserProfile()`
- **Description**: Creates the user profile if it does not exist. Optionally sets or clears paid status.
- **Input Schema**:
```json
{
  "uid": "string (user email)",
  "name": "string (optional — display name for new profile)",
  "setPaid": "boolean (optional)",
  "setUnPaid": "boolean (optional)"
}
```
- **Output Schema**: `user.getFullJSON()` with `isPaid` field

---

### 96. updateUserProfile.json
- **URL**: `/{siteId}/$/updateUserProfile.json`
- **Method**: POST
- **Controller**: `SiteController.updateUserProfile()`
- **Description**: Updates a user's profile settings at the site level.
- **Input Schema**:
```json
{
  "uid": "string (user email)",
  "name": "string",
  "description": "string"
}
```
- **Output Schema**: `user.getFullJSON()`

---

### 97. manageUserRoles.json
- **URL**: `/{siteId}/$/manageUserRoles.json`
- **Method**: POST
- **Controller**: `SiteController.manageUserRoles()`
- **Description**: Adds or removes a user from a specific role within a specific workspace. Site-level admin operation.
- **Input Schema**:
```json
{
  "uid": "string (user email)",
  "workspace": "string (workspace page ID)",
  "role": "string (role ID)",
  "add": "boolean (true to add, false to remove)"
}
```
- **Output Schema**: `user.getFullJSON()` — updated user profile

---

### 98. SiteMail.json
- **URL**: `/{siteId}/$/SiteMail.json`
- **Method**: POST
- **Controller**: `SiteController.SiteMail()`
- **Description**: Creates or updates a site-level email generator (stored email template/schedule).
- **Input Schema**: Site mail generator JSON
- **Output Schema**: `emailGenerator.getJSON()` — generator state

---

### 99. SitePeople.json
- **URL**: `/{siteId}/$/SitePeople.json`
- **Method**: GET
- **Controller**: `SiteController.SitePeople()`
- **Description**: Returns all people who are members of any workspace in the site.
- **Output Schema**:
```json
{
  "people": [
    {
      "id": "string",
      "name": "string",
      "email": "string",
      "isPaid": "boolean"
    }
  ]
}
```

---

### 100. SiteStatistics.json
- **URL**: `/{siteId}/$/SiteStatistics.json`
- **Method**: GET
- **Controller**: `SiteController.SiteStatistics()`
- **Description**: Returns usage statistics for the site. Pass `recalc=true` to force a statistics recalculation.
- **Query Parameters**: `recalc` (string — optional, "true" to recalculate)
- **Output Schema**:
```json
{
  "siteId": "string",
  "stats": {
    "workspaceCount": "number",
    "memberCount": "number",
    "topicCount": "number",
    "meetingCount": "number"
  }
}
```

---

### 101/102. SiteUserMap.json (GET / POST)
- **URL**: `/{siteId}/$/SiteUserMap.json`
- **Method**: GET / POST
- **Controller**: `SiteController.SiteUserMap()`
- **Description**: GET returns the full site user map (users, roles, permissions). POST applies a delta update to the user map.
- **Input Schema** (POST): User map delta JSON object
- **Output Schema**: `userMap.getJson()` — complete user map with permissions

---

### 103. GarbageCollect.json
- **URL**: `/{siteId}/$/GarbageCollect.json`
- **Method**: GET
- **Controller**: `SiteController.GarbageCollect()`
- **Description**: Performs garbage collection on the site, removing orphaned data and temporary files.
- **Output Schema**: Site GC result JSON with counts of items cleaned

---

### 104. QuerySiteEmail.json
- **URL**: `/{siteId}/$/QuerySiteEmail.json`
- **Method**: POST
- **Controller**: `SiteController.QuerySiteEmail()`
- **Description**: Queries email delivery history at the site level.
- **Input Schema**: Posted JSON query object
- **Output Schema**: `EmailSender.querySiteEmail(site, posted)` results

---

### 105. createWorkspace.json
- **URL**: `/{siteId}/$/createWorkspace.json`
- **Method**: POST
- **Controller**: `CreateProjectController.createWorkspace()`
- **Description**: Creates a new workspace within the site. Optionally copies structure from a template workspace, sets a parent, and seeds initial membership.
- **Input Schema**:
```json
{
  "newName": "string (workspace name)",
  "template": "string (optional — template workspace ID to clone from)",
  "parent": "string (optional — parent workspace ID for hierarchy)",
  "frozen": "boolean (optional — prevent further changes)",
  "purpose": "string (optional — description)",
  "members": [
    {
      "uid": "string (user email)",
      "role": "string (role ID)"
    }
  ]
}
```
- **Output Schema**: `newWorkspace.getConfigJSON()` — workspace configuration

---

## Super Admin APIs

### 106. takeOwnershipSite.json
- **URL**: `/su/takeOwnershipSite.json`
- **Method**: POST
- **Controller**: `SiteController.takeOwnershipSite()`
- **Description**: Allows a super admin to take ownership of a site by adding themselves to the owners role. Used for administration of abandoned or problematic sites.
- **Input Schema**:
```json
{
  "key": "string (site key)"
}
```
- **Output Schema**: `site.getConfigJSON()`

---

### 107. garbageCollect.json
- **URL**: `/su/garbageCollect.json`
- **Method**: POST
- **Controller**: `SiteController.garbageCollect()`
- **Description**: Super admin operation to garbage-collect a deleted site, permanently removing its data from storage.
- **Input Schema**:
```json
{
  "key": "string (site key)"
}
```
- **Output Schema**:
```json
{
  "key": "string (site key)",
  "op": "string (operation performed)",
  "status": "success"
}
```

---

### 108. updateCharge.json
- **URL**: `/su/updateCharge.json`
- **Method**: POST
- **Controller**: `SiteController.updateCharge()`
- **Description**: Creates or updates a billing charge entry for a site for a specific year/month.
- **Input Schema**:
```json
{
  "site": "string (site ID)",
  "year": "number",
  "month": "number (1-12)",
  "amount": "number (charge amount)"
}
```
- **Output Schema**: `ledger.generateJson()` — ledger entry

---

### 109. recordPayment.json
- **URL**: `/su/recordPayment.json`
- **Method**: POST
- **Controller**: `SiteController.recordPayment()`
- **Description**: Records a payment against a site's billing ledger.
- **Input Schema**:
```json
{
  "site": "string (site ID)",
  "year": "number",
  "month": "number (1-12)",
  "day": "number",
  "amount": "number (payment amount)",
  "detail": "string (payment description/reference)"
}
```
- **Output Schema**: `ledger.generateJson()`

---

### 110. clearAllSiteCharges.json
- **URL**: `/su/clearAllSiteCharges.json`
- **Method**: POST
- **Controller**: `SiteController.clearAllSiteCharges()`
- **Description**: Clears billing charges for all sites for a specific year/month. Super admin bulk billing operation.
- **Input Schema**:
```json
{
  "year": "number",
  "month": "number (1-12)"
}
```
- **Output Schema**:
```json
{
  "list": ["array of site IDs that were cleared"]
}
```

---

### 111. acceptOrDenySite.json
- **URL**: `/su/acceptOrDenySite.json`
- **Method**: POST
- **Controller**: `SuperAdminController.acceptOrDenySite()`
- **Description**: Approves or denies a pending site creation request. Updates the request status and records the decision in the history log.
- **Input Schema**:
```json
{
  "requestId": "string (site request ID)",
  "siteId": "string (optional — site ID if granting)",
  "newStatus": "string (Granted | Denied)"
}
```
- **Output Schema**: `siteRequest.getJSON()`

---

### 112. testEmailSend.json
- **URL**: `/su/testEmailSend.json`
- **Method**: POST
- **Controller**: `SuperAdminController.testEmailSend()`
- **Description**: Sends a test email with specified parameters. Used to validate email configuration.
- **Input Schema**:
```json
{
  "to": "string (recipient address)",
  "from": "string (sender address)",
  "subject": "string",
  "body": "string (email body)"
}
```
- **Output Schema**:
```json
{
  "status": "success"
}
```

---

### 113. QuerySuperAdminEmail.json
- **URL**: `/su/QuerySuperAdminEmail.json`
- **Method**: POST
- **Controller**: `SuperAdminController.QuerySuperAdminEmail()`
- **Description**: Queries the super-admin-level email delivery history.
- **Input Schema**: Posted JSON query object
- **Output Schema**: `EmailSender.querySuperAdminEmail(posted)` results

---

### 114. lookUpUser.json
- **URL**: `/su/lookUpUser.json`
- **Method**: POST
- **Controller**: `SuperAdminController.lookUpUser()`
- **Description**: Looks up a user profile by any identifier (email, user key, etc.).
- **Input Schema**:
```json
{
  "uid": "string (user ID or email to look up)"
}
```
- **Output Schema**: `userProfile.getJSON()` — full user profile

---

## Admin APIs

### 115. updateProjectInfo.json
- **URL**: `/{siteId}/{pageId}/updateProjectInfo.json`
- **Method**: POST
- **Controller**: `AdminController.updateProjectInfo()`
- **Description**: Updates workspace configuration. Saves the new config object directly without marking it as modified (caller is responsible for change tracking).
- **Input Schema**:
```json
{
  "newConfig": {
    "name": "string",
    "description": "string",
    "visibility": "string",
    "frozen": "boolean"
  }
}
```
- **Output Schema**: `configJSON` — updated workspace config

---

### 116. updateWorkspaceName.json
- **URL**: `/{siteId}/{pageId}/updateWorkspaceName.json`
- **Method**: POST
- **Controller**: `AdminController.updateWorkspaceName()`
- **Description**: Changes the display name of a workspace. Validates the new name before saving.
- **Input Schema**:
```json
{
  "newName": "string (new workspace display name)"
}
```
- **Output Schema**: `configJSON` — workspace config with updated name

---

### 117. deleteWorkspaceName.json
- **URL**: `/{siteId}/{pageId}/deleteWorkspaceName.json`
- **Method**: POST
- **Controller**: `AdminController.deleteWorkspaceName()`
- **Description**: Deletes/archives a workspace. Marks the workspace as deleted.
- **Input Schema**:
```json
{
  "confirm": "boolean (must be true to confirm deletion)"
}
```
- **Output Schema**: Deletion confirmation JSON

---

### 118. updateSiteInfo.json
- **URL**: `/{siteId}/$/updateSiteInfo.json`
- **Method**: POST
- **Controller**: `AdminController.updateSiteInfo()`
- **Description**: Updates site-level configuration. Super admins may also update the admin config block within the site config.
- **Input Schema**:
```json
{
  "newConfig": {
    "name": "string",
    "description": "string",
    "adminConfig": "object (optional, super admin only)"
  }
}
```
- **Output Schema**: `site.getConfigJSON()` — updated site config

---

## Summary

**Total API Endpoints: 118**

### Distribution by Controller:
- **UserController**: 11 endpoints
- **ProjectSettingController**: 17 endpoints
- **TopicController**: 9 endpoints
- **CommentController**: 4 endpoints
- **ProjectGoalController**: 10 endpoints
- **MeetingControler**: 16 endpoints
- **ProjectDocsController**: 19 endpoints
- **MainTabsViewControler**: 6 endpoints
- **SiteController**: 18 endpoints
- **CreateProjectController**: 1 endpoint
- **SuperAdminController**: 4 endpoints
- **AdminController**: 4 endpoints

### Common Patterns:
1. All endpoints follow the `.json` naming convention
2. POST endpoints receive JSON via `getPostedObject(ar)`
3. GET endpoints use query parameters via `ar.reqParam()`
4. Responses are sent via `sendJson(ar, jsonObject)` or `sendJsonArray(ar, jsonArray)`
5. Error handling uses `streamException(exception, ar)`
6. Authentication and authorization checks are performed via `AuthRequest` (ar) object

### Path Variable Conventions:
- `{userKey}`: User identifier
- `{siteId}`: Site identifier
- `{pageId}`: Workspace/page identifier
- `{id}`: Generic identifier for various resources
- `/su/`: Super admin endpoints prefix
- `/$/`: Site-level endpoints (not workspace-specific)

### Upload Workflow (three-step):
1. `GetTempName.json` — allocate a temp filename and upload URL
2. `UploadTempFile.json` (PUT) — upload binary content
3. `AttachTempFile.json` — move to permanent storage and attach to a workspace object
