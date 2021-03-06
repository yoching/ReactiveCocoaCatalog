//
//  MultipleTextFieldViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2015-09-16.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift

private let MIN_PASSWORD_LENGTH = 4

///
/// Original demo:
/// iOS - ReactiveCocoaをかじってみた - Qiita
/// http://qiita.com/paming/items/9ac189ab0fe5b25fe722
///
class MultipleTextFieldViewController: UIViewController, NibSceneProvider
{
    @IBOutlet var usernameTextField: UITextField?
    @IBOutlet var emailTextField: UITextField?
    @IBOutlet var passwordTextField: UITextField?
    @IBOutlet var password2TextField: UITextField?

    @IBOutlet var messageLabel: UILabel?
    @IBOutlet var okButton: UIButton?

    override func viewDidLoad()
    {
        super.viewDidLoad()

        self._setupViews()
        self._setupProducers()
    }

    func _setupViews()
    {
        self.messageLabel?.text = ""
        self.okButton?.isEnabled = false
    }

    func _setupProducers()
    {

        let usernameProducer = SignalProducer(self.usernameTextField!.reactive.continuousTextValues)
            .map { $0 ?? "" }
            .prefix(value: "")
        let emailProducer = SignalProducer(self.emailTextField!.reactive.continuousTextValues)
            .map { $0 ?? "" }
            .prefix(value: "")
        let passwordProducer = SignalProducer(self.passwordTextField!.reactive.continuousTextValues)
            .map { $0 ?? "" }
            .prefix(value: "")
        let password2Producer = SignalProducer(self.password2TextField!.reactive.continuousTextValues)
            .map { $0 ?? "" }
            .prefix(value: "")

        let combinedProducer = SignalProducer.combineLatest(usernameProducer, emailProducer, passwordProducer, password2Producer)

        // logging
        combinedProducer.startWithValues { print("combinedProducer = \($0)") }

        // create button-enabling stream via any textField change
        let buttonEnablingProducer = combinedProducer
            .map { username, email, password, password2 -> Bool in

                // validation
                let buttonEnabled = username.characters.count > 0 && email.characters.count > 0 && password.characters.count >= MIN_PASSWORD_LENGTH && password == password2
                return buttonEnabled
            }

        // create error-messaging stream via any textField change
        let errorMessagingProducer = combinedProducer
            .map { username, email, password, password2 -> String? in
                switch (username, email, password, password2) {
                    case ("", "", "", ""):
                        return ""
                    case ("", _, _, _):
                        return "Username is not set."
                    case (_, "", _, _):
                        return "Email is not set."
                    case _ where password.characters.count < MIN_PASSWORD_LENGTH:
                        return "Password requires at least \(MIN_PASSWORD_LENGTH) characters."
                    case _ where password != password2:
                        return "Password is not same."
                    default:
                        return ""
                }
            }

        // bind messageLabel
        let d1 = self.messageLabel!.reactive.text
            <~ errorMessagingProducer

        // bind okButton enabled
        let d2 = self.okButton!.reactive.isEnabled
            <~ buttonEnablingProducer

        let compositeDisposable = CompositeDisposable([d1, d2])

        // UI button tap: unbind all
        self.okButton!.reactive.controlEvents(.touchUpInside)
            .observeValues { _ in
                if compositeDisposable.isDisposed {
                    print("Already unbinded.")
                }
                else {
                    print("OK!")
                    compositeDisposable.dispose()
                }
            }
    }
}
