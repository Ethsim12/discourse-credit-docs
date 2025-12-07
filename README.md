# discourse-credit-docs

> ⚠️ **Experimental plugin** – API and schema may change.  
> Please test on a staging site before using in production.

`discourse-credit-docs` adds a simple **credit / points system for file downloads** in Discourse, inspired by “Scribd-style” document gating.

Users:

- **Earn** credits when their posts are approved.
- **Spend** credits to download **gated** attachments (per-upload, not per-category).
- See their current **credit balance** in the user menu.

Admins and staff can configure default rewards and costs, and gate individual uploads directly from the composer.

---

## Features

### 💵 Credit balance per user

- Each user has a `user_credits` row that tracks:
  - `balance` – current available credits
  - (optionally) `lifetime_earned`, `lifetime_spent` if those columns exist
- The current balance is exposed to the client via the `current_user` serializer as `credit_balance`.
- A small UI connector shows the balance in the user menu:

  > `Credits: 10`

### ✅ Automatic credit rewards

- Listens to the Discourse `:post_approved` event.
- When a queued post is approved and the plugin is enabled, the post author is awarded credits:

  - Amount is controlled by `credit_docs_default_reward` (site setting).
  - A `CreditTransaction` row is recorded with metadata (e.g. `"source" => "post_approved"`).

### 📎 Per-upload gating

- Gated documents are represented by `CreditDocument` rows associated with an `Upload`.
- A small UI block is added under each upload in the composer via a widget decorator:

  - “Gate (credits): [cost] [Apply]”
  - Clicking **Apply** calls `PUT /credit-docs/gate`, which creates or updates the `CreditDocument` for that upload.

- When a user attempts to download a gated upload:

  - Their credit balance is checked.
  - If they have enough credits, the cost is deducted and the download proceeds.
  - If not, the plugin returns **403 Forbidden** with a simple error message.

### 👤 Who pays and who skips?

When a gated upload is downloaded:

- **Uploader** of the document never pays.
- **Staff** can optionally bypass the credit check.
- A **“free access” group** can be configured so members can download without spending credits.
- Everyone else must have at least `cost` credits to proceed.

### 🧾 Basic transaction log

- Credit changes are recorded in `credit_transactions`:
  - `user_id`
  - `amount` (positive = earn, negative = spend)
  - `tx_type` (string, e.g. `"upload_reward"`, `"download_cost"`)
  - optional `upload_id`, `post_id`, `metadata`
- Simple scopes and helpers exist to distinguish earnings vs spend.

---

## Installation

1. On your Discourse host, edit your container definition (usually `app.yml`):

   ```yml
   hooks:
     after_code:
       - exec:
           cd: $home
           cmd:
             - git clone https://github.com/Ethsim12/discourse-credit-docs.git
   ```

2. Rebuild the container:

```
cd /var/discourse
./launcher rebuild app
```

3. After the rebuild completes, log into Discourse and visit:

`/admin/plugins` – confirm Credit Docs appears and is enabled.

`/admin/site_settings/category/plugins?filter=credit` – adjust settings.

---

## Configuration

All plugin settings live under Admin → Settings → Plugins.

Current settings include:

`credit_docs_enabled`
Master switch for the plugin. If disabled, no credits are awarded or spent.

`credit_docs_default_cost`
Default number of credits required to unlock a gated document.
(Used as a sensible default in the composer UI; final cost is per-upload.)

`credit_docs_default_reward`
Default number of credits awarded when a user’s post is approved.

`credit_docs_min_trust_level_to_download`
Minimum trust level required to attempt unlocking / downloading a gated document.
(Currently a forward-looking setting; enforcement may change as the plugin evolves.)

`credit_docs_allow_free_for_group`
Optional Discourse group whose members can download all gated documents without being charged.

---

## How it works (flow)

1. Earning credits

A post enters the review queue (e.g. first-time poster, or specific category settings).

A staff member approves it.

The :post_approved event fires.

If the plugin is enabled and credit_docs_default_reward > 0:

The post author’s UserCredits row is created (if needed) and incremented.

A CreditTransaction of type "upload_reward" is recorded.

You can extend this logic later to award credits for other actions.

---

2. Gating an upload

Start a new topic or reply.

Upload a file (PDF, DOCX, etc.).

Under the upload preview, you’ll see:

```
Gate (credits): [N] [Apply]
```

Enter a cost (e.g. 5) and click Apply.

The plugin calls the CreditDocs::GatingController, which:

Validates cost >= 0.

Finds or creates a CreditDocument for that upload_id.

Stores cost, uploader_id, and (optionally) post_id.

At this point, that upload is considered gated.

---

3. Downloading a gated document

When a user clicks on a gated attachment:

The plugin hooks into the download controller (DownloadController / UploadsController depending on Discourse version).

It looks up the associated CreditDocument using the Upload.

If there is no document, or the cost is 0, the plugin does nothing (download is free).

Otherwise:

If the user is the uploader → allowed, no credits deducted.

If the user is staff or in the configured free access group → allowed, no credits deducted.

Else:

The plugin tries to CreditsService.spend! the document cost.

On success:

A negative CreditTransaction is recorded with tx_type: "download_cost".

The download proceeds as normal.

On failure (NotEnoughCreditsError):

The request is blocked with HTTP 403 and an explanatory text message.

---

## Status & limitations

This plugin is early-stage / experimental:

The database schema and public API may change.

No full UI yet for:

Viewing past transactions.

Browsing / editing all CreditDocument entries in admin.

No payment integration:

“Credits” are virtual only; buying credits via Stripe/PayPal/etc. is out of scope for now.

Only standard download paths are gated; edge cases (e.g. some direct S3 URLs) may bypass gating depending on your storage setup.

You should:

Use on a test site first.

Take a backup before enabling on production.

Expect to adjust or migrate data between releases.

---

## Development notes

Plugin is MIT-licensed.

Targets a recent Discourse version (Rails 7 / 8 stack and modern Ember).

Uses the recommended after_initialize pattern and plugin API (withPluginApi("1.8.0", …)).

Database migrations are automatically run during normal `./launcher rebuild app`.

---

## Local testing tips

On a dev/staging Discourse:

Ensure the plugin is cloned into plugins/ and rebuild.

Create a couple of test users (staff + regular).

Create and approve a post to generate some credits.

Upload a file, gate it, and test downloads as different users.

---

## Roadmap ideas

Things that could be added in future versions:

Admin UI to browse credit balances and transactions.

Per-category or per-tag default gating rules.

More ways to earn credits (likes, solutions, time-read, custom events).

A small “credit history” panel in the user menu or profile.

Integrations with payment providers for “buy credits” flows (if desired).

---

## Contributing / feedback

The plugin is still evolving. Bug reports, suggestions, and PRs are very welcome.

Meta topic: “Gating system similar to Scribd” (original context for this plugin).

GitHub issues: use the Issues tab to report problems or suggest improvements.
