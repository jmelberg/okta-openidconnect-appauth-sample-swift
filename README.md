# iOS Native Application with AppAuth
Sample application for communicating with OAuth 2.0 and OpenID Connect providers. Demonstrates single-sign-on (SSO) with [AppAuth for iOS](https://github.com/openid/AppAuth-iOS) implemented in Swift.

## Installation
This sample application was tested with an Okta org. If you do not have an Okta org, you can easily [sign up for a free Developer Okta org](https://www.okta.com/developer/signup/).

### Okta Application:
To properly set up an application that supports OAuth 2.0 and OpenID Connect, follow these steps.
  - Application Type
    - Native
  - Allowed Grant Types
    - Authorization Code, Refresh Token
  - Redirect URI:
    - Reverse DNS with route (*Ex: com.otkapreview.jordandemo:/openid*)
  - Client Credientials
    - Proof Key for Code Exchange

### Sample Application
Once the project is cloned, install [AppAuth](https://github.com/openid/AppAuth-iOS) with [CocoaPods](https://guides.cocoapods.org/using/getting-started.html) by running the following from the project root.

    pod install
    

**Important:** Open `OpenIDConnectSwift.xcworkspace`. This file should be used to run/test your application.


Update the following in your `Models.swift` file:
  - kIssuer
    - Your okta/oktapreview domain (*Ex: https://jordandemo.oktapreview.com*)
  - kClientID
   	- Okta Application ID
  - kRedirectURI
    - Reverse DNS w/ route (*Ex: com.oktapreview.jordandemo:/openid*)

Modify the `Info.plist` file by including a custom URI scheme 
  - URL types -> Item 0 -> URL Schemes -> Item 0 -> kRedirectURI without route (*Ex: com.oktapreview.jordandemo*)
