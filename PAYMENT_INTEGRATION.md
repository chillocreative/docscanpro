# Connecting the $4.99 Lifetime Premium to Google Play Billing

This app uses the `in_app_purchase` plugin (already wired in
`lib/features/paywall/data/iap_service.dart`) to talk to **Google Play
Billing**. There is no other payment provider — Google Play handles the
card entry, billing, taxes, refunds, and receipts. You will not write
server code or store payment instruments yourself.

The code is already done. To go live you only need to do the Play
Console + signing work below.

## What is already wired in code

- `AppConstants.premiumLifetimeSku = 'premium_lifetime'`
  — the SKU the app queries and buys (`lib/core/constants/app_constants.dart`).
- `IapController.buyPremium()` calls `InAppPurchase.buyNonConsumable(...)`
  with that SKU. Non-consumable = one-time, never replenishes. Correct
  for "lifetime".
- The Settings → Premium card and the standalone Paywall page both
  drive `buyPremium()`.
- A successful purchase or `restored` event flips
  `AdEntitlement.active`, which `adsHiddenProvider` reads to hide all
  ads everywhere.
- The entitlement is cached in `SharedPreferences` so the user is not
  re-prompted on every cold start.

## Privacy policy URL (required for the listing)

Play Console requires a publicly hosted privacy policy URL before
you can publish. We host one out of this repo via GitHub Pages:

1. Push the repo to GitHub (already done if you're reading this in
   `chillocreative/docscanpro`).
2. In the GitHub repo: **Settings → Pages → Source → Deploy from a
   branch** → Branch: `main`, Folder: `/docs` → Save.
3. Wait ~30s for Pages to build, then verify:
   - <https://chillocreative.github.io/docscanpro/privacy.html>
   - <https://chillocreative.github.io/docscanpro/terms.html>
4. In Play Console **Policy → App content → Privacy policy**, paste
   the privacy URL.

The same URLs are exported from the app as
`AppConstants.publicPrivacyPolicyUrl` and `AppConstants.publicTermsUrl`
if you want to surface them anywhere in-app later.

## What you need to do in Google Play Console

1. **Create the app** in Play Console with package
   `com.docscanar.app` (already matches `applicationId` in
   `android/app/build.gradle`).
2. **Upload at least one signed App Bundle** to the *Internal testing*
   track. Google won't surface in-app products until a build has been
   uploaded.
3. **Monetisation setup → In-app products → Create product**:
   - Product ID: `premium_lifetime` (must match exactly).
   - Type: **Managed product** (not subscription).
   - Name: `DocScan Pro Premium (Lifetime)`.
   - Description: anything you like; the app does not display it.
   - Default price: **USD 4.99** (Play will auto-convert for other
     locales; you can override per-country if you want).
   - Status: **Active**.
4. **Set up a Payments profile** under *Setup → Payments profile* if
   you do not already have one. This is where Google deposits your
   share (70% of the gross, 85% if you stay under \$1M/yr — the
   "small business" rate). You will need bank details and tax info.
5. **License testing** (so you can buy without being charged):
   *Setup → License testing → Add testers* and add your own Gmail
   address. Testers see "Test card, always approves" instead of a real
   card.

## What you need to do in this codebase

1. Sign the release build. Generate an upload keystore once:

       keytool -genkey -v -keystore docscan-upload.keystore \
         -alias docscan -keyalg RSA -keysize 2048 -validity 10000

   Drop `docscan-upload.keystore` somewhere outside the repo (e.g.
   `D:\keys\docscan-upload.keystore`) and add the path + alias +
   passwords to `android/key.properties` (the file is
   `.gitignore`-able). Wire `android/app/build.gradle` to read from
   `key.properties` for the `release` signingConfig — the standard
   Flutter pattern: <https://docs.flutter.dev/deployment/android#signing-the-app>.
2. Build a release App Bundle:

       flutter build appbundle --release

   Output: `build/app/outputs/bundle/release/app-release.aab`.
3. Upload that `.aab` to the *Internal testing* track in Play Console
   and add yourself to the testing track.
4. Install the test build via the *Internal testing* opt-in link on
   your test device (do not sideload — Play Billing only works for
   apps installed through Play).
5. Open the app → Settings → Premium card → tap **Get lifetime —
   $4.99**. You should see the Play purchase sheet with the test card.
   Approve. The app will flip the card to **Active** and hide ads
   everywhere.

## Sanity-check the purchase flow

After a successful test purchase:

- The settings card label should change from *Get lifetime — $4.99* to
  *Active*.
- The "Ads Active" yellow banner on My Documents should disappear.
- Cold-start the app — entitlement is restored from the cache, so the
  card stays *Active*.
- Open Play Console → *Order management* → you should see the test
  order. You can refund / cancel it from there to re-test.

## Things that are intentionally NOT in the code

- **No subscription** — lifetime is a one-time `buyNonConsumable`.
  Subscriptions need the `purchaseUpdated` stream to handle renewals
  and grace periods, which adds a lot of code and is not needed here.
- **No "Restore purchases" tile** — `InAppPurchase.restorePurchases()`
  is still called automatically on every cold start (see
  `IapController._init`), so users that reinstall the app
  automatically get their entitlement back. The button was removed at
  product request because users found it confusing.
- **No server-side receipt validation.** For a $4.99 product this is
  usually overkill, but if you ever care about preventing modded APKs
  from spoofing entitlements, switch on Play Integrity API and add a
  tiny verification endpoint. The `purchase.verificationData` field
  is what you would forward.

## Known cliffs

- The first product query after fresh install can take 5–10 s. The
  Premium button is correctly disabled while products load — do not
  show "Get lifetime" until `iap.products` has at least one entry if
  you want to be even more conservative.
- License testers must be on a device whose primary Google account is
  the tester account, otherwise Play returns *"Item unavailable"*.
- The `premium_lifetime` SKU must exist and be **Active** in Play
  Console before any device can query it. If you change the product
  ID later, update `AppConstants.premiumLifetimeSku` to match.
