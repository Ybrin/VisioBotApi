//
//  BotController.swift
//  App
//
//  Created by Koray Koska on 24.01.19.
//

import Foundation
import TelegramBot

final class BotController {

    let botName: String

    let token: String

    let apiKey: String

    init(botName: String, token: String, apiKey: String) {
        self.botName = botName
        self.token = token
        self.apiKey = apiKey
    }

    func getMessage(id: Int, message: TelegramMessage) {
        print("TestDebug")
        let commands: [BaseCommand.Type] = [StartCommand.self, AnalyzeCommand.self, PhotoCommand.self]

        var correctCommands: [BaseCommand] = []
        for command in commands {
            if command.isParsable(message: message, botName: botName) {
                correctCommands.append(command.init(message: message, token: token, apiKey: apiKey))
            }
        }

        for command in correctCommands {
            try? command.run()
        }
    }

    func getCallback(id: Int, callback: TelegramCallbackQuery) {
        let callbackQueries: [BaseCallbackQuery.Type] = [AnalyzeInlineCallbackQuery.self]

        var correctCallbackQueries: [BaseCallbackQuery] = []
        for query in callbackQueries {
            if query.isParsable(callbackQuery: callback) {
                correctCallbackQueries.append(query.init(callbackQuery: callback, token: token, apiKey: apiKey))
            }
        }

        for query in correctCallbackQueries {
            try? query.run()
        }
    }
}
