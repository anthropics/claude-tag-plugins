# Confluence Cloud REST API — Endpoint Reference

All requests go to `${CONFLUENCE_BASE}` — the site's `/wiki` root
(`https://your-domain.atlassian.net/wiki`) or, for service-account tokens, the API gateway's
(`https://api.atlassian.com/ex/confluence/<cloud-id>/wiki`) — with:

```
Authorization: ...              # injected by the runtime (Basic for site tokens, Bearer for gateway/service-account tokens)
Accept: application/json
Content-Type: application/json  # on any request with a body
```

v2 API is under `/api/v2/`; v1 (legacy + CQL search) is under `/rest/api/`. Official docs:
`https://developer.atlassian.com/cloud/confluence/rest/v2/` and
`https://developer.atlassian.com/cloud/confluence/rest/v1/`.

## Table of contents

- [Pages](#pages)
- [Body formats](#body-formats)
- [Spaces](#spaces)
- [Blog posts](#blog-posts)
- [Comments](#comments)
- [Attachments](#attachments)
- [Labels](#labels)
- [Versions](#versions)
- [Content properties](#content-properties)
- [Whiteboards, databases, custom content](#whiteboards-databases-custom-content)
- [Search (CQL — v1)](#search-cql--v1)
- [CQL reference](#cql-reference)
- [Content conversion (v1)](#content-conversion-v1)
- [Storage format macros](#storage-format-macros)
- [Users & groups](#users--groups)
- [Space permissions & settings](#space-permissions--settings)

---

## Pages

- **`GET /api/v2/pages`** — List all pages. Params: `id` (comma-sep), `space-id`, `status` (`current`/`archived`/`deleted`/`trashed`), `title`, `body-format`, `sort` (`id`/`created-date`/`modified-date`/`title`, prefix `-` for desc), `cursor`, `limit` (max 250).
- **`GET /api/v2/pages/{id}`** — One page. Params: `body-format`, `get-draft` (bool), `version` (number — fetch a historical version), `include-labels`, `include-properties`, `include-operations`, `include-likes`, `include-versions`, `include-version`, `include-favorited-by-current-user-status`.
- **`POST /api/v2/pages`** — Create. Body: `{"spaceId","status":"current"|"draft","title","parentId","body":{"representation","value"}}`. `spaceId` and `parentId` are numeric strings. Title unique per space.
- **`PUT /api/v2/pages/{id}`** — Update. Body: `{"id","status","title","spaceId","parentId","body":{...},"version":{"number":<current+1>,"message"}}`. Increment version or get `409`.
- **`DELETE /api/v2/pages/{id}`** — Move to trash (soft delete). Params: `purge` (bool — permanent, requires admin), `draft` (bool — delete a draft).
- **`GET /api/v2/pages/{id}/children`** — **Deprecated**, use `/direct-children`. Child pages only. Params: `cursor`, `limit`, `sort`.
- **`GET /api/v2/pages/{id}/descendants`** — All descendants. Params: `depth` (1–10, default 2), `limit`, `cursor`.
- **`GET /api/v2/pages/{id}/ancestors`** — Ancestor chain from root to parent (excludes the page itself).
- **`GET /api/v2/pages/{id}/direct-children`** — Direct children of any type — pages, whiteboards, databases, folders, etc. Params: `cursor`, `limit`, `sort`.
- **`GET /api/v2/pages/{id}/operations`** — Permitted operations for the current user (`read`, `update`, `delete`, `create`, …).
- **`GET /api/v2/pages/{id}/likes/count`** — Like count.
- **`GET /api/v2/pages/{id}/likes/users`** — Who liked it.
- **`GET /api/v2/spaces/{spaceId}/pages`** — Pages in a space. Params: `depth` (`all`/`root`), `sort`, `status`, `title`, `body-format`, `limit`, `cursor`.

## Body formats

Request with `?body-format=X` on GETs; set `body.representation` on writes.

- **`storage`** (R+W) — String of XHTML with `<ac:...>` macros (see [Storage format macros](#storage-format-macros)).
- **`atlas_doc_format`** (R+W) — **A JSON string** containing an ADF document — parse it again: `jq '.body.atlas_doc_format.value | fromjson'`. On write, the value must be a JSON-encoded string, not a nested object.
- **`view`** (R) — Rendered HTML, macros expanded. Relative URLs. Best for reading.
- **`export_view`** (R) — Like `view` but absolute URLs.
- **`anonymous_export_view`** (R) — Export view as seen by an anonymous user.
- **`styled_view`** (R) — View with inline styles.
- **`editor`** (R) — Internal editor format. Avoid.
- **`wiki`** (W) — Legacy wiki markup. Deprecated.

ADF (`atlas_doc_format`) uses the same node types as Jira descriptions — `doc`, `paragraph`,
`heading`, `bulletList`, `codeBlock`, `table`, `panel`, etc. — so content can round-trip between the
two products.

## Spaces

- **`GET /api/v2/spaces`** — List. Params: `ids`, `keys` (comma-sep), `type` (`global`/`personal`), `status` (`current`/`archived`), `labels`, `favorited-by`, `not-favorited-by`, `sort`, `description-format`, `include-icon`, `cursor`, `limit`.
- **`GET /api/v2/spaces/{id}`** — One space. Params: `description-format`, `include-icon`, `include-operations`, `include-properties`, `include-permissions`, `include-role-assignments`, `include-labels`.
- **`POST /api/v2/spaces`** — Create. Body: `{"name","key","alias","description":{"representation":"plain"|"view","value"},"roleAssignments":[...]}`.
- **`GET /api/v2/spaces/{id}/pages`** — Pages in a space.
- **`GET /api/v2/spaces/{id}/blogposts`** — Blog posts in a space.
- **`GET /api/v2/spaces/{id}/labels`** — Space labels.
- **`GET /api/v2/spaces/{id}/content/labels`** — Labels used on content in the space.
- **`GET/POST /api/v2/spaces/{id}/properties`** — Space properties (arbitrary JSON).
- **`GET /api/v2/spaces/{id}/operations`** — Permitted operations.
- **`GET /api/v2/spaces/{id}/permissions`** — Space permission grants.
- **`GET /api/v2/space-roles`** — Available space roles.

Space IDs are numeric in v2 (not the string key). Look the ID up from the key via `?keys=ENG`.

## Blog posts

Same shape as pages — swap the resource name.

- **`GET /api/v2/blogposts`** — List. Params as pages.
- **`GET /api/v2/blogposts/{id}`** — One post.
- **`POST /api/v2/blogposts`** — Create. Body: `{"spaceId","status","title","body":{...}}`. No `parentId`.
- **`PUT/DELETE /api/v2/blogposts/{id}`** — Update / delete. Same version rules as pages.
- **`GET /api/v2/blogposts/{id}/footer-comments`** — Comments.
- **`GET /api/v2/blogposts/{id}/attachments`** — Attachments.
- **`GET /api/v2/blogposts/{id}/labels`** — Labels.
- **`GET /api/v2/blogposts/{id}/likes/count`** — Likes.

## Comments

Two types: **footer** (page-level thread at the bottom) and **inline** (anchored to highlighted text
— created from the editor; the API can read and reply but can't anchor a new selection).

- **`GET /api/v2/footer-comments`** — All footer comments you can see. Params: `body-format`, `sort`, `cursor`, `limit`.
- **`POST /api/v2/footer-comments`** — Create. Body: `{"pageId"|"blogPostId"|"parentCommentId"|"attachmentId"|"customContentId","body":{...}}`. Exactly one parent field.
- **`GET/PUT/DELETE /api/v2/footer-comments/{id}`** — One comment. PUT body: `{"version":{"number":<current+1>},"body":{...}}`.
- **`GET /api/v2/footer-comments/{id}/children`** — Replies in the thread.
- **`GET /api/v2/footer-comments/{id}/operations`** — Permitted operations.
- **`GET /api/v2/footer-comments/{id}/likes/count`** — Likes.
- **`GET/POST /api/v2/inline-comments`** — Inline comments. POST body includes `inlineCommentProperties: {"textSelection","textSelectionMatchCount","textSelectionMatchIndex"}`.
- **`GET/PUT/DELETE /api/v2/inline-comments/{id}`** — One inline comment.
- **`GET /api/v2/inline-comments/{id}/children`** — Inline thread replies.
- **`GET /api/v2/pages/{id}/footer-comments`** — Footer comments on a page.
- **`GET /api/v2/pages/{id}/inline-comments`** — Inline comments on a page. Param: `resolution-status` (`open`/`resolved`/`dangling`).

## Attachments

- **`GET /api/v2/attachments`** — All attachments you can see. Params: `sort`, `cursor`, `status`, `mediaType`, `filename`, `limit`.
- **`GET /api/v2/attachments/{id}`** — Metadata. Returns `downloadLink` / `_links.download` (relative to the `/wiki` root — prepend `${CONFLUENCE_BASE}`). Those ad-hoc `/download/attachments/...` URLs are deprecated; prefer the v1 `.../download` endpoint below.
- **`DELETE /api/v2/attachments/{id}`** — Move to trash. Param: `purge`.
- **`GET /api/v2/attachments/{id}/thumbnail/download`** — Thumbnail bytes.
- **`GET /api/v2/pages/{id}/attachments`** — Attachments on a page.
- **`GET /api/v2/blogposts/{id}/attachments`** — Attachments on a blog post.
- **`GET /api/v2/attachments/{id}/versions`** — Version history.
- **`GET /api/v2/attachments/{id}/operations`** — Permitted operations.
- **`POST /rest/api/content/{id}/child/attachment`** (v1) — **Upload.** `Content-Type: multipart/form-data`, field `file`, optional `comment` and `minorEdit`. Header `X-Atlassian-Token: nocheck` required. Same filename → new version.
- **`GET /rest/api/content/{id}/child/attachment/{attId}/download`** (v1) — **Download** raw bytes. 302 redirect — use `-L`.

## Labels

- **`GET /api/v2/labels`** — All labels. Params: `prefix` (`global`/`my`/`team`), `label-id`, `sort`, `cursor`, `limit`.
- **`GET /api/v2/labels/{id}/pages`** — Pages carrying a label (by numeric label ID). Params: `space-id`, `body-format`, `sort`, `cursor`, `limit`.
- **`GET /api/v2/labels/{id}/blogposts`** — Blog posts carrying a label.
- **`GET /api/v2/labels/{id}/attachments`** — Attachments carrying a label.
- **`GET /api/v2/pages/{id}/labels`** — Labels on a page.
- **`GET /api/v2/blogposts/{id}/labels`** — Labels on a blog post.
- **`GET /api/v2/spaces/{id}/labels`** — Labels on a space.
- **`GET /api/v2/attachments/{id}/labels`** — Labels on an attachment.
- **`POST /rest/api/content/{id}/label`** (v1) — **Add labels.** Body: `[{"prefix":"global","name":"howto"}]`. No v2 write yet.
- **`DELETE /rest/api/content/{id}/label`** (v1) — Remove. Param: `name`.

## Versions

- **`GET /api/v2/pages/{id}/versions`** — Version history. Params: `body-format`, `cursor`, `limit`, `sort` (`-modified-date` for newest first).
- **`GET /api/v2/pages/{id}/versions/{versionNumber}`** — One historical version, including body.
- **`GET /api/v2/blogposts/{id}/versions`** — Blog post versions.
- **`GET /api/v2/footer-comments/{id}/versions`** — Comment versions.
- **`GET /api/v2/attachments/{id}/versions`** — Attachment versions.

There is no diff endpoint — to compare versions, fetch both and diff the bodies client-side.

## Content properties

Arbitrary JSON attached to pages, blog posts, comments, attachments, spaces.

- **`GET/POST /api/v2/pages/{id}/properties`** — List / create. POST body: `{"key","value":<any JSON>}`.
- **`GET/PUT/DELETE /api/v2/pages/{id}/properties/{propId}`** — One property. PUT requires `version.number`.
- Same pattern under `/blogposts/`, `/comments/` (covers both footer and inline), `/attachments/`, `/spaces/`, `/custom-content/`, `/whiteboards/`, `/databases/`.

## Whiteboards, databases, custom content

- **`POST /api/v2/whiteboards`** — Create. Body: `{"spaceId","title","parentId"}`.
- **`GET/DELETE /api/v2/whiteboards/{id}`** — Fetch / delete. No body-format — whiteboard content isn't readable via REST.
- **`GET /api/v2/whiteboards/{id}/direct-children`** / `/descendants` / `/ancestors` / `/operations` — Tree / permissions.
- **`POST /api/v2/databases`** — Create a Confluence database. Body: `{"spaceId","title","parentId"}`.
- **`GET/DELETE /api/v2/databases/{id}`** — Fetch / delete.
- **`GET/POST /api/v2/custom-content`** — Custom content types (app-defined). Params: `type` (required), `space-id`. Per-page filtering: `GET /api/v2/pages/{id}/custom-content`.
- **`GET/PUT/DELETE /api/v2/custom-content/{id}`** — One custom content item.
- **`POST /api/v2/embeds`** — Create a Smart Link (embed) in the content tree. Body: `{"spaceId","title","parentId","embedUrl"}`.
- **`POST /api/v2/folders`** — Create a folder.
- **`GET/DELETE /api/v2/folders/{id}`** — Fetch / delete.

## Search (CQL — v1)

v2 has no search endpoint. Use v1.

- **`GET /rest/api/content/search`** — Search **content** (pages, blog posts, attachments, comments). Params: `cql` (required), `cqlcontext` (JSON: `{"spaceKey","contentId","contentStatuses"}`), `expand`, `cursor`, `limit`. Paginate by following `_links.next`.
- **`GET /rest/api/search`** — Search **everything** (content + spaces + users). Params: `cql`, `limit`, `start`, `includeArchivedSpaces`, `excerpt` (`highlight`/`indexed`/`none`). Returns typed results under `.results[].content` / `.results[].space` / `.results[].user`.
- **`GET /rest/api/search/user`** — Search users. Params: `cql` (e.g. `user.fullname ~ "jane"`), `limit`, `start`.

Useful `expand` values on `/content/search`: `space`, `version`, `body.view`, `body.storage`,
`history`, `metadata.labels`, `ancestors`, `children.page`.

## CQL reference

Fields: `type` (`page`/`blogpost`/`comment`/`attachment`/`space`/`user`), `id`, `title`, `text`
(full-text), `space`, `space.key`, `space.title`, `space.type`, `label`, `creator`, `contributor`,
`mention`, `watcher`, `favourite`, `parent`, `ancestor`, `container`, `created`, `lastmodified`,
`content` (on attachments/comments — the containing content's ID), `macro` (pages using a macro).

Operators: `=`, `!=`, `~` (contains / fuzzy), `!~`, `>`, `>=`, `<`, `<=`, `IN`, `NOT IN`. Logical:
`AND`, `OR`, `NOT`, parentheses. `ORDER BY <field> [ASC|DESC]`.

Functions: `currentUser()`, `now()`, `now("-7d")`, `startOfDay()`, `startOfWeek()`,
`startOfMonth()`, `startOfYear()`, `endOfDay()` etc., `currentContent()`, `currentSpace()`,
`favouriteSpaces()`, `recentlyViewedContent(limit, offset)`, `recentlyViewedSpaces(limit)`.

Examples:
- `type = page AND space = ENG AND label = "howto"`
- `type = page AND title ~ "onboard*" ORDER BY lastmodified DESC`
- `contributor = currentUser() AND lastmodified >= now("-30d")`
- `ancestor = 12345` — all descendants of a page
- `type = attachment AND container = 12345` — attachments on a page

## Content conversion (v1)

- **`POST /rest/api/contentbody/convert/async/{to}`** — Convert between body formats. Supported conversions: `atlas_doc_format` → `editor`/`export_view`/`storage`/`styled_view`/`view`; `storage` → `atlas_doc_format`/`editor`/`export_view`/`styled_view`/`view`; `editor` → `storage`. Body: `{"representation":"atlas_doc_format"|"storage"|"editor","value":"..."}`. Returns `{"asyncId":"..."}`. The synchronous `/contentbody/convert/{to}` was removed in April 2025 — only the async form remains.
- **`GET /rest/api/contentbody/convert/async/{id}`** — Poll the conversion. `status` ∈ `WORKING`/`QUEUED`/`RERUNNING`/`COMPLETED`/`FAILED`; the converted body is in `value` when `COMPLETED`. Bound the poll loop and stop on `FAILED` (the `error` field says why). Results are cached ~5 minutes.

## Storage format macros

Confluence storage format is XHTML with `ac:` / `ri:` namespaced elements for macros and resource
links. Common patterns for writing:

```xml
<!-- Headings, text, lists are plain HTML -->
<h2>Section</h2><p>Text with <strong>bold</strong> and <em>italic</em>.</p>
<ul><li>one</li><li>two</li></ul>

<!-- Link to another Confluence page -->
<ac:link><ri:page ri:content-title="Other Page" ri:space-key="ENG"/></ac:link>

<!-- Link to an attachment -->
<ac:link><ri:attachment ri:filename="diagram.png"/></ac:link>

<!-- Inline image from an attachment -->
<ac:image ac:width="600"><ri:attachment ri:filename="diagram.png"/></ac:image>

<!-- Info / warning / note panel -->
<ac:structured-macro ac:name="info"><ac:rich-text-body><p>Heads up.</p></ac:rich-text-body></ac:structured-macro>

<!-- Code block -->
<ac:structured-macro ac:name="code">
  <ac:parameter ac:name="language">python</ac:parameter>
  <ac:plain-text-body><![CDATA[print("hi")]]></ac:plain-text-body>
</ac:structured-macro>

<!-- Table of contents -->
<ac:structured-macro ac:name="toc"/>

<!-- Expand / collapse -->
<ac:structured-macro ac:name="expand">
  <ac:parameter ac:name="title">Details</ac:parameter>
  <ac:rich-text-body><p>Hidden content.</p></ac:rich-text-body>
</ac:structured-macro>

<!-- Mention a user -->
<ac:link><ri:user ri:account-id="ACCOUNT_ID"/></ac:link>

<!-- Task list -->
<ac:task-list><ac:task><ac:task-status>incomplete</ac:task-status><ac:task-body>Do the thing</ac:task-body></ac:task></ac:task-list>
```

## Users & groups

- **`GET /rest/api/user/current`** (v1) — The authenticated user. Sanity check.
- **`GET /rest/api/user`** (v1) — One user. Param: `accountId`.
- **`GET /rest/api/user/bulk`** (v1) — Multiple users. Param: `accountId` (comma-sep).
- **`GET /rest/api/user/memberof`** (v1) — Groups a user belongs to. Param: `accountId`.
- **`GET /rest/api/group`** (v1) — List groups.
- **`GET /rest/api/group/{groupId}/membersByGroupId`** (v1) — Group members.
- **`GET /rest/api/search/user`** (v1) — Search. Param: `cql` (e.g. `user.fullname ~ "jane"`).

v2 has no user endpoints yet — use v1.

## Space permissions & settings

- **`GET /api/v2/spaces/{id}/permissions`** — Permission grants. Each result: `{principal:{type,id},operation:{key,targetType}}`.
- **`POST /rest/api/space/{key}/permission`** (v1) — Grant. Body: `{"subject":{"type":"user"|"group","identifier"},"operation":{"key":"read"|"create"|...,"target":"space"|"page"|"blogpost"}}`. Revoke with DELETE `/rest/api/space/{key}/permission/{id}`.
- **`GET/PUT /rest/api/space/{key}/settings`** (v1) — Space settings (`routeOverrideEnabled`, etc.).
- **`GET/PUT/DELETE /rest/api/space/{key}/theme`** (v1) — Space theme.
- **`GET/PUT /rest/api/content/{id}/restriction`** (v1) — Page-level view/edit restrictions.

---

## Cross-cutting notes

**`/wiki` prefix.** The Confluence API is under `/wiki`, not the site root. A missing `/wiki` gives
404s on every call. Jira on the same site is at the root (`/rest/api/3/...` with no `/wiki`).

**v2 uses numeric IDs.** Space IDs, page IDs, comment IDs are numeric strings. v1 used string space
keys (`ENG`) — v2 needs the numeric ID (look it up via `?keys=ENG`). v2 body fields (`spaceId`,
`parentId`) must be **strings**, not JSON numbers — `{"spaceId": 123}` is a `400`.

**`atlas_doc_format.value` is a nested JSON string.** On read, parse it:
`jq '.body.atlas_doc_format.value | fromjson'`. On write, stringify:
`jq -n '{representation:"atlas_doc_format", value: ($adf | tojson)}'`.

**Titles are unique per space.** Creating a page with a title that already exists in the space
returns `400` ("A page with this title already exists").

**Version bumps are required on PUT.** Every PUT to pages, blog posts, comments, properties must
carry `version.number` one greater than the current version. Forgetting this is the #1 source of
`409 Conflict`.

**Deletes are soft.** DELETE moves to trash by default. `?purge=true` is permanent (admin only) and
only works on already-trashed content.

**CQL lives in v1.** There is no v2 search. Mix v1 search with v2 reads freely — they return the
same numeric IDs.
