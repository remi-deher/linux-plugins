# Ryoku plugins

Format: `manifest.json`, `service/Main.qml`, `content/Widget.qml`, optional `content/Panel.qml`. Hosts: `topbarGlyph`, `desktopWidget`, `framePopout`, `sidebarCard`.

```bash
scripts/new-plugin.sh ryoku my-plugin      # scaffold here
ryoku plugin validate linux/ryoku/my-plugin
ryoku plugin add linux/ryoku/my-plugin --bar --yes
ryoku plugin share my-plugin               # Ryostore PR, only when you decide to publish
```

## Visual code

A Ryoku plugin must look like the rest of the shell. Only `Ryoku.PluginKit` and `Ryoku.PluginKit.Singletons` are importable (rule R4), so build with those and copy the idiom of the shell's own panels (mixer, brightness, system card). `ryoku-pods` is a worked example.

- **Colour and type: tokens only.** Use `Theme.accent`, `Theme.bright`, `Theme.dim`, `Theme.border`, `Theme.threadBg`, `Theme.sheen`, `Theme.tileBg`, `Theme.sun` (alert), and the fonts `Theme.font`, `Theme.display` (titles), `Theme.mono`. No hardcoded hex, so the plugin follows the active scheme and wallpaper accent.
- **Square, hairline.** `Theme.radius` is 0: no rounded cards or buttons. Frames are 1px `Theme.border`; the selected state is an `Theme.accent` border or underline over a `Theme.threadBg` tint; hover is `Theme.sheen`.
- **Section headings:** `MicroLabel` (accent dot, mono uppercase). **Surfaces:** `Card`. **Measures** (battery, RAM, disk): `WaveMeter`. **Icons:** `GlyphIcon`.
- **Sliders:** 3px `Theme.threadBg` track, accent gradient fill (`Theme.vermDim` to `Theme.vermLit`), flat 2.5px tick as the thumb, value readout at the right. No round thumbs.
- **Alert state:** `Theme.sun` on the value or glyph, never a new colour.
- **Scale everything by `s`** (host-set), including font sizes, and read `density` and `widthBudget` instead of assuming a width.
- **Tooltips and popups** must not take the pointer (`mask: Region { item: null }`) or they steal the hover and flicker.
- Compare against a built-in panel on your bar before publishing, in the light and dark scheme.

Plugins: [ryoku-pods](ryoku-pods/README.md).
