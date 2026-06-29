// Tab switcher
function show(id, el) {
  document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
  document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
  document.getElementById(id).classList.add('active');
  el.classList.add('active');
}

const privacy = [
  ['Overview', 'Aqistat ("we", "our", or "the app") respects your privacy. This policy explains what information the app accesses, how it is used, and your choices. We designed Aqistat to collect as little data as possible.'],
  ['Location Data', 'With your permission, the app accesses your device location to show local weather and air quality. Your location is used only to fetch this data from our weather providers. It is never sold, shared with advertisers, or stored on our servers. You can deny location access and search for cities manually instead.'],
  ['Data We Store On Your Device', 'To reduce network usage and protect API limits, the app caches recent weather and air-quality results locally on your device. This cache stays on your phone, is never uploaded, and is cleared when you uninstall the app.'],
  ['Third-Party Services', 'Weather data is provided by OpenWeatherMap and air-quality data by the World Air Quality Index (WAQI) project. When the app requests data, your approximate coordinates are sent to these services so they can return local results. Please review their respective privacy policies.'],
  ['What We Do NOT Collect', 'We do not collect your name, email, contacts, photos, or any personal identifiers. We do not use analytics or advertising trackers. We do not create user accounts.'],
  ['Data Security', 'All network requests use encrypted HTTPS connections. The app blocks insecure (cleartext) traffic, disables cloud backup of its local data, and ships with code obfuscation in release builds to protect against tampering.'],
  ['Children\u2019s Privacy', 'Aqistat is suitable for general audiences and does not knowingly collect personal information from children.'],
  ['Changes To This Policy', 'We may update this policy from time to time. Material changes will be reflected by the "Last updated" date at the top of this page.'],
  ['Contact', 'Questions about this policy? Reach us at support@aqistat.app.'],
];

const terms = [
  ['Acceptance of Terms', 'By downloading or using Aqistat, you agree to these Terms of Service. If you do not agree, please do not use the app.'],
  ['Weather Data Disclaimer', 'Aqistat provides weather and air-quality information for general informational purposes only. Forecasts and readings are sourced from third parties and may be inaccurate, delayed, or unavailable. Do not rely on the app as your sole source for decisions involving safety, health, travel, or property. Always consult official local authorities during severe weather.'],
  ['No Professional Advice', 'Air-quality and health-related tips in the app are general guidance, not medical advice. Consult a qualified professional for medical concerns.'],
  ['Acceptable Use', 'You agree not to misuse the app, attempt to reverse engineer it, overload the underlying data providers, or use it for any unlawful purpose.'],
  ['Limitation of Liability', 'The app is provided "as is" without warranties of any kind. To the maximum extent permitted by law, we are not liable for any damages arising from your use of, or inability to use, the app or its data.'],
  ['Service Availability', 'We do not guarantee uninterrupted access. Features depend on third-party APIs that may change or become unavailable.'],
  ['Changes To These Terms', 'We may revise these terms at any time. Continued use after changes constitutes acceptance of the updated terms.'],
  ['Contact', 'Questions about these terms? Reach us at support@aqistat.app.'],
];

function render(arr, target) {
  document.getElementById(target).innerHTML = arr.map(
    ([h, b]) => `<div class="card"><h2>${h}</h2><p>${b}</p></div>`
  ).join('');
}

render(privacy, 'privacy');
render(terms, 'terms');
