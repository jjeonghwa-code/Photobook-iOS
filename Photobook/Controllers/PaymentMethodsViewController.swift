//
//  PaymentMethodsViewController.swift
//  Shopify
//
//  Created by Jaime Landazuri on 12/09/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Stripe

class PaymentMethodsViewController: UIViewController {
    
    private struct Constants {
        static let creditCardSegueName = "CreditCardSegue"
    }
    
    var order: Order!
    
    @IBOutlet weak var tableView: UITableView!

    private var selectedPaymentMethod: PaymentMethod? {
        get { return order.paymentMethod }
        set { order.paymentMethod = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Analytics.shared.trackScreenViewed(.paymentMethods)
        
        title = NSLocalizedString("PaymentMethods/Title", value: "Payment Methods", comment: "Title for the payment methods screen")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.creditCardSegueName, let destination = segue.destination as? CreditCardTableViewController {
            destination.delegate = self
        }
    }
        
}

extension PaymentMethodsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PaymentAuthorizationManager.availablePaymentMethods.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let availablePaymentMethods = PaymentAuthorizationManager.availablePaymentMethods
        switch availablePaymentMethods[indexPath.item] {
        case .applePay:
            let cell = tableView.dequeueReusableCell(withIdentifier: PaymentMethodTableViewCell.reuseIdentifier, for: indexPath) as! PaymentMethodTableViewCell
            let method = "ApplePay"
            cell.method = method
            cell.icon = UIImage(namedInPhotobookBundle:"apple-pay-method")
            
            let selected = selectedPaymentMethod != nil && selectedPaymentMethod == .applePay
            cell.ticked = selected
            
            cell.separator.isHidden = true
            cell.accessibilityIdentifier = "applePayCell"
            cell.accessibilityLabel = (selected ? CommonLocalizedStrings.accessibilityListItemSelected : "") + method
            cell.accessibilityHint = selected ? nil : CommonLocalizedStrings.accessibilityDoubleTapToSelectListItem
            return cell
        case .payPal:
            let cell = tableView.dequeueReusableCell(withIdentifier: PaymentMethodTableViewCell.reuseIdentifier, for: indexPath) as! PaymentMethodTableViewCell
            let method = "PayPal"
            cell.method = method
            
            cell.icon = UIImage(namedInPhotobookBundle:"paypal-method")
            
            let selected = selectedPaymentMethod != nil && selectedPaymentMethod == .payPal
            cell.ticked = selected
            
            cell.separator.isHidden = false
            cell.accessibilityIdentifier = "payPalCell"
            cell.accessibilityLabel = (selected ? CommonLocalizedStrings.accessibilityListItemSelected : "") + method
            cell.accessibilityHint = selected ? nil : CommonLocalizedStrings.accessibilityDoubleTapToSelectListItem
            return cell
        case .creditCard where indexPath.item != availablePaymentMethods.count - 1: // Saved card
            guard let card = Card.currentCard else { fallthrough }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: PaymentMethodTableViewCell.reuseIdentifier, for: indexPath) as! PaymentMethodTableViewCell
            let method = card.numberMasked
            cell.method = method
            
            cell.icon = card.cardIcon
            
            let selected = selectedPaymentMethod != nil && selectedPaymentMethod == .creditCard
            cell.ticked = selected
            
            cell.separator.isHidden = true
            cell.accessibilityIdentifier = "creditCardCell"
            cell.accessibilityLabel = (selected ? CommonLocalizedStrings.accessibilityListItemSelected : "") + method
            cell.accessibilityHint = selected ? nil : CommonLocalizedStrings.accessibilityDoubleTapToSelectListItem
            return cell
        default:
            return tableView.dequeueReusableCell(withIdentifier: "AddPaymentMethodCell", for: indexPath)
        }
    }
}

extension PaymentMethodsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 44 : 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? NSLocalizedString("PaymentMethods/Header", value: "Your Methods", comment: "Payment method selection screen header") : nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let supportsApplePay = PaymentAuthorizationManager.isApplePayAvailable ? 1 : 0
        
        switch indexPath.item {
        case -1 + supportsApplePay: // Apple Pay
            selectedPaymentMethod = .applePay
        case 0 + supportsApplePay: // PayPal
            selectedPaymentMethod = .payPal
        case 1 + supportsApplePay: // Saved card
            guard Card.currentCard != nil else { fallthrough }
            
            selectedPaymentMethod = .creditCard
        default: // Add Payment Method
            performSegue(withIdentifier: Constants.creditCardSegueName, sender: nil)
        }
        
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let cardIndex = PaymentAuthorizationManager.isApplePayAvailable ? 2 : 1
        return indexPath.row == cardIndex && Card.currentCard != nil
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        Card.currentCard = nil
        if PaymentAuthorizationManager.isApplePayAvailable { selectedPaymentMethod = .applePay }
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
}

extension PaymentMethodsViewController: CreditCardTableViewControllerDelegate {

    func didAddCreditCard(on viewController: CreditCardTableViewController) {
        navigationController?.popViewController(animated: true)
    }
}
