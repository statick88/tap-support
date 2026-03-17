# Core Application Specification

## Purpose

This spec defines the requirements for the TikTok Tap Support TUI application - a manual tap counter and account metrics viewer for TikTok creators.

## ADDED Requirements

### Requirement: Tap Counter

The system MUST provide a manual tap counter that the user operates physically on their device. The application SHALL track taps via keyboard input (e.g., pressing a key to increment the counter).

#### Scenario: Starting a counting session

- GIVEN the application is running in the terminal
- WHEN the user presses the designated start key (e.g., 's')
- THEN the counter starts counting from 0
- AND the timer begins counting elapsed time

#### Scenario: Incrementing the tap count

- GIVEN a counting session is active
- WHEN the user presses the tap key (e.g., 't' or Space)
- THEN the tap count increments by 1
- AND the display updates to show the new count

#### Scenario: Stopping a counting session

- GIVEN a counting session is active
- WHEN the user presses the stop key (e.g., 's' again)
- THEN the counter stops
- AND the timer stops
- AND the final taps-per-minute rate is calculated

#### Scenario: Resetting the counter

- GIVEN a counting session is active or stopped
- WHEN the user presses the reset key (e.g., 'r')
- THEN the tap count resets to 0
- AND the timer resets to 0
- AND the session is cleared

### Requirement: Tap Rate Calculation

The system MUST calculate and display the taps-per-minute rate in real-time during an active session.

#### Scenario: Real-time rate display

- GIVEN a counting session is active for at least 5 seconds
- WHEN the user has tapped at least once
- THEN the system SHALL display the current taps-per-minute rate
- AND the rate SHALL update every second

#### Scenario: Rate calculation at session end

- GIVEN a counting session is stopped
- WHEN the session ends
- THEN the system SHALL calculate: total_taps / (elapsed_seconds / 60)
- AND display the final average taps-per-minute

### Requirement: Account Metrics Display

The system MUST fetch and display public account metrics for a given TikTok username.

#### Scenario: Fetching account metrics

- GIVEN a valid TikTok username
- WHEN the user requests account metrics
- THEN the system SHALL fetch: followers, following, likes, video_count
- AND display the metrics in a formatted view

#### Scenario: Invalid username

- GIVEN an invalid or non-existent TikTok username
- WHEN the user requests account metrics
- THEN the system SHALL display an appropriate error message
- AND allow the user to enter a different username

#### Scenario: Rate limiting

- GIVEN the TikTok API rate limit is reached
- WHEN the user requests account metrics
- THEN the system SHALL display a rate limit message
- AND suggest waiting before retrying

### Requirement: Background Mode

The system SHOULD support a minimized background mode where the counter remains active but uses minimal screen space.

#### Scenario: Entering background mode

- GIVEN the application is running in normal mode
- WHEN the user presses the background toggle key (e.g., 'b')
- THEN the UI switches to a compact view showing only: tap count, time elapsed, rate
- AND the view auto-refreshes

#### Scenario: Exiting background mode

- GIVEN the application is in background mode
- WHEN the user presses any key or the exit command
- THEN the UI returns to normal view

### Requirement: Session History

The system SHOULD store the history of counting sessions for later review.

#### Scenario: Saving session to history

- GIVEN a counting session ends (via stop)
- WHEN the session ends
- THEN the system SHALL save: username (optional), tap_count, duration_seconds, taps_per_minute, timestamp to local storage

#### Scenario: Viewing session history

- GIVEN the user requests to view history
- WHEN the user presses the history key (e.g., 'h')
- THEN the system SHALL display the last N sessions
- AND show: timestamp, tap count, duration, rate

### Requirement: Security

The system MUST implement security by default principles.

#### Scenario: No hardcoded secrets

- GIVEN the codebase
- WHEN the application is inspected
- THEN there SHALL be no hardcoded API keys, passwords, or credentials
- AND all secrets SHALL be loaded from environment variables or config files

#### Scenario: Input sanitization

- GIVEN user input (TikTok username)
- WHEN input is processed
- THEN the system SHALL sanitize input to prevent injection attacks
- AND validate username format before API calls

## MODIFIED Requirements

None - this is a new application.

## REMOVED Requirements

None - this is a new application.
