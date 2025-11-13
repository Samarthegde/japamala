# Japamala App Requirements

## Overview
A Flutter-based mobile application for digital mantra counting and meditation tracking. Users can create custom mantras with individual bead counters, track their spiritual practice, and monitor progress over time.

## Core Features

### 1. Custom Mantra Management
- **Create Custom Mantras**: Users can add their own mantras with:
  - Mantra name/text
  - Target count (customizable, not limited to 108)
  - Optional description or notes
- **Edit/Delete Mantras**: Full CRUD operations for mantra management
- **Mantra List**: Clean list view of all created mantras

### 2. Independent Bead Counters
- **Separate Counters**: Each mantra has its own persistent counter
- **Visual Bead Representation**: Digital mala beads that fill up as user counts
- **Counter Reset**: Manual reset option for each mantra
- **Count Persistence**: Counters maintain state across app sessions

### 3. Session Tracking
- **Automatic Session Logging**: Records when users complete mantra rounds
- **Session History**: View past sessions with date, time, and completion status
- **Session Details**: Duration, mantra name, count achieved

### 4. Progress Dashboard
- **Completion Status**: Visual progress bars for each mantra's target
- **Statistics Overview**: Total sessions, total mantras completed, streaks
- **Recent Activity**: Timeline of recent counting sessions

### 5. User Experience
- **Intuitive Interface**: Simple, meditation-friendly design
- **Haptic Feedback**: Optional vibration on bead count
- **Dark/Light Theme**: User preference for visual comfort
- **Offline First**: All functionality works without internet

## Technical Requirements

### Platform Support
- **Primary**: Android and iOS
- **Framework**: Flutter with Dart
- **State Management**: Provider or Riverpod
- **Local Storage**: SQLite or Hive for data persistence

### Data Models
- **Mantra**: id, name, targetCount, description, createdDate
- **Session**: id, mantraId, count, startTime, endTime, completed
- **UserSettings**: theme, hapticEnabled, etc.

## Development Roadmap

### Phase 1: Core Functionality (Week 1-2)
- [ ] Basic app structure and navigation
- [ ] Mantra creation and management
- [ ] Basic bead counter UI
- [ ] Local data storage setup

### Phase 2: Session Tracking (Week 3)
- [x] Session logging and persistence
- [x] Counter state management
- [x] Basic progress indicators

### Phase 3: Dashboard & Analytics (Week 4)
- [ ] Progress dashboard implementation
- [ ] Statistics calculations
- [ ] Session history view

### Phase 4: Polish & Features (Week 5)
- [ ] UI/UX improvements
- [ ] Haptic feedback
- [ ] Theme support
- [ ] Data export functionality

## Success Metrics
- **User Engagement**: Daily active users, session frequency
- **Feature Usage**: Mantra creation rate, completion rates
- **Technical**: App stability, load times, battery usage

## Future Enhancements (Post-MVP)
- Audio chanting integration
- Guided meditation sessions
- Social features (sharing progress)
- Cloud backup and sync
- Advanced analytics and insights
