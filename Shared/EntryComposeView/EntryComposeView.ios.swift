import SwiftUI
import ComposableArchitecture
import SwiftUIX

struct EntryComposeView: View {
    let store: Store<EntryComposeState, EntryComposeAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            List {
                TitleSection(viewStore: viewStore)
                ComponentsSection(viewStore: viewStore, store: store)
                Section {
                    Button("Add paragraph") {
                        viewStore.send(.addParagraph)
                    }
                    Button("Add Headline") {
                        viewStore.send(.addHeadline)
                    }
                    Button("Add Link") {
                        viewStore.send(.addLink)
                    }
                    Button("Add Image") {
                        viewStore.send(.showsImagePicker(true))
                    }.sheet(
                        isPresented: viewStore.binding(get: { $0.showsImagePicker},
                                                       send: EntryComposeAction.showsImagePicker)
                    ) {
                        ImagePicker(
                            data: viewStore.binding(get: { $0.pickedImage },
                                                    send: EntryComposeAction.imageSelectionResponse
                            ),
                            encoding: .jpeg(compressionQuality: 85)
                        )
                    }
                }
                UploadSection(viewStore: viewStore)
            }
            .popover(
                isPresented: viewStore.binding(get: { $0.showsSettings},
                                               send: EntryComposeAction.showSettings)) {
                settingsView(store: store)
            }
            .navigationBarItems(
                leading: Button {
                    viewStore.send(.showSettings(true))
                } label: {
                    Text("Settings")
                },
                trailing: EditButton()
            )
        }
        .navigationTitle("Post")
        .listStyle(InsetGroupedListStyle())
    }

    private func settingsView(store: Store<EntryComposeState, EntryComposeAction>) -> some View {
        let store = store.scope(state: \.settingsState,
                                action: EntryComposeAction.settingsAction)
        return SettingsComponentView(store: store)
    }

    private struct UploadSection: View {
        let viewStore: ViewStore<EntryComposeState, EntryComposeAction>

        var body: some View {
            Section {
                Button {
                    viewStore.send(.upload)
                } label: {
                    Text(viewStore.uploadButtonTitle)
                }
                .disabled(!viewStore.uploadButtonEnabled)
                viewStore.uploadMessage.map {
                    Text($0)
                }
            }
        }
    }

    private struct ComponentsSection: View {
        let viewStore: ViewStore<EntryComposeState, EntryComposeAction>
        let store: Store<EntryComposeState, EntryComposeAction>

        var body: some View {
            Section {
                ForEachStore(
                    self.store.scope(
                        state: \.componentStates,
                        action: EntryComposeAction.composeAction
                    ),
                    content: EntryComposeComponentView.init(store:)
                )
                .onMove { items, position in
                    viewStore.send(.move(items: items, position: position))
                }
            }
        }
    }

    private struct TitleSection: View {
        let viewStore: ViewStore<EntryComposeState, EntryComposeAction>

        var body: some View {
            Section {
                MultilineTextEditor(
                    placeholder: "Title",
                    text: viewStore.binding(
                        get: { $0.title },
                        send: EntryComposeAction.updateTitle(text:)
                    )
                )
            }
        }
    }
}

