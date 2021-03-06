import Foundation
import ComposableArchitecture
import Combine

let entryComposeReducer = Reducer<EntryComposeState, EntryComposeAction, EntryComposeEnviornment>.combine(
    entryComposeComponentReducer.forEach(state: \EntryComposeState.componentStates,
                                         action: /EntryComposeAction.composeAction,
                                         environment: { env in
                                            EntryComposeComponentEnviornment(
                                                client: env.client,
                                                secretsStore: env.secretsStore
                                            )
                                         }),
    Reducer { state, action, enviornment in
        switch action {
        case .updateTitle(let title):
            state.title = title
            return .none
        case .addParagraph:
            let paragraphState = EntryComposeComponentState(componentType: .paragraph(""))
            state.componentStates.append(paragraphState)
            return .none
        case .addHeadline:
            let paragraphState = EntryComposeComponentState(componentType: .headline(""))
            state.componentStates.append(paragraphState)
            return .none
        case .addLink:
            let linkState = EntryComposeComponentState(componentType: .link(title: "", urlString: ""))
            state.componentStates.append(linkState)
            return .none
        case .selectImage:
            state.showsImagePicker = true
            return .none
        case .imageSelectionResponse(let data):
            if let data = data {
                let uploadingState = EntryComposeComponentState(componentType: .uploadingImage(data))
                state.componentStates.append(uploadingState)
            }
            
            return .none
        case .composeAction(let index, let action):
            switch action {
            case .delete:
                state.componentStates.remove(at: index)
                return .none
            default:
                return .none
            }
        case .settingsAction(let action):
            switch action {
            case .dismiss:
                state.showsSettings = false

                state.uploadButtonEnabled = true
                state.uploadMessage = nil
                return .none
            default:
                return .none
            }
        case .showSettings(let show):
            state.showsSettings = show

            return .none
        case .showsImagePicker(let newValue):
            state.showsImagePicker = newValue
            return .none
        case .move(let items, let position):
            state.componentStates.move(fromOffsets: items, toOffset: position)
            return .none
        case .uploadPost:
            guard let location = enviornment.secretsStore.contentLocation(for: state.settingsState.blogConfig) else {
                state.uploadMessage = "Not logged in"
                state.uploadButtonEnabled = false

                return .none
            }

            let content = state.componentStates.compactMap { state in
                state.toContentPart()
            }

            let postContent = PostContent(
                location: location,
                date: state.date,
                title: state.title,
                postfolder: state.date.iso8601withFractionalSeconds,
                content: content)

            let service = MyWeBlogService(baseURL: URL(string: state.settingsState.blogConfig.urlString)!,
                                          client: enviornment.client)
            let upload: Future<Empty, Error> = service
                .perform(endpoint: .createEntry(postContent))
            return upload
                .catchToEffect()
                .map { result in
                    switch result {
                    case .success:
                        return .uploadSuccess(true)
                    case .failure:
                        return .uploadSuccess(false)
                    }
                }
        case .uploadSuccess(let success):
            state.uploadButtonEnabled = true

            if success {
                state.uploadButtonTitle = "Upload"
                state.componentStates = []
                state.title = ""
            } else {
                state.uploadButtonTitle = "Upload failed, try again"
            }

            return .none
        case .uploadImage(let position):
            let position = position
            var imageState = state.componentStates[position]
            guard let location = enviornment.secretsStore.contentLocation(for: state.settingsState.blogConfig),
                  case .uploadingImage(let data) = imageState.componentType else {
                return .none
            }

            let service = MyWeBlogService(baseURL: URL(string: state.settingsState.blogConfig.urlString)!,
                                          client: enviornment.client)
            let upload: Future<ImageUploadContent, Error> = service
                .perform(endpoint: .uploadImage(contentLocation: location,
                                                imageData: data,
                                                postfolder: state.date.iso8601withFractionalSeconds))
            return upload
                .catchToEffect()
                .map { result in
                    print("Result \(result)")
                    switch result {
                    case .success(let uploadContent):
                        imageState.componentType = .imageURL(data,
                                                             uploadContent.filename)
                        return .uploadedImage(position, uploadContent, data)
                    case .failure:
                        return .uploadSuccess(false)
                    }
                }
        case .upload:
            state.uploadButtonTitle = "Uploading"
            state.uploadButtonEnabled = false

            for (index, state) in state.componentStates.enumerated() {
                if case .uploadingImage(_) = state.componentType {
                    return Effect(value: EntryComposeAction.uploadImage(position: index))
                }
            }

            return Effect(value: EntryComposeAction.uploadPost)
        case .uploadedImage(let position, let uploadContent, let data):
            var imageState = state.componentStates[position]
            imageState.componentType = .imageURL(data,
                                                 uploadContent.filename)
            state.componentStates[position] = imageState
            return Effect(value: .upload)
        case .deleteBlog:
            // Handled by BlogSelector reducer
            return .none
        }
    },
    settingsComponentReducer.pullback(state: \EntryComposeState.settingsState,
                                      action: /EntryComposeAction.settingsAction,
                                      environment: { env in
                                        return SettingsComponentEnviornment(secretsStore: env.secretsStore,
                                                                            configStore: env.configStore)
                                      })
    )

