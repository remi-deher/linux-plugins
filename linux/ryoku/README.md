# Ryoku plugins

Format: `manifest.json`, `service/Main.qml`, `content/Widget.qml`, optional `content/Panel.qml`. Hosts: `topbarGlyph`, `desktopWidget`, `framePopout`, `sidebarCard`.

```bash
scripts/new-plugin.sh ryoku my-plugin      # scaffold here
ryoku plugin validate linux/ryoku/my-plugin
ryoku plugin add linux/ryoku/my-plugin --bar --yes
ryoku plugin share my-plugin               # Ryostore PR, only when you decide to publish
```

Plugins: [ryoku-pods](ryoku-pods/README.md).
