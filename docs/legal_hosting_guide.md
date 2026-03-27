# TempCam Legal Page Hosting Guide

This guide is the exact simple path to get legal page URLs that Google Play and
the App Store can accept, even if you do not have a website.

## Files Already Prepared For You

Use these ready-made HTML pages:

- `docs/privacy-policy.html`
- `docs/subscription-terms.html`

These are better than raw Markdown because GitHub Pages can host them directly.

## Step 1: Create a GitHub Account

If you do not already have one:

1. Go to `https://github.com`
2. Create an account
3. Verify your email

## Step 2: Create a GitHub Repository

1. Click `New repository`
2. Name it something like:
   - `tempcam`
3. Choose `Public`
4. Click `Create repository`

## Step 3: Upload This Project To GitHub

If you are using Git locally:

```powershell
git init
git add .
git commit -m "Initial TempCam release prep"
git branch -M main
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/tempcam.git
git push -u origin main
```

Replace `YOUR_GITHUB_USERNAME` with your real GitHub username.

If you do not want to use Git commands:

1. Open the new GitHub repository page
2. Click `uploading an existing file`
3. Drag this project in or upload the needed files
4. Commit the upload

## Step 4: Turn On GitHub Pages

1. Open your GitHub repository
2. Click `Settings`
3. In the left menu, click `Pages`
4. Under `Build and deployment`:
   - Source: `Deploy from a branch`
   - Branch: `main`
   - Folder: `/docs`
5. Click `Save`

Wait a minute or two.

GitHub will then show a public site URL, usually:

`https://YOUR_GITHUB_USERNAME.github.io/tempcam/`

## Step 5: Your Final Legal URLs

Once GitHub Pages is live, your URLs should be:

- Privacy Policy:
  `https://YOUR_GITHUB_USERNAME.github.io/tempcam/privacy-policy.html`
- Subscription Terms:
  `https://YOUR_GITHUB_USERNAME.github.io/tempcam/subscription-terms.html`

Replace `YOUR_GITHUB_USERNAME` with your real GitHub username.

## Step 6: Put The Privacy Policy URL In Play Console

In Google Play Console:

1. Open your app
2. Go to `App content`
3. Find `Privacy policy`
4. Paste your public Privacy Policy URL:

`https://YOUR_GITHUB_USERNAME.github.io/tempcam/privacy-policy.html`

5. Save

## Step 7: Put The Privacy Policy URL In App Store Connect

In App Store Connect:

1. Open your app
2. Go to the app information section
3. Find the `Privacy Policy URL` field
4. Paste the same public Privacy Policy URL
5. Save

## Step 8: Link The Pages Inside TempCam

TempCam supports linking legal pages from build-time environment variables.

Use these values when building:

```powershell
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols --dart-define=TEMPCAM_PRIVACY_POLICY_URL=https://YOUR_GITHUB_USERNAME.github.io/tempcam/privacy-policy.html --dart-define=TEMPCAM_SUBSCRIPTION_TERMS_URL=https://YOUR_GITHUB_USERNAME.github.io/tempcam/subscription-terms.html
```

That will let the app open the public pages from the paywall.

## Step 9: Verify The Links

Before uploading:

1. Open the privacy policy URL in a normal browser
2. Open the subscription terms URL in a normal browser
3. Build the app with the `--dart-define` values
4. Open TempCam
5. Go to the paywall
6. Tap `Privacy Policy`
7. Tap `Terms`
8. Confirm both open correctly

## Fastest Practical Choice

If you want the simplest no-website path:

- use GitHub Pages
- host `privacy-policy.html`
- host `subscription-terms.html`
- use those two URLs in the stores and in the app build
