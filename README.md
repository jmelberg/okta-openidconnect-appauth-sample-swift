# iOS Native Application with AppAuth
Sample application for communicating with OAuth 2.0 and OpenID Connect providers. Demonstrates single-sign-on (SSO) with [AppAuth for iOS](https://github.com/openid/AppAuth-iOS) implemented in Swift.

## Running the Sample with your Okta Organization

###Pre-requisites
This sample application was tested with an Okta org. If you do not have an Okta org, you can easily [sign up for a free Developer Okta org](https://www.okta.com/developer/signup/).

1. Verify OpenID Connect is enabled for your Okta organization. `Admin -> Applications -> Add Application -> Create New App -> OpenID Connect`
  - If you do not see this option, email [developers@okta.com](mailto:developers@okta.com) to enable it.
2. In the **Create A New Application Integration** screen, click the **Platform** dropdown and select **Native app only**
3. Press **Create**. When the page appears, enter an **Application Name**. Press **Next**.
4. Add the reverse DNS notation of your organization to the *Redirect URIs*, followed by a custom route. *(Ex: "com.oktapreview.jordandemo:/oidc")*
5. Click **Finish** to redirect back to the *General Settings* of your application.
6. Select the **Edit** button to configure the **Allowed Grant Types** and **Client Authentication**
  - Ensure *Authorization Code* and *Refresh Token* are selected in **Allowed Grant Types**
  - Verify *Proof Key for Code Exchange (PKCE)* is the default **Client Authentication**
7. **Save** the application.
8. Copy the **Client ID**, as it will be needed for the `Models.swift` configuration file.
9. Finally, select the **People** tab and **Assign to People** in your organization.

### Configure the Sample Application
Once the project is cloned, install [AppAuth](https://github.com/openid/AppAuth-iOS) with [CocoaPods](https://guides.cocoapods.org/using/getting-started.html) by running the following from the project root.

    pod install
    

**Important:** Open `OpenIDConnectSwift.xcworkspace`. This file should be used to run/test your application.

Update the **kIssuer**, **kClientID**, and **kRedirectURI** in your `Models.swift` file:
```swift

class OktaConfiguration {
    ...
    
    init(){
        kIssuer = "https://example.com"       // Base url of Okta Developer domain
        kClientID = "CLIENT_ID"               // Client ID of Application
        kRedirectURI = "com.example:/openid"  // Reverse DNS notation of base url with openid route
        kAppAuthExampleAuthStateKey = "com.okta.openid.authState"
        apiEndpoint = NSURL(string: "https://example.server.com")
    }
}
```

Modify the `Info.plist` file by including a custom URI scheme **without** the route
  - `URL types -> Item 0 -> URL Schemes -> Item 0 ->  <kRedirectURI>` (*Ex: com.oktapreview.jordandemo*)

## Running the Sample Application


| Get Tokens      | Get User Info  | Refresh Token  | Revoke Token   | Call API       | Clear Tokens   |
| :-------------: |:-------------: |:-------------: |:-------------: |:-------------: |:-------------: |
| ![Get Tokens](https://raw.githubusercontent.com/jmelberg/okta-openidconnect-appauth-sample-swift/master/OpenIDConnectSwift/Assets.xcassets/key_circle.imageset/key.png)| ![Get User Info](https://raw.githubusercontent.com/jmelberg/okta-openidconnect-appauth-sample-swift/master/OpenIDConnectSwift/Assets.xcassets/Reporting.imageset/Reporting.png)| ![Refresh Token](https://raw.githubusercontent.com/jmelberg/okta-openidconnect-appauth-sample-swift/master/OpenIDConnectSwift/Assets.xcassets/refresh.imageset/api_call.png)| ![Revoke Token](https://raw.githubusercontent.com/jmelberg/okta-openidconnect-appauth-sample-swift/master/OpenIDConnectSwift/Assets.xcassets/revoke.imageset/revoke.png) | ![Call API](https://raw.githubusercontent.com/jmelberg/okta-openidconnect-appauth-sample-swift/master/OpenIDConnectSwift/Assets.xcassets/refresh.imageset/api_call.png) | ![Clear Tokens](https://raw.githubusercontent.com/jmelberg/okta-openidconnect-appauth-sample-swift/master/OpenIDConnectSwift/Assets.xcassets/ic_key.imageset/MFA_for_Your_Apps.png)|

###Get Tokens
Interacts with the Authorization Server by using the discovered values from the domain's `.well-known/openid-configuration`. If the endpoints are found, AppAuth method `OIDAuthorizationRequest` generates the request by passing in the required scopes and opening up an in-app Safari Browser to get the User credentials.

```swift
// Discovers Endpoints
  OIDAuthorizationService.discoverServiceConfigurationForIssuer(issuer!) {
    config, error in
    ...
    // Build Authentication Request
    let request = OIDAuthorizationRequest(
      configuration: config!,
      clientId: self.appConfig.kClientID,
      scopes: [
        OIDScopeOpenID,  OIDScopeProfile,  OIDScopeEmail,
        OIDScopePhone, OIDScopeAddress,
        "groups", "offline_access"
      ],
      redirectURL: redirectURI!,
      responseType: OIDResponseTypeCode,
      additionalParameters: nil)
    
    ...
  }
```

###Get User Info
If the user is authenticated, fresh tokens are generated for calling the [`/userinfo`](http://developer.okta.com/docs/api/resources/oidc#get-user-information) endpoint to retrieve user data. If received, the output is printed to the console and a UIAlert.

###Refresh Tokens
The AppAuth method `withFreshTokensPerformAction()` is used to refresh the current **access token** if the user is authenticated and the `setNeedsTokenRefresh` flag is set to `true`.
```swift
  func refreshTokens(){
    // Refreshes token
    if checkAuthState() {
      print("Refreshed tokens")
      authState?.setNeedsTokenRefresh()
      authState?.withFreshTokensPerformAction(){
        accessToken, idToken, error in
        
        if(error != nil){
          print("Error fetching fresh tokens: \(error!.localizedDescription)")
          self.createAlert("Error", alertMessage: "Error fetching fresh tokens")
          return
        }
        self.createAlert("Success", alertMessage: "Token was refreshed")
      }
    }
    else {
      print("Not authenticated")
      createAlert("Error", alertMessage: "Not authenticated")
    }
  }
```

###Revoke Tokens
If authenticated, the token is passed to the `/revoke` endpoint to be revoked.

```swift
func revokeToken(){
  // Removes current refresh token on hand and replaces with nil
    if checkAuthState() {
            print("Revoking token..")
            // Call revoke endpoint to terminate access_token
            authState?.withFreshTokensPerformAction(){
                accessToken, idToken, error in
                
                let url = NSURL(string: "\(self.appConfig.kIssuer)/oauth2/v1/revoke")
                let request = NSMutableURLRequest(URL: url!)
                request.HTTPMethod = "POST"
                
                let requestData = "token=\(accessToken!)&client_id=\(self.appConfig.kClientID)"
                request.HTTPBody = requestData.dataUsingEncoding(NSUTF8StringEncoding);
                
                let config = NSURLSessionConfiguration.defaultSessionConfiguration()
                let session = NSURLSession(configuration: config)
                
                //Perform HTTP Request
                ...
            }
        }
    }
```

###Call API
Passes the current access token *(active or inactive)* to a resource server for validation. Returns an api-specific details about the authenticated user.

###Clear Tokens
Sets the current `authState` to `nil`.
