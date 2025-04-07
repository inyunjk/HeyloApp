import UIKit

// Extension to find the current first responder
extension UIResponder {
    private static weak var _currentFirstResponder: UIResponder?

    static var currentFirstResponder: UIResponder? {
        _currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(UIResponder.findFirstResponder(_:)), to: nil, from: nil, for: nil)
        return _currentFirstResponder
    }

    @objc private func findFirstResponder(_ sender: Any) {
        UIResponder._currentFirstResponder = self
    }
}

extension UIViewController {

    // MARK: - Keyboard Handling
    func setupKeyboardHandling() {
        // Add keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    func removeKeyboardHandling() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let activeTextField = UIResponder.currentFirstResponder as? UITextField else { return }

        // Convert the text field's frame to the view's coordinate system
        let textFieldFrame = activeTextField.convert(activeTextField.bounds, to: view)
        let textFieldBottom = textFieldFrame.origin.y + textFieldFrame.size.height

        // Calculate the bottom of the visible area when the keyboard is shown
        let visibleAreaBottom = view.frame.height - keyboardSize.height

        // Calculate how much we need to scroll to make the text field visible
        let buttonOffset: CGFloat = 100 // Extra space for buttons below the text field
        let offset = textFieldBottom + buttonOffset - visibleAreaBottom

        if offset > 0 && self.view.frame.origin.y == 0 {
            // Only scroll if needed and if we haven't already scrolled
            UIView.animate(withDuration: 0.3) {
                self.view.frame.origin.y = -offset
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            UIView.animate(withDuration: 0.3) {
                self.view.frame.origin.y = 0
            }
        }
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
