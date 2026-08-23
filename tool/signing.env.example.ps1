# Copy these names into an isolated release environment. Do not put real values
# in this repository or dot-source a credential file from a package script.
$env:CLOCK_RHYTHM_ANDROID_KEYSTORE = 'C:\external\clock-rhythm-production.jks'
$env:CLOCK_RHYTHM_ANDROID_KEY_ALIAS = 'clock-rhythm-production'
$env:CLOCK_RHYTHM_ANDROID_STORE_PASSWORD = '<secret>'
$env:CLOCK_RHYTHM_ANDROID_KEY_PASSWORD = '<secret>'

$env:CLOCK_RHYTHM_WINDOWS_CERTIFICATE = 'C:\external\clock-rhythm-production.pfx'
$env:CLOCK_RHYTHM_WINDOWS_CERTIFICATE_PASSWORD = '<secret>'
