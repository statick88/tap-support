package main

import (
	"fmt"
	"os"

	"github.com/joho/godotenv"
	"github.com/statick/tap-support/internal/infrastructure/tiktok"
)

func main() {
	_ = godotenv.Load()

	username := os.Args[1]
	if username == "" {
		fmt.Println("Usage: go run cmd/live-check/main.go <username>")
		fmt.Println("Example: go run cmd/live-check/main.go lauragaviria")
		os.Exit(1)
	}

	client := tiktok.NewLiveClient()

	fmt.Printf("🔍 Checking if %s is live...\n", username)

	info, err := client.FetchLiveInfo(username)
	if err != nil {
		fmt.Printf("❌ Error: %v\n", err)
		os.Exit(1)
	}

	if info.IsLive {
		fmt.Printf("\n🟢 %s IS LIVE!\n", username)
		fmt.Printf("   👁️ Viewers: %d\n", info.ViewerCount)
		fmt.Printf("   ❤️ Likes: %d\n", info.LikeCount)
		if info.StreamTitle != "" {
			fmt.Printf("   📝 Title: %s\n", info.StreamTitle)
		}
	} else {
		fmt.Printf("\n🔴 %s is NOT live\n", username)
	}

	fmt.Printf("\n   Checked at: %s\n", info.FetchedAt.Format("2006-01-02 15:04:05"))
}
