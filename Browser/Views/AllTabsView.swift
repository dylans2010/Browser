import SwiftUI

@available(iOS 16.0, *)
struct AllTabsView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @Environment(\.dismiss) var dismiss

    @State private var layout: TabLayout = .grid
    @State private var sortOrder: TabSortOrder = .recent
    @State private var showCreateGroup = false
    @State private var newGroupName = ""
    @State private var newGroupColor: Color = .blue

    enum TabLayout { case grid, list }
    enum TabSortOrder { case recent, title }

    var filteredTabs: [TabItem] {
        let tabs = viewModel.tabs.filter { $0.groupId == viewModel.activeGroupId }
        switch sortOrder {
        case .recent: return tabs.sorted { $0.createdAt > $1.createdAt }
        case .title: return tabs.sorted { $0.title < $1.title }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Toolbar/Options area
                HStack {
                    Picker("Layout", selection: $layout) {
                        Image(systemName: "square.grid.2x2").tag(TabLayout.grid)
                        Image(systemName: "list.bullet").tag(TabLayout.list)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)

                    Spacer()

                    Picker("Sort", selection: $sortOrder) {
                        Text("Recent").tag(TabSortOrder.recent)
                        Text("Title").tag(TabSortOrder.title)
                    }
                    .pickerStyle(.menu)
                }
                .padding()
                .background(.ultraThinMaterial)

                if layout == .grid {
                    gridView
                } else {
                    listView
                }

                // Tab Groups Control at Bottom
                tabGroupsControl
            }
            .navigationTitle(currentGroupTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.addTab()
                        dismiss()
                    }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showCreateGroup) {
                createGroupSheet
            }
        }
    }

    private var currentGroupTitle: String {
        if let groupId = viewModel.activeGroupId, let group = viewModel.tabGroups.first(where: { $0.id == groupId }) {
            return group.name
        }
        return "All Tabs"
    }

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 20)], spacing: 20) {
                ForEach(filteredTabs) { tab in
                    tabButton(tab: tab, isGrid: true)
                }
            }
            .padding()
        }
    }

    private var listView: some View {
        List {
            ForEach(filteredTabs) { tab in
                tabButton(tab: tab, isGrid: false)
            }
        }
        .listStyle(.plain)
    }

    private func tabButton(tab: TabItem, isGrid: Bool) -> some View {
        Button {
            viewModel.activateTab(id: tab.id)
            dismiss()
        } label: {
            if isGrid {
                VStack {
                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.1))
                            .frame(height: 120)
                            .overlay(
                                VStack {
                                    Image(systemName: "globe")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    Text(tab.title)
                                        .font(.caption)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 8)
                                }
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.activeTabId == tab.id ? Color.blue : Color.clear, lineWidth: 3)
                            )

                        Button(action: {
                            viewModel.removeTab(id: tab.id)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .padding(4)
                        }
                        .buttonStyle(.plain)
                    }

                    Text(tab.title)
                        .font(.caption2)
                        .lineLimit(1)
                }
            } else {
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(.secondary)
                    Text(tab.title)
                        .lineLimit(1)
                    Spacer()
                    if viewModel.activeTabId == tab.id {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                    Button(action: {
                        viewModel.removeTab(id: tab.id)
                    }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var tabGroupsControl: some View {
        VStack(spacing: 0) {
            Divider()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    Button(action: { viewModel.activeGroupId = nil }) {
                        Text("All")
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(viewModel.activeGroupId == nil ? Color.blue : Color.secondary.opacity(0.2))
                            .foregroundColor(viewModel.activeGroupId == nil ? .white : .primary)
                            .cornerRadius(20)
                    }

                    ForEach(viewModel.tabGroups) { group in
                        Button(action: { viewModel.activeGroupId = group.id }) {
                            HStack {
                                Circle().fill(Color(hex: group.color)).frame(width: 8, height: 8)
                                Text(group.name)
                            }
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(viewModel.activeGroupId == group.id ? Color.blue : Color.secondary.opacity(0.2))
                            .foregroundColor(viewModel.activeGroupId == group.id ? .white : .primary)
                            .cornerRadius(20)
                        }
                    }

                    Button(action: { showCreateGroup = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
            }
            .background(.ultraThinMaterial)
        }
    }

    private var createGroupSheet: some View {
        NavigationView {
            Form {
                TextField("Group Name", text: $newGroupName)
                ColorPicker("Color", selection: $newGroupColor)
            }
            .navigationTitle("New Tab Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCreateGroup = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.createTabGroup(name: newGroupName, color: newGroupColor.toHex() ?? "#007AFF")
                        newGroupName = ""
                        showCreateGroup = false
                    }
                    .disabled(newGroupName.isEmpty)
                }
            }
        }
    }
}
