//
//  KeyboardObserver.swift
//  RunestoneEditor
//
//  Created by Simon Støvring on 14/12/2020.
//

import UIKit

protocol KeyboardObserverDelegate: AnyObject {
    func keyboardObserver(
        _ keyboardObserver: KeyboardObserver,
        keyboardWillShowWithHeight keyboardHeight: CGFloat,
        animation: KeyboardObserver.Animation?)
    func keyboardObserverKeyboardWillHide(_ keyboardObserver: KeyboardObserver, animation: KeyboardObserver.Animation?)
    func keyboardObserver(
        _ keyboardObserver: KeyboardObserver,
        keyboardWillChangeHeight keyboardHeight: CGFloat,
        animation: KeyboardObserver.Animation?)
}

extension KeyboardObserverDelegate {
    func keyboardObserver(
        _ keyboardObserver: KeyboardObserver,
        keyboardWillShowWithHeight keyboardHeight: CGFloat,
        animation: KeyboardObserver.Animation?) {}
    func keyboardObserverKeyboardWillHide(_ keyboardObserver: KeyboardObserver, animation: KeyboardObserver.Animation?) {}
    func keyboardObserver(
        _ keyboardObserver: KeyboardObserver,
        keyboardWillChangeHeight keyboardHeight: CGFloat,
        animation: KeyboardObserver.Animation?) {}
}

final class KeyboardObserver {
    struct Animation {
        let duration: TimeInterval
        let curve: UIView.AnimationOptions

        fileprivate init(duration: TimeInterval, curve: UIView.AnimationCurve) {
            self.duration = duration
            self.curve = UIView.AnimationOptions(rawValue: UInt(curve.rawValue << 16))
        }

        func run(animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
            UIView.animate(withDuration: duration, delay: 0, options: curve, animations: animations, completion: completion)
        }
    }

    weak var delegate: KeyboardObserverDelegate?
    private(set) var keyboardHeight: CGFloat = 0
    private(set) var isKeyboardVisible = false

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(notification:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(notification:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

private extension KeyboardObserver {
    @objc private func keyboardWillShow(notification: Notification) {
        let animation = createAnimation(from: notification)
        let newKeyboardHeight = keyboardHeight(from: notification)
        if !isKeyboardVisible {
            keyboardHeight = newKeyboardHeight
            isKeyboardVisible = true
            delegate?.keyboardObserver(self, keyboardWillShowWithHeight: keyboardHeight, animation: animation)
        } else if newKeyboardHeight != keyboardHeight {
            keyboardHeight = newKeyboardHeight
            let animation = createAnimation(from: notification)
            delegate?.keyboardObserver(self, keyboardWillChangeHeight: keyboardHeight, animation: animation)
        }
    }

    @objc private func keyboardWillHide(notification: Notification) {
        if isKeyboardVisible {
            isKeyboardVisible = false
            let animation = createAnimation(from: notification)
            keyboardHeight = 0
            delegate?.keyboardObserverKeyboardWillHide(self, animation: animation)
        }
    }

    @objc private func keyboardWillChangeFrame(notification: Notification) {
        if isKeyboardVisible {
            let newKeyboardHeight = keyboardHeight(from: notification)
            if newKeyboardHeight != keyboardHeight {
                let animation = createAnimation(from: notification)
                delegate?.keyboardObserver(self, keyboardWillChangeHeight: keyboardHeight, animation: animation)
            }
        }
    }

    @objc private func keyboardHeight(from notification: Notification) -> CGFloat {
        let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
        return frame.height
    }

    private func createAnimation(from notification: Notification) -> Animation? {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
        let rawCurve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int
        if let duration = duration, let rawCurve = rawCurve, let curve = UIView.AnimationCurve(rawValue: rawCurve) {
            return Animation(duration: duration, curve: curve)
        } else {
            return nil
        }
    }
}
