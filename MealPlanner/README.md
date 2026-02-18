# Family Dinner Planner — iOS App

A native iOS app that helps your family plan dinners by scanning your fridge and pantry,
learning everyone's food preferences, and suggesting personalized recipes.

## Features

- **Scan fridge & pantry** — take a photo and AI identifies all your food items
- **Family profiles** — a profile for each family member with dietary restrictions, allergies, liked/disliked ingredients
- **Smart recipe suggestions** — recipes generated based on what you actually have and who's eating
- **Weekly meal planner** — plan dinners for the week, view ingredients and steps
- **Post-meal feedback** — rate meals per family member; profiles update automatically

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI |
| Database | Firebase Firestore |
| Image storage | Firebase Storage |
| Food recognition | OpenAI GPT-4o Vision |
| Recipe generation | OpenAI GPT-4o |

## Setup

### 1. Firebase
1. Go to [console.firebase.google.com](https://console.firebase.google.com) and create a project
2. Add an iOS app with bundle ID `com.yourfamily.mealplanner`
3. Download `GoogleService-Info.plist` and add it to the `MealPlanner/` folder in Xcode
4. Enable **Firestore** and **Storage** in the Firebase console

### 2. OpenAI API Key
1. Get an API key from [platform.openai.com](https://platform.openai.com)
2. Open `MealPlanner/Info.plist` and replace `YOUR_OPENAI_API_KEY_HERE` with your key

### 3. Generate Xcode project
```bash
brew install xcodegen
cd MealPlanner
xcodegen generate
open MealPlanner.xcodeproj
```

### 4. Build & run
- Select an iPhone simulator or a real device
- Press ⌘R

## Project Structure

```
MealPlanner/
├── MealPlannerApp.swift        # App entry point, environment setup
├── Info.plist                  # Keys: camera, photo library, OpenAI
├── Models/
│   ├── FamilyMember.swift      # Profile + FoodPreferences + MealRating
│   ├── FoodItem.swift          # Individual ingredient/item
│   ├── Recipe.swift            # Recipe with ingredients + instructions
│   └── MealPlan.swift          # Planned dinner + feedback
├── Services/
│   ├── FirebaseService.swift   # All Firestore & Storage operations
│   ├── VisionService.swift     # GPT-4o Vision food identification
│   └── RecipeService.swift     # GPT-4o recipe generation
├── ViewModels/
│   ├── FamilyViewModel.swift   # Family CRUD + preference updates
│   ├── InventoryViewModel.swift# Fridge/pantry/freezer management
│   ├── MealPlanViewModel.swift # Weekly plan + suggestions
│   └── FeedbackViewModel.swift # Post-meal feedback + profile sync
└── Views/
    ├── HomeView.swift           # Dashboard: tonight's dinner + quick actions
    ├── InventoryView.swift      # Browse/add food items per location
    ├── CameraView.swift         # Scan photo + review identified items
    ├── FamilyProfilesView.swift # List, add, edit family members
    ├── WeeklyMealPlanView.swift # 7-day planner + recipe detail
    └── PostMealFeedbackView.swift # Per-member star ratings → updates profiles
```

## How preference learning works

1. After a meal, you rate it 1–5 stars for each family member
2. **≥ 4 stars** → all recipe ingredients are added to that member's **liked** list
3. **≤ 2 stars** → ingredients are added to **disliked** list
4. Next time recipes are generated, the AI is told each person's liked/disliked ingredients
5. Over time, suggestions get increasingly personalised
