// ===== Enable all Autoplay =====

// Allow all autoplay, including with sound
user_pref("media.autoplay.default", 0); // 0 = Allowed, 1 = Block Audio, 2 = Prompt
user_pref("media.autoplay.allow-muted", true);
user_pref("media.autoplay.blocking_policy", 0);

// Disable autoplay blocking heuristics
user_pref("media.autoplay.enabled.user-gestures-needed", false);
user_pref("media.autoplay.block-event.enabled", false);

// Remove UI permission prompts
user_pref("media.autoplay.enabled", true);

// ===== Disable all First Run in Firefox =====

// Disable "What's New" pages on startup or after update
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.aboutwelcome.browser.places/import_history", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);

// Prevent Firefox from opening pages on startup after update or crash
user_pref("browser.startup.page", 0); // 0=blank, 1=home, 2=last session
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("startup.homepage_welcome_url", "");
user_pref("startup.homepage_welcome_url.additional", "");

// Disable first run pages and onboarding
user_pref("browser.onboarding.enabled", false);                 // Disable onboarding UI
user_pref("browser.onboarding.state", "");                      // Clear onboarding state
user_pref("browser.onboarding.showFirstRunUI", false);          // Don't show first run UI
user_pref("browser.shell.checkDefaultBrowser", false);          // Don't prompt to set default browser on first run
user_pref("toolkit.telemetry.reportingpolicy.firstRun", false); // Disable telemetry first run report
user_pref("startup.homepage_welcome_url", "");                  // Clear welcome URL
user_pref("startup.homepage_welcome_url.additional", "");       // Clear additional welcome URL

// ===== Disable all Telemetry in Firefox =====

// Disable telemetry data submission and collection
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.server", "");
user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
user_pref("toolkit.telemetry.newProfilePing.enabled", false);
user_pref("toolkit.telemetry.bhrPing.enabled", false);
user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);
user_pref("toolkit.telemetry.updatePing.enabled", false);
user_pref("toolkit.telemetry.hybridContent.enabled", false);

// Disable telemetry experiments and studies
user_pref("experiments.enabled", false);
user_pref("experiments.supported", false);
user_pref("experiments.activeExperiment", false);
user_pref("experiments.manifest.uri", "");
user_pref("experiments.enabledScopes", "");
user_pref("network.allow-experiments", false);
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("app.shield.optoutstudies.telemetry", false);

// Disable Health Report and related telemetry
user_pref("datareporting.healthreport.service.enabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.policy.dataSubmissionPolicyAcceptedVersion", 2);
user_pref("datareporting.policy.dataSubmissionPolicyBypassNotification", true);
user_pref("datareporting.policy.dataSubmissionEnabled", false);

// Disable Normandy (Firefox Studies/Shield)
user_pref("app.normandy.enabled", false);
user_pref("app.normandy.api_url", "");
user_pref("app.normandy.first_run", false);

// Disable crash reports
user_pref("breakpad.reportURL", "");
user_pref("browser.crashReports.unsubmittedCheck.enabled", false);
user_pref("browser.crashReports.unsubmittedCheck.autoSubmit", false);

// ===== Set the theme to a dark theme =====

user_pref("extensions.activeThemeID", "firefox-dark@mozilla.org");
// Force websites to use dark theme (dark mode for web content)
user_pref("ui.systemUsesDarkTheme", 1);
