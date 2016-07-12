import Foundation

class OktaConfiguration {
    let kIssuer: String!
    let kClientID: String!
    let kRedirectURI: String!
    let kAppAuthExampleAuthStateKey: String!
    let apiEndpoint: NSURL!
    
    init(){
        kIssuer = "https://jordandemo.oktapreview.com"
        kClientID = "Jw1nyzbsNihSuOETY3R1"
        kRedirectURI = "com.oktapreview.jordandemo:/openid"
        kAppAuthExampleAuthStateKey = "com.okta.openid.authState"
        apiEndpoint = NSURL(string: "https://example.server.com")
    }
}
