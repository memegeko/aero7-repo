# Integrated theme source

This package now builds `theme/` inside the tested Aero7 Desktop GitHub commit.
The session, theme, gadgets and browser identity recipes share that source pin.
The legacy package name is retained for seamless upgrades and dependency
compatibility; it no longer requires the archived theme repository.

The patch, keyboard, backgrounds and defaults beside this recipe are retained
only as historical provenance. They are not downloaded, patched or overlaid by
the recipe. Their accepted changes and assets live in Desktop's source, where
runtime-layout, native-helper, Start-search and staged-install tests run.

Icons and sound packs remain separate packages. This source consolidation does
not merge release branches or publish binaries automatically.
