import SwiftUI

struct RootTabView: View {
    var openSettingsOnAppear: Bool = false

    @State private var selectedTab = 0
    @State private var showingSettings = false
    @State private var searchText = ""
    @State private var selectedGameGenre = "Все"
    @State private var selectedAppCategory = "Все"
    @State private var sortOrder: AppSortOrder = .date
    @State private var searchHistory: [String] = UserDefaults.standard.stringArray(forKey: StoreConfig.searchHistoryKey) ?? []

    private let gameGenres = ["Все", "Экшен", "Гонки", "Стратегии", "Аркады"]
    private let appCategories = ["Все", "Банки", "Фото и видео", "Музыка", "Соцсети", "Утилиты"]

    private let sampleApps: [AppItem] = [
        AppItem(name: "Neon Drift", subtitle: "Ночной заезд начинается здесь", category: .racing, popularity: 97, isFeatured: true),
        AppItem(name: "Pocket Tactics", subtitle: "Тактика в кармане", category: .strategy, popularity: 89, isFeatured: true),
        AppItem(name: "Retro Arcade", subtitle: "Классика без лишнего шума", category: .arcade, popularity: 82),
        AppItem(name: "Photo Studio", subtitle: "Инструменты для творчества", category: .photoVideo, popularity: 93),
        AppItem(name: "Music Box", subtitle: "Твоя музыка в одном месте", category: .music, popularity: 88),
        AppItem(name: "Utility Kit", subtitle: "Маленькие инструменты на каждый день", category: .utilities, popularity: 75)
    ]

    var body: some View {
        ZStack {
            OrganicBackground()

            TabView(selection: $selectedTab) {
                todayView
                    .tabItem { Label("Сегодня", systemImage: "sparkles") }
                    .tag(0)

                gamesView
                    .tabItem { Label("Игры", systemImage: "gamecontroller.fill") }
                    .tag(1)

                appsView
                    .tabItem { Label("Приложения", systemImage: "square.grid.2x2.fill") }
                    .tag(2)

                searchView
                    .tabItem { Label("Поиск", systemImage: "magnifyingglass") }
                    .tag(3)
            }
            .tint(ThemeConfig.neonPink)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            if openSettingsOnAppear {
                showingSettings = true
            }
        }
    }

    private var todayView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header(title: "Сегодня", subtitle: "Твоя витрина приложений")

                RoseGlassCard {
                    HStack(spacing: 14) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(ThemeConfig.roseGradient)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Состояние сертификата").font(.headline)
                            Text("Добавь сертификат в настройках, чтобы проверить профиль.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.65))
                        }
                        Spacer(minLength: 0)
                    }
                }

                sectionHeader("Свежие моды", action: "Смотреть все")
                appRow(sampleApps[0])
                appRow(sampleApps[3])

                sectionHeader("Возвращение легенд", action: "Подборка")
                RoseGlassCard {
                    HStack {
                        Image(systemName: "heart.rectangle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(ThemeConfig.roseGradient)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Приложения вне App Store").font(.headline)
                            Text("Каталог совместимых и архивных релизов — наличие зависит от источника.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.62))
                        }
                    }
                }
            }
            .padding(18)
        }
    }

    private var gamesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header(title: "Игры", subtitle: "Выбирай свой режим")
                chipScroller(items: gameGenres, selection: $selectedGameGenre)
                sectionHeader("Витрина новинок", action: "Все игры")
                ForEach(sampleApps.filter { $0.category.isGame && (selectedGameGenre == "Все" || $0.category.rawValue == selectedGameGenre) }) { app in
                    appRow(app)
                }
                if sampleApps.filter({ $0.category.isGame && (selectedGameGenre == "Все" || $0.category.rawValue == selectedGameGenre) }).isEmpty {
                    emptyState("Пока пусто", detail: "В этой категории скоро появятся игры.")
                }
            }
            .padding(18)
        }
    }

    private var appsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header(title: "Приложения", subtitle: "Полезное на каждый день")
                chipScroller(items: appCategories, selection: $selectedAppCategory)
                ForEach(sampleApps.filter {
                    !$0.category.isGame && (selectedAppCategory == "Все" || $0.category.rawValue == selectedAppCategory)
                }) { app in
                    appRow(app)
                }
                if sampleApps.filter({ !$0.category.isGame && (selectedAppCategory == "Все" || $0.category.rawValue == selectedAppCategory) }).isEmpty {
                    emptyState("Категория пуста", detail: "Здесь появятся приложения из выбранной категории.")
                }
            }
            .padding(18)
        }
    }

    private var searchView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header(title: "Поиск", subtitle: "Найди нужное быстрее")

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(ThemeConfig.neonPink)
                    TextField("Название или категория", text: $searchText)
                        .submitLabel(.search)
                        .onSubmit { rememberSearch() }
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.white.opacity(0.55))
                        }
                    }
                }
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(ThemeConfig.glassStroke, lineWidth: 1))

                Menu {
                    Picker("Сортировка", selection: $sortOrder) {
                        ForEach(AppSortOrder.allCases) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                } label: {
                    Label(sortOrder.rawValue, systemImage: "arrow.up.arrow.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }

                if searchText.isEmpty && !searchHistory.isEmpty {
                    sectionHeader("Недавние запросы", action: "Очистить")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(searchHistory, id: \.self) { term in
                                Button(term) {
                                    searchText = term
                                }
                                .buttonStyle(.bordered)
                                .tint(ThemeConfig.neonPink)
                            }
                            Button("Очистить") {
                                searchHistory = []
                                UserDefaults.standard.removeObject(forKey: StoreConfig.searchHistoryKey)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                let results = filteredSearchResults
                if results.isEmpty {
                    emptyState("Ничего не найдено", detail: "Попробуй другое название или категорию.")
                } else {
                    ForEach(results) { app in appRow(app) }
                }
            }
            .padding(18)
        }
    }

    private var filteredSearchResults: [AppItem] {
        let filtered = sampleApps.filter {
            searchText.isEmpty ||
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.subtitle.localizedCaseInsensitiveContains(searchText) ||
            $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
        }

        switch sortOrder {
        case .date:
            return filtered.sorted { $0.releaseDate > $1.releaseDate }
        case .size:
            return filtered.sorted { ($0.fileSizeBytes ?? 0) > ($1.fileSizeBytes ?? 0) }
        case .popularity:
            return filtered.sorted { $0.popularity > $1.popularity }
        }
    }

    private func header(title: String, subtitle: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            if title == "Сегодня" {
                Button {
                    HapticManager.light()
                    showingSettings = true
                } label: {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 38))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, ThemeConfig.rose)
                        .padding(3)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(ThemeConfig.glassStroke, lineWidth: 1))
                }
                .accessibilityLabel("Открыть настройки")
            }
        }
        .padding(.bottom, 4)
    }

    private func sectionHeader(_ title: String, action: String) -> some View {
        HStack {
            Text(title).font(.title3.bold()).foregroundStyle(.white)
            Spacer()
            Button(action) {
                if action == "Очистить" {
                    searchHistory = []
                    UserDefaults.standard.removeObject(forKey: StoreConfig.searchHistoryKey)
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(ThemeConfig.neonPink)
        }
    }

    private func chipScroller(items: [String], selection: Binding<String>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(items, id: \.self) { item in
                    Button {
                        HapticManager.light()
                        selection.wrappedValue = item
                    } label: {
                        Text(item)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                selection.wrappedValue == item ? ThemeConfig.rose.opacity(0.35) : Color.white.opacity(0.07),
                                in: Capsule()
                            )
                            .overlay(Capsule().stroke(selection.wrappedValue == item ? ThemeConfig.neonPink.opacity(0.8) : Color.white.opacity(0.13), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func appRow(_ app: AppItem) -> some View {
        RoseGlassCard {
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(ThemeConfig.roseGradient.opacity(0.28))
                        .frame(width: 58, height: 58)
                    Image(systemName: app.category.isGame ? "gamecontroller.fill" : "app.fill")
                        .font(.title2)
                        .foregroundStyle(ThemeConfig.roseGradient)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name).font(.headline).foregroundStyle(.white)
                    Text(app.subtitle).font(.caption).foregroundStyle(.white.opacity(0.62)).lineLimit(2)
                    Text(app.category.rawValue).font(.caption2).foregroundStyle(ThemeConfig.neonPink)
                }
                Spacer(minLength: 4)
                Button {
                    HapticManager.medium()
                } label: {
                    Text("ЗАГРУЗИТЬ")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .background(ThemeConfig.roseGradient, in: Capsule())
                }
                .accessibilityLabel("Подготовить загрузку \(app.name)")
                .contextMenu {
                    Button("Сменить Bundle ID", systemImage: "app.badge") {
                        alertNotImplemented("Смена Bundle ID доступна после подключения движка пересборки.")
                    }
                    Button("Клонировать приложение", systemImage: "plus.square.on.square") {
                        alertNotImplemented("Клонирование требует пересборки пакета и проверки подписи.")
                    }
                    Button("Инъекция dylib", systemImage: "puzzlepiece.extension") {
                        alertNotImplemented("Инъекция dylib требует отдельного совместимого инструмента сборки.")
                    }
                }
            }
        }
    }

    private func emptyState(_ title: String, detail: String) -> some View {
        RoseGlassCard {
            VStack(spacing: 8) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 30))
                    .foregroundStyle(ThemeConfig.roseGradient)
                Text(title).font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    private func rememberSearch() {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }
        searchHistory.removeAll { $0.caseInsensitiveCompare(term) == .orderedSame }
        searchHistory.insert(term, at: 0)
        searchHistory = Array(searchHistory.prefix(StoreConfig.maxSearchHistoryItems))
        UserDefaults.standard.set(searchHistory, forKey: StoreConfig.searchHistoryKey)
    }

    private func alertNotImplemented(_ message: String) {
        // The menu action is intentionally safe until a real package-processing engine is added.
        HapticManager.warning()
        print("[GeraKStore] \(message)")
    }
}
