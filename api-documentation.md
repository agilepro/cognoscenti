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
- **Input Schema**:
```json
{
"address": "string (email address)",
"act": "string (Create | Delete)"
}
```
- **Output**: Plain text message confirmation

### 2. updateProfile.json
- **URL**: `/{userKey}/updateProfile.json`
- **Method**: POST
- **Controller**: `UserController.updateProfile()`
- **Input Schema**: User profile fields (varies based on UserProfile object)
- **Output Schema**: Full user profile JSON from `userBeingEdited.getFullJSON()`

### 3. updateMicroProfile.json
- **URL**: `/updateMicroProfile.json`
- **Method**: POST
- **Controller**: `UserController.updateMicroProfile()`
- **Input Schema**:
```json
{
"uid": "string (email ID)",
"name": "string (display name)"
}
```
- **Output Schema**: Echo of input JSON

### 4. searchNotes.json (User)
- **URL**: `/{userKey}/searchNotes.json`
- **Method**: POST
- **Controller**: `UserController.searchPublicNotesJSON()`
- **Input Schema**:
```json
{
"searchFilter": "string",
"searchProject": "string"
}
```
- **Output Schema**:
```json
[
{
"// SearchResultRecord fields"
}
]
```

### 5. QueryUserEmail.json
- **URL**: `/{userKey}/QueryUserEmail.json`
- **Method**: POST
- **Controller**: `UserController.queryEmail()`
- **Input Schema**: Email query fields (system adds userKey and userEmail)
- **Output Schema**: Email query results from EmailSender

### 6. GetFacilitatorInfo.json
- **URL**: `/{userKey}/GetFacilitatorInfo.json`
- **Method**: GET
- **Controller**: `UserController.getFacilitatorInfo()`
- **Query Parameters**: `key` (string - user key)
- **Output Schema**: Facilitator fields from user cache

### 7. UpdateFacilitatorInfo.json
- **URL**: `/{userKey}/UpdateFacilitatorInfo.json`
- **Method**: POST
- **Controller**: `UserController.updateFacilitatorInfo()`
- **Query Parameters**: `key` (string - user key)
- **Input Schema**:
```json
{
"isActive": "boolean",
"// other facilitator fields"
}
```
- **Output Schema**: Updated facilitator fields

### 8. MailProblems.json
- **URL**: `/{userKey}/MailProblems.json`
- **Method**: GET
- **Controller**: `UserController.mailProblems()`
- **Output Schema**:
```json
{
"blocks": [],
"bounces": [],
"spams": []
}
```

### 9. MailProblemsUser.json
- **URL**: `/{userKey}/MailProblemsUser.json`
- **Method**: GET
- **Controller**: `UserController.mailProblemsUser()`
- **Output Schema**:
```json
{
"blocks": ["array of blocks for this user"],
"bounces": ["array of bounces for this user"],
"spams": ["array of spam reports for this user"]
}
```

### 10. ClearLearningDone.json
- **URL**: `/{userKey}/ClearLearningDone.json`
- **Method**: POST
- **Controller**: `UserController.clearLearningPath()`
- **Output Schema**:
```json
{
"status": "cleared"
}
```

### 11. UserPostOps.json
- **URL**: `/{userKey}/UserPostOps.json`
- **Method**: POST
- **Controller**: `UserController.userPostOps()`
- **Input Schema**:
```json
{
"op": "string (tempFile | finishIcon)",
"tempFileName": "string (required for finishIcon op)"
}
```
- **Output Schema** (tempFile op):
```json
{
"responseCode": 200,
"tempFileName": "string",
"tempFileURL": "string"
}
```
- **Output Schema** (finishIcon op):
```json
{
"responseCode": 200,
"tempFileName": "string",
"iconFileName": "string"
}
```

---

## Project Settings APIs

### 12. personalUpdate.json
- **URL**: `/{siteId}/{pageId}/personalUpdate.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.personalUpdate()`
- **Input Schema**:
```json
{
"op": "string (SetWatch | SetReviewTime | ClearWatch | SetNotify)",
"// operation-specific fields"
}
```
- **Output Schema**: Operation-dependent

### 13. setPersonal.json
- **URL**: `/{siteId}/{pageId}/setPersonal.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.setPersonal()`
- **Input Schema**: Personal workspace settings fields
- **Output Schema**: Updated personal workspace settings

### 14. rolePlayerUpdate.json
- **URL**: `/{siteId}/{pageId}/rolePlayerUpdate.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.rolePlayerUpdate()`
- **Input Schema**:
```json
{
"op": "string (Join | Drop)",
"roleId": "string",
"desc": "string (optional)"
}
```
- **Output Schema**: Role request record JSON

### 15. roleRequestResolution.json
- **URL**: `/{siteId}/{pageId}/roleRequestResolution.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.roleRequestResolution()`
- **Input Schema**:
```json
{
"op": "string (Approve | Reject)",
"rrId": "string (role request ID)"
}
```
- **Output Schema**: Updated role request record

### 16. roleUpdate.json
- **URL**: `/{siteId}/{pageId}/roleUpdate.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.roleUpdate()`
- **Input Schema**:
```json
{
"op": "string (Update | etc.)",
"symbol": "string",
"// other role fields"
}
```
- **Output Schema**: Role information

### 17. roleDefinitions.json
- **URL**: `/{siteId}/{pageId}/roleDefinitions.json`
- **Method**: GET
- **Controller**: `ProjectSettingController.roleDefinitions()`
- **Output Schema**:
```json
{
"defs": ["array of role definitions"]
}
```

### 18. getAllLabels.json
- **URL**: `/{siteId}/{pageId}/getAllLabels.json`
- **Method**: GET
- **Controller**: `ProjectSettingController.getAllLabels()`
- **Output Schema**:
```json
{
"list": ["array of label objects"]
}
```

### 19. isRolePlayer.json
- **URL**: `/{siteId}/{pageId}/isRolePlayer.json`
- **Method**: GET
- **Controller**: `ProjectSettingController.isRolePlayer()`
- **Query Parameters**: `role` (string)
- **Output Schema**: Boolean indicating role player status

### 20. assureRolePlayer.json
- **URL**: `/{siteId}/{pageId}/assureRolePlayer.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.assureRolePlayer()`
- **Input Schema**:
```json
{
"roleId": "string"
}
```
- **Output Schema**: Confirmation of role player status

### 21. emailGeneratorUpdate.json
- **URL**: `/{siteId}/{pageId}/emailGeneratorUpdate.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.emailGeneratorUpdate()`
- **Input Schema**: Email generator configuration fields
- **Output Schema**: Email generator state

### 22. renderEmail.json
- **URL**: `/{siteId}/{pageId}/renderEmail.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.renderEmail()`
- **Input Schema**: Email template and data fields
- **Output Schema**: Rendered email content

### 23. getLabels.json
- **URL**: `/{siteId}/{pageId}/getLabels.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.getLabels()`
- **Input Schema**: Label identifiers
- **Output Schema**: List of labels

### 24. labelUpdate.json
- **URL**: `/{siteId}/{pageId}/labelUpdate.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.labelUpdate()`
- **Input Schema**:
```json
{
"op": "string",
"// label data fields"
}
```
- **Output Schema**: Updated label information

### 25. copyLabels.json
- **URL**: `/{siteId}/{pageId}/copyLabels.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.copyLabels()`
- **Input Schema**: Source and destination label information
- **Output Schema**: Copy operation confirmation

### 26. QueryEmail.json
- **URL**: `/{siteId}/{pageId}/QueryEmail.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.QueryEmail()`
- **Input Schema**: Email query fields
- **Output Schema**: Email query results

### 27. invitations.json
- **URL**: `/{siteId}/{pageId}/invitations.json`
- **Method**: GET
- **Controller**: `ProjectSettingController.invitations()`
- **Output Schema**: Array of invitation objects

### 28. invitationUpdate.json
- **URL**: `/{siteId}/{pageId}/invitationUpdate.json`
- **Method**: POST
- **Controller**: `ProjectSettingController.invitationUpdate()`
- **Input Schema**:
```json
{
"ss": "string (status)",
"// invitation data"
}
```
- **Output Schema**: Updated invitation

---

## Topic/Discussion APIs

### 29. getTopics.json
- **URL**: `/{siteId}/{pageId}/getTopics.json`
- **Method**: GET
- **Controller**: `TopicController.getTopics()`
- **Output Schema**: Array of topic objects

### 30. topicList.json
- **URL**: `/{siteId}/{pageId}/topicList.json`
- **Method**: GET
- **Controller**: `TopicController.topicList()`
- **Output Schema**:
```json
{
"topics": ["array of topic objects"]
}
```

### 31. getTopic.json
- **URL**: `/{siteId}/{pageId}/getTopic.json`
- **Method**: GET
- **Controller**: `TopicController.getTopic()`
- **Query Parameters**: `nid` (string - note/topic ID)
- **Output Schema**: Topic with comments

### 32. getNoteHistory.json
- **URL**: `/{siteId}/{pageId}/getNoteHistory.json`
- **Method**: GET
- **Controller**: `TopicController.getGoalHistory()`
- **Query Parameters**: `nid` (string - note ID)
- **Output Schema**: Array of history records

### 33. mergeTopicDoc.json
- **URL**: `/{siteId}/{pageId}/mergeTopicDoc.json`
- **Method**: POST
- **Controller**: `TopicController.mergeTopicDoc()`
- **Input Schema**:
```json
{
"nid": "string",
"old": "string (old markdown)",
"new": "string (new markdown)",
"subject": "string (optional)"
}
```
- **Output Schema**: Topic with comments

### 34. updateNote.json
- **URL**: `/{siteId}/{pageId}/updateNote.json`
- **Method**: POST
- **Controller**: `TopicController.updateNote()`
- **Query Parameters**: `nid` (string - note ID)
- **Input Schema**: Note/topic fields
- **Output Schema**: Updated topic with comments

### 35. noteHtmlUpdate.json
- **URL**: `/{siteId}/{pageId}/noteHtmlUpdate.json`
- **Method**: POST
- **Controller**: `TopicController.noteHtmlUpdate()`
- **Query Parameters**: `nid` (string - note ID, can be "~new~" for new topic)
- **Input Schema**:
```json
{
"saveMode": "string (optional - 'autosave')",
"// note fields including HTML content"
}
```
- **Output Schema**: Updated topic with comments

### 36. topicSubscribe.json
- **URL**: `/{siteId}/{pageId}/topicSubscribe.json`
- **Method**: GET
- **Controller**: `TopicController.topicSubscribe()`
- **Query Parameters**: `nid` (string - note ID), `emailId` (string - optional if not logged in)
- **Output Schema**: Topic with comments

### 37. topicUnsubscribe.json
- **URL**: `/{siteId}/{pageId}/topicUnsubscribe.json`
- **Method**: GET
- **Controller**: `TopicController.topicUnsubscribe()`
- **Query Parameters**: `nid` (string - note ID), `emailId` (string - optional if not logged in)
- **Output Schema**: Topic with comments

---

## Comment APIs

### 38. getComment.json
- **URL**: `/{siteId}/{pageId}/getComment.json`
- **Method**: GET
- **Controller**: `CommentController.getTopic()`
- **Query Parameters**: `cid` (long - comment ID)
- **Output Schema**: Complete comment JSON

### 39. getCommentList.json
- **URL**: `/{siteId}/{pageId}/getCommentList.json`
- **Method**: GET
- **Controller**: `CommentController.getCommentList()`
- **Output Schema**:
```json
{
"list": ["array of comment objects"]
}
```

### 40. updateComment.json
- **URL**: `/{siteId}/{pageId}/updateComment.json`
- **Method**: POST
- **Controller**: `CommentController.updateComment()`
- **Query Parameters**: `cid` (long - comment ID)
- **Input Schema**:
```json
{
"deleteMe": "boolean (optional)",
"// comment fields"
}
```
- **Output Schema**: Updated comment with documents or deletion status

### 41. updateCommentAnon.json
- **URL**: `/{siteId}/{pageId}/updateCommentAnon.json`
- **Method**: POST
- **Controller**: `CommentController.updateCommentAnon()`
- **Query Parameters**: `cid` (long - comment ID), `msg` (long - message ID for authorization)
- **Input Schema**: Comment fields
- **Output Schema**: Updated comment with documents

---

## Goal/Action Item APIs

### 42. fetchGoal.json
- **URL**: `/{siteId}/{pageId}/fetchGoal.json`
- **Method**: GET
- **Controller**: `ProjectGoalController.fetchGoal()`
- **Query Parameters**: `gid` (string - goal ID)
- **Output Schema**: Goal data

### 43. updateGoal.json
- **URL**: `/{siteId}/{pageId}/updateGoal.json`
- **Method**: POST
- **Controller**: `ProjectGoalController.updateGoal()`
- **Input Schema**: Goal fields
- **Output Schema**: Updated goal

### 44. updateMultiGoal.json
- **URL**: `/{siteId}/{pageId}/updateMultiGoal.json`
- **Method**: POST
- **Controller**: `ProjectGoalController.updateMultiGoal()`
- **Input Schema**: Array or object with multiple goal updates
- **Output Schema**: Updated goals

### 45. getGoalHistory.json
- **URL**: `/{siteId}/{pageId}/getGoalHistory.json`
- **Method**: GET
- **Controller**: `ProjectGoalController.getGoalHistory()`
- **Query Parameters**: `gid` (string - goal ID)
- **Output Schema**: Array of goal history records

### 46. updateDecision.json
- **URL**: `/{siteId}/{pageId}/updateDecision.json`
- **Method**: POST
- **Controller**: `ProjectGoalController.updateDecision()`
- **Input Schema**: Decision data
- **Output Schema**: Updated decision

### 47. taskAreas.json
- **URL**: `/{siteId}/{pageId}/taskAreas.json`
- **Method**: GET
- **Controller**: `ProjectGoalController.taskAreas()`
- **Output Schema**: Array of task areas

### 48. moveTaskArea.json
- **URL**: `/{siteId}/{pageId}/moveTaskArea.json`
- **Method**: POST
- **Controller**: `ProjectGoalController.moveTaskArea()`
- **Input Schema**:
```json
{
"taId": "string",
"// position/movement parameters"
}
```
- **Output Schema**: Move confirmation

### 49. taskArea{id}.json
- **URL**: `/{siteId}/{pageId}/taskArea{id}.json`
- **Method**: GET/POST (method varies)
- **Controller**: `ProjectGoalController.getTaskArea()`
- **Path Parameters**: `id` (string - task area ID)
- **Output Schema**: Task area data

### 50. moveActionItem.json
- **URL**: `/{siteId}/{pageId}/moveActionItem.json`
- **Method**: POST
- **Controller**: `ProjectGoalController.moveActionItem()`
- **Input Schema**: Action item ID and movement parameters
- **Output Schema**: Move confirmation

### 51. createActionItem.json
- **URL**: `/{siteId}/{pageId}/createActionItem.json`
- **Method**: POST
- **Controller**: `MainTabsViewControler.createActionItem()`
- **Input Schema**: Action item details
- **Output Schema**: Created action item

---

## Meeting APIs

### 52. meetingCreate.json
- **URL**: `/{siteId}/{pageId}/meetingCreate.json`
- **Method**: POST
- **Controller**: `MeetingControler.meetingCreate()`
- **Input Schema**: Meeting details
- **Output Schema**: Created meeting record

### 53. meetingList.json
- **URL**: `/{siteId}/{pageId}/meetingList.json`
- **Method**: GET
- **Controller**: `MeetingControler.meetingList()`
- **Output Schema**: Array of meeting records

### 54. meetingRead.json
- **URL**: `/{siteId}/{pageId}/meetingRead.json`
- **Method**: GET
- **Controller**: `MeetingControler.meetingRead()`
- **Query Parameters**: Meeting ID
- **Output Schema**: Meeting details

### 55. meetingUpdate.json
- **URL**: `/{siteId}/{pageId}/meetingUpdate.json`
- **Method**: POST
- **Controller**: `MeetingControler.meetingUpdate()`
- **Input Schema**: Updated meeting fields
- **Output Schema**: Updated meeting record

### 56. proposedTimes.json
- **URL**: `/{siteId}/{pageId}/proposedTimes.json`
- **Method**: POST
- **Controller**: `MeetingControler.proposedTimes()`
- **Input Schema**: Time proposal data
- **Output Schema**: Array of proposed time options

### 57. setSituation.json
- **URL**: `/{siteId}/{pageId}/setSituation.json`
- **Method**: POST
- **Controller**: `MeetingControler.setSituation()`
- **Input Schema**: Situation data
- **Output Schema**: Situation update confirmation

### 58. getMeetingNotes.json
- **URL**: `/{siteId}/{pageId}/getMeetingNotes.json`
- **Method**: GET
- **Controller**: `MeetingControler.getMeetingNotes()`
- **Query Parameters**: Meeting ID
- **Output Schema**: Meeting notes

### 59. updateMeetingNotes.json
- **URL**: `/{siteId}/{pageId}/updateMeetingNotes.json`
- **Method**: POST
- **Controller**: `MeetingControler.updateMeetingNotes()`
- **Input Schema**: Meeting notes content
- **Output Schema**: Updated notes

### 60. meetingDelete.json
- **URL**: `/{siteId}/{pageId}/meetingDelete.json`
- **Method**: POST
- **Controller**: `MeetingControler.meetingDelete()`
- **Input Schema**: Meeting ID or deletion flag
- **Output Schema**: Deletion confirmation

### 61. agendaAdd.json
- **URL**: `/{siteId}/{pageId}/agendaAdd.json`
- **Method**: POST
- **Controller**: `MeetingControler.agendaAdd()`
- **Input Schema**: Agenda item details
- **Output Schema**: Created agenda item

### 62. agendaDelete.json
- **URL**: `/{siteId}/{pageId}/agendaDelete.json`
- **Method**: POST
- **Controller**: `MeetingControler.agendaDelete()`
- **Input Schema**: Agenda item ID or deletion flag
- **Output Schema**: Deletion confirmation

### 63. agendaMove.json
- **URL**: `/{siteId}/{pageId}/agendaMove.json`
- **Method**: POST
- **Controller**: `MeetingControler.agendaMove()`
- **Input Schema**: Agenda item ID and new position
- **Output Schema**: Move confirmation

### 64. agendaGet.json
- **URL**: `/{siteId}/{pageId}/agendaGet.json`
- **Method**: GET
- **Controller**: `MeetingControler.agendaGet()`
- **Query Parameters**: Agenda item ID
- **Output Schema**: Agenda item details

### 65. agendaUpdate.json
- **URL**: `/{siteId}/{pageId}/agendaUpdate.json`
- **Method**: POST
- **Controller**: `MeetingControler.agendaUpdate()`
- **Input Schema**: Updated agenda item fields
- **Output Schema**: Updated agenda item

### 66. createMinutes.json
- **URL**: `/{siteId}/{pageId}/createMinutes.json`
- **Method**: POST
- **Controller**: `MeetingControler.createMinutes()`
- **Input Schema**: Minutes content
- **Output Schema**: Created minutes record

### 67. timeZoneList.json
- **URL**: `/{siteId}/{pageId}/timeZoneList.json`
- **Method**: POST
- **Controller**: `MeetingControler.timeZoneList()`
- **Input Schema**: Timezone parameters
- **Output Schema**: Array of available timezones

---

## Document APIs

### 68. docInfo.json
- **URL**: `/{siteId}/{pageId}/docInfo.json`
- **Method**: GET
- **Controller**: `ProjectDocsController.docInfo()`
- **Query Parameters**: Document ID
- **Output Schema**: Document information

### 69. docsUpdate.json
- **URL**: `/{siteId}/{pageId}/docsUpdate.json`
- **Method**: POST
- **Controller**: `ProjectDocsController.docsUpdate()`
- **Input Schema**: Document update fields
- **Output Schema**: Updated document

### 70. docsList.json
- **URL**: `/{siteId}/{pageId}/docsList.json`
- **Method**: GET
- **Controller**: `ProjectDocsController.docsList()`
- **Output Schema**:
```json
{
"docs": ["array of document objects"]
}
```

### 71. copyDocument.json
- **URL**: `/{siteId}/{pageId}/copyDocument.json`
- **Method**: POST
- **Controller**: `ProjectDocsController.copyDocument()`
- **Input Schema**: Source document ID and destination parameters
- **Output Schema**: Copied document

### 72. moveDocument.json
- **URL**: `/{siteId}/{pageId}/moveDocument.json`
- **Method**: POST
- **Controller**: `ProjectDocsController.moveDocument()`
- **Input Schema**: Document ID and new location
- **Output Schema**: Move confirmation

### 73. sharePorts.json
- **URL**: `/{siteId}/{pageId}/sharePorts.json`
- **Method**: GET
- **Controller**: `ProjectDocsController.sharePorts()`
- **Output Schema**: Array of shared ports/links

### 74. share/{id}.json
- **URL**: `/{siteId}/{pageId}/share/{id}.json`
- **Method**: GET/POST
- **Controller**: `ProjectDocsController.share()`
- **Path Parameters**: `id` (share ID)
- **Input Schema**: Optional sharing parameters
- **Output Schema**: Sharing information

### 75. SaveReply.json
- **URL**: `/{siteId}/{pageId}/SaveReply.json`
- **Method**: POST
- **Controller**: `ProjectDocsController.SaveReply()`
- **Input Schema**: Reply/comment data
- **Output Schema**: Saved reply

### 76. attachedDocs.json
- **URL**: `/{siteId}/{pageId}/attachedDocs.json`
- **Method**: GET
- **Controller**: `ProjectDocsController.attachedDocs()`
- **Query Parameters**: Parent document or container ID
- **Output Schema**: Array of attached documents

### 77. allActionsList.json
- **URL**: `/{siteId}/{pageId}/allActionsList.json`
- **Method**: GET
- **Controller**: `ProjectDocsController.allActionsList()`
- **Output Schema**: Array of all action items

### 78. attachedActions.json
- **URL**: `/{siteId}/{pageId}/attachedActions.json`
- **Method**: GET
- **Controller**: `ProjectDocsController.attachedActions()`
- **Query Parameters**: Parent document or container ID
- **Output Schema**: Array of attached action items

### 79. GetTempName.json
- **URL**: `/{siteId}/{pageId}/GetTempName.json`
- **Method**: GET
- **Controller**: `ProjectDocsController.GetTempName()`
- **Output Schema**:
```json
{
"tempFileName": "string"
}
```

### 80. UploadTempFile.json
- **URL**: `/{siteId}/{pageId}/UploadTempFile.json`
- **Method**: PUT
- **Controller**: `ProjectDocsController.UploadTempFile()`
- **Input**: File content in request body
- **Output Schema**: Confirmation with temp file info

### 81. AttachTempFile.json
- **URL**: `/{siteId}/{pageId}/AttachTempFile.json`
- **Method**: POST
- **Controller**: `ProjectDocsController.AttachTempFile()`
- **Input Schema**:
```json
{
"tempFileName": "string",
"// attachment metadata"
}
```
- **Output Schema**: Attached document information

### 82. GetScratchpad.json
- **URL**: `/{siteId}/{pageId}/GetScratchpad.json`
- **Method**: GET
- **Controller**: `ProjectDocsController.GetScratchpad()`
- **Output Schema**: Scratchpad content

### 83. UpdateScratchpad.json
- **URL**: `/{siteId}/{pageId}/UpdateScratchpad.json`
- **Method**: POST
- **Controller**: `ProjectDocsController.UpdateScratchpad()`
- **Input Schema**: Scratchpad content
- **Output Schema**: Updated scratchpad

### 84. GetWebFile.json
- **URL**: `/{siteId}/{pageId}/GetWebFile.json`
- **Method**: GET
- **Controller**: `ProjectDocsController.GetWebFile()`
- **Query Parameters**: File identifier
- **Output Schema**: Web file content

### 85. UpdateWebFile.json
- **URL**: `/{siteId}/{pageId}/UpdateWebFile.json`
- **Method**: POST
- **Controller**: `ProjectDocsController.UpdateWebFile()`
- **Input Schema**: Web file content and metadata
- **Output Schema**: Updated web file

### 86. UpdateWebFileComments.json
- **URL**: `/{siteId}/{pageId}/UpdateWebFileComments.json`
- **Method**: POST
- **Controller**: `ProjectDocsController.UpdateWebFileComments()`
- **Input Schema**: Comment content and metadata
- **Output Schema**: Updated comments

---

## Workspace/Site Management APIs

### 87. getLearning.json
- **URL**: `/{siteId}/{pageId}/getLearning.json`
- **Method**: GET
- **Controller**: `MainTabsViewControler.getLearning()`
- **Output Schema**: Learning path data

### 88. setLearning.json
- **URL**: `/{siteId}/{pageId}/setLearning.json`
- **Method**: POST
- **Controller**: `MainTabsViewControler.setLearning()`
- **Input Schema**: Learning item identifiers
- **Output Schema**: Learning update confirmation

### 89. MarkLearningDone.json
- **URL**: `/{siteId}/{pageId}/MarkLearningDone.json`
- **Method**: POST
- **Controller**: `MainTabsViewControler.MarkLearningDone()`
- **Input Schema**: Completed learning item
- **Output Schema**: Completion confirmation

### 90. removeMe.json
- **URL**: `/removeMe.json`
- **Method**: GET
- **Controller**: `MainTabsViewControler.removeMe()`
- **Output Schema**: Removal confirmation

### 91. searchNotes.json (Workspace)
- **URL**: `/{siteId}/{pageId}/searchNotes.json`
- **Method**: POST
- **Controller**: `MainTabsViewControler.searchNotes()`
- **Input Schema**:
```json
{
"searchFilter": "string",
"searchSite": "string"
}
```
- **Output Schema**: Array of search results

### 92. siteRequest.json
- **URL**: `/{userKey}/siteRequest.json`
- **Method**: POST
- **Controller**: `SiteController.siteRequest()`
- **Input Schema**: Site request details
- **Output Schema**: Site request confirmation

### 93. replaceUsers.json
- **URL**: `/{siteId}/$/replaceUsers.json`
- **Method**: POST
- **Controller**: `SiteController.replaceUsers()`
- **Input Schema**: User replacement mapping
- **Output Schema**: Replacement confirmation

### 94. findUserProfile.json
- **URL**: `/{siteId}/$/findUserProfile.json`
- **Method**: POST
- **Controller**: `SiteController.findUserProfile()`
- **Input Schema**: User search criteria
- **Output Schema**: Found user profile

### 95. assureUserProfile.json
- **URL**: `/{siteId}/$/assureUserProfile.json`
- **Method**: POST
- **Controller**: `SiteController.assureUserProfile()`
- **Input Schema**: User details
- **Output Schema**: User profile (created if needed)

### 96. updateUserProfile.json
- **URL**: `/{siteId}/$/updateUserProfile.json`
- **Method**: POST
- **Controller**: `SiteController.updateUserProfile()`
- **Input Schema**: Updated user profile fields
- **Output Schema**: Updated user profile

### 97. manageUserRoles.json
- **URL**: `/{siteId}/$/manageUserRoles.json`
- **Method**: POST
- **Controller**: `SiteController.manageUserRoles()`
- **Input Schema**: Role assignments for user
- **Output Schema**: Updated role assignments

### 98. SiteMail.json
- **URL**: `/{siteId}/$/SiteMail.json`
- **Method**: POST
- **Controller**: `SiteController.SiteMail()`
- **Input Schema**: Email content and recipients
- **Output Schema**: Mail send confirmation

### 99. SitePeople.json
- **URL**: `/{siteId}/$/SitePeople.json`
- **Method**: GET
- **Controller**: `SiteController.SitePeople()`
- **Output Schema**: Array of site members

### 100. SiteStatistics.json
- **URL**: `/{siteId}/$/SiteStatistics.json`
- **Method**: GET
- **Controller**: `SiteController.SiteStatistics()`
- **Output Schema**: Site statistics

### 101. SiteUserMap.json (GET)
- **URL**: `/{siteId}/$/SiteUserMap.json`
- **Method**: GET
- **Controller**: `SiteController.SiteUserMap()`
- **Output Schema**: User mapping

### 102. SiteUserMap.json (POST)
- **URL**: `/{siteId}/$/SiteUserMap.json`
- **Method**: POST
- **Controller**: `SiteController.SiteUserMap()`
- **Input Schema**: User mapping updates
- **Output Schema**: Update confirmation

### 103. GarbageCollect.json
- **URL**: `/{siteId}/$/GarbageCollect.json`
- **Method**: GET
- **Controller**: `SiteController.GarbageCollect()`
- **Output Schema**: Garbage collection info

### 104. QuerySiteEmail.json
- **URL**: `/{siteId}/$/QuerySiteEmail.json`
- **Method**: POST
- **Controller**: `SiteController.QuerySiteEmail()`
- **Input Schema**: Email query parameters
- **Output Schema**: Email results

### 105. createWorkspace.json
- **URL**: `/{siteId}/$/createWorkspace.json`
- **Method**: POST
- **Controller**: `CreateProjectController.createWorkspace()`
- **Input Schema**:
```json
{
"name": "string",
"description": "string",
"// other workspace details"
}
```
- **Output Schema**: Created workspace record

---

## Super Admin APIs

### 106. takeOwnershipSite.json
- **URL**: `/su/takeOwnershipSite.json`
- **Method**: POST
- **Controller**: `SiteController.takeOwnershipSite()`
- **Input Schema**: Site ID
- **Output Schema**: Ownership transfer confirmation

### 107. garbageCollect.json
- **URL**: `/su/garbageCollect.json`
- **Method**: POST
- **Controller**: `SiteController.garbageCollect()`
- **Input Schema**: Optional garbage collection parameters
- **Output Schema**: Garbage collection results

### 108. updateCharge.json
- **URL**: `/su/updateCharge.json`
- **Method**: POST
- **Controller**: `SiteController.updateCharge()`
- **Input Schema**: Charge update details
- **Output Schema**: Updated charge

### 109. recordPayment.json
- **URL**: `/su/recordPayment.json`
- **Method**: POST
- **Controller**: `SiteController.recordPayment()`
- **Input Schema**: Payment details
- **Output Schema**: Payment recording confirmation

### 110. clearAllSiteCharges.json
- **URL**: `/su/clearAllSiteCharges.json`
- **Method**: POST
- **Controller**: `SiteController.clearAllSiteCharges()`
- **Input Schema**: Site ID or clearing parameters
- **Output Schema**: Charges cleared confirmation

### 111. acceptOrDenySite.json
- **URL**: `/su/acceptOrDenySite.json`
- **Method**: POST
- **Controller**: `SuperAdminController.acceptOrDenySite()`
- **Input Schema**:
```json
{
"siteId": "string",
"status": "string (accept | deny)"
}
```
- **Output Schema**: Action confirmation

### 112. testEmailSend.json
- **URL**: `/su/testEmailSend.json`
- **Method**: POST
- **Controller**: `SuperAdminController.testEmailSend()`
- **Input Schema**:
```json
{
"emailAddress": "string",
"// test parameters"
}
```
- **Output Schema**: Test email send confirmation

### 113. QuerySuperAdminEmail.json
- **URL**: `/su/QuerySuperAdminEmail.json`
- **Method**: POST
- **Controller**: `SuperAdminController.QuerySuperAdminEmail()`
- **Input Schema**: Email query parameters
- **Output Schema**: Email results

### 114. lookUpUser.json
- **URL**: `/su/lookUpUser.json`
- **Method**: POST
- **Controller**: `SuperAdminController.lookUpUser()`
- **Input Schema**: User search criteria
- **Output Schema**: Found user information

---

## Admin APIs

### 115. updateProjectInfo.json
- **URL**: `/{siteId}/{pageId}/updateProjectInfo.json`
- **Method**: POST
- **Controller**: `AdminController.updateProjectInfo()`
- **Input Schema**: Updated project information
- **Output Schema**: Updated project info

### 116. updateWorkspaceName.json
- **URL**: `/{siteId}/{pageId}/updateWorkspaceName.json`
- **Method**: POST
- **Controller**: `AdminController.updateWorkspaceName()`
- **Input Schema**:
```json
{
"name": "string"
}
```
- **Output Schema**: Name update confirmation

### 117. deleteWorkspaceName.json
- **URL**: `/{siteId}/{pageId}/deleteWorkspaceName.json`
- **Method**: POST
- **Controller**: `AdminController.deleteWorkspaceName()`
- **Input Schema**: Workspace deletion flag or confirmation
- **Output Schema**: Deletion confirmation

### 118. updateSiteInfo.json
- **URL**: `/{siteId}/$/updateSiteInfo.json`
- **Method**: POST
- **Controller**: `AdminController.updateSiteInfo()`
- **Input Schema**: Updated site information
- **Output Schema**: Updated site info

---

## Summary

**Total API Endpoints: 118**

### Distribution by Controller:
- **UserController**: 11 endpoints
- **ProjectSettingController**: 17 endpoints
- **TopicController**: 9 endpoints
- **CommentController**: 4 endpoints
- **ProjectGoalController**: 9 endpoints
- **MeetingControler**: 16 endpoints
- **ProjectDocsController**: 19 endpoints
- **MainTabsViewControler**: 6 endpoints
- **SiteController**: 18 endpoints
- **CreateProjectController**: 1 endpoint
- **SuperAdminController**: 4 endpoints
- **AdminController**: 4 endpoints

### Common Patterns:
1. All endpoints follow the `.json` naming convention
2. POST endpoints typically receive JSON via `getPostedObject(ar)`
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
- `/$/ `: Site-level endpoints (not workspace-specific)