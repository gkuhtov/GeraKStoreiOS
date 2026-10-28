import SwiftUI

public struct SearchView: View {
    @ObservedObject var theme = ThemeConfig.shared
    @ObservedObject var catalog = CatalogService.shared

    @State private var searchText = ""
    @State private var recentSearches = ["BHTikTok", "Сбербанк", "Asphalt", "Т-Банк"]
    @State private var selectedSort = "По дате"
    @State private var showSortSheet = false

    private let sortOptions = ["По дате", "По размеру", "По популярности", "По названию (А-Я)"]

    public init() {}

    private var searchResults: [AppItem] {
        if searchText.isEmpty {
            return []
        }
        var results = catalog.allApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.subcategory.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleId.localizedCaseInsensitiveContains(searchText)
        }

        switch selectedSort {
        case "По названию (А-Я)":
            results.sort { $0.name < $1.name }
        default:
            break
        }
        return results
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)

                        TextField("Игры, программы, твики...", text: $searchText)
                            .foregroundColor(.white)
                            .autocorrectionDisabled()

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Button(action: {
                        HapticManager.shared.tap()
                        showSortSheet = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        if searchText.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("НЕДАВНИЕ ЗАПРОСЫ")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Button("Очистить") {
                                        HapticManager.shared.tap()
                                        recentSearches.removeAll()
                                    }
                                    .font(.system(size: 12))
                                    .foregroundColor(theme.rosePrimary)
                                }

                                ForEach(recentSearches, id: \.self) { query in
                                    HStack {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)

                                        Text(query)
                                            .font(.system(size: 15))
                                            .foregroundColor(.primary)

                                        Spacer()

                                        Image(systemName: "arrow.up.left")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 6)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        searchText = query
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        } else {
                            Text("Результаты для «\(searchText)» (\(searchResults.count))")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.top, 10)

                            LazyVStack(spacing: 12) {
                                ForEach(searchResults) { item in
                                    AppItemRow(app: item)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .background(theme.canvasBackground.ignoresSafeArea())
            .navigationTitle("Поиск")
            .confirmationDialog("Сортировка каталога", isPresented: $showSortSheet, titleVisibility: .visible) {
                ForEach(sortOptions, id: \.self) { option in
                    Button(option) {
                        HapticManager.shared.tap()
                        selectedSort = option
                    }
                }
            }
        }
    }
}
