# TabView Patterns

Tab-based navigation for organizing top-level app sections. iOS 18 introduced major new capabilities including customizable tab bars and sidebar-adaptive layouts.

## Basic TabView (iOS 16+)

```swift
struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}
```

## Modern TabView with Tab (iOS 18+)

iOS 18 introduced the `Tab` type for more control:

```swift
struct ContentView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                HomeView()
            }

            Tab("Search", systemImage: "magnifyingglass", value: .search) {
                SearchView()
            }

            Tab("Profile", systemImage: "person", value: .profile) {
                ProfileView()
            }
        }
    }
}

enum AppTab: Hashable {
    case home, search, profile
}
```

## Tab Sections and Sidebar (iOS 18+)

On iPad, a `TabView` can present as a sidebar using `.tabViewStyle(.sidebarAdaptable)`. Use `TabSection` to group tabs:

```swift
struct ContentView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                HomeView()
            }

            Tab("Search", systemImage: "magnifyingglass", value: .search) {
                SearchView()
            }

            TabSection("Library") {
                Tab("Favorites", systemImage: "heart", value: .favorites) {
                    FavoritesView()
                }
                Tab("Downloads", systemImage: "arrow.down.circle", value: .downloads) {
                    DownloadsView()
                }
                Tab("History", systemImage: "clock", value: .history) {
                    HistoryView()
                }
            }

            Tab("Settings", systemImage: "gear", value: .settings) {
                SettingsView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}
```

On iPhone, this renders as a standard tab bar (with overflow in "More" if needed). On iPad, it can show as a sidebar with sections.

## Tab Customization (iOS 18+)

Allow users to reorder and hide tabs:

```swift
TabView(selection: $selectedTab) {
    Tab("Home", systemImage: "house", value: .home) {
        HomeView()
    }
    .customizationID("home")            // Enable customization for this tab

    Tab("Search", systemImage: "magnifyingglass", value: .search) {
        SearchView()
    }
    .customizationID("search")

    Tab("Profile", systemImage: "person", value: .profile) {
        ProfileView()
    }
    .customizationID("profile")
    .defaultVisibility(.hidden, for: .tabBar)  // Hidden by default, user can add
}
.tabViewStyle(.sidebarAdaptable)
.tabViewCustomization($customization)   // Bind to persisted customization state

@AppStorage("tabCustomization") private var customization: TabViewCustomization
```

## TabView with NavigationStack Per Tab

Each tab should have its own `NavigationStack` for independent navigation state:

```swift
TabView(selection: $selectedTab) {
    Tab("Home", systemImage: "house", value: .home) {
        NavigationStack {
            HomeView()
                .navigationTitle("Home")
                .navigationDestination(for: Item.self) { item in
                    ItemDetailView(item: item)
                }
        }
    }

    Tab("Search", systemImage: "magnifyingglass", value: .search) {
        NavigationStack {
            SearchView()
                .navigationTitle("Search")
        }
    }
}
```

**Why per-tab stacks?** Each tab maintains its own navigation history. Switching tabs and back preserves the drill-down state.

## Badge

```swift
Tab("Inbox", systemImage: "tray", value: .inbox) {
    InboxView()
}
.badge(unreadCount)  // Shows count badge on tab
```

## Page Style TabView

For swipeable pages (onboarding, image galleries):

```swift
TabView {
    OnboardingPage1()
    OnboardingPage2()
    OnboardingPage3()
}
.tabViewStyle(.page)
.indexViewStyle(.page(backgroundDisplayMode: .always))
```

## Common Mistakes

### NavigationStack Wrapping TabView

```swift
// ❌ Navigation pushes replace the entire tab bar
NavigationStack {
    TabView {
        HomeView()
            .tabItem { Label("Home", systemImage: "house") }
    }
}

// ✅ NavigationStack inside each tab
TabView {
    NavigationStack {
        HomeView()
    }
    .tabItem { Label("Home", systemImage: "house") }
}
```

**Why?** Wrapping `TabView` in a `NavigationStack` means any navigation push hides the tab bar entirely. Each tab should own its own stack.

### Mixing .tabItem and Tab APIs

```swift
// ❌ Don't mix old and new APIs
TabView {
    Tab("Home", systemImage: "house", value: .home) {
        HomeView()
    }
    SearchView()
        .tabItem { Label("Search", systemImage: "magnifyingglass") }
}

// ✅ Use one API consistently
TabView {
    Tab("Home", systemImage: "house", value: .home) { HomeView() }
    Tab("Search", systemImage: "magnifyingglass", value: .search) { SearchView() }
}
```

### Too Many Tabs

```swift
// ❌ More than 5 tabs on iPhone — cluttered, tiny targets
TabView {
    Tab("Home", ...) { }
    Tab("Search", ...) { }
    Tab("Favorites", ...) { }
    Tab("Messages", ...) { }
    Tab("Profile", ...) { }
    Tab("Settings", ...) { }  // 6th tab — bad on iPhone
}

// ✅ Use TabSection with sidebarAdaptable for many sections
// On iPhone: show 4-5 tabs with "More" overflow
// On iPad: show sidebar with all sections
```

Apple HIG recommends 3-5 tabs for iPhone tab bars.

### Programmatic Tab Selection Without Binding

```swift
// ❌ No way to programmatically switch tabs
TabView {
    Tab("Home", systemImage: "house") { HomeView() }
}

// ✅ Use selection binding for programmatic control
@State private var selectedTab: AppTab = .home

TabView(selection: $selectedTab) {
    Tab("Home", systemImage: "house", value: .home) { HomeView() }
}

// Now you can switch tabs programmatically:
selectedTab = .search
```

## Hiding the Tab Bar

On iOS 16+, hide the tab bar when pushing to a detail view:

```swift
NavigationStack {
    ListView()
        .navigationDestination(for: Item.self) { item in
            DetailView(item: item)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
}
```

## Checklist

- [ ] Using `Tab` type (iOS 18+) or `.tabItem` (iOS 16+) consistently
- [ ] Each tab has its own `NavigationStack` (not wrapping `TabView`)
- [ ] Selection binding for programmatic tab switching
- [ ] 3-5 tabs maximum for iPhone (use `TabSection` + `sidebarAdaptable` for more)
- [ ] Badges on tabs where counts are relevant
- [ ] `.tabViewStyle(.sidebarAdaptable)` considered for iPad with many sections
- [ ] Tab bar hidden appropriately in immersive detail views
