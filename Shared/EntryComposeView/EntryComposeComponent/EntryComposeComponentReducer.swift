import Foundation
import ComposableArchitecture
import Combine

let entryComposeComponentReducer = Reducer<EntryComposeComponentState, EntryComposeComponentAction, EntryComposeComponentEnviornment> { state, action, env in
    switch action {
    case .delete:
        return .none
    case .changeText(let text):
        state.componentType = .paragraph(text)
        return .none
    case .changeImage(let url, let filename):
        guard let url = url, let filename = filename else {
            return .none
        }

        state.componentType = .imageURL(url, filename)

        return .none
    case .uploadImageIfNeeded:
        switch state.componentType {
        case .uploadingImage(let data, let startUpload) where startUpload == true:
            guard let accessToken = env.secretsStore.accessToken,
                  let repo = env.secretsStore.repoName else {
                return .none
            }

            state.componentType = .uploadingImage(data, startUpload: false)

            let upload: Future<ImageUploadContent, Error> = env
                .service
                .perform(endpoint: .uploadImage(repo: repo,
                                                 accessToken: accessToken,
                                                 imageData: data,
                                                 postfolder: state.postfolder))
            return upload
                .catchToEffect()
                .map { result in
                    print("Result \(result)")
                    switch result {
                    case .success(let uploadContent):
                        return .changeImage(URL(string: uploadContent.commitResponse.content.downloadUrl), filename: uploadContent.filename)
                    case .failure:
                        return .changeImage(nil, filename: nil)
                    }
                }
        default:
            return .none
        }
    }

}
