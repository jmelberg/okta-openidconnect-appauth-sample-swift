import Foundation

class OktaConfiguration {
    let kIssuer: String!
    let kClientID: String!
    let kRedirectURI: String!
    let kAppAuthExampleAuthStateKey: String!
    let apiEndpoint: NSURL!
    
    init(){
        kIssuer = "https://example.com"
        kClientID = "CLIENT_ID"
        kRedirectURI = "com.example:/openid"
        kAppAuthExampleAuthStateKey = "com.okta.openid.authState"
        apiEndpoint = NSURL(string: "https://example.server.com")
    }
}
