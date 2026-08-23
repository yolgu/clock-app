# Preserve theme compatibility with redistributable palettes

All schema-version-1 theme identifiers remain valid backup values. The proprietary Monokai Pro palette and user-facing name are not redistributed: stored ID `monokai-pro` selects the original Clock Rhythm Compatibility Theme displayed as `Neon Dusk`. Other inherited palettes receive a source and license audit recorded in `THIRD_PARTY_NOTICES.md`; an unverified palette is replaced through the same stable-ID mechanism, and names such as `Dracula Official` are shortened where they could imply product affiliation.

The existing `public/icon.png` and `src/assets/CHIME14.mp3` are carried into the Flutter application as directed product assets even though the Neutralino repository contains no provenance or license record for them. Their undocumented provenance is an accepted distribution risk and is recorded in the asset notice rather than being silently represented as independently verified.
