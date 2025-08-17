# RarityRadar WoW Addon Makefile

# Variables
ADDON_NAME = RarityRadar
VERSION = $(shell grep "## Version:" $(ADDON_NAME).toc | cut -d' ' -f3)
RELEASE_DIR = releases
ZIP_NAME = $(ADDON_NAME)-$(VERSION).zip

# Source files to include in release
SOURCES = $(ADDON_NAME).toc $(ADDON_NAME).lua

# Default target
all: release

# Create release directory
$(RELEASE_DIR):
	mkdir -p $(RELEASE_DIR)

# Build release zip
release: $(RELEASE_DIR)
	@echo "Building $(ADDON_NAME) v$(VERSION)..."
	@echo "Including files: $(SOURCES)"
	zip -j $(RELEASE_DIR)/$(ZIP_NAME) $(SOURCES)
	@echo "Release created: $(RELEASE_DIR)/$(ZIP_NAME)"

# Clean release directory
clean:
	rm -rf $(RELEASE_DIR)
	@echo "Cleaned release directory"

# Show current version
version:
	@echo "$(ADDON_NAME) version: $(VERSION)"

# List all releases
list:
	@echo "Available releases:"
	@ls -la $(RELEASE_DIR)/ 2>/dev/null || echo "No releases found. Run 'make release' to create one."

# Help
help:
	@echo "RarityRadar Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  release    - Create release zip file (default)"
	@echo "  clean      - Remove release directory"
	@echo "  version    - Show current addon version"
	@echo "  list       - List available releases"
	@echo "  help       - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make release"

.PHONY: all release clean version list help
