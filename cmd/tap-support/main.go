package main

import (
	"fmt"
	"os"
	"strconv"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/joho/godotenv"
	"github.com/statick/tap-support/internal/application"
	"github.com/statick/tap-support/internal/infrastructure/storage"
	"github.com/statick/tap-support/internal/infrastructure/tiktok"
	"github.com/statick/tap-support/internal/ui"
)

func main() {
	// Load .env file if exists
	_ = godotenv.Load()

	// Configuration from environment variables
	storagePath := os.Getenv("TIKTOK_STORAGE_PATH")
	if storagePath == "" {
		storagePath = "./data"
	}

	// Auto-tap configuration - enabled by default!
	autoTapEnv := os.Getenv("TIKTOK_AUTO_TAP")
	autoTap := autoTapEnv == "" || autoTapEnv == "true" // Default: enabled

	defaultUsername := os.Getenv("TIKTOK_USERNAME")
	if defaultUsername == "" {
		defaultUsername = "lauragavidia" // Default TikTok username
	}

	// Tap rate configuration (taps per second) - MAXIMUM EFFECTIVENESS
	tapRate := 60 // default 60 taps per second (3600 taps/minute!)
	if rateStr := os.Getenv("TIKTOK_TAP_RATE"); rateStr != "" {
		if rate, err := strconv.Atoi(rateStr); err == nil && rate > 0 {
			tapRate = rate
		}
	}

	// Instance ID for parallel execution
	instanceID := os.Getenv("TIKTOK_INSTANCE_ID")
	if instanceID != "" {
		storagePath = fmt.Sprintf("%s/%s", storagePath, instanceID)
	}

	fmt.Printf("📱 TikTok Tap Support - Starting...\n")
	fmt.Printf("   Auto-tap: %v | Rate: %d taps/sec | Username: %s\n", autoTap, tapRate, defaultUsername)
	if instanceID != "" {
		fmt.Printf("   Instance: %s | Storage: %s\n", instanceID, storagePath)
	}
	fmt.Println()

	// Initialize storage
	jsonStorage, err := storage.NewJSONStorage(storagePath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to initialize storage: %v\n", err)
		os.Exit(1)
	}

	// Initialize services
	counterService := application.NewCounterService()
	tiktokClient := tiktok.NewTikTokScraper()
	metricsService := application.NewMetricsService(tiktokClient)
	historyService := application.NewHistoryService(jsonStorage)

	// Calculate tick duration from tap rate
	tickDuration := time.Second / time.Duration(tapRate)

	// Create and run the app
	app := ui.NewApp(counterService, metricsService, historyService, autoTap, defaultUsername, tickDuration)

	p := tea.NewProgram(app)
	if _, err := p.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Error running app: %v\n", err)
		os.Exit(1)
	}
}
