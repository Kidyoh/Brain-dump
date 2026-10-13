# Brain Dump on Google Play

Everything the Play Console asks for, in the order it asks. Signing and
building the upload are in [RELEASING.md](../RELEASING.md).

## Store listing

The text, icon (512 × 512), feature graphic (1024 × 500) and screenshots are
in `fastlane/metadata/android/en-US/`. Copy them into **Grow → Store presence → Main store
listing**, or upload them with `fastlane supply` if you use fastlane.

| Field | Answer |
| --- | --- |
| App or game | App |
| Category | Productivity |
| Tags | Note taking, To-do list |
| Free or paid | Free |
| Privacy policy | https://kidus.pro.et/privacy/brain-dump/ |

The privacy policy is a page on the portfolio site (`frontend/` in the
Kstore repo). The URL above works once the portfolio is deployed at
kidus.pro.et; if it's hosted elsewhere, use that address with
`/privacy/brain-dump/`.

## Data safety

**Does your app collect or share any of the required user data types?** Yes,
because of the optional AI services. Fill it in like this:

| Data type | Collected | Shared | Optional | Purpose |
| --- | --- | --- | --- | --- |
| Audio → Voice or sound recordings | Yes | No | Yes | App functionality |
| App info and performance → none | No | | | |
| Personal info → none | No | | | |
| Messages / user content → **Other user-generated content** (the text of each dump) | Yes | No | Yes | App functionality |

- **Is all user data encrypted in transit?** Yes (HTTPS to api.openai.com and api.anthropic.com).
- **Can people request deletion?** Data on the phone is deleted in the app or by uninstalling. There is no account and no server of ours; anything sent to OpenAI or Anthropic is under the person's own API account.
- **Why "not shared":** the recording and text go to OpenAI or Anthropic only when the person has added their own key and records a dump. Google's form treats a transfer the person deliberately starts, to a service they chose, as not sharing. If you'd rather be extra cautious, you can also tick *Shared* for both; it doesn't change review.
- Without a key nothing leaves the phone. The phone's own speech recognition is an Android system service, not data collected by Brain Dump.

## Permissions

| Permission | Why | Console |
| --- | --- | --- |
| `RECORD_AUDIO` | Hearing the dump while the button is held | Not restricted; no form |
| `INTERNET` | Only for the optional AI services | — |
| `POST_NOTIFICATIONS`, `VIBRATE` | Reminders | Not restricted |
| `SCHEDULE_EXACT_ALARM` | Reminders on the minute; the person allows it under "Alarms & reminders" | If asked about exact alarms: reminders the person sets are core functionality |
| `RECEIVE_BOOT_COMPLETED` | Reschedule reminders after a restart | Not restricted |

## Content rating (IARC questionnaire)

Category **Utility, Productivity, Communication or other**. Answer **No** to every question. User interaction: **No** (nothing is shared between users). Expected rating: **Everyone / PEGI 3**.

## Target audience

**18 and over** (or 13 and over).

## Store settings

| Field | Answer |
| --- | --- |
| Contact email | kidyoh789@gmail.com |
| Website | https://kidus.pro.et |
| Ads | No, the app has no ads |
| App access | All functionality is available without special access (no login) |
| Government app | No |
| Financial features | None |
| Health | None |

## Notes

- If the Console asks whether the app uses **generative AI**: AI is optional, uses the person's own OpenAI or Claude key, and only sorts what they said into tasks, reminders, notes and ideas. It doesn't generate images or open-ended content.
- Reviewers can test everything without a key (built-in sorting), so App access is "all functionality available".
