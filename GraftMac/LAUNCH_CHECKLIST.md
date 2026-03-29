# GraftMac Launch Checklist

## Pre-Launch

### App Store Listing
- [ ] App name "GraftMac" confirmed available
- [ ] Tagline: "Master any skill, one practice at a time."
- [ ] Subtitle: "Craftsman's toolkit for deliberate practice"
- [ ] Full description written and reviewed (see `Marketing/APPSTORE.md`)
- [ ] Keywords populated (see `Marketing/APPSTORE.md`)
- [ ] Screenshots taken at 1440×900 @ 144dpi (see `Marketing/APPSTORE.md` for specs)
- [ ] App icon uploaded (1024×1024 PNG, see `Marketing/APPSTORE.md` for concept)
- [ ] Age rating: 4+ confirmed
- [ ] Category: Productivity selected
- [ ] Pricing configured (Free / Track $2.99 / Master $5.99)

### Legal & Privacy
- [ ] Privacy Policy URL posted
- [ ] Terms of Service URL posted
- [ ] End User License Agreement (EULA) posted
- [ ] Apple Privacy Nutrition Labels completed in App Store Connect
  - [ ] No data collection (app is fully offline)
  - [ ] No third-party analytics SDKs
  - [ ] No crash reporters
  - [ ] No advertising identifiers

### Build & Signing
- [ ] `MARKETING_VERSION` set to "1.0.0" in `project.yml`
- [ ] `CURRENT_PROJECT_VERSION` set to "1" in `project.yml`
- [ ] Bundle ID `com.graft.macos` registered in Apple Developer account
- [ ] App Store Connect "macOS" app entry created
- [ ] Xcode Cloud or local build produces valid .app
- [ ] Build verified with: `xcodebuild -scheme GraftMac -configuration Release -destination 'platform=macOS,arch=arm64' build CODE_SIGN_IDENTITY="-"`

### macOS-Specific Requirements
- [ ] App Sandbox enabled (for Mac App Store distribution)
- [ ] Hardened Runtime enabled
- [ ] Notarization completed (if distributing outside Mac App Store)
- [ ] App Store Connect: "macOS 12.0 or later" minimum selected
- [ ] App Store Connect: Silicon + Intel (Universal) selected

### Feature Readiness
- [ ] Onboarding flow functional
- [ ] Log session sheet functional
- [ ] Skill management (add/edit/select skills) functional
- [ ] Monthly stats view functional
- [ ] Weekly chart rendering correctly
- [ ] Menu bar icon quick-entry functional
- [ ] Settings (export data) functional
- [ ] Light/Dark mode both render correctly

### Accessibility
- [ ] VoiceOver: all buttons and interactive elements labeled
- [ ] VoiceOver: skill list rows labeled with skill name and active state
- [ ] VoiceOver: session rows labeled with date, duration, feel rating
- [ ] VoiceOver: stat cards labeled with label and value
- [ ] Keyboard navigation: ⌘L opens Log Session
- [ ] Keyboard navigation: ⌘, opens Settings
- [ ] Keyboard navigation: ⌘M opens Monthly Stats
- [ ] Dynamic Type: all text scales with system font size

### Performance
- [ ] App launches in < 2 seconds on M1 MacBook Air
- [ ] No LazyVStack misuse (all scrollable lists use lazy loading)
- [ ] Search fields (if any) debounced
- [ ] No UI freezes during database operations (all DB on background queue)

### Localization (optional for v1)
- [ ] English (U.S.) ready
- [ ] Localization strings externalized for future translation

---

## Launch Day

- [ ] Submit for review in App Store Connect
- [ ] Apple review SLA: 1-5 business days for new apps
- [ ] Prepare marketing copy for social channels
- [ ] Prepare direct announcements to any beta testers

---

## Post-Launch

- [ ] Monitor App Store Connect for reviews and ratings
- [ ] Monitor for crash reports in Xcode Cloud / App Store Connect
- [ ] Track adoption metrics (daily active users, sessions per user)
- [ ] Plan v1.1 based on initial user feedback

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | TBD | Initial macOS App Store release |
