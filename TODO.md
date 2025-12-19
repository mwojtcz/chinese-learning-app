# ChineseFlow Development Roadmap

## ✅ Completed (v1.0 - v1.4)

- [x] Test answer correction + performance optimization
- [x] Reverse test mode (Polish→Chinese)
- [x] Traditional Chinese support (繁體字)
- [x] HSK 1-4 complete vocabulary (3,229 words, 4 languages)
- [x] OpenCC integration for accurate traditional conversion
- [x] DeepL API integration for Polish translations
- [x] **Dashboard/Home Screen** - Complete UI redesign
- [x] **Hamburger Menu Navigation** - Drawer-based navigation
- [x] **Dark Theme** - Complete dark mode implementation
- [x] **Smooth Transitions** - AnimatedSwitcher with fade effects
- [x] **Chengyu Learning Screen** - First 5 idioms with examples
- [x] **Improved Typography** - Significantly larger fonts

---

## 🎯 Phase 1 - UI Foundation & Navigation ✅ COMPLETED (v1.3-v1.4)

### Dashboard / Home Screen 🏠 ✅
- [x] Create new home screen layout
- [x] Streak counter with fire emoji (🔥 motivation!)
- [x] Quick stats cards:
  - [x] Total words learned: X / 11,092
  - [x] My saved words count
  - [x] Words to review today (placeholder)
  - [x] Test accuracy percentage (placeholder)
- [x] Quick action buttons:
  - [x] Continue Learning (→ Dictionary)
  - [x] Daily Practice Test (→ Tests)
  - [x] Review Weak Words (→ My Words)
- [x] Progress chart placeholder (last 7 days)
- [x] Chengyu of the Day widget 🎋
- [x] Two-column compact layout optimization
- [x] Dark theme with grey.shade800/900

### Hamburger Menu Navigation 🍔 ✅
- [x] Implement drawer navigation
- [x] Menu structure:
  - [x] 🏠 Home (Dashboard)
  - [x] 📚 Dictionary (HSK vocabulary)
  - [x] ⭐ My Words (saved words)
  - [x] 📝 Tests (practice & review)
  - [x] 🎋 Chengyu (idioms) **NEW**
  - [x] 📊 Statistics (coming soon - locked)
  - [x] 🔄 SRS Review (coming soon - locked)
  - [x] ⚙️ Settings
- [x] Active route highlighting (gold icon + white text)
- [x] Smooth fade transitions (300ms AnimatedSwitcher)
- [x] Dark drawer theme (grey.shade900)
- [x] Improved font sizes and icon sizes

### Basic Progress Tracking ⏳ (Partial)
- [x] Word count display (total + my words)
- [ ] Word status system (New/Learning/Mastered/Weak)
- [ ] Local storage for progress data
- [ ] Test history tracking
- [ ] Calculate accuracy per HSK level

---

## 🎯 Phase 2 - Core Feature Expansion (Priority: HIGH)

### HSK 5-6 Vocabulary 📚
- [ ] Add traditional Chinese to HSK 5 (1,071 words) using OpenCC
- [ ] Add traditional Chinese to HSK 6 (1,140 words) using OpenCC
- [ ] Translate HSK 5 to Polish (DeepL API)
- [ ] Translate HSK 6 to Polish (DeepL API)
- [ ] Update database_helper.dart to load HSK 5-6
- [ ] Update pubspec.yaml assets
- [ ] **Total: 5,440 words (HSK 1-6)**

### Chengyu Database 🎭 ⏳ (Started - 5/100 idioms)
- [x] Design Chengyu data model (成语):
  - [x] Simplified + Traditional
  - [x] Pinyin
  - [x] Literal meaning
  - [x] Actual meaning
  - [x] Example sentence
  - [ ] Origin story
  - [ ] English + Polish translations (English only for now)
- [x] Create first 5 popular chengyu
- [x] Create chengyu browsing UI (card-based layout)
- [ ] Collect remaining 45-95 chengyu
- [ ] Search functionality
- [ ] Category filters (animals, nature, people, etc.)
- [x] Chengyu of the Day feature (on Dashboard)
- [ ] Quiz mode for chengyu

### Spaced Repetition System (SRS) 🔄
- [ ] Implement SM-2 or Leitner algorithm
- [ ] Card scheduling system
- [ ] Due cards counter
- [ ] Review session UI
- [ ] Difficulty rating (Easy/Good/Hard/Again)
- [ ] Integration with My Words
- [ ] SRS statistics dashboard

---

## 🎯 Phase 3 - Advanced Testing (Priority: MEDIUM)

### Fill-in-the-Blank ✍️
- [ ] Design test format (sentence with gap)
- [ ] Multiple choice answers
- [ ] Context-based word selection
- [ ] Grammar focus mode
- [ ] Test results with explanations

### Matching Pairs 🎴
- [ ] Grid layout (4x4 or 5x4)
- [ ] Card flip animations
- [ ] Match Chinese ↔ Polish/English
- [ ] Time challenge mode
- [ ] Scoring system
- [ ] Memory game mechanics

### Sentence Building 🧩
- [ ] Scrambled word order
- [ ] Drag & drop interface
- [ ] Sentence validation
- [ ] Difficulty levels (HSK-based)
- [ ] Grammar pattern focus

---

## 🎯 Phase 4 - Enhanced Learning Features (Priority: MEDIUM)

### Character Breakdown 汉字拆解
- [ ] Radical decomposition
- [ ] Stroke order animation
- [ ] Etymology/origin stories
- [ ] Component meanings
- [ ] Similar characters comparison

### Contextual Examples 例句
- [ ] Add 3-5 example sentences per word
- [ ] Real-world usage contexts
- [ ] Formal vs casual examples
- [ ] Audio for sentences (optional)

### Similar Words Comparison 近义词
- [ ] Group similar words (看 vs 见 vs 看见)
- [ ] Explain subtle differences
- [ ] Usage context guidelines
- [ ] Comparison quiz mode

### Tone Practice Mode 声调练习
- [ ] Visual tone markers
- [ ] Audio comparison
- [ ] Tone identification quiz
- [ ] Pinyin tone training

---

## 🎯 Phase 5 - Gamification & Engagement (Priority: LOW)

### Achievements & Badges 🎖️
- [ ] First 100 words learned
- [ ] 7-day streak
- [ ] 95%+ test accuracy
- [ ] HSK level completed
- [ ] Perfect test score
- [ ] 1000 words mastered

### Study Streaks 🔥
- [ ] Daily streak counter
- [ ] Streak preservation (1 freeze per week)
- [ ] Longest streak record
- [ ] Streak milestones

### XP & Leveling System 🎮
- [ ] XP for completed tests
- [ ] XP for daily login
- [ ] XP for mastered words
- [ ] User level progression
- [ ] Level rewards/unlocks

### Daily Challenges
- [ ] Random daily objectives
- [ ] Bonus XP rewards
- [ ] Challenge variety
- [ ] Completion history

---

## 🎯 Phase 6 - Quality of Life (Priority: LOW)

### Writing Practice 写字练习
- [ ] Canvas for character drawing
- [ ] Stroke order hints
- [ ] Auto-validation
- [ ] Progress tracking

### Dark Mode 🌙
- [ ] Dark theme implementation
- [ ] Theme toggle in settings
- [ ] Persistent theme preference
- [ ] OLED-friendly colors

### Export/Import Progress 💾
- [ ] JSON export of user data
- [ ] Import saved progress
- [ ] Cloud sync (optional, future)
- [ ] Backup reminders

### Reading Practice 📖
- [ ] Short stories by HSK level
- [ ] Click-to-define words
- [ ] Comprehension questions
- [ ] Reading progress tracking

### Word of the Day Notifications 📬
- [ ] Daily push notifications (optional)
- [ ] New word presentation
- [ ] Reminder for daily practice
- [ ] Notification settings

---

## 🎯 Phase 7 - Advanced Content (Priority: OPTIONAL)

### HSK 7-9 Vocabulary
- [ ] Source structured data (~5,636 words)
- [ ] Extract from PDF or find alternative source
- [ ] Add English translations (if available)
- [ ] Polish translations
- [ ] Traditional Chinese conversion
- [ ] **Total: 11,092 words (complete HSK 3.0)**

### Audio Pronunciation 🔊
- [ ] TTS integration (Google/Azure)
- [ ] Native speaker recordings (premium)
- [ ] Pronunciation assessment
- [ ] Listen & repeat mode

### Advanced Statistics 📈
- [ ] Learning velocity chart
- [ ] Retention rate analysis
- [ ] Weak points identification
- [ ] Study time analytics
- [ ] Heatmap calendar

---

## 📝 Notes

### Tech Stack Decisions
- **Traditional Chinese:** OpenCC (Python) for batch conversion
- **Translations:** DeepL API (500k chars/month free tier)
- **Data Scraping:** BeautifulSoup4 + requests
- **Local Storage:** SQLite (desktop), SharedPreferences (web)
- **State Management:** Provider

### Data Sources
- **HSK Vocabulary:** mandarinbean.com
- **Chengyu:** To be determined
- **Audio:** Google Cloud TTS or similar

### Version Planning
- v1.3.0 - Phase 1 (Dashboard + Navigation)
- v1.4.0 - Phase 2 (HSK 5-6 + Chengyu)
- v1.5.0 - Phase 2 (SRS System)
- v1.6.0 - Phase 3 (Advanced Tests)
- v2.0.0 - Complete redesign with all features

---

**Last Updated:** 2025-12-19
**Current Version:** v1.2.0
**Total Words:** 3,229 (HSK 1-4)
**Target:** 11,092 (complete HSK 3.0)
