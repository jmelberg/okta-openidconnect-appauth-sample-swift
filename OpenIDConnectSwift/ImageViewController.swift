import UIKit
import AppAuth

class ImageViewController: UIViewController {
    
    // MARK: Properties
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var activityLoad: UIActivityIndicatorView!
    @IBOutlet weak var imageText: UILabel!
    
    // Retrieve from segue needed request values
    var authState:OIDAuthState?
    var appConfig = OktaConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityLoad.startAnimating()
        sendDemoApiRequest(appConfig.apiEndpoint!, accessToken: (authState?.lastTokenResponse!.accessToken)!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
     *  Dismisses ImageViewController
     */
    @IBAction func backButton(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    /**
     *  Calls endpoint on given server to decode and validate access token
     *
     *  NOTE: Does not refresh tokens before request
     *
     *  - parameters:
     *    - url: NSURL of server endpoint
     *    - accessToken: Current token
     */
    /*  Calls  apiEndpoint on a server and populates imageView with returned image    */
    func sendDemoApiRequest(url: NSURL, accessToken: String){
        print("Performing DEMO API request without auto-refresh")
        
        // Create Requst to Demo API endpoint, with access_token in Authorization Header
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        let authorizationHeaderValue = "Bearer \(accessToken)"
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
                        if let imageURL = jsonDictionaryOrArray["image"] as? String{
                            if let name = jsonDictionaryOrArray["name"] as? NSString{
                                self.loadImageFromURL(imageURL, name: name as String)
                                print("\(jsonDictionaryOrArray)")
                            }
                        }
                        if let found_error = jsonDictionaryOrArray["Error"]{
                            self.imageText.text = found_error as? String
                            self.activityLoad.stopAnimating()
                            print("\(jsonDictionaryOrArray)")
                        }
                    } catch {
                        print("Error while serializing data to JSON")
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                } else {
                    print("Non-HTTP response \(error)")
                    return
                }
            }
        }
        postDataTask.resume()
    }

    /**
     *  Loads ImageView and ImageText from response object
     * 
     *  - parameters:
     *    - url: Url of image path
     *    - name: Name of user
     */
    func loadImageFromURL(url: String, name: String){
        print(url)
        if let userImageURL = NSURL(string: url){
            let data = NSData(contentsOfURL: userImageURL)
            if (data != nil){
                self.image.image = UIImage(data: data!)
                self.imageText.text = name
                self.activityLoad.stopAnimating()
            } else { return }
            
        }
    }
}