# RarityRadar

> **Smart Auto-Looting for World of Warcraft Classic**

Tired of manually looting everything? RarityRadar automatically grabs valuable items based on rarity, handles crafting materials from disenchanting/professions, and manages group loot rolling. Set your minimum quality threshold and let it work in the background while you focus on playing.

[![Version](https://img.shields.io/badge/version-1.8-blue.svg)](https://github.com/AndrewDonelson/RarityRadar/releases)
[![WoW Version](https://img.shields.io/badge/wow-MoP%20Classic%20(5.4.0)-orange.svg)](https://worldofwarcraft.com/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Developer](https://img.shields.io/badge/developer-Andrew%20Donelson-blue.svg)](https://andrewdonelson.com)

## ✨ Features

### 🎯 **Smart Auto-Looting**

- **Rarity-Based Filtering**: Automatically loot items of your chosen quality (Poor to Legendary)
- **Currency Auto-Loot**: Always grabs money (gold, silver, copper)
- **Crafting Material Detection**: Intelligently detects and loots disenchanting results regardless of rarity
- **Cloth Management**: Optional auto-looting of cloth items with separate toggle

### ⚔️ **Group Play Support**

- **Auto-Greed Rolling**: Automatically roll greed on valuable items in group scenarios
- **Smart Roll Decisions**: Passes on items below your rarity threshold
- **Soulbound Confirmation**: Auto-accepts soulbound item dialogs when enabled

### 🔧 **Advanced Detection**

- **Crafting Scenario Recognition**: Detects disenchanting, profession crafting, and trade skill activities
- **Spell-Based Detection**: Monitors crafting spells to trigger smart looting modes
- **Material Recognition**: Identifies enchanting materials (Strange Dust, essences, shards, crystals)

### 🛠️ **Customization & Control**

- **Flexible Settings**: Enable/disable individual features as needed
- **Debug Modes**: Comprehensive logging for troubleshooting
- **Real-time Configuration**: Change settings without reloading
- **Status Monitoring**: View current configuration at a glance

## 🚀 Installation

### Method 1: Manual Installation

1. Download the latest release from [Releases](https://github.com/AndrewDonelson/RarityRadar/releases)
2. Extract the zip file
3. Copy the `RarityRadar` folder to your WoW AddOns directory:

   ```text
   World of Warcraft\_classic_\Interface\AddOns\RarityRadar\
   ```

4. Restart World of Warcraft or reload UI (`/reload`)

### Method 2: Build from Source

1. Clone this repository: `git clone https://github.com/AndrewDonelson/RarityRadar.git`
2. Run `make release` to build a distribution zip
3. Install the generated zip file

## 📖 Usage

### Basic Setup

1. Load into the game - RarityRadar is enabled by default
2. Set your minimum rarity threshold:

   ```text
   /rr rarity 2    # Green (Uncommon) and above
   /rr rarity 3    # Blue (Rare) and above
   ```

3. Start looting - the addon works automatically!

### Command Reference

| Command | Description | Example |
|---------|-------------|---------|
| `/rr help` | Show all available commands | `/rr help` |
| `/rr enable/disable` | Toggle addon on/off | `/rr enable` |
| `/rr rarity <0-5>` | Set minimum rarity level | `/rr rarity 2` |
| `/rr greed enable/disable` | Toggle auto-greed in groups | `/rr greed enable` |
| `/rr confirm enable/disable` | Toggle soulbound auto-confirm | `/rr confirm enable` |
| `/rr cloth enable/disable` | Toggle cloth auto-looting | `/rr cloth disable` |
| `/rr status` | Show current settings | `/rr status` |
| `/rr debug` | Toggle debug mode | `/rr debug` |
| `/rr verbose` | Toggle detailed debugging | `/rr verbose` |

### Rarity Levels

- **0** - Poor (Gray)
- **1** - Common (White)
- **2** - Uncommon (Green) *[Default]*
- **3** - Rare (Blue)
- **4** - Epic (Purple)
- **5** - Legendary (Orange)

## 🎮 How It Works

### Normal Looting

RarityRadar analyzes each loot slot and automatically takes:

- ✅ Currency (money) - always looted
- ✅ Items meeting your rarity threshold
- ✅ Cloth items (if cloth looting enabled)
- ❌ Items below rarity threshold (unless in crafting mode)
- ❌ Soulbound items (skipped, with optional auto-confirm)

### Crafting Mode

When disenchanting or crafting, RarityRadar switches to **Crafting Mode** and loots everything regardless of rarity:

- **Triggered by**: Disenchanting materials detected in loot
- **Detects**: Strange Dust, essences, shards, crystals, gems
- **Behavior**: Overrides rarity settings, loots all items
- **Duration**: Active for current loot window

### Group Loot

In group scenarios with loot rolling:

- **Auto-Greed**: Rolls greed on items meeting your rarity threshold
- **Auto-Pass**: Passes on items below threshold
- **Respectful**: Only acts on items you can greed (not needed by others)

## ⚙️ Configuration Examples

### Conservative Setup (Rare+ Only)

```text
/rr rarity 3           # Blue and above only
/rr cloth disable      # Skip cloth items
/rr greed enable       # Participate in group loot
```

### Aggressive Farming Setup

```text
/rr rarity 1           # White and above
/rr cloth enable       # Grab all cloth
/rr confirm enable     # Auto-accept soulbound items
```

### Crafting-Focused Setup

```text
/rr rarity 2           # Green+ for normal items
/rr cloth enable       # Collect cloth for tailoring
# Crafting materials auto-looted regardless of settings
```

## 🐛 Troubleshooting

### Common Issues

#### Addon not working after installation

- Ensure folder is named exactly `RarityRadar`
- Check that both `.toc` and `.lua` files are present
- Try `/reload` or restart WoW

#### Items not being looted

- Verify addon is enabled: `/rr status`
- Check your rarity setting: `/rr rarity 1` (try lower threshold)
- Enable debug mode: `/rr debug` and check output

#### Too many items being looted

- Increase rarity threshold: `/rr rarity 3`
- Disable cloth looting: `/rr cloth disable`
- The addon may have detected crafting materials (this is intentional)

### Debug Information

Enable verbose debugging to see detailed decision-making:

```text
/rr verbose
/rr debug
```

Check the chat log for detailed information about why each item was looted or skipped.

## 🔧 Development

### Building

```bash
# Create release zip
make release

# Show current version
make version

# Clean build artifacts
make clean
```

### File Structure

```text
RarityRadar/
├── RarityRadar.toc     # Addon metadata
├── RarityRadar.lua     # Main addon code
├── Makefile           # Build system
├── README.md          # This file
└── .gitignore         # Git ignore rules
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly in-game
5. Submit a pull request

## 📋 Compatibility

- **WoW Version**: Mists of Pandaria Classic (5.4.0)
- **Dependencies**: None
- **Conflicts**: May conflict with other auto-loot addons
- **Performance**: Lightweight, minimal CPU/memory usage

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Support the Project

If RarityRadar has saved you time and enhanced your WoW experience, consider supporting its development:

### ☕ Buy Me a Coffee

[![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/nlaakstudios)

**PayPal**: [paypal.me/nlaakstudios](https://paypal.me/nlaakstudios)

### 💳 One-Time Donation

For other payment methods or one-time donations, feel free to reach out via:

- **GitHub Issues**: [Create an issue](https://github.com/AndrewDonelson/RarityRadar/issues)
- **Email**: <nlaakstudiosllc@gmail.com>
- **Company Website**: [nlaak.com](https://nlaak.com)
- **Developer Website**: [andrewdonelson.com](https://andrewdonelson.com)

### 🌟 Free Support

- ⭐ **Star this repository** on GitHub
- 🐛 **Report bugs** or suggest features via Issues
- 📢 **Share** with fellow WoW players
- 💡 **Contribute** code improvements

Your support helps maintain and improve RarityRadar for the entire community!

## 🙏 Acknowledgments

- **Blizzard Entertainment** - for World of Warcraft
- **WoW Classic Community** - for testing and feedback
- **Open Source Contributors** - for inspiration and code examples

## 📞 Contact & Support

- **Bug Reports**: [GitHub Issues](https://github.com/AndrewDonelson/RarityRadar/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/AndrewDonelson/RarityRadar/discussions)
- **General Questions**: Create an issue with the `question` label
- **Developer**: [Andrew Donelson](https://andrewdonelson.com)
- **Company**: [NLAAK Studios](https://nlaak.com)

---

**Made with ❤️ for the WoW Classic community by Andrew Donelson @ NLAAK Studios**

[⬆ Back to top](#rarityradar)
