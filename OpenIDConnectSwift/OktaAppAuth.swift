// OktaAppAuth.swift

import UIKit
import AppAuth


class OktaAppAuth: UIViewController, OIDAuthStateChangeDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var tokensButton: UIImageView!
    @IBOutlet weak var apiCallIcon: UIImageView!
    @IBOutlet weak var userInfoIcon: UIImageView!
    @IBOutlet weak var accessTokenIcon: UIImageView!
    @IBOutlet weak var refreshTokenIcon: UIImageView!
    @IBOutlet weak var revokeTokenIcon: UIImageView!
    @IBOutlet weak var clearIcon: UIImageView!
    @IBOutlet weak var userInfoButton: UIButton!
    @IBOutlet weak var refreshTokensButton: UIButton!
    @IBOutlet weak var callApiButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var revokeTokensButton: UIButton!
    
    // Okta Configuration
    var appConfig = OktaConfiguration()
    
    // AppAuth authState
    var authState:OIDAuthState?

    override func viewDidLoad() {
        super.viewDidLoad()
        connectIcons()
        self.loadState()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    /**
     *  Saves the current authState into NSUserDefaults
     */
    func saveState() {
        // Saves user OIDState into NSUserdefaults
        if(authState != nil){
            let archivedAuthState = NSKeyedArchiver.archivedDataWithRootObject(authState!)
            NSUserDefaults.standardUserDefaults().setObject(archivedAuthState, forKey: appConfig.kAppAuthExampleAuthStateKey)
        } else { NSUserDefaults.standardUserDefaults().setObject(nil, forKey: appConfig.kAppAuthExampleAuthStateKey) }
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    /**
     *   Loads the current authState from NSUserDefaults
     */
    func loadState() {
        if let archivedAuthState = NSUserDefaults.standardUserDefaults().objectForKey(appConfig.kAppAuthExampleAuthStateKey) as? NSData {
            if let authState = NSKeyedUnarchiver.unarchiveObjectWithData(archivedAuthState) as? OIDAuthState {
                setAuthState(authState)
            } else {  return  }
        } else { return }
    }
    
    /**
     *  Setter method for authState update
     *
     *  :param: authState The input value representing the new authorization state
     */
    private func setAuthState(authState:OIDAuthState?){
        self.authState = authState
        self.authState?.stateChangeDelegate = self
        self.stateChanged()
    }
    
    /**
     *  Required method
     */
    func stateChanged(){
        self.saveState()
    }
    
    /**
     *  Required method
     */
    func didChangeState(state: OIDAuthState) {
        self.stateChanged()
    }
    
    /**
     *  Starts Authorization Flow
     *
     *  :param: sender The UI button 'Get Tokens'
     */
    @IBAction func openIDbutton(sender: AnyObject) {
        authenticate()
    }
    
    /**
     *  Authorization Flow Sequence
     *  
     *  This method retrieves the OpenID Connect discovery document based on the configuration specified in 'Models.swift' and creates an AppAuth authState
     *  -   Builds the authentication request with helper method OIDAuthorizationRequest
     *  -   Opens in-app iOS Safari browser to validate user credientials
     *  -   Logs: Access Token, Refresh Token, and Id Token
     *  -   Alerts: Success
     */
    func authenticate() {
        // Sign in user with authCodeExchange
        let issuer = NSURL(string: appConfig.kIssuer)
        let redirectURI = NSURL(string: appConfig.kRedirectURI)
        
        // Discovers Endpoints
        OIDAuthorizationService.discoverServiceConfigurationForIssuer(issuer!) {
            config, error in
            
            if ((config == nil)) {
                print("Error retrieving discovery document: \(error?.localizedDescription)")
                return
            }
            print("Retrieved configuration: \(config!)")
            
            // Build Authentication Request
            let request = OIDAuthorizationRequest(configuration: config!,
                                                  clientId: self.appConfig.kClientID,
                                                  scopes: [OIDScopeOpenID, OIDScopeProfile, OIDScopeEmail, OIDScopePhone, OIDScopeAddress, "groups", "offline_access"],
                                                  redirectURL: redirectURI!,
                                                  responseType: OIDResponseTypeCode,
                                                  additionalParameters: nil)
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            
            print("Initiating Authorization Request: \(request!)")
            appDelegate.currentAuthorizationFlow =
                OIDAuthState.authStateByPresentingAuthorizationRequest(request!,presentingViewController: self){
                    authorizationResponse, error in
                    if(authorizationResponse != nil){
                        self.setAuthState(authorizationResponse)
                        let authToken = authorizationResponse!.lastTokenResponse!.accessToken!
                        let refreshToken = authorizationResponse!.lastTokenResponse!.refreshToken!
                        let idToken = authorizationResponse!.lastTokenResponse!.idToken!
                        print("Retrieved Tokens.\n\nAccess Token: \(authToken) \n\nRefresh Token: \(refreshToken) \n\nId Token: \(idToken)")
                        self.createAlert("Tokens", alertMessage: "Check logs for token values")
                        
                    } else {
                        print("Authorization Error: \(error!.localizedDescription)")
                        self.setAuthState(nil)
                    }
            }
        }
    }
    
    /**
     *  Calls Userinfo Endpoint
     *  
     *  - parameters:
     *   - sender: The UI button 'Get User Info'
     */
    @IBAction func userinfo(sender: AnyObject) {
        let userinfoEndpoint = authState?.lastAuthorizationResponse
            .request.configuration.discoveryDocument?.userinfoEndpoint
        if(userinfoEndpoint  == nil ) {
            print("Userinfo endpoint not declared in discovery document")
            self.createAlert("Error", alertMessage: "User info endpoint not declared in discovery document")
            return
        }
        sendUserInfoRequest(userinfoEndpoint!)
    }
    
    /**
     *  Creates HTTP request to the User Info API endpoint
     *  
     *  - parameters:
     *    - url: The url in NSURL format for the request to be made
     */
    func sendUserInfoRequest(url: NSURL){
        if checkAuthState() {
            performRequest("User Info", currentAccessToken: (authState?.lastTokenResponse?.accessToken)!, url: url)
        } else { print("Not authenticated") }
    }
    
    /**
     *  Performs HTTP Request with current access token
     *
     *  - parameters:
     *      - returnTitle: Title of response alert
     *      - currentAccessToken: Current access token (may be refreshed)
     *      - url: NSURL of API endpoint
     */
    func performRequest(returnTitle: String, currentAccessToken: String, url: NSURL) {
        authState?.withFreshTokensPerformAction(){
            accessToken, idToken, error in
            if(error != nil){
                print("Error fetching fresh tokens: \(error!.localizedDescription)")
                return
            }
            
            if(currentAccessToken != accessToken){
                print("Access token refreshed automatially (\(currentAccessToken) to \(accessToken!))")
            } else {
                print("Access token was fresh and not updated [\(accessToken!)]")
            }
            
            // Create Request to endpoint, with access_token in Authorization Header
            let request = NSMutableURLRequest(URL: url)
            let authorizationHeaderValue = "Bearer \(accessToken!)"
            request.addValue(authorizationHeaderValue, forHTTPHeaderField: "Authorization")
            
            let config = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: config)
            
            //Perform HTTP Request
            let postDataTask = session.dataTaskWithRequest(request) {
                data, response, error in
                dispatch_async( dispatch_get_main_queue() ){
                    if let httpResponse = response as? NSHTTPURLResponse {
                        do{
                            let jsonDictionaryOrArray = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
                            if ( httpResponse.statusCode != 200 ){
                                let responseText = NSString(data: data!, encoding: NSUTF8StringEncoding)
                                if ( httpResponse.statusCode == 401 ){
                                    
                                    let oauthError = OIDErrorUtilities.resourceServerAuthorizationErrorWithCode(0,
                                        errorResponse: jsonDictionaryOrArray as? [NSObject : AnyObject],
                                        underlyingError: error)
                                    self.authState?.updateWithAuthorizationError(oauthError!)
                                    print("Authorization Error (\(oauthError)). Response: \(responseText)")
                                }
                                else{ print("HTTP: \(httpResponse.statusCode). Response: \(responseText)") }
                                return
                            }
                            print("Success: \(jsonDictionaryOrArray)")
                            self.createAlert(returnTitle, alertMessage: "\(jsonDictionaryOrArray)")
                        } catch {  print("Error while serializing data to JSON")  }
                    } else {
                        print("Non-HTTP response \(error)")
                        return
                    }
                }
            }
            postDataTask.resume()
        }
    }
    
    /**
     *  Creates pop-up alert given Title and Message
     *
     *  Dismisses on UI button click 'Cancel'
     *
     *  - parameters:
     *    - alertTitle: Title of alert
     *    - alertMessage: Output message
     */
    func createAlert(alertTitle: String, alertMessage: String) {
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
        alert.view.tintColor = UIColor.blackColor()
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        let textIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRectMake(10, 5, 50, 50)) as UIActivityIndicatorView
        alert.view.addSubview(textIndicator)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    /**
     *  Segue to ImageView for testing Demo API Call
     *
     *  Sends current authState and configuration to view
     *
     *  NOTE: Please read documentation for server repo in README
     */
    /*  Segue to next ImageView for testing Demo API Call    */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?){
        if segue.identifier == "ImageViewSegue" {
            let destinationController = segue.destinationViewController as! ImageViewController
            destinationController.authState = authState
            destinationController.appConfig = appConfig
        }
    }
    
    /**
     *  Outlet to call refreshTokens method
     *
     *  - parameters:
     *    - sender: UI button 'Refresh Token'
     */
    @IBAction func refreshTokenButton(sender: AnyObject) {
        // Refresh Token
        refreshTokens()
    }
    
    /**
     *  Outlet to call revokeTokens method
     *
     *  - parameters:
     *    - sender: UI button 'Revoke Token'
     */
    @IBAction func revokeTokensButton(sender: AnyObject) {
        // Revoke Token
        revokeToken()
    }
    
    /**
     *  Outlet to call clearTokens method
     *  
     *  - parameters:
     *    - sender: UI button 'Clear Tokens'
     */
    @IBAction func clearButton(sender: AnyObject) {
        // Clear all
        clearTokens()
    }
    
    /**
     *  Connects UI image icons to functions
     */
    func connectIcons() {
        // Assign Access Icon to Retrieve Access Token
        let access_gesture = UITapGestureRecognizer(target:self, action: #selector(OktaAppAuth.openIDbutton(_:)))
        accessTokenIcon.userInteractionEnabled = true
        accessTokenIcon.addGestureRecognizer(access_gesture)
        
        //Assign Userinfo Icon to Retrieve User Info
        let user_gesture = UITapGestureRecognizer(target: self, action:#selector(OktaAppAuth.userinfo(_:)))
        userInfoIcon.userInteractionEnabled = true
        userInfoIcon.addGestureRecognizer(user_gesture)
        
        //Assign API Call Icon to Retrieve Info from Demo Endpoint
        let api_gesture = UITapGestureRecognizer(target: self, action:#selector(OktaAppAuth.apiCall))
        apiCallIcon.userInteractionEnabled = true
        apiCallIcon.addGestureRecognizer(api_gesture)
        
        //Assign Refresh Token Icon to Function
        let refresh_gesture = UITapGestureRecognizer(target: self, action:#selector(OktaAppAuth.refreshTokens))
        refreshTokenIcon.userInteractionEnabled = true
        refreshTokenIcon.addGestureRecognizer(refresh_gesture)
        
        // Assign Revoke Token Icon to Function
        let revoke_gesture = UITapGestureRecognizer(target: self, action:#selector(OktaAppAuth.revokeToken))
        revokeTokenIcon.userInteractionEnabled = true
        revokeTokenIcon.addGestureRecognizer(revoke_gesture)
        
        // Assign Sign out to Function
        let clear_gesture = UITapGestureRecognizer(target: self, action: #selector(OktaAppAuth.clearTokens))
        clearIcon.userInteractionEnabled = true
        clearIcon.addGestureRecognizer(clear_gesture)

    }
    
    /**
     *  Revokes current access token by calling OAuth revoke endpoint
     */
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
                let postDataTask = session.dataTaskWithRequest(request) {
                    data, response, error in
                    dispatch_async( dispatch_get_main_queue() ){
                        if let httpResponse = response as? NSHTTPURLResponse {
                            do{
                                if (httpResponse.statusCode == 200 || httpResponse.statusCode == 204){
                                    self.createAlert("Token Revoked", alertMessage: "Previous access token is considered invalid")
                                    print("Previous access token is considered invalid")
                                    self.authState?.setNeedsTokenRefresh()
                                    return
                                } else {
                                    // Error JSON
                                    let jsonDictionaryOrArray = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
                                    if ( httpResponse.statusCode != 200 || httpResponse.statusCode != 204 ){
                                        let responseText = NSString(data: data!, encoding: NSUTF8StringEncoding)
                                        if ( httpResponse.statusCode == 401 ){
                                            let oauthError = OIDErrorUtilities.resourceServerAuthorizationErrorWithCode(0,
                                                errorResponse: jsonDictionaryOrArray as? [NSObject : AnyObject],
                                                underlyingError: error)
                                            self.authState?.updateWithAuthorizationError(oauthError!)
                                            print("Authorization Error (\(oauthError)). Response: \(responseText)")
                                        }
                                        else{ print("HTTP: \(httpResponse.statusCode). Response: \(responseText)") }
                                        return
                                    }                                 }
                            } catch { print("Error while serializing data to JSON")  }
                        } else {
                            print("Non-HTTP response \(error)")
                            return
                        }
                    }
                }
                postDataTask.resume()
            }
        } else {
            print("Not authenticated")
            createAlert("Error", alertMessage: "Not authenticated")
        }
    }
    
    /**
     *  Refreshes the current tokens with existing refresh token
     */
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
        } else {
            print("Not authenticated")
            createAlert("Error", alertMessage: "Not authenticated")
        }
    }
    
    /**
     *  Removes all tokens from curent authState
     */
    func clearTokens(){
        if checkAuthState() {
            self.setAuthState(nil)
            let clearAll = NSBundle.mainBundle().bundleIdentifier!
            NSUserDefaults.standardUserDefaults().removePersistentDomainForName(clearAll)
            createAlert("Signed out", alertMessage: "Successfully forgot all tokens")
        } else {
            print("Not authenticated")
            createAlert("Error", alertMessage: "Not authenticated")
        }
        
    }
    
    /**
     *  Calls external server API to return image
     *
     *  NOTE: Work in progress
     */
    func apiCall() {
        if checkAuthState(){
            self.performSegueWithIdentifier("ImageViewSegue", sender: self)
        } else {
            print("Not authenticated")
            createAlert("Error", alertMessage: "Not authenticated")
        }
    }
    
    /**
     *  Verifies authState was performed
     */
    func checkAuthState() -> Bool {
        if (authState != nil){
            return true
        } else { return false }
    }
}


