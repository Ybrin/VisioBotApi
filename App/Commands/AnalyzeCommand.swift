//
//  AnalyzeCommand.swift
//  App
//
//  Created by Koray Koska on 29.01.19.
//

import Vapor
import TelegramBot
import TelegramBotPromiseKit
import PromiseKit

class AnalyzeCommand: BaseCommand {

    enum Error: Swift.Error {

        case imageDownloadFailed
    }

    static let command: String = "/analyze"

    let message: TelegramMessage

    let token: String

    let apiKey: String

    required init(message: TelegramMessage, token: String, apiKey: String) {
        self.message = message
        self.token = token
        self.apiKey = apiKey
    }

    func run() throws {
        let chat = message.chat
        let chatId = chat.id

        guard let photos = message.replyToMessage?.photo else {
            // TODO: Send message with expenation how to use the /analyze command
            return
        }
        let bestPhoto = photos[photos.count - 1]

        let fileId = bestPhoto.fileId

        let sendApi = TelegramSendApi(token: token)

        sendApi.getFile(fileId: fileId).then { file in
            return ImageDownloader.downloadImage(url: "https://api.telegram.org/file/bot\(self.token)/\(file.filePath ?? "")")
        }.then { imageData -> PromiseKit.Promise<GoogleVisionApiAnnotateResponse> in
            let imageRequest = GoogleVisionApiAnnotateRequest.ImageRequest(
                image: .init(content: imageData.base64EncodedString()),
                features: [
                    .init(type: .labelDetection, maxResults: 10)
                ]
            )
            let visionRequest = GoogleVisionApiAnnotateRequest(requests: [imageRequest])

            return GoogleVisionApi(apiKey: self.apiKey).annotate(request: visionRequest)
        }.done { visionResponse in
            let responses = visionResponse.responses
            guard responses.count > 0, let labels = responses[0].labelAnnotations else {
                // TODO: Something went wrong with the vision api request or we have no assumptions. Inform the user...
                return
            }

            let texts = [
                "Oh I know, it's a",
                "Do you think that's a",
                "This kinda looks like a"
            ]
            for label in labels {
                let l = label.description

                let number = Int.random(in: 0 ..< texts.count)
                let text = "\(texts[number]) *\(l)*"
                let replyMessageId = self.message.replyToMessage?.messageId

                let m = TelegramSendMessage(chatId: chatId, text: text, parseMode: .markdown, replyToMessageId: replyMessageId)

                sendApi.sendMessage(message: m)
            }
        }.catch { err in
            print(err)
        }
    }
}