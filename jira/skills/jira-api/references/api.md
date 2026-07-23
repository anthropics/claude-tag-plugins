# Jira Cloud REST API — Endpoint Reference

All requests go to `${JIRA_BASE}` — either the site (`https://your-domain.atlassian.net`) or, for
service-account tokens, the API gateway (`https://api.atlassian.com/ex/jira/<cloud-id>`) — with:

```
Authorization: ...              # injected by the runtime (Basic for site tokens, Bearer for gateway/service-account tokens)
Accept: application/json
Content-Type: application/json  # on any request with a body
```

Platform API is under `/rest/api/3/`; Agile API is under `/rest/agile/1.0/`. Official docs:
`https://developer.atlassian.com/cloud/jira/platform/rest/v3/` and
`https://developer.atlassian.com/cloud/jira/software/rest/`.

## Table of contents

- [Myself & users](#myself--users)
- [JQL search](#jql-search)
- [Issues](#issues)
- [Issue fields & ADF](#issue-fields--adf)
- [Comments](#comments)
- [Transitions & workflows](#transitions--workflows)
- [Attachments](#attachments)
- [Issue links & remote links](#issue-links--remote-links)
- [Worklogs](#worklogs)
- [Projects](#projects)
- [Versions & components](#versions--components)
- [Boards, sprints, epics (Agile)](#boards-sprints-epics-agile)
- [Filters & dashboards](#filters--dashboards)
- [Permissions & groups](#permissions--groups)
- [Webhooks](#webhooks)
- [JQL reference](#jql-reference)

---

## Myself & users

- **`GET /rest/api/3/myself`** — The authenticated user. Good sanity check.
- **`GET /rest/api/3/user`** — One user. Param: `accountId`.
- **`GET /rest/api/3/user/search`** — Params: `query` (matches name/email), `maxResults`.
- **`GET /rest/api/3/user/assignable/search`** — Users who can be assigned. Params: `query`, `project` or `issueKey`.
- **`GET /rest/api/3/user/assignable/multiProjectSearch`** — Params: `query`, `projectKeys`.
- **`GET /rest/api/3/user/picker`** — Typeahead for @-mentions. Param: `query`.
- **`GET /rest/api/3/users/search`** — All users (paged with `startAt`/`maxResults`).
- **`GET /rest/api/3/groupuserpicker`** — Users + groups. Param: `query`.

Users are identified by **`accountId`** everywhere. Jira Cloud hides emails unless the user has made
them public; don't rely on `emailAddress` being present.

## JQL search

- **`GET/POST /rest/api/3/search/jql`** — Enhanced JQL search, the only supported search. POST body: `{"jql","fields":[...],"maxResults","nextPageToken","expand","properties":[...],"fieldsByKeys","reconcileIssues":[...]}`. `expand` is a comma-delimited *string*, not an array. `fields` defaults to `id` only — always pass it. `jql` must be bounded (≥1 filter clause). `maxResults` default 50, up to 5000 when only `id`/`key` is requested. Response: `{issues, isLast, nextPageToken}` — pass `nextPageToken` back to continue; it's absent on the last page. No total count.
- **`GET/POST /rest/api/3/search`** — **Removed**, returns `410 Gone` (CHANGE-2046). Same for `/rest/api/3/search/id`. Migrate to `/search/jql`.
- **`POST /rest/api/3/search/approximate-count`** — Fast approximate count for a JQL. Body: `{"jql"}`. Response: `{"count"}`. Useful since `/search/jql` doesn't return a total.
- **`POST /rest/api/3/jql/parse`** — Validate + show parsed structure. Body: `{"queries":["..."]}`.
- **`GET /rest/api/3/jql/autocompletedata`** — JQL fields, functions, and reserved words for autocomplete.
- **`GET /rest/api/3/jql/autocompletedata/suggestions`** — Field value suggestions. Params: `fieldName`, `fieldValue`.

`fields` in the search body controls what's returned. Use `"*all"` (slow), `"*navigable"`, or an
explicit list. `expand` can include `changelog`,
`renderedFields`, `names`, `schema`, `transitions`, `editmeta`.

## Issues

- **`GET /rest/api/3/issue/{keyOrId}`** — One issue. Params: `fields`, `expand`, `properties`.
- **`POST /rest/api/3/issue`** — Create. Body: `{"fields":{"project":{"key"},"issuetype":{"name"|"id"},"summary","description":<ADF>,"priority":{"name"},"labels":[],"assignee":{"accountId"},"components":[{"name"}],"fixVersions":[{"name"}],"parent":{"key"},"customfield_NNNNN":...}}`. Returns `{key,id,self}`.
- **`PUT /rest/api/3/issue/{keyOrId}`** — Update. Body: `{"fields":{...}}` (set) and/or `{"update":{"labels":[{"add":"x"},{"remove":"y"}]}}` (operations). `204` on success.
- **`DELETE /rest/api/3/issue/{keyOrId}`** — Delete. Param: `deleteSubtasks=true` if it has subtasks.
- **`POST /rest/api/3/issue/bulk`** — Bulk create. Body: `{"issueUpdates":[{"fields":{...}}, ...]}`. Up to 50.
- **`PUT /rest/api/3/issue/{keyOrId}/assignee`** — Assign. Body: `{"accountId":"..."}` or `{"accountId":null}` (unassign) or `{"accountId":"-1"}` (auto).
- **`GET/POST/DELETE /rest/api/3/issue/{keyOrId}/watchers`** — Watchers. POST body is a bare JSON string: `"accountId"`. DELETE has no body — pass `?accountId=...` as a query param.
- **`GET/POST/DELETE /rest/api/3/issue/{keyOrId}/votes`** — Vote on / unvote.
- **`GET /rest/api/3/issue/{keyOrId}/changelog`** — History (paged). Alternative to `expand=changelog`.
- **`GET /rest/api/3/issue/{keyOrId}/editmeta`** — Fields editable on this issue (respects screen config).
- **`GET /rest/api/3/issue/createmeta/{projectKey}/issuetypes`** — Issue types available in a project. Paginated; array under `.issueTypes`.
- **`GET /rest/api/3/issue/createmeta/{projectKey}/issuetypes/{typeId}`** — Required/available fields for that type, read this before create. Paginated; array under `.fields`. Each entry: `{key, name, required, schema, allowedValues}`.
- **`GET /rest/api/3/issue/{keyOrId}/properties`** — List entity properties (arbitrary JSON attached to the issue).
- **`GET/PUT/DELETE /rest/api/3/issue/{keyOrId}/properties/{key}`** — One property.
- **`PUT /rest/api/3/issue/archive`** — Archive issues. Body: `{"issueIdsOrKeys":["PROJ-1"]}`. Premium feature.

## Issue fields & ADF

- **`GET /rest/api/3/field`** — All fields (system + custom) with `id`, `key`, `name`, `schema`. Custom fields are `customfield_NNNNN`.
- **`GET /rest/api/3/field/search`** — Search fields. Params: `query`, `type` (`custom`/`system`), `orderBy`.
- **`GET /rest/api/3/field/{fieldId}/context`** — Field contexts (which projects/issue types a custom field applies to).
- **`GET /rest/api/3/field/{fieldId}/context/{contextId}/option`** — Options for a select-list custom field (per context — get the `contextId` from the call above).
- **`GET /rest/api/3/issuetype`** — All issue types.
- **`GET /rest/api/3/priority/search`** — Priorities (paged; list-all endpoint is deprecated).
- **`GET /rest/api/3/resolution/search`** — Resolutions (paged; list-all endpoint is deprecated).
- **`GET /rest/api/3/status`** — All statuses. `/rest/api/3/status/{idOrName}` for one.
- **`GET /rest/api/3/statuscategory`** — `To Do` / `In Progress` / `Done` rollups.
- **`GET /rest/api/3/label`** — All labels (paged).

**Atlassian Document Format (ADF).** `description` and comment bodies are ADF, a JSON tree:

```json
{"type": "doc", "version": 1, "content": [
  {"type": "paragraph", "content": [
    {"type": "text", "text": "Plain text "},
    {"type": "text", "text": "bold", "marks": [{"type": "strong"}]},
    {"type": "text", "text": ", see "},
    {"type": "text", "text": "PROJ-99", "marks": [{"type": "link", "attrs": {"href": "https://..."}}]}
  ]},
  {"type": "bulletList", "content": [
    {"type": "listItem", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "item"}]}]}
  ]},
  {"type": "codeBlock", "attrs": {"language": "python"}, "content": [{"type": "text", "text": "print(1)"}]}
]}
```

Common block nodes: `paragraph`, `heading` (attrs `{level:1..6}`), `bulletList`, `orderedList`,
`listItem`, `codeBlock`, `blockquote`, `rule`, `table`/`tableRow`/`tableCell`, `mediaSingle`,
`panel` (attrs `{panelType:"info"|"note"|"warning"|"error"|"success"}`). Inline marks: `strong`,
`em`, `code`, `strike`, `underline`, `link`, `textColor`. Mention a user with
`{"type":"mention","attrs":{"id":"<accountId>"}}`.

To read ADF as something human-legible, request `expand=renderedFields` to get HTML, or walk the
tree and concatenate `text` nodes.

## Comments

- **`GET /rest/api/3/issue/{keyOrId}/comment`** — List (paged, under `.comments`). Params: `orderBy` (`created`/`-created`), `expand=renderedBody`.
- **`POST /rest/api/3/issue/{keyOrId}/comment`** — Add. Body: `{"body":<ADF>, "visibility":{"type":"role","value":"Developers"}}`.
- **`GET/PUT/DELETE /rest/api/3/issue/{keyOrId}/comment/{id}`** — One comment.
- **`POST /rest/api/3/comment/list`** — Bulk-fetch by IDs. Body: `{"ids":[...]}`.

## Transitions & workflows

- **`GET /rest/api/3/issue/{keyOrId}/transitions`** — Valid transitions **from the current status**. Param: `expand=transitions.fields` to see which fields each transition requires.
- **`POST /rest/api/3/issue/{keyOrId}/transitions`** — Perform. Body: `{"transition":{"id":"31"},"fields":{"resolution":{"name":"Done"}},"update":{"comment":[{"add":{"body":<ADF>}}]}}`. `204` on success.
- **`GET /rest/api/3/workflows/search`** — Workflow definitions.
- **`GET /rest/api/3/workflowscheme/project`** — Which scheme a project uses. Param: `projectId`.

## Attachments

- **`POST /rest/api/3/issue/{keyOrId}/attachments`** — Upload. `Content-Type: multipart/form-data`, field name `file`, header `X-Atlassian-Token: no-check` (required — disables XSRF check). `curl -F "file=@path.png" -H "X-Atlassian-Token: no-check"`.
- **`GET/DELETE /rest/api/3/attachment/{id}`** — Metadata / delete.
- **`GET /rest/api/3/attachment/content/{id}`** — Download the raw bytes (303 redirect — use `-L`).
- **`GET /rest/api/3/attachment/thumbnail/{id}`** — Thumbnail (images only).
- **`GET /rest/api/3/attachment/meta`** — Global attachment settings (max size, enabled).

## Issue links & remote links

- **`GET /rest/api/3/issueLinkType`** — Available link types (`Blocks`, `Cloners`, `Duplicate`, `Relates`, custom).
- **`POST /rest/api/3/issueLink`** — Create. Body: `{"type":{"name":"Blocks"},"inwardIssue":{"key"},"outwardIssue":{"key"},"comment":{"body":<ADF>}}`.
- **`GET/DELETE /rest/api/3/issueLink/{id}`** — One link.
- **`GET/POST /rest/api/3/issue/{keyOrId}/remotelink`** — External web links. POST body: `{"object":{"url","title","summary","icon":{"url16x16"}}}`.
- **`GET/PUT/DELETE /rest/api/3/issue/{keyOrId}/remotelink/{id}`** — One remote link.

## Worklogs

- **`GET/POST /rest/api/3/issue/{keyOrId}/worklog`** — List / log time. POST body: `{"timeSpent":"3h 30m","started":"2025-06-01T10:00:00.000+0000","comment":<ADF>}`. Or `timeSpentSeconds`.
- **`GET/PUT/DELETE /rest/api/3/issue/{keyOrId}/worklog/{id}`** — One worklog.
- **`GET /rest/api/3/worklog/updated`** — IDs of worklogs changed since a timestamp, for incremental sync.

## Projects

- **`GET /rest/api/3/project/search`** — Paged project list. Params: `query`, `typeKey`, `categoryId`, `orderBy`, `expand`, `status` (`live`/`archived`/`deleted`). Returns `{values,startAt,maxResults,total,isLast}`.
- **`GET /rest/api/3/project/{keyOrId}`** — One project. Param: `expand=description,lead,issueTypes,url,projectKeys,permissions,insight`.
- **`POST /rest/api/3/project`** — Create. Body: `{"key","name","projectTypeKey":"software"|"business"|"service_desk","projectTemplateKey","leadAccountId","description"}`.
- **`PUT/DELETE /rest/api/3/project/{keyOrId}`** — Update / delete.
- **`GET /rest/api/3/project/{keyOrId}/statuses`** — Statuses per issue type for this project.
- **`GET /rest/api/3/project/{keyOrId}/role`** — Roles; each maps to a URL for members.
- **`GET /rest/api/3/project/{keyOrId}/properties`** — Entity properties.
- **`GET /rest/api/3/project/type`** — Project type keys and descriptions.

## Versions & components

- **`GET /rest/api/3/project/{keyOrId}/versions`** — All versions (unpaged — small lists).
- **`GET /rest/api/3/project/{keyOrId}/version`** — Paged version list.
- **`POST /rest/api/3/version`** — Create. Body: `{"projectId","name","description","startDate","releaseDate","released":false,"archived":false}`.
- **`GET/PUT /rest/api/3/version/{id}`** — One version (DELETE is deprecated).
- **`POST /rest/api/3/version/{id}/removeAndSwap`** — Delete a version (replaces deprecated DELETE).
- **`GET /rest/api/3/version/{id}/relatedIssueCounts`** — Counts by `fixVersion`/`affectedVersion`.
- **`GET /rest/api/3/project/{keyOrId}/components`** — All components.
- **`POST /rest/api/3/component`** — Create. Body: `{"project","name","description","leadAccountId","assigneeType"}`.
- **`GET/PUT/DELETE /rest/api/3/component/{id}`** — One component.

## Boards, sprints, epics (Agile)

All under `/rest/agile/1.0/`. Pagination: `startAt`/`maxResults`, results under `.values` (or
`.issues` for issue lists).

The `GET` issue-list endpoints below (board/backlog/sprint/epic `.../issue`) are deprecated — use
the token-paginated `/rest/software/1.0/` enhanced equivalents instead.

- **`GET /rest/agile/1.0/board`** — Boards. Params: `projectKeyOrId`, `type` (`scrum`/`kanban`/`simple`), `name`.
- **`GET /rest/agile/1.0/board/{id}`** — One board.
- **`GET /rest/agile/1.0/board/{id}/configuration`** — Column mapping, estimation field, swimlanes, filter.
- **`GET /rest/agile/1.0/board/{id}/issue`** — Issues on a board. Params: `jql` (combined with board filter), `fields`, `startAt`.
- **`GET /rest/agile/1.0/board/{id}/backlog`** — Backlog issues (not in a sprint).
- **`GET /rest/agile/1.0/board/{id}/sprint`** — Sprints. Param: `state` (`active`/`future`/`closed`).
- **`GET /rest/agile/1.0/board/{id}/epic`** — Epics. Param: `done`.
- **`GET/PUT/DELETE /rest/agile/1.0/sprint/{id}`** — One sprint. PUT body: `{"state":"active"|"closed","name","startDate","endDate","goal"}`.
- **`POST /rest/agile/1.0/sprint`** — Create. Body: `{"originBoardId","name","startDate","endDate","goal"}`.
- **`GET /rest/agile/1.0/sprint/{id}/issue`** — Issues in a sprint. Params: `jql`, `fields`.
- **`POST /rest/agile/1.0/sprint/{id}/issue`** — Move issues into a sprint. Body: `{"issues":["PROJ-1","PROJ-2"]}`. Max 50.
- **`POST /rest/agile/1.0/backlog/issue`** — Move issues to backlog. Body: `{"issues":[...]}`.
- **`GET /rest/agile/1.0/epic/{idOrKey}`** — One epic.
- **`GET/POST /rest/agile/1.0/epic/{idOrKey}/issue`** — Issues in an epic / move issues into it.
- **`GET/POST /rest/agile/1.0/epic/none/issue`** — Issues without an epic / remove issues from epics.
- **`GET/PUT /rest/agile/1.0/issue/{idOrKey}/estimation`** — Story points. Param: `boardId`. PUT body: `{"value":"5"}`.
- **`PUT /rest/agile/1.0/issue/rank`** — Re-rank. Body: `{"issues":["PROJ-2"],"rankBeforeIssue":"PROJ-1"}`.

## Filters & dashboards

- **`GET /rest/api/3/filter/search`** — Saved filters. Params: `filterName`, `accountId`, `projectId`, `orderBy`.
- **`GET /rest/api/3/filter/{id}`** — One filter (includes `jql`).
- **`POST /rest/api/3/filter`** — Create. Body: `{"name","jql","description","favourite"}`.
- **`GET /rest/api/3/filter/favourite`** — Your favourites.
- **`GET /rest/api/3/dashboard`** — Dashboards. Param: `filter` (`my`/`favourite`).
- **`GET /rest/api/3/dashboard/{id}`** — One dashboard.

## Permissions & groups

- **`GET /rest/api/3/mypermissions`** — Your permissions. Params: `permissions` (comma-sep, required), `projectKey`/`issueKey`.
- **`GET /rest/api/3/permissions`** — All permission keys.
- **`POST /rest/api/3/permissions/check`** — Bulk check. Body: `{"projectPermissions":[{"permissions":["EDIT_ISSUES"],"issues":[10001]}]}`.
- **`GET /rest/api/3/group/member`** — Members of a group. Param: `groupname` or `groupId`.
- **`GET /rest/api/3/groups/picker`** — Group search. Param: `query`.

## Webhooks

- **`GET/POST/DELETE /rest/api/3/webhook`** — Dynamic webhooks (registered by OAuth2/Connect apps; not available to Basic-auth API tokens — use site admin UI for those).
- **`PUT /rest/api/3/webhook/refresh`** — Extend expiry (webhooks auto-expire after 30 days).
- **`GET /rest/api/3/webhook/failed`** — Recent failed deliveries.

## JQL reference

Clauses: `project`, `issuetype`, `status`, `statusCategory`, `priority`, `resolution`, `assignee`,
`reporter`, `creator`, `labels`, `component`, `fixVersion`, `affectedVersion`, `sprint`, `epic` (or
`"Epic Link"`), `parent`, `summary`, `description`, `comment`, `text` (full-text), `created`,
`updated`, `resolved`, `due`, `lastViewed`, `key`, `id`, `watchers`, `votes`, `cf[NNNNN]` or
`"Custom Field Name"`.

Operators: `=`, `!=`, `>`, `>=`, `<`, `<=`, `IN`, `NOT IN`, `~` (contains), `!~`, `IS EMPTY` /
`IS NOT EMPTY`, `WAS`, `WAS IN`, `WAS NOT IN`, `CHANGED`.

Functions: `currentUser()`, `membersOf("group")`, `now()`, `startOfDay()`, `endOfDay()`,
`startOfWeek()`, `startOfMonth()`, `startOfYear()`, `openSprints()`, `closedSprints()`,
`futureSprints()`, `linkedIssues("PROJ-1")`, `issueHistory()`, `watchedIssues()`, `votedIssues()`,
`currentLogin()`, `lastLogin()`, `latestReleasedVersion("PROJ")`, `unreleasedVersions()`,
`earliestUnreleasedVersion("PROJ")`, `parentEpic("PROJ-1")`.

Date math: `-1d`, `-1w`, `-4h`, `2025-06-01`, `"2025/06/01 14:30"`.

`ORDER BY <field> [ASC|DESC], <field> ...`. Logical: `AND`, `OR`, `NOT`, parentheses.

---

## Cross-cutting notes

**Issue keys vs IDs.** Most endpoints accept either `PROJ-123` (key) or the numeric `id`. Keys can
change if an issue is moved between projects; the numeric `id` is stable.

**Custom fields.** All custom fields appear as `customfield_NNNNN`. Get the mapping via
`/rest/api/3/field`. The `id` is stable; the display name isn't.

**Cloud vs Server.** Server/Data Center uses `/rest/api/2/`, username+password or PAT auth,
plain-text `description`/comments (wiki markup, not ADF), and `name` instead of `accountId` for
users. (On Cloud, `Authorization: Bearer` is also how service-account tokens authenticate — via the
`api.atlassian.com` gateway — so Bearer alone doesn't indicate Server/DC.) This doc targets Cloud.
