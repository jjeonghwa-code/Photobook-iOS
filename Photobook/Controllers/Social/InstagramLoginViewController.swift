//
//  InstagramLoginViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 15/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import OAuthSwift
import WebKit
import KeychainSwift

class InstagramLoginViewController: UIViewController {
    
    private var webView: WKWebView = WKWebView()
    
    private lazy var instagramClient: OAuth2Swift = {
        let client = OAuth2Swift.instagramClient()
        client.authorizeURLHandler = self
        return client
    }()
    private lazy var emptyScreenViewController: EmptyScreenViewController = {
        return EmptyScreenViewController.emptyScreen(parent: self)
    }()

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        webView.frame = view.bounds
        view.insertSubview(webView, at: 0)
        
        startAuthenticatingUser()
    }
    
    private func startAuthenticatingUser() {
        activityIndicatorView.startAnimating()
        
        // Before doing anything, clear any web data left over from a previous session
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), completionHandler: { records in
            for record in records {
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        })
        
        instagramClient.authorize(withCallbackURL: URL(string: OAuth2Swift.Constants.redirectUri)!, scope: OAuth2Swift.Constants.scope, state:"INSTAGRAM",
            success: { [weak welf = self] credential, response, parameters in
                KeychainSwift().set(credential.oauthToken, forKey: OAuth2Swift.Constants.keychainInstagramTokenKey)
                let instagramAssetPicker = AssetPickerCollectionViewController.instagramAssetPicker()
                instagramAssetPicker.delegate = instagramAssetPicker
                welf?.navigationController?.setViewControllers([instagramAssetPicker], animated: false)
        }, failure: { [weak welf = self] error in
            welf?.emptyScreenViewController.show(ErrorUtils.genericRetryErrorMessage(message: error.localizedDescription, action: { [weak welf = self] in
                welf?.emptyScreenViewController.hide()
                welf?.startAuthenticatingUser()
            }))
        })
    }
}

extension InstagramLoginViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.allow); return }
        
        // Intercept the redirectUri. User has logged in successfully
        guard !url.absoluteString.hasPrefix(OAuth2Swift.Constants.redirectUri) else {
            webView.stopLoading()
            activityIndicatorView.stopAnimating()
            
            OAuthSwift.handle(url: url)
            decisionHandler(.cancel)
            return
        }
        
        // Intercept the password reset link and open in it Safari. Currently redirects to https://www.instagram.com/accounts/password/reset/
        guard !(url.absoluteString.contains("password") && url.absoluteString.contains("reset")) else {
            decisionHandler(.cancel)
            
            let alertController = UIAlertController(title: NSLocalizedString("Social/Instagram/ResetPasswordTitle", value: "Reset Instagram Password?", comment: "Alert title asking to reset the user's Instagram password"), message: NSLocalizedString("Social/Instagram/ResetPasswordMessage", value: "This will open Safari so you can reset your password. Please return here when you are done.", comment: "Instructions for resetting the user's Instagram password"), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: CommonLocalizedStrings.alertOK, style: .default, handler: { _ in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }))
            alertController.addAction(UIAlertAction(title: CommonLocalizedStrings.cancel, style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
            return
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard let statusCode = (navigationResponse.response as? HTTPURLResponse)?.statusCode,
            statusCode == 200 || statusCode == 404 else {
                emptyScreenViewController.show(ErrorUtils.genericRetryErrorMessage(message: NSLocalizedString("General/PleaseTryAgain", value: "Please try again", comment: "Message telling the user to retry their action"), action: { [weak welf = self] in
                    welf?.webView.loadHTMLString("", baseURL: nil)
                    welf?.emptyScreenViewController.hide(animated: true)
                }))
                decisionHandler(.cancel)
                return
        }
        
        guard statusCode != 404 else {
            let serviceName = "Instagram"
            let alertController = UIAlertController(title: NSLocalizedString("Social/CouldNotLoginTitle", value: "Could not log in to \(serviceName)", comment: "Title saying we couldn't login to a social service eg Instagram/Facebook"), message: NSLocalizedString("Social/CouldNotLoginMessage", value: "Please check your username and password and try again", comment: "Message asking the user to check their username and password and try again"), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("GenericAlert/OK", value: "OK", comment: "Acknowledgement to an alert dialog"), style: .default, handler: nil))
            
            present(alertController, animated: true, completion: nil)
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicatorView.stopAnimating()
        
        if webView.url?.absoluteString == "about:blank" {
            startAuthenticatingUser()
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // We cancelled the navigation ourselves
        guard (error as NSError).code != 102 else {
            return
        }
        
        emptyScreenViewController.show(ErrorUtils.genericRetryErrorMessage(message: error.localizedDescription, action: { [weak welf = self] in
            welf?.emptyScreenViewController.hide()
            welf?.startAuthenticatingUser()
        }))
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // We cancelled the navigation ourselves
        guard (error as NSError).code != 102 else {
            return
        }
        
        emptyScreenViewController.show(ErrorUtils.genericRetryErrorMessage(message: error.localizedDescription, action: { [weak welf = self] in
            welf?.emptyScreenViewController.hide()
            welf?.startAuthenticatingUser()
        }))
    }
    
}

extension InstagramLoginViewController: OAuthSwiftURLHandlerType {
    func handle(_ url: URL) {
        webView.load(URLRequest(url: url))
    }
    
    
}
